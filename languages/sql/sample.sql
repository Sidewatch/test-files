-- SQL:2023 — syntax showcase (ISO core, then widely used PostgreSQL / MySQL / SQLite / Hive forms)
-- ── Comments ──
-- Line comment: warehouse inventory schema and reports.
/* Block comment
   spanning several lines. */
/* TODO: partition the movements table */
-- FIXME: reorder query ignores supplier lead time

-- ── DDL: tables with every constraint form ──
CREATE TABLE IF NOT EXISTS warehouses (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        VARCHAR(8)  NOT NULL UNIQUE,
    name        TEXT        NOT NULL,
    region      CHAR(2)     DEFAULT 'EU',
    capacity    INTEGER     CHECK (capacity > 0),
    opened_on   DATE,
    created_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    sku         TEXT PRIMARY KEY,
    name        VARCHAR(120) NOT NULL,
    description TEXT,
    unit_price  NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (unit_price >= 0),
    weight_kg   REAL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    attributes  BYTEA,
    tags        JSON,
    CONSTRAINT sku_format CHECK (sku LIKE '___-%')
);

CREATE TABLE stock (
    warehouse_id INTEGER NOT NULL REFERENCES warehouses (id) ON DELETE CASCADE ON UPDATE NO ACTION,
    sku          TEXT    NOT NULL,
    quantity     INTEGER NOT NULL DEFAULT 0,
    reserved     INTEGER NOT NULL DEFAULT 0,
    updated_at   TIMESTAMP,
    PRIMARY KEY (warehouse_id, sku),
    FOREIGN KEY (sku) REFERENCES products (sku) ON DELETE RESTRICT,
    CHECK (reserved <= quantity)
);

CREATE TABLE movements (
    id           INTEGER PRIMARY KEY,
    warehouse_id INTEGER NOT NULL,
    sku          TEXT NOT NULL,
    delta        INTEGER NOT NULL,
    reason       TEXT CHECK (reason IN ('receipt', 'shipment', 'adjustment', 'return')),
    note         TEXT,
    moved_at     TIMESTAMP NOT NULL DEFAULT (now()),
    total_cents  BIGINT GENERATED ALWAYS AS (delta * 100) STORED,
    FOREIGN KEY (warehouse_id, sku) REFERENCES stock (warehouse_id, sku)
);

CREATE TEMPORARY TABLE scratch (n INTEGER, label TEXT);
CREATE UNLOGGED TABLE staging (n INTEGER, label TEXT);
CREATE TABLE measurements (id INTEGER, readings INTEGER[], grid INTEGER[3], names TEXT ARRAY, codes INT ARRAY[4]);
CREATE TABLE ledger_parts (id INTEGER NOT NULL) PARTITION BY RANGE (id);
CREATE TABLE named_constraints (
    id INTEGER,
    label TEXT,
    CONSTRAINT pk_named PRIMARY KEY (id)
);
CREATE TABLE stock_snapshot AS SELECT warehouse_id, sku, quantity FROM stock WHERE quantity > 0;

-- ── Schemas, databases, sequences, extensions, types, roles ──
CREATE DATABASE warehouse_db;
CREATE SCHEMA IF NOT EXISTS inventory AUTHORIZATION acme_admin;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SEQUENCE IF NOT EXISTS inventory.sku_seq START WITH 1000 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 CACHE 10 NO CYCLE;
CREATE TYPE inventory.stock_state AS ENUM ('pending', 'active', 'retired');
CREATE ROLE acme_reader LOGIN PASSWORD 'example-not-a-real-key';
ALTER SEQUENCE inventory.sku_seq RESTART WITH 2000;
ALTER SCHEMA inventory RENAME TO inv;
ALTER ROLE acme_reader SET search_path = inv;
ALTER DATABASE warehouse_db SET timezone = 'UTC';
ALTER INDEX idx_a RENAME TO idx_b;
ALTER VIEW v RENAME TO v2;
DROP ROLE IF EXISTS acme_reader;
DROP SEQUENCE IF EXISTS inv.sku_seq;
DROP TYPE IF EXISTS inv.stock_state;
DROP EXTENSION IF EXISTS pgcrypto;
DROP SCHEMA IF EXISTS inv CASCADE;
DROP DATABASE IF EXISTS warehouse_db;

-- ── Indexes, views, materialized views ──
CREATE INDEX idx_movements_sku ON movements (sku, moved_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_name ON products (lower(name));
CREATE INDEX idx_stock_low ON stock (quantity) WHERE quantity < 25;
CREATE INDEX CONCURRENTLY idx_tags ON products USING gin (tags);
CREATE INDEX idx_expr ON products USING btree (lower(name) ASC) WHERE is_active;

CREATE VIEW low_stock AS
SELECT s.warehouse_id, s.sku, s.quantity
FROM stock AS s
WHERE s.quantity <= 25;

CREATE VIEW v_totals (sku, total) AS SELECT sku, SUM(quantity) FROM stock GROUP BY sku;
CREATE OR REPLACE VIEW recent AS SELECT * FROM movements WHERE moved_at > now() - INTERVAL '7 days';
CREATE MATERIALIZED VIEW stock_totals AS SELECT sku, SUM(quantity) AS total FROM stock GROUP BY sku WITH NO DATA;

-- ── Functions and triggers ──
CREATE FUNCTION add_one(n INTEGER) RETURNS INTEGER LANGUAGE SQL IMMUTABLE AS $$ SELECT n + 1 $$;

CREATE FUNCTION stock_of(IN wanted TEXT, OUT total INTEGER, INOUT scale INTEGER DEFAULT 1, VARIADIC extra INTEGER[])
RETURNS RECORD
LANGUAGE SQL
CALLED ON NULL INPUT
VOLATILE
SECURITY INVOKER
AS $fn$ SELECT SUM(quantity) * scale, scale FROM stock WHERE sku = wanted $fn$;

CREATE FUNCTION pure_math(a INT, b INT) RETURNS INT
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 10
AS $$ SELECT a * b $$;

CREATE FUNCTION recent_moves(wanted TEXT) RETURNS TABLE (id INTEGER, delta INTEGER)
LANGUAGE SQL STABLE LEAKPROOF SECURITY DEFINER ROWS 100
AS $$ SELECT id, delta FROM movements WHERE sku = wanted $$;

CREATE FUNCTION one() RETURNS INT LANGUAGE SQL RETURN 1;
CREATE FUNCTION two() RETURNS INT LANGUAGE SQL BEGIN ATOMIC SELECT 2; END;

CREATE TRIGGER trg_stock_touch
AFTER UPDATE OF quantity ON stock
FOR EACH ROW
WHEN (NEW.quantity <> OLD.quantity)
EXECUTE FUNCTION touch_stock();

CREATE TRIGGER trg_before BEFORE INSERT ON stock FOR EACH ROW EXECUTE PROCEDURE touch_stock();
CREATE TRIGGER trg_multi AFTER INSERT OR UPDATE OR DELETE ON stock FOR EACH STATEMENT EXECUTE FUNCTION audit_stock();
CREATE TRIGGER trg_view INSTEAD OF INSERT ON v_totals FOR EACH ROW EXECUTE FUNCTION touch_stock();
CREATE CONSTRAINT TRIGGER trg_deferred AFTER INSERT ON stock DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION touch_stock();

-- ── ALTER and DROP ──
ALTER TABLE products ADD COLUMN supplier TEXT NOT NULL DEFAULT 'none';
ALTER TABLE products ADD CONSTRAINT price_positive CHECK (unit_price >= 0);
ALTER TABLE products ADD CONSTRAINT fk_vendor FOREIGN KEY (supplier) REFERENCES suppliers (code);
ALTER TABLE products ALTER COLUMN name SET NOT NULL;
ALTER TABLE products ALTER COLUMN name DROP NOT NULL;
ALTER TABLE products ALTER COLUMN unit_price SET DEFAULT 0;
ALTER TABLE products ALTER COLUMN unit_price TYPE NUMERIC(12, 2);
ALTER TABLE products RENAME COLUMN supplier TO vendor;
ALTER TABLE products DROP CONSTRAINT price_positive;
ALTER TABLE products DROP COLUMN vendor;
ALTER TABLE products OWNER TO acme_admin;
ALTER TABLE scratch RENAME TO scratch_old;
DROP TABLE IF EXISTS scratch_old CASCADE;
DROP INDEX IF EXISTS idx_stock_low;
DROP VIEW IF EXISTS recent;
DROP FUNCTION IF EXISTS add_one;
TRUNCATE movements;
TRUNCATE TABLE staging, scratch;
COMMENT ON TABLE stock IS 'Quantity per warehouse and SKU';
COMMENT ON COLUMN stock.quantity IS 'Units on hand';

-- ── DML: insert ──
INSERT INTO warehouses (code, name, region, capacity, opened_on)
VALUES ('NORTH', 'North Depot', 'EU', 5000, '2020-03-01'),
       ('SOUTH', 'South Depot', 'EU', 3000, '2021-07-15'),
       ('EAST',  'East "Quoted" Depot', 'US', NULL, NULL);

INSERT INTO products (sku, name, unit_price, weight_kg, is_active)
VALUES ('ABC-1', 'Hammer', 12.50, 0.8, TRUE),
       ('ABC-2', 'Nails (box of 100)', 3.99, 0.25, TRUE),
       ('ABC-3', 'Saw', 24.00, 1.2, FALSE),
       ('ABC-4', 'It''s a ''quoted'' name', 100.0, 0.25, TRUE);

INSERT INTO stock (warehouse_id, sku, quantity)
SELECT w.id, p.sku, 10 * w.id
FROM warehouses AS w CROSS JOIN products AS p;

INSERT INTO t VALUES (1), (2);
INSERT INTO t (a, b) VALUES (1, DEFAULT);
INSERT INTO t (a) SELECT 1 UNION SELECT 2;
INSERT INTO products (sku, name) VALUES ('ABC-8', 'Ignored') ON CONFLICT DO NOTHING;
INSERT INTO audit (who) VALUES ('system') RETURNING id, who, at;

-- ── DML: update / delete / merge ──
UPDATE stock SET quantity = quantity - 5, updated_at = CURRENT_TIMESTAMP
WHERE sku = 'ABC-1' AND warehouse_id IN (SELECT id FROM warehouses WHERE region = 'EU');

UPDATE products SET unit_price = unit_price * 1.05 WHERE is_active AND unit_price BETWEEN 1 AND 50;
UPDATE products SET unit_price = DEFAULT WHERE sku = 'ABC-3';
UPDATE products SET unit_price = unit_price + 1 WHERE sku = 'ABC-1' RETURNING sku, unit_price;
UPDATE stock SET quantity = quantity + 1 FROM (SELECT 1 AS one) AS src WHERE sku = 'ABC-1';
DELETE FROM movements WHERE moved_at < now() - INTERVAL '1 year' OR reason IS NULL;
DELETE FROM stock WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.sku = stock.sku);
DELETE FROM audit WHERE who = 'system' RETURNING *;

MERGE INTO stock AS s
USING incoming AS i ON s.sku = i.sku
WHEN MATCHED THEN UPDATE SET quantity = s.quantity + i.quantity
WHEN NOT MATCHED THEN INSERT (sku, quantity) VALUES (i.sku, i.quantity);

-- ── Literals ──
SELECT 42, -7, +3, 3.14, .5, 5., 0xFF, 0b101, 0o17, 1_000, 1e10, 1E5, 1.5e3, 1.5e+3, 2e-3,
       'plain', 'it''s', 'a' 'b', X'DEADBEEF', x'00ff', B'1010', N'national', E'tab\t', U&'\0041',
       $$dollar quoted$$, $tag$tagged dollar quoted$tag$,
       TRUE, FALSE, NULL,
       CURRENT_DATE, CURRENT_TIME, CURRENT_TIMESTAMP, LOCALTIME, LOCALTIMESTAMP,
       CURRENT_USER, SESSION_USER, CURRENT_CATALOG, CURRENT_SCHEMA,
       DATE '2026-01-01', TIME '10:00:00', TIMESTAMP '2026-01-01 00:00:00',
       INTERVAL '1 day', INTERVAL '2' HOUR,
       1 AS "quoted identifier";

-- ── Queries: joins and filters ──
SELECT DISTINCT p.sku, p.name, w.name AS warehouse, s.quantity
FROM products AS p
INNER JOIN stock AS s ON s.sku = p.sku
LEFT OUTER JOIN warehouses AS w ON w.id = s.warehouse_id
LEFT JOIN movements m USING (sku)
RIGHT JOIN suppliers AS r ON r.code = p.sku
FULL OUTER JOIN archive AS a ON a.sku = p.sku
CROSS JOIN (SELECT 1) AS one
WHERE p.is_active = TRUE
  AND s.quantity BETWEEN 0 AND 1000
  AND s.quantity NOT BETWEEN 5 AND 9
  AND p.name LIKE '%am%'
  AND p.name NOT LIKE 'X%'
  AND p.name ILIKE 'h%'
  AND p.name NOT ILIKE 'z%'
  AND p.name SIMILAR TO '(H|S)%'
  AND p.name NOT SIMILAR TO 'Q%'
  AND (s.quantity IS NOT NULL OR s.reserved IS NULL)
  AND s.quantity IS DISTINCT FROM s.reserved
  AND s.warehouse_id IN (1, 2, 3)
  AND s.sku NOT IN (SELECT sku FROM products WHERE is_active = FALSE)
  AND s.quantity = ANY (SELECT quantity FROM stock)
  AND s.quantity > ALL (SELECT reserved FROM stock)
  AND s.quantity <> SOME (SELECT 0)
  AND EXISTS (SELECT 1 FROM movements mv WHERE mv.sku = p.sku)
  AND NOT EXISTS (SELECT 1 FROM movements mv WHERE mv.delta < 0)
ORDER BY s.quantity DESC NULLS LAST, p.name ASC
LIMIT 25 OFFSET 5;

SELECT * FROM a JOIN b USING (x) JOIN c USING (y);
SELECT * FROM t, u WHERE t.id = u.id;
SELECT t.*, u.a FROM t JOIN u ON TRUE;
SELECT * FROM (VALUES (1, 'a'), (2, 'b')) AS v (n, s);
SELECT DISTINCT ON (sku) sku, quantity FROM stock ORDER BY sku, quantity DESC;
SELECT 1 INTO new_table;
SELECT a AS "x", b "y", c z FROM t AS tt (p, q);
SELECT x FROM generate_series(1, 10) AS g (x);

-- ── Expressions ──
SELECT sku,
       quantity * 2 + 1 - 3 / 4 % 5 AS arithmetic,
       quantity || '-' || sku AS concatenated,
       quantity & 3 | 4 << 1 >> 1 AS bitwise,
       quantity # 2 AS xor_bits,
       ~quantity AS inverted,
       0 - quantity AS negated,
       quantity > 5 AND quantity <= 50 OR NOT (quantity = 0) AS logic,
       quantity <> 3 AND quantity != 4 AND quantity >= 1 AND quantity < 99 AS comparison,
       quantity IS TRUE AS is_true, quantity IS NOT UNKNOWN AS known,
       CASE WHEN quantity = 0 THEN 'out'
            WHEN quantity < 25 THEN 'low'
            ELSE 'ok' END AS level,
       CASE sku WHEN 'ABC-1' THEN 1 ELSE 0 END AS simple_case,
       CAST(quantity AS DECIMAL(10, 2)) / 3 AS ratio,
       COALESCE(updated_at, now()) AS updated,
       NULLIF(quantity, 0) AS nonzero,
       GREATEST(quantity, 1) AS at_least, LEAST(quantity, 100) AS at_most,
       ABS(quantity) AS magnitude, ROUND(quantity / 3.0, 2) AS rounded, FLOOR(2.5) AS fl, CEIL(2.5) AS ce,
       MOD(quantity, 3) AS remainder, POWER(quantity, 2) AS squared, SQRT(quantity) AS root,
       UPPER(sku) AS up, LOWER(sku) AS lo, CHAR_LENGTH(sku) AS len,
       EXTRACT(EPOCH FROM updated_at) AS epoch,
       CAST(sku AS CHARACTER VARYING(10)) AS vc, CAST(quantity AS SMALLINT) AS sm,
       CAST(quantity AS DOUBLE PRECISION) AS dp, CAST(quantity AS FLOAT) AS fl2,
       CAST(updated_at AS TIME) AS tm, CAST(sku AS BYTEA) AS raw,
       CAST(sku AS UUID) AS uid, CAST(sku AS JSONB) AS js,
       CAST(updated_at AS TIMESTAMPTZ) AS tz, CAST(sku AS INTERVAL) AS iv,
       CAST(quantity AS BIT(8)) AS bits, CAST(sku AS NCHAR(5)) AS nc, CAST(sku AS NVARCHAR(10)) AS nv,
       CAST(quantity AS TINYINT) AS ti, CAST(quantity AS MEDIUMINT) AS mi, CAST(sku AS VARBINARY(4)) AS vb,
       ROW(1, 2) AS pair, (1, 2) = (1, 2) AS tuple_eq, (quantity, reserved) IN ((1, 2), (3, 4)) AS tuple_in
FROM stock
JOIN products USING (sku);

-- ── Casts, arrays, subscripts, JSON operators, parameters ──
SELECT quantity::INTEGER, sku::TEXT, '{1,2,3}'::INTEGER[], ARRAY[1, 2, 3],
       tags -> 'a' ->> 'b', tags #> '{a,b}', tags #>> '{a,b}', tags @> '{"a":1}', tags <@ '{}',
       tags ? 'a', tags ?| ARRAY['a'], tags ?& ARRAY['a']
FROM products;

SELECT readings[1], readings[1:2], readings[:2] FROM measurements;
SELECT * FROM t WHERE a = $1 AND b = ?;

-- ── Aggregates, grouping ──
SELECT warehouse_id,
       COUNT(*) AS lines,
       COUNT(DISTINCT sku) AS skus,
       SUM(quantity) AS units,
       AVG(quantity) AS mean,
       MIN(quantity) AS least,
       MAX(quantity) AS most,
       STRING_AGG(sku, ', ' ORDER BY sku) AS sku_list,
       ARRAY_AGG(DISTINCT sku ORDER BY sku DESC) AS sku_array,
       COUNT(*) FILTER (WHERE quantity > 0) AS positive
FROM stock
GROUP BY warehouse_id
HAVING SUM(quantity) > 100 AND COUNT(*) >= 2
ORDER BY units DESC;

SELECT warehouse_id, sku, SUM(quantity) FROM stock GROUP BY ROLLUP (warehouse_id, sku);
SELECT warehouse_id, sku, SUM(quantity) FROM stock GROUP BY CUBE (warehouse_id, sku);

-- ── CTEs: plain, recursive, materialized, data-modifying ──
WITH recent AS (
    SELECT sku, SUM(delta) AS net
    FROM movements
    WHERE moved_at >= now() - INTERVAL '30 days'
    GROUP BY sku
), ranked AS (
    SELECT sku, net, RANK() OVER (ORDER BY net DESC) AS rnk
    FROM recent
)
SELECT p.name, r.net, r.rnk
FROM ranked AS r JOIN products AS p ON p.sku = r.sku
WHERE r.rnk <= 3;

WITH RECURSIVE countdown (n) AS (
    SELECT 5
    UNION ALL
    SELECT n - 1 FROM countdown WHERE n > 1
)
SELECT n FROM countdown;

WITH t AS MATERIALIZED (SELECT sku, quantity FROM stock), u AS NOT MATERIALIZED (SELECT sku FROM products)
SELECT t.sku FROM t JOIN u USING (sku);

WITH ins AS (INSERT INTO audit (who) VALUES ('cte') RETURNING id) SELECT * FROM ins;
WITH del AS (DELETE FROM audit RETURNING *) SELECT COUNT(*) FROM del;

-- ── Window functions ──
SELECT sku,
       warehouse_id,
       quantity,
       ROW_NUMBER() OVER (PARTITION BY warehouse_id ORDER BY quantity DESC) AS rn,
       DENSE_RANK() OVER w AS dr,
       LAG(quantity, 1, 0) OVER (PARTITION BY sku ORDER BY warehouse_id) AS prev_qty,
       LEAD(quantity) OVER (PARTITION BY sku ORDER BY warehouse_id) AS next_qty,
       SUM(quantity) OVER (PARTITION BY warehouse_id ORDER BY sku
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running,
       AVG(quantity) OVER (ORDER BY sku ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving,
       SUM(quantity) OVER (ORDER BY quantity RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS by_range,
       SUM(quantity) OVER (ORDER BY quantity GROUPS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING EXCLUDE TIES) AS by_group,
       SUM(quantity) OVER (ORDER BY quantity ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW) AS excluding,
       SUM(quantity) OVER () AS grand_total,
       SUM(quantity) OVER (ORDER BY sku ROWS UNBOUNDED PRECEDING) AS since_start,
       NTILE(4) OVER w AS quartile,
       PERCENT_RANK() OVER (ORDER BY quantity) AS pct,
       CUME_DIST() OVER (ORDER BY quantity) AS cume,
       FIRST_VALUE(sku) OVER (PARTITION BY warehouse_id ORDER BY quantity) AS smallest,
       LAST_VALUE(quantity) OVER (ORDER BY quantity ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_q,
       NTH_VALUE(quantity, 2) OVER (ORDER BY quantity) AS second_q
FROM stock
WINDOW w AS (PARTITION BY warehouse_id ORDER BY quantity DESC);

-- ── Set operations, subqueries, LATERAL ──
SELECT sku FROM stock WHERE warehouse_id = 1
UNION
SELECT sku FROM stock WHERE warehouse_id = 2
INTERSECT
SELECT sku FROM products WHERE is_active
EXCEPT
SELECT sku FROM low_stock;

(SELECT 1) UNION (SELECT 2);
SELECT a FROM t UNION ALL SELECT b FROM u ORDER BY 1 DESC LIMIT 3;

SELECT name, (SELECT SUM(quantity) FROM stock s WHERE s.sku = p.sku) AS total
FROM products AS p
WHERE unit_price > 0 AND unit_price > (SELECT AVG(unit_price) FROM products);

SELECT p.sku, recent.delta
FROM products AS p
CROSS JOIN LATERAL (SELECT delta FROM movements m WHERE m.sku = p.sku ORDER BY moved_at DESC LIMIT 1) AS recent;

SELECT p.sku, last_move.moved_at
FROM products AS p
LEFT JOIN LATERAL (SELECT moved_at FROM movements m WHERE m.sku = p.sku LIMIT 1) AS last_move ON TRUE;

-- ── Transactions ──
BEGIN;
UPDATE stock SET quantity = 0 WHERE sku = 'ABC-3';
COMMIT;

BEGIN TRANSACTION;
UPDATE stock SET quantity = 1 WHERE sku = 'ABC-3';
COMMIT TRANSACTION;

BEGIN;
DELETE FROM scratch;
ROLLBACK;

-- ── Session, procedural and administrative statements ──
SET SESSION timezone = 'UTC';
SET LOCAL statement_timeout = 5000;
SET @answer = 42;
SET NAMES utf8mb4;
RESET search_path;
EXPLAIN SELECT * FROM stock WHERE sku = 'ABC-1';
EXPLAIN ANALYZE SELECT * FROM stock;
VACUUM;
VACUUM ANALYZE stock;

-- ── MySQL forms ──
CREATE TABLE mysql_forms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tiny TINYINT UNSIGNED ZEROFILL,
    mid MEDIUMINT,
    big BIGINT UNSIGNED,
    price MONEY,
    small_price SMALLMONEY
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='mysql table options';

ALTER TABLE mysql_forms ADD COLUMN note TEXT AFTER mid;
ALTER TABLE mysql_forms MODIFY COLUMN note VARCHAR(80);
ALTER TABLE mysql_forms CHANGE COLUMN note memo VARCHAR(80) FIRST;
INSERT LOW_PRIORITY INTO mysql_forms (tiny) VALUES (1);
INSERT DELAYED INTO mysql_forms (tiny) VALUES (2);
INSERT HIGH_PRIORITY INTO mysql_forms (tiny) VALUES (3);
INSERT INTO mysql_forms (id, tiny) VALUES (1, 1) ON DUPLICATE KEY UPDATE tiny = VALUES(tiny);
REPLACE INTO mysql_forms (id, tiny) VALUES (1, 9);
SELECT * FROM mysql_forms USE INDEX (PRIMARY) WHERE id = 1;
SELECT * FROM mysql_forms FORCE INDEX (PRIMARY) WHERE id = 1;
SELECT * FROM mysql_forms IGNORE INDEX (PRIMARY) WHERE id = 1;
SELECT SQL_CALC_FOUND_ROWS * FROM mysql_forms;
SELECT * FROM mysql_forms WHERE MATCH (memo) AGAINST ('nail');

-- ── Hive / Spark table definitions ──
CREATE EXTERNAL TABLE events (id INT, payload STRING)
PARTITIONED BY (day STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://example-bucket/events';

CREATE TABLE columnar (id INT) STORED AS ORC TBLPROPERTIES ('transactional'='true');
CREATE EXTERNAL TABLE parquet_events (id INT) STORED AS PARQUET LOCATION 's3://example-bucket/parquet';

-- ── SQL Server column types ──
CREATE TABLE mssql_types (a DATETIME2, b DATETIMEOFFSET, c SMALLDATETIME, d IMAGE, e INET, f GEOMETRY, g GEOGRAPHY, h OID, i REGCLASS, j XML, k SERIAL, l BIGSERIAL, m SMALLSERIAL, n UUID);

-- ── SQLite forms ──
PRAGMA foreign_keys = ON;
CREATE TABLE lite_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL COLLATE NOCASE,
    qty INTEGER,
    total INTEGER GENERATED ALWAYS AS (qty * 2) VIRTUAL
) WITHOUT ROWID;
CREATE TABLE lite_strict (id INTEGER PRIMARY KEY, who TEXT) STRICT;
CREATE VIRTUAL TABLE IF NOT EXISTS product_search USING fts5(name, description);
CREATE TRIGGER trg_lite AFTER UPDATE OF qty ON lite_items
FOR EACH ROW
WHEN NEW.qty <> OLD.qty
BEGIN
    UPDATE lite_items SET name = name WHERE id = NEW.id;
    SELECT RAISE(ABORT, 'read only');
END;
INSERT OR REPLACE INTO lite_items (id, name) VALUES (1, 'a');
INSERT OR IGNORE INTO lite_items (id, name) VALUES (1, 'a');
INSERT INTO lite_items (id, name) VALUES (2, 'b') ON CONFLICT (id) DO UPDATE SET name = excluded.name;
SELECT 2 AS [bracket identifier], 3 AS `backtick identifier`, 4 AS 'string alias';
SELECT name FROM lite_items WHERE name GLOB 'A*' AND name NOT GLOB 'X*' AND name REGEXP '^a' AND name ISNULL AND qty NOTNULL;
SELECT name FROM lite_items WHERE name COLLATE NOCASE = 'a' ORDER BY name COLLATE BINARY;
SELECT * FROM product_search WHERE product_search MATCH 'nail';
SELECT json_extract(tags, '$.colour') AS colour, tags ->> '$.size' AS size_text, typeof(qty) AS t, random() AS r, date('now') AS today, strftime('%Y-%m-%d', 'now') AS formatted, IIF(qty > 0, 'yes', 'no') AS in_stock, IFNULL(qty, 0) AS q FROM lite_items;
EXPLAIN QUERY PLAN SELECT * FROM lite_items WHERE id = 1;
ANALYZE;
REINDEX lite_items;
ATTACH DATABASE ':memory:' AS archive;
DETACH DATABASE archive;

-- ── More types and forms ──
CREATE TABLE more_types (
    kind ENUM('raw', 'finished') NOT NULL,
    token BINARY(16),
    ts DATETIME,
    ts3 TIMESTAMP(3),
    t6 TIME(6),
    proc REGPROC, typ REGTYPE, ns REGNAMESPACE,
    area BOX2D, volume BOX3D
) WITH (fillfactor = 70);
ALTER TABLE more_types SET SCHEMA archive_schema;
ALTER TABLE more_types ADD COLUMN extra_a INT, ADD COLUMN extra_b INT;
SELECT 2 ^ 3, kind, USER, VERSION() FROM more_types ORDER BY kind USING <;

-- ── Valid SQL that the bundled tree-sitter grammar cannot parse yet ──
-- Each statement below is ordinary SQL:2023 or a common PostgreSQL / MySQL form; the grammar reports an error on it.
SELECT -quantity FROM stock;
SELECT kind FROM more_types WHERE token IS NOT DISTINCT FROM kind;
SELECT ARRAY[[1, 2], [3, 4]];
SELECT readings[2:] FROM measurements;
SELECT 2.5E-3;
VALUES (1, 'one'), (2, 'two');
SELECT x FROM UNNEST(ARRAY[1, 2]) WITH ORDINALITY AS u (x, n);
SELECT a FROM t, LATERAL (SELECT b FROM u WHERE u.id = t.id LIMIT 1) AS x;
SELECT * FROM a NATURAL JOIN b;
SELECT * FROM a NATURAL LEFT JOIN b;
SELECT name FROM products WHERE name LIKE '50!%%' ESCAPE '!';
SELECT name FROM products ORDER BY name COLLATE "C" ASC;
SELECT name FROM products ORDER BY name NULLS FIRST;
SELECT name FROM products LIMIT 5, 10;
SELECT name FROM products FETCH FIRST 5 ROWS ONLY;
SELECT name FROM products OFFSET 5 ROWS FETCH NEXT 5 ROWS WITH TIES;
SELECT name FROM products FOR UPDATE;
SELECT name FROM products FOR UPDATE OF products NOWAIT;
SELECT name FROM products FOR SHARE;
SELECT name FROM products FOR NO KEY UPDATE;
SELECT name FROM products FOR UPDATE SKIP LOCKED;
SELECT warehouse_id, sku FROM stock GROUP BY GROUPING SETS ((warehouse_id), (sku), ());
SELECT COUNT(*) FROM stock HAVING COUNT(*) > 1;
SELECT 1 EXCEPT ALL SELECT 3;
SELECT 1 INTERSECT ALL SELECT 3;
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY quantity) FROM stock;
SELECT TRIM(BOTH ' ' FROM name), POSITION('a' IN name), SUBSTRING(name FROM 1 FOR 2), OVERLAY(name PLACING 'x' FROM 1 FOR 1) FROM products;
SELECT TIMESTAMP WITH TIME ZONE '2026-01-01 00:00:00+00';
SELECT sku FROM products TABLESAMPLE BERNOULLI (10);
SELECT $1, $2::TEXT, :name, @var;
SELECT a := 1;
SELECT @x := 1;
SELECT SUM(quantity) OVER (w ROWS 1 PRECEDING) FROM stock WINDOW w AS (PARTITION BY warehouse_id);
CREATE TABLE named_inline (id INTEGER CONSTRAINT nn NOT NULL CONSTRAINT df DEFAULT 1 CONSTRAINT pk PRIMARY KEY);
CREATE TABLE named_unique (id INTEGER, label TEXT, CONSTRAINT uq_label UNIQUE (label));
CREATE TABLE by_default (id INTEGER GENERATED BY DEFAULT AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY);
CREATE TABLE refs (a INT REFERENCES u MATCH FULL ON DELETE SET NULL ON UPDATE SET DEFAULT DEFERRABLE INITIALLY DEFERRED);
CREATE TABLE with_exclude (a INT, EXCLUDE USING gist (a WITH =));
CREATE TABLE copy_of (LIKE products INCLUDING ALL);
CREATE TABLE child (extra INT) INHERITS (products);
CREATE TABLE table_copy AS TABLE products;
CREATE TABLE no_data AS SELECT 1 AS a WITH NO DATA;
CREATE TEMP TABLE on_commit (a INT) ON COMMIT DROP;
CREATE TABLE hash_parts (a INT) PARTITION BY HASH (a) PARTITIONS 4;
CREATE TABLE auto_inc (a INT) AUTO_INCREMENT=10;
CREATE TABLE hive_types (a STRING, b ARRAY<INT>);
CREATE TABLE bucketed (a INT, b INT) CLUSTERED BY (a) INTO 4 BUCKETS;
CREATE INDEX idx_include ON products (name) INCLUDE (sku) WITH (fillfactor = 70) TABLESPACE fast;
CREATE UNIQUE INDEX idx_nulls ON products (name) NULLS NOT DISTINCT;
CREATE OR REPLACE FUNCTION touch_stock() RETURNS TRIGGER AS $body$ BEGIN NEW.updated_at := now(); RETURN NEW; END; $body$ LANGUAGE plpgsql;
CREATE TRIGGER trg_transition AFTER UPDATE ON stock REFERENCING OLD TABLE AS o NEW TABLE AS n FOR EACH STATEMENT EXECUTE FUNCTION audit_stock();
CREATE PROCEDURE restock(sku TEXT, amount INTEGER) LANGUAGE SQL AS $$ UPDATE stock SET quantity = quantity + amount WHERE stock.sku = restock.sku $$;
CALL restock('ABC-1', 10);
DO $$ BEGIN PERFORM 1; END $$;
ALTER TYPE inventory.stock_state ADD VALUE 'archived';
ALTER MATERIALIZED VIEW stock_totals RENAME TO totals;
ALTER TABLE products DROP COLUMN IF EXISTS vendor CASCADE;
ALTER TABLE stock ENABLE TRIGGER trg_stock_touch;
DROP MATERIALIZED VIEW IF EXISTS totals;
DROP TRIGGER IF EXISTS trg_stock_touch ON stock;
DROP FUNCTION IF EXISTS add_one(INTEGER);
DROP TABLE IF EXISTS first_table, second_table;
TRUNCATE TABLE movements RESTART IDENTITY CASCADE;
ANALYZE stock;
INSERT INTO t DEFAULT VALUES;
INSERT INTO t (a) OVERRIDING SYSTEM VALUE VALUES (1);
INSERT INTO products (sku, name) VALUES ('ABC-9', 'Upsert') ON CONFLICT (sku) DO UPDATE SET name = excluded.name;
UPDATE products SET (name, unit_price) = ('Renamed', 1) WHERE sku = 'ABC-1';
MERGE INTO stock s USING incoming i ON s.sku = i.sku WHEN MATCHED AND i.quantity = 0 THEN DELETE WHEN NOT MATCHED BY SOURCE THEN DELETE;
WITH RECURSIVE countdown (n) AS (VALUES (5) UNION ALL SELECT n - 1 FROM countdown WHERE n > 1) SELECT n FROM countdown;
SET search_path TO inv, public;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SHOW search_path;
GRANT SELECT, INSERT ON stock TO acme_reader;
REVOKE ALL PRIVILEGES ON stock FROM acme_reader;
COPY stock (sku, quantity) FROM STDIN WITH (FORMAT csv, HEADER true);
COPY stock TO '/tmp/stock.csv' WITH (FORMAT csv);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM stock;
LOCK TABLE stock IN ACCESS EXCLUSIVE MODE;
PREPARE find_stock (INT) AS SELECT * FROM stock WHERE warehouse_id = $1;
EXECUTE find_stock(1);
DEALLOCATE find_stock;
DECLARE stock_cursor CURSOR FOR SELECT * FROM stock;
USE warehouse_db;
BEGIN ISOLATION LEVEL SERIALIZABLE;
SAVEPOINT before_adjust;
ROLLBACK TO SAVEPOINT before_adjust;
RELEASE SAVEPOINT before_adjust;
COMMIT;
START TRANSACTION;
ROLLBACK;
SELECT * FROM products SORT BY name;
