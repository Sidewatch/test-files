-- Oracle PL/SQL showcase: package spec and body, types, cursors, exceptions, bulk and dynamic SQL.
/* A block comment
   over several lines. */
REM A SQL*Plus remark line
PROMPT Creating stock package
-- TODO: add autonomous logging
-- FIXME: bulk collect has no LIMIT

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE stock_pkg AUTHID DEFINER AS
    -- ── Constants and literals ──
    c_reorder_point CONSTANT NUMBER := 25;
    c_name          CONSTANT VARCHAR2(30) := 'it''s "stock"';
    c_quoted        CONSTANT VARCHAR2(60) := q'[bracket-quoted with 'single' quotes]';
    c_quoted2       CONSTANT VARCHAR2(60) := q'{braces}' || Q'(parens)' || q'<angles>' || q'!bang!';
    c_nq            CONSTANT NVARCHAR2(10) := N'unicode';
    c_hex           CONSTANT RAW(4) := HEXTORAW('DEADBEEF');
    c_num           CONSTANT NUMBER := 1.5E-3;
    c_float         CONSTANT BINARY_FLOAT := 3.14f;
    c_double        CONSTANT BINARY_DOUBLE := 2.71d;
    c_inf           CONSTANT BINARY_DOUBLE := BINARY_DOUBLE_INFINITY;
    c_date          CONSTANT DATE := DATE '2025-01-31';
    c_ts            CONSTANT TIMESTAMP := TIMESTAMP '2025-01-31 12:30:00.123';
    c_tstz          CONSTANT TIMESTAMP WITH TIME ZONE := TIMESTAMP '2025-01-31 12:30:00 -05:00';
    c_iv            CONSTANT INTERVAL DAY TO SECOND := INTERVAL '1 02:03:04' DAY TO SECOND;
    c_ym            CONSTANT INTERVAL YEAR TO MONTH := INTERVAL '1-6' YEAR TO MONTH;
    c_bool          CONSTANT BOOLEAN := TRUE;
    c_null          CONSTANT VARCHAR2(1) := NULL;

    -- ── Types ──
    TYPE sku_list IS TABLE OF VARCHAR2(20);
    TYPE sku_idx IS TABLE OF NUMBER INDEX BY VARCHAR2(20);
    TYPE sku_arr IS VARRAY(10) OF VARCHAR2(20);
    TYPE stock_rec IS RECORD (sku VARCHAR2(20), qty NUMBER(10), price NUMBER(10, 2) NOT NULL := 0);
    TYPE stock_cur IS REF CURSOR RETURN stock%ROWTYPE;
    TYPE any_cur IS REF CURSOR;
    SUBTYPE sku_t IS VARCHAR2(20) NOT NULL;
    SUBTYPE small_t IS PLS_INTEGER RANGE 0 .. 100;

    -- ── Exceptions and pragmas ──
    e_negative EXCEPTION;
    e_locked   EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_locked, -54);

    -- ── Subprograms ──
    FUNCTION low_stock RETURN sku_list PIPELINED;
    FUNCTION cached(p_sku IN VARCHAR2) RETURN NUMBER RESULT_CACHE DETERMINISTIC;
    PROCEDURE adjust(p_sku IN VARCHAR2, p_delta IN NUMBER, p_new OUT NUMBER, p_io IN OUT NOCOPY NUMBER);
    PROCEDURE overloaded(p IN NUMBER);
    PROCEDURE overloaded(p IN VARCHAR2);
END stock_pkg;
/

CREATE OR REPLACE PACKAGE BODY stock_pkg AS
    g_calls PLS_INTEGER := 0;
    g_cache sku_idx;

    CURSOR c_low (p_limit NUMBER DEFAULT c_reorder_point) IS
        SELECT sku, qty FROM stock WHERE qty <= p_limit ORDER BY price;

    FUNCTION low_stock RETURN sku_list PIPELINED IS
    BEGIN
        FOR r IN (SELECT sku FROM stock WHERE qty <= c_reorder_point ORDER BY price) LOOP
            PIPE ROW (r.sku);
        END LOOP;
        RETURN;
    END low_stock;

    FUNCTION cached(p_sku IN VARCHAR2) RETURN NUMBER RESULT_CACHE RELIES_ON (stock) DETERMINISTIC IS
        v NUMBER;
    BEGIN
        SELECT qty INTO v FROM stock WHERE sku = p_sku;
        RETURN v;
    END cached;

    PROCEDURE adjust(p_sku IN VARCHAR2, p_delta IN NUMBER, p_new OUT NUMBER, p_io IN OUT NOCOPY NUMBER) IS
        v_qty stock.qty%TYPE;
        v_row stock%ROWTYPE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        SELECT qty INTO v_qty FROM stock WHERE sku = p_sku FOR UPDATE NOWAIT;
        IF v_qty + p_delta < 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'stock cannot go negative for ' || p_sku);
        END IF;
        UPDATE stock SET qty = qty + p_delta WHERE sku = p_sku RETURNING qty INTO p_new;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('unknown sku ' || p_sku);
        WHEN e_locked OR TOO_MANY_ROWS THEN
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(SQLCODE || ': ' || SQLERRM || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            RAISE;
    END adjust;

    PROCEDURE overloaded(p IN NUMBER) IS BEGIN NULL; END;
    PROCEDURE overloaded(p IN VARCHAR2) IS BEGIN NULL; END;

    PROCEDURE showcase IS
        v_n      NUMBER := 0;
        v_i      PLS_INTEGER;
        v_str    VARCHAR2(100) := 'abc';
        v_clob   CLOB;
        v_blob   BLOB;
        v_list   sku_list := sku_list('A-100', 'B-200');
        v_idx    sku_idx;
        v_rec    stock_rec;
        v_cur    any_cur;
        v_ids    DBMS_SQL.NUMBER_TABLE;
        TYPE num_tab IS TABLE OF NUMBER;
        v_nums   num_tab;
        v_ref    SYS_REFCURSOR;
        v_bool   BOOLEAN;
        v_sql    VARCHAR2(200);
    BEGIN
        -- Assignment, operators
        v_n := 1 + 2 - 3 * 4 / 2 ** 2;
        v_n := MOD(7, 3) + ABS(-1) + ROUND(1.5) + TRUNC(2.7);
        v_str := 'a' || 'b' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
        v_bool := v_n >= 1 AND v_n <= 9 OR NOT (v_n <> 3) AND v_str IS NOT NULL;
        v_bool := v_str LIKE 'a%' ESCAPE '\' OR v_n BETWEEN 1 AND 5 OR v_n IN (1, 2, 3);
        v_bool := v_str IS NULL OR v_n = ANY (1, 2) OR v_n NOT IN (4, 5);
        v_n := CASE WHEN v_n > 5 THEN 1 WHEN v_n > 2 THEN 2 ELSE 3 END;
        v_n := CASE v_i WHEN 1 THEN 10 ELSE 0 END;
        v_n := NVL(v_n, 0) + COALESCE(v_n, 1) + NULLIF(v_n, 0) + DECODE(v_n, 1, 'a', 'b');
        v_idx('A-100') := 12;
        v_list.EXTEND;
        v_list(v_list.LAST) := 'C-300';
        IF v_list.EXISTS(1) AND v_list.COUNT > 0 THEN v_list.DELETE(1); END IF;
        v_n := v_list.FIRST + v_list.NEXT(1) + v_list.PRIOR(2) + v_list.LIMIT;

        -- Control flow
        IF v_n > 10 THEN
            NULL;
        ELSIF v_n > 5 THEN
            NULL;
        ELSE
            NULL;
        END IF;

        <<outer_loop>>
        FOR i IN 1 .. 10 LOOP
            CONTINUE WHEN MOD(i, 2) = 0;
            EXIT outer_loop WHEN i > 8;
        END LOOP outer_loop;
        FOR i IN REVERSE 1 .. 5 LOOP NULL; END LOOP;
        FOR i IN 1 .. 10 BY 2 LOOP NULL; END LOOP;
        FOR r IN c_low(30) LOOP DBMS_OUTPUT.PUT_LINE(r.sku || ' ' || r.qty); END LOOP;
        FOR r IN (SELECT * FROM stock) LOOP NULL; END LOOP;
        WHILE v_n < 10 LOOP v_n := v_n + 1; END LOOP;
        LOOP v_n := v_n - 1; EXIT WHEN v_n < 5; END LOOP;
        FORALL i IN 1 .. v_list.COUNT SAVE EXCEPTIONS
            UPDATE stock SET qty = qty + 1 WHERE sku = v_list(i);
        FORALL i IN INDICES OF v_list DELETE FROM stock WHERE sku = v_list(i);
        CASE v_str
            WHEN 'a' THEN NULL;
            WHEN 'b' THEN NULL;
            ELSE NULL;
        END CASE;
        CASE WHEN v_n > 1 THEN NULL; ELSE NULL; END CASE;
        GOTO done_label;
        <<done_label>>
        NULL;

        -- Cursors
        OPEN c_low(25);
        FETCH c_low INTO v_rec.sku, v_rec.qty;
        v_bool := c_low%FOUND OR c_low%ISOPEN OR SQL%ROWCOUNT > 0 OR SQL%FOUND OR SQL%NOTFOUND;
        CLOSE c_low;
        OPEN v_ref FOR SELECT * FROM stock WHERE qty > :min_qty USING 5;
        FETCH v_ref BULK COLLECT INTO v_nums LIMIT 100;
        SELECT qty BULK COLLECT INTO v_nums FROM stock;
        SELECT qty, price INTO v_rec.qty, v_rec.price FROM stock WHERE ROWNUM = 1;

        -- DML and dynamic SQL
        INSERT INTO stock (sku, qty, price) VALUES ('Z-999', 1, 9.99);
        MERGE INTO stock s USING (SELECT 'A-100' sku, 5 qty FROM dual) d ON (s.sku = d.sku)
            WHEN MATCHED THEN UPDATE SET s.qty = s.qty + d.qty
            WHEN NOT MATCHED THEN INSERT (sku, qty) VALUES (d.sku, d.qty);
        EXECUTE IMMEDIATE 'UPDATE stock SET qty = qty + :1 WHERE sku = :2' USING 5, 'A-100';
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM stock' INTO v_n;
        EXECUTE IMMEDIATE v_sql INTO v_n USING IN 1, OUT v_str;
        LOCK TABLE stock IN EXCLUSIVE MODE NOWAIT;
        SAVEPOINT before_change;
        ROLLBACK TO before_change;
        COMMIT;

        -- Exceptions, nested blocks
        BEGIN
            RAISE e_negative;
        EXCEPTION
            WHEN e_negative THEN DBMS_OUTPUT.PUT_LINE('negative');
            WHEN ZERO_DIVIDE OR VALUE_ERROR OR INVALID_NUMBER THEN NULL;
            WHEN OTHERS THEN RAISE_APPLICATION_ERROR(-20002, SQLERRM, TRUE);
        END;
        <<inner>>
        DECLARE
            v_local NUMBER := 1;
        BEGIN
            inner.v_local := 2;
            $IF DBMS_DB_VERSION.VER_LE_12 $THEN
                NULL;
            $ELSIF $$PLSQL_UNIT = 'X' $THEN
                NULL;
            $ELSE
                NULL;
            $END
            $ERROR 'unsupported' $END
        END inner;
        RETURN;
    END showcase;
END stock_pkg;
/

CREATE OR REPLACE FUNCTION gross(p_net NUMBER) RETURN NUMBER DETERMINISTIC IS
BEGIN
    RETURN p_net * 1.2;
END gross;
/

CREATE OR REPLACE TRIGGER stock_biu
    BEFORE INSERT OR UPDATE OF qty ON stock
    FOR EACH ROW
    WHEN (NEW.qty < 0)
DECLARE
    v_msg VARCHAR2(100);
BEGIN
    :NEW.qty := 0;
    IF INSERTING THEN v_msg := 'ins'; ELSIF UPDATING('qty') THEN v_msg := 'upd'; ELSIF DELETING THEN v_msg := 'del'; END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TYPE sku_obj AS OBJECT (
    sku VARCHAR2(20),
    qty NUMBER,
    MEMBER FUNCTION label RETURN VARCHAR2,
    STATIC FUNCTION make(p_sku VARCHAR2) RETURN sku_obj,
    CONSTRUCTOR FUNCTION sku_obj(SELF IN OUT NOCOPY sku_obj, p_sku VARCHAR2) RETURN SELF AS RESULT,
    MAP MEMBER FUNCTION key RETURN VARCHAR2
) NOT FINAL;
/

BEGIN
    stock_pkg.overloaded(1);
    DBMS_OUTPUT.PUT_LINE('done');
END;
/
SHOW ERRORS
EXEC stock_pkg.showcase

-- ── More PL/SQL and Oracle SQL ──
CREATE OR REPLACE TYPE BODY sku_obj AS
    MEMBER FUNCTION label RETURN VARCHAR2 IS BEGIN RETURN SELF.sku || ':' || SELF.qty; END;
    STATIC FUNCTION make(p_sku VARCHAR2) RETURN sku_obj IS BEGIN RETURN sku_obj(p_sku, 0); END;
    CONSTRUCTOR FUNCTION sku_obj(SELF IN OUT NOCOPY sku_obj, p_sku VARCHAR2) RETURN SELF AS RESULT IS
    BEGIN SELF.sku := p_sku; SELF.qty := 0; RETURN; END;
    MAP MEMBER FUNCTION key RETURN VARCHAR2 IS BEGIN RETURN sku; END;
END;
/

CREATE SEQUENCE order_seq START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE TABLE stock (
    sku        VARCHAR2(20 CHAR) PRIMARY KEY,
    qty        NUMBER(10) DEFAULT 0 NOT NULL CHECK (qty >= 0),
    price      NUMBER(10, 2),
    tags       sku_list,
    created    TIMESTAMP(6) WITH LOCAL TIME ZONE DEFAULT SYSTIMESTAMP,
    doc        CLOB,
    img        BLOB,
    id         NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    total      NUMBER GENERATED ALWAYS AS (qty * price) VIRTUAL,
    CONSTRAINT stock_fk FOREIGN KEY (sku) REFERENCES catalog (sku) ON DELETE CASCADE
) TABLESPACE users PCTFREE 10 INITRANS 2 STORAGE (INITIAL 64K NEXT 1M) NOLOGGING COMPRESS
  PARTITION BY RANGE (created) INTERVAL (NUMTOYMINTERVAL(1, 'MONTH')) (PARTITION p0 VALUES LESS THAN (TIMESTAMP '2025-01-01 00:00:00'));
CREATE INDEX stock_fn_ix ON stock (UPPER(sku)) TABLESPACE users PARALLEL 4 ONLINE;
CREATE BITMAP INDEX stock_bm ON stock (qty) LOCAL;
CREATE OR REPLACE VIEW v_low AS SELECT * FROM stock WHERE qty < 25 WITH READ ONLY;
CREATE MATERIALIZED VIEW mv_stock BUILD IMMEDIATE REFRESH FAST ON COMMIT ENABLE QUERY REWRITE AS SELECT sku, SUM(qty) q FROM stock GROUP BY sku;
CREATE GLOBAL TEMPORARY TABLE gtt (id NUMBER) ON COMMIT PRESERVE ROWS;
CREATE SYNONYM stock_syn FOR app.stock;
CREATE PUBLIC DATABASE LINK remote CONNECT TO app IDENTIFIED BY "example-not-a-real-password" USING 'remote_tns';
CREATE OR REPLACE DIRECTORY data_dir AS '/opt/data';
CREATE USER app IDENTIFIED BY "example-not-a-real-password" DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
GRANT CREATE SESSION, RESOURCE TO app;
GRANT SELECT, INSERT ON stock TO app WITH GRANT OPTION;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
ALTER SYSTEM SET open_cursors = 500 SCOPE = BOTH;
ALTER TABLE stock ADD (note VARCHAR2(100)) MODIFY (qty NUMBER(12)) DROP COLUMN doc;
COMMENT ON COLUMN stock.qty IS 'Units on hand';
ANALYZE TABLE stock COMPUTE STATISTICS;
FLASHBACK TABLE stock TO BEFORE DROP;
PURGE RECYCLEBIN;
TRUNCATE TABLE gtt;
RENAME stock TO stock_old;
AUDIT SELECT ON stock BY ACCESS;

SELECT LEVEL, sku, SYS_CONNECT_BY_PATH(sku, '/') AS path, CONNECT_BY_ROOT sku AS root, CONNECT_BY_ISLEAF AS leaf
FROM catalog START WITH parent IS NULL CONNECT BY NOCYCLE PRIOR sku = parent ORDER SIBLINGS BY sku;

SELECT sku, qty,
       ROW_NUMBER() OVER (PARTITION BY sku ORDER BY qty DESC NULLS LAST) rn,
       RANK() OVER (ORDER BY qty) rk, LAG(qty, 1, 0) OVER (ORDER BY sku) prev,
       LISTAGG(sku, ', ') WITHIN GROUP (ORDER BY sku) OVER (PARTITION BY qty) agg,
       RATIO_TO_REPORT(qty) OVER () ratio, KEEP (DENSE_RANK FIRST ORDER BY qty) k
FROM stock s
WHERE ROWNUM <= 10 AND qty IS NOT NULL
ORDER BY 2 DESC
FETCH FIRST 5 ROWS ONLY OFFSET 2 ROWS;

SELECT * FROM stock PIVOT (SUM(qty) FOR sku IN ('A-100' AS a, 'B-200' AS b));
SELECT * FROM stock UNPIVOT INCLUDE NULLS (qty FOR col IN (qty AS 'Q', price AS 'P'));
SELECT * FROM stock AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' HOUR) VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE;
SELECT * FROM stock SAMPLE (10) SEED (1) PARTITION (p0) @remote;
SELECT /*+ INDEX(s stock_fn_ix) PARALLEL(4) */ s.* FROM stock s, TABLE(stock_pkg.low_stock) t WHERE s.sku = t.COLUMN_VALUE (+);
SELECT * FROM JSON_TABLE('{"a":[1,2]}', '$.a[*]' COLUMNS (n NUMBER PATH '$')) jt;
SELECT JSON_OBJECT('sku' VALUE sku, 'qty' VALUE qty), JSON_ARRAYAGG(sku RETURNING CLOB), XMLELEMENT("sku", sku), XMLAGG(XMLELEMENT("q", qty)) FROM stock;
SELECT sku FROM stock MINUS SELECT sku FROM catalog INTERSECT SELECT sku FROM stock UNION ALL SELECT 'x' FROM dual;
SELECT NVL2(qty, 'y', 'n'), TO_NUMBER('1.5', '9D9'), TO_DATE('2025-01-31', 'YYYY-MM-DD'), ADD_MONTHS(SYSDATE, 1), MONTHS_BETWEEN(SYSDATE, SYSDATE), TRUNC(SYSDATE, 'MM'), LAST_DAY(SYSDATE), NEXT_DAY(SYSDATE, 'MONDAY'), CAST(qty AS VARCHAR2(10)), TREAT(sku AS sku_obj), REGEXP_LIKE(sku, '^A'), REGEXP_SUBSTR(sku, '[0-9]+'), SOUNDEX(sku), TRANSLATE(sku, 'AB', 'ab'), INSTR(sku, '-'), LPAD(sku, 10, '*'), SYS_GUID(), USERENV('SESSIONID'), ORA_HASH(sku), DUMP(sku), ROWID FROM stock;

WITH FUNCTION double_it(n NUMBER) RETURN NUMBER IS BEGIN RETURN n * 2; END;
     cte AS (SELECT double_it(qty) d FROM stock)
SELECT d FROM cte;

INSERT ALL
    INTO stock (sku, qty) VALUES ('X-1', 1)
    INTO stock (sku, qty) VALUES ('X-2', 2)
SELECT 1 FROM dual;

UPDATE stock SET (qty, price) = (SELECT 1, 2 FROM dual) WHERE sku = 'X-1' LOG ERRORS INTO err$_stock ('batch') REJECT LIMIT UNLIMITED;
DELETE FROM stock WHERE EXISTS (SELECT 1 FROM catalog c WHERE c.sku = stock.sku);

DECLARE
    TYPE rec_t IS RECORD (sku stock.sku%TYPE, qty stock.qty%TYPE);
    TYPE tab_t IS TABLE OF rec_t INDEX BY PLS_INTEGER;
    l_tab tab_t;
    l_cnt PLS_INTEGER;
    l_out SYS_REFCURSOR;
    l_obj sku_obj := sku_obj('A-100');
    l_json JSON_OBJECT_T := JSON_OBJECT_T.parse('{"a":1}');
    l_val NUMBER := 0;
    l_str VARCHAR2(30) := sys_context('USERENV', 'SESSION_USER');
BEGIN
    SELECT sku, qty BULK COLLECT INTO l_tab FROM stock;
    l_cnt := l_tab.COUNT;
    $IF $$DEBUG_MODE $THEN DBMS_OUTPUT.PUT_LINE('debug'); $END
    FOR i IN INDICES OF l_tab LOOP NULL; END LOOP;
    FOR r IN (SELECT * FROM stock) LOOP
        l_val := l_val + CASE WHEN r.qty > 0 THEN 1 ELSE 0 END;
    END LOOP;
    l_val := l_val + (SELECT COUNT(*) FROM stock);
    OPEN l_out FOR 'SELECT * FROM stock WHERE qty > :1' USING 5;
    CLOSE l_out;
    <<retry>>
    BEGIN
        NULL;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -60 THEN GOTO retry; END IF;
            RAISE;
    END;
    DBMS_LOCK.SLEEP(0);
    DBMS_SCHEDULER.CREATE_JOB(job_name => 'j1', job_type => 'PLSQL_BLOCK', job_action => 'BEGIN NULL; END;', repeat_interval => 'FREQ=DAILY');
    UTL_FILE.PUT_LINE(UTL_FILE.FOPEN('DATA_DIR', 'out.txt', 'w'), 'text');
END;
/
