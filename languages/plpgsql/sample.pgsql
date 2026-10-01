-- PL/pgSQL showcase: functions, triggers, DO blocks, cursors, exceptions and dynamic SQL.
/* A block comment
   /* with a nested block comment (Postgres allows nesting) */
   still inside */
-- TODO: partition stock_audit by month
-- FIXME: reorder_needed ignores reserved stock

CREATE EXTENSION IF NOT EXISTS pgcrypto;
SET search_path TO public, inventory;
SET LOCAL statement_timeout = '5s';
CREATE SCHEMA IF NOT EXISTS inventory AUTHORIZATION postgres;

-- ── Types and tables ──
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'cancelled');
CREATE TYPE money_pair AS (amount numeric(12,2), currency char(3));
CREATE DOMAIN sku_t AS text CHECK (VALUE ~ '^[A-Z]-[0-9]{3}$');

CREATE TABLE IF NOT EXISTS stock (
    sku        sku_t PRIMARY KEY,
    qty        integer NOT NULL DEFAULT 0 CHECK (qty >= 0),
    price      numeric(10,2) NOT NULL,
    tags       text[] DEFAULT ARRAY[]::text[],
    meta       jsonb DEFAULT '{}'::jsonb,
    status     order_status DEFAULT 'pending',
    id         bigint GENERATED ALWAYS AS IDENTITY,
    updated_at timestamptz DEFAULT now(),
    search     tsvector GENERATED ALWAYS AS (to_tsvector('english', sku)) STORED
);
CREATE TABLE stock_audit (sku text, old_qty int, new_qty int, changed_at timestamptz);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_meta ON stock USING gin (meta jsonb_path_ops) WHERE qty > 0;
CREATE SEQUENCE order_seq START WITH 100 INCREMENT BY 1 CACHE 10;

-- ── Literals ──
SELECT 'it''s', E'tab\there\nnewline \x41 é', $$dollar quoted$$, $tag$tagged $$ inside$tag$,
       U&'d\0061t\+000061', B'1010', X'1F', 0x1F, 0o17, 0b101, 1_000_000, 1.5e-3, .5, -3,
       TRUE, FALSE, NULL, 'infinity'::float8, 'NaN'::float8,
       DATE '2025-01-01', TIMESTAMPTZ '2025-01-01 00:00:00+00', INTERVAL '1 day 2 hours',
       ARRAY[1, 2, 3], ARRAY[[1, 2], [3, 4]], '{1,2,3}'::int[], '{"a": [1, null, true]}'::jsonb,
       ROW(1, 'x'), (1, 2), 'x'::text, CAST('5' AS integer), '5'::int4::numeric, $1, $2::text;

-- ── Functions ──
CREATE OR REPLACE FUNCTION reorder_needed(p_sku text, p_threshold integer DEFAULT 25)
RETURNS boolean
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public
COST 100
AS $$
DECLARE
    v_qty integer;
BEGIN
    SELECT qty INTO v_qty FROM stock WHERE sku = p_sku;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'unknown sku %', p_sku USING ERRCODE = 'no_data_found';
    END IF;
    RETURN v_qty <= p_threshold;
END;
$$;

CREATE OR REPLACE FUNCTION stock_audit() RETURNS trigger AS $$
BEGIN
    INSERT INTO stock_audit(sku, old_qty, new_qty, changed_at)
    VALUES (NEW.sku, OLD.qty, NEW.qty, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION demo(
    IN a integer,
    INOUT b text DEFAULT 'x',
    OUT c numeric,
    VARIADIC rest integer[] DEFAULT '{}'
) RETURNS record AS $body$
<<outer_block>>
DECLARE
    counter    integer := 0;
    r          record;
    row_var    stock%ROWTYPE;
    col_type   stock.qty%TYPE;
    constant_v CONSTANT numeric NOT NULL DEFAULT 3.14;
    arr        int[] := ARRAY[1, 2, 3];
    cur        CURSOR FOR SELECT sku FROM stock;
    cur2       refcursor;
    cur3 CURSOR (min_qty integer) FOR SELECT sku FROM stock WHERE qty >= min_qty;
    j          jsonb := '{"k": 1}';
    n          integer;
    msg        text;
    state      text;
    detail     text;
BEGIN
    -- Assignments and expressions
    counter := counter + 1;
    counter = counter * 2;
    c := (a ** 2) / 3.0 + a % 3 - (a << 1) | (a & 3) # 1;
    b := b || ' suffix' || E'\n';
    arr[1] := arr[2] + 1;
    j := j || '{"x": 2}'::jsonb;
    msg := j ->> 'k';
    msg := j -> 'k' ->> 'x';
    msg := j #>> '{k}';
    PERFORM pg_sleep(0);
    PERFORM 1 WHERE j @> '{"k": 1}' AND j ? 'k' AND NOT j ?| ARRAY['z'];

    -- Conditionals
    IF a > 10 THEN
        counter := 1;
    ELSIF a > 5 THEN
        counter := 2;
    ELSEIF a > 2 THEN
        counter := 3;
    ELSE
        counter := 4;
    END IF;

    CASE a
        WHEN 1, 2 THEN counter := 10;
        WHEN 3 THEN counter := 20;
        ELSE counter := 0;
    END CASE;
    CASE WHEN a < 0 THEN counter := -1; WHEN a = 0 THEN counter := 0; END CASE;

    -- Loops
    <<named_loop>>
    LOOP
        counter := counter + 1;
        EXIT named_loop WHEN counter > 10;
        CONTINUE WHEN counter % 2 = 0;
    END LOOP named_loop;

    WHILE counter < 20 LOOP counter := counter + 1; END LOOP;
    FOR i IN 1..10 LOOP counter := counter + i; END LOOP;
    FOR i IN REVERSE 10..1 BY 2 LOOP counter := counter - i; END LOOP;
    FOR r IN SELECT sku, qty FROM stock WHERE qty < 25 ORDER BY qty LOOP
        RAISE NOTICE 'low: % (%)', r.sku, r.qty;
    END LOOP;
    FOR r IN EXECUTE format('SELECT * FROM %I WHERE qty > $1', 'stock') USING 5 LOOP NULL; END LOOP;
    FOREACH n IN ARRAY arr LOOP counter := counter + n; END LOOP;
    FOREACH n SLICE 1 IN ARRAY ARRAY[[1, 2], [3, 4]] LOOP NULL; END LOOP;

    -- Cursors
    OPEN cur;
    FETCH cur INTO r;
    FETCH NEXT FROM cur INTO r;
    MOVE FORWARD 2 FROM cur;
    CLOSE cur;
    OPEN cur3(min_qty := 5);
    OPEN cur2 FOR SELECT * FROM stock;
    FETCH FIRST FROM cur2 INTO row_var;
    CLOSE cur2;

    -- SQL inside
    SELECT count(*), sum(qty) INTO STRICT n, col_type FROM stock;
    INSERT INTO stock (sku, qty, price) VALUES ('A-100', 1, 4.5)
        ON CONFLICT (sku) DO UPDATE SET qty = stock.qty + EXCLUDED.qty
        RETURNING qty INTO n;
    UPDATE stock SET qty = qty - 1 WHERE sku = 'A-100' RETURNING * INTO row_var;
    DELETE FROM stock WHERE qty = 0;
    GET DIAGNOSTICS n = ROW_COUNT;
    GET CURRENT DIAGNOSTICS n = ROW_COUNT;
    GET STACKED DIAGNOSTICS msg = MESSAGE_TEXT, detail = PG_EXCEPTION_DETAIL, state = RETURNED_SQLSTATE;

    -- Dynamic SQL
    EXECUTE 'UPDATE stock SET qty = qty + $1 WHERE sku = $2' USING 5, 'A-100';
    EXECUTE format('SELECT %L, %I, %s', 'lit', 'ident', 5) INTO msg;

    -- Messages
    RAISE DEBUG 'debug %', counter;
    RAISE LOG 'log';
    RAISE INFO 'info';
    RAISE NOTICE 'notice %%';
    RAISE WARNING 'warning';
    RAISE EXCEPTION 'custom' USING ERRCODE = '22012', HINT = 'check input', DETAIL = 'details';
    RAISE SQLSTATE '22012' USING MESSAGE = 'by sqlstate';
    RAISE division_by_zero;
    ASSERT counter > 0, 'counter positive';

    -- Exceptions
    BEGIN
        n := 1 / 0;
    EXCEPTION
        WHEN division_by_zero THEN
            RAISE NOTICE 'caught';
        WHEN unique_violation OR foreign_key_violation THEN
            NULL;
        WHEN SQLSTATE '23505' THEN
            RAISE;
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS msg = MESSAGE_TEXT;
            RAISE EXCEPTION 'wrapped: %', msg;
    END;

    -- Transaction control (procedures only) and returns
    RETURN;
END outer_block;
$body$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION low_stock(p_limit int) RETURNS TABLE (sku text, qty int)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT s.sku::text, s.qty FROM stock s WHERE s.qty < p_limit;
    RETURN QUERY EXECUTE 'SELECT sku::text, qty FROM stock';
    RETURN NEXT;
END $$;

CREATE OR REPLACE FUNCTION series(n int) RETURNS SETOF integer AS $$
DECLARE i int;
BEGIN
    FOR i IN 1..n LOOP RETURN NEXT i; END LOOP;
    RETURN;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE restock(p_sku text, p_qty integer)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE stock SET qty = qty + p_qty WHERE sku = p_sku;
    COMMIT;
    UPDATE stock SET updated_at = now() WHERE sku = p_sku;
    ROLLBACK;
END $$;

CALL restock('A-100', 5);

-- ── Triggers ──
CREATE TRIGGER stock_audit_trg AFTER UPDATE OF qty ON stock
    FOR EACH ROW WHEN (OLD.qty IS DISTINCT FROM NEW.qty) EXECUTE FUNCTION stock_audit();
CREATE TRIGGER stmt_trg BEFORE INSERT OR DELETE ON stock
    FOR EACH STATEMENT EXECUTE PROCEDURE stock_audit();
CREATE CONSTRAINT TRIGGER ct AFTER INSERT ON stock DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION stock_audit();
CREATE EVENT TRIGGER ddl_watch ON ddl_command_end EXECUTE FUNCTION stock_audit();

CREATE OR REPLACE FUNCTION trigger_vars() RETURNS trigger AS $$
BEGIN
    RAISE NOTICE '% % % % % %', TG_NAME, TG_WHEN, TG_LEVEL, TG_OP, TG_TABLE_NAME, TG_TABLE_SCHEMA;
    IF TG_OP = 'INSERT' THEN RETURN NEW; ELSIF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

-- ── DO blocks ──
DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT sku FROM stock WHERE reorder_needed(sku) LOOP
        RAISE NOTICE 'reorder %', r.sku;
    END LOOP;
END $$;

DO LANGUAGE plpgsql $do$ BEGIN PERFORM 1; END $do$;

-- ── Queries ──
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 5
), totals AS MATERIALIZED (
    SELECT status, sum(price * qty) AS s FROM stock GROUP BY ROLLUP (status)
)
SELECT n, s,
       row_number() OVER (ORDER BY n) AS rn,
       sum(s) OVER (PARTITION BY status ORDER BY n ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running,
       lag(s) OVER w AS prev,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY n) AS median,
       count(*) FILTER (WHERE n > 2) AS big
FROM seq CROSS JOIN LATERAL (SELECT * FROM totals LIMIT 1) t
WINDOW w AS (ORDER BY n)
ORDER BY n DESC NULLS LAST
LIMIT 10 OFFSET 2 FOR UPDATE SKIP LOCKED;

SELECT DISTINCT ON (sku) sku, qty FROM stock WHERE tags && ARRAY['a'] AND sku ~* '^a' AND sku SIMILAR TO 'A%' AND qty BETWEEN SYMMETRIC 1 AND 5;
SELECT * FROM stock TABLESAMPLE SYSTEM (10) WHERE meta @> '{"a":1}' AND meta #> '{a,b}' IS NOT NULL;
SELECT generate_series(1, 3), unnest(ARRAY[1, 2]), string_agg(sku, ', ' ORDER BY sku), jsonb_build_object('a', 1);
SELECT * FROM stock s JOIN LATERAL jsonb_each(s.meta) AS kv(k, v) ON true NATURAL LEFT JOIN stock_audit USING (sku);
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT * FROM stock;
COPY stock (sku, qty, price) FROM STDIN WITH (FORMAT csv, HEADER true);
LISTEN stock_changed;
NOTIFY stock_changed, 'payload';
GRANT SELECT, UPDATE ON stock TO PUBLIC;
REVOKE ALL ON SCHEMA inventory FROM PUBLIC;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS note text, ALTER COLUMN qty SET DEFAULT 1;
COMMENT ON TABLE stock IS 'Current stock levels';
BEGIN ISOLATION LEVEL SERIALIZABLE;
SAVEPOINT sp1;
ROLLBACK TO SAVEPOINT sp1;
COMMIT;
VACUUM (ANALYZE, VERBOSE) stock;
\echo psql meta-command

-- ── More PL/pgSQL and PostgreSQL DDL ──
CREATE OR REPLACE VIEW v_low AS SELECT sku, qty FROM stock WHERE qty < 25 WITH CHECK OPTION;
CREATE MATERIALIZED VIEW mv_totals AS SELECT status, count(*) AS n FROM stock GROUP BY status WITH NO DATA;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_totals;
CREATE TEMP TABLE scratch (id int) ON COMMIT DROP;
CREATE UNLOGGED TABLE fast_log (msg text) WITH (fillfactor = 70);
CREATE TABLE measurements (ts timestamptz NOT NULL, v double precision) PARTITION BY RANGE (ts);
CREATE TABLE measurements_2025 PARTITION OF measurements FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE child () INHERITS (stock);
CREATE FOREIGN TABLE remote_stock (sku text, qty int) SERVER remote OPTIONS (schema_name 'public', table_name 'stock');
CREATE SERVER remote FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'db.example.com', dbname 'inventory');
CREATE USER MAPPING FOR CURRENT_USER SERVER remote OPTIONS (user 'app', password 'example-not-a-real-password');
CREATE RULE protect_delete AS ON DELETE TO stock DO INSTEAD NOTHING;
CREATE POLICY own_rows ON stock FOR SELECT TO app_role USING (current_user = 'app_role') WITH CHECK (true);
ALTER TABLE stock ENABLE ROW LEVEL SECURITY;
CREATE ROLE app_role LOGIN PASSWORD 'example-not-a-real-password' NOSUPERUSER CREATEDB VALID UNTIL 'infinity';
CREATE AGGREGATE sum_sq(int) (SFUNC = int4pl, STYPE = int, INITCOND = '0');
CREATE OPERATOR === (LEFTARG = text, RIGHTARG = text, FUNCTION = texteq, COMMUTATOR = ===);
CREATE CAST (text AS sku_t) WITH INOUT AS IMPLICIT;
CREATE COLLATION ci (provider = icu, locale = 'und-u-ks-level2', deterministic = false);
CREATE STATISTICS st_stock (dependencies) ON sku, qty FROM stock;
CREATE PUBLICATION pub FOR TABLE stock;
CREATE SUBSCRIPTION sub CONNECTION 'host=192.0.2.5 dbname=inventory' PUBLICATION pub;
CREATE TEXT SEARCH CONFIGURATION inv (COPY = english);
CREATE LANGUAGE plmine HANDLER mine_handler;
CREATE TABLESPACE fast LOCATION '/mnt/fast';
CREATE INDEX idx_expr ON stock ((lower(sku))) INCLUDE (qty) WITH (fillfactor = 90) TABLESPACE fast;
CREATE INDEX idx_brin ON measurements USING brin (ts) WHERE v IS NOT NULL;
CREATE UNIQUE INDEX idx_u ON stock (sku) NULLS NOT DISTINCT;
ALTER TABLE stock ADD CONSTRAINT stock_excl EXCLUDE USING gist (sku WITH =) DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE stock ALTER COLUMN qty TYPE bigint USING qty::bigint, ALTER COLUMN price SET STORAGE EXTERNAL, DROP CONSTRAINT IF EXISTS chk CASCADE;
ALTER SEQUENCE order_seq OWNED BY stock.id RESTART WITH 1000;
ALTER FUNCTION reorder_needed(text, integer) OWNER TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_role;
ALTER SYSTEM SET work_mem = '64MB';
SELECT pg_reload_conf();
DROP FUNCTION IF EXISTS reorder_needed(text, integer) CASCADE;
DROP TABLE IF EXISTS scratch, fast_log RESTRICT;
TRUNCATE stock, stock_audit RESTART IDENTITY CASCADE;
REINDEX (VERBOSE) TABLE stock;
CLUSTER stock USING idx_stock_meta;
SECURITY LABEL FOR selinux ON TABLE stock IS 'system_u:object_r:sepgsql_table_t:s0';
DISCARD ALL;
RESET ALL;
SHOW search_path;
SET ROLE app_role;
SET SESSION AUTHORIZATION DEFAULT;
PREPARE find_stock (text) AS SELECT * FROM stock WHERE sku = $1;
EXECUTE find_stock('A-100');
DEALLOCATE ALL;
DECLARE cur_stock SCROLL CURSOR WITH HOLD FOR SELECT * FROM stock;
FETCH BACKWARD 5 FROM cur_stock;
CLOSE cur_stock;
LOCK TABLE stock IN SHARE ROW EXCLUSIVE MODE NOWAIT;
CHECKPOINT;
TABLE stock;
MERGE INTO stock t USING (VALUES ('A-100', 5)) AS s(sku, qty) ON t.sku = s.sku
    WHEN MATCHED AND s.qty = 0 THEN DELETE
    WHEN MATCHED THEN UPDATE SET qty = t.qty + s.qty
    WHEN NOT MATCHED THEN INSERT (sku, qty, price) VALUES (s.sku, s.qty, 0);
SELECT * FROM unnest(ARRAY[1, 2], ARRAY['a', 'b']) WITH ORDINALITY AS t(n, c, ord);
SELECT sku, status, count(*) FROM stock GROUP BY GROUPING SETS ((sku), (status), ()), CUBE (sku, status);
SELECT sku FROM stock ORDER BY sku USING <;
SELECT 'a' COLLATE "C", 'x' AT TIME ZONE 'UTC', now() AT TIME ZONE 'Europe/London', extract(epoch FROM now()), interval '1 day' * 2, date_trunc('day', now()), age(now(), '2020-01-01');
SELECT '192.0.2.0/24'::cidr >>= '192.0.2.5'::inet, '{"a":1}'::jsonb @? '$.a', '[1,5)'::int4range @> 3, 'a & b'::tsquery, to_tsvector('x') @@ to_tsquery('x'), '1 2'::point <-> '3 4'::point, ~ 5, 5 !, @ -5, |/ 25, ||/ 27;
SELECT jsonb_path_query('{"a":[1,2]}', '$.a[*] ? (@ > 1)'), jsonb_agg(sku) FILTER (WHERE qty > 0), json_build_array(1, 'a'), row_to_json(s), to_jsonb(s) - 'sku' #- '{a,b}' FROM stock s;
SELECT * FROM xmltable('/rows/row' PASSING '<rows><row id="1"/></rows>'::xml COLUMNS id int PATH '@id');
SELECT * FROM json_to_recordset('[{"a":1}]') AS x(a int);
SELECT 1 FROM stock WHERE sku = ANY (ARRAY['A-100', 'B-200']) AND NOT (qty = ALL (ARRAY[1, 2])) AND sku IS DISTINCT FROM NULL AND qty IS NOT NULL AND tags <@ ARRAY['a'];
SELECT CASE WHEN qty > 0 THEN 'in' ELSE 'out' END, COALESCE(qty, 0), NULLIF(qty, 0), GREATEST(1, 2), LEAST(1, 2), qty::text || '!' FROM stock;
\set ON_ERROR_STOP on
\c inventory
\dt+ stock
\x auto
