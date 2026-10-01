-- ── Comments ──
-- Line comment: warehouse inventory schema and reports.
/* Block comment
   spanning several lines. */
/* TODO: partition the movements table */
-- FIXME: reorder query ignores supplier lead time

PRAGMA foreign_keys = ON;

-- ── DDL: tables with every constraint form ──
CREATE TABLE IF NOT EXISTS warehouses (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        VARCHAR(8)  NOT NULL UNIQUE,
    name        TEXT        NOT NULL COLLATE NOCASE,
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
    is_active   BOOLEAN NOT NULL DEFAULT 1,
    attributes  BLOB,
    tags        JSON,
    CONSTRAINT sku_format CHECK (sku GLOB '[A-Z][A-Z][A-Z]-[0-9]*')
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
) WITHOUT ROWID;

CREATE TABLE movements (
    id           INTEGER PRIMARY KEY,
    warehouse_id INTEGER NOT NULL,
    sku          TEXT NOT NULL,
    delta        INTEGER NOT NULL,
    reason       TEXT CHECK (reason IN ('receipt', 'shipment', 'adjustment', 'return')),
    note         TEXT,
    moved_at     TIMESTAMP NOT NULL DEFAULT (datetime('now')),
    total_cents  BIGINT GENERATED ALWAYS AS (delta * 100) VIRTUAL,
    FOREIGN KEY (warehouse_id, sku) REFERENCES stock (warehouse_id, sku)
);

CREATE TEMPORARY TABLE scratch (n INTEGER, label TEXT);

-- ── Indexes, views, triggers ──
CREATE INDEX idx_movements_sku ON movements (sku, moved_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_name ON products (lower(name));
CREATE INDEX idx_stock_low ON stock (quantity) WHERE quantity < 25;

CREATE VIEW low_stock AS
SELECT s.warehouse_id, s.sku, s.quantity
FROM stock AS s
WHERE s.quantity <= 25;

CREATE TRIGGER trg_stock_touch
AFTER UPDATE OF quantity ON stock
FOR EACH ROW
WHEN NEW.quantity <> OLD.quantity
BEGIN
    UPDATE stock SET updated_at = CURRENT_TIMESTAMP
    WHERE warehouse_id = NEW.warehouse_id AND sku = NEW.sku;
    INSERT INTO movements (warehouse_id, sku, delta, reason)
    VALUES (NEW.warehouse_id, NEW.sku, NEW.quantity - OLD.quantity, 'adjustment');
END;

-- ── ALTER and DROP ──
ALTER TABLE products ADD COLUMN supplier TEXT;
ALTER TABLE products RENAME COLUMN supplier TO vendor;
ALTER TABLE products DROP COLUMN vendor;
ALTER TABLE scratch RENAME TO scratch_old;
DROP TABLE IF EXISTS scratch_old;
DROP INDEX IF EXISTS idx_stock_low;

-- ── DML: insert ──
INSERT INTO warehouses (code, name, region, capacity, opened_on)
VALUES ('NORTH', 'North Depot', 'EU', 5000, '2020-03-01'),
       ('SOUTH', 'South Depot', 'EU', 3000, '2021-07-15'),
       ('EAST',  'East "Quoted" Depot', 'US', NULL, NULL);

INSERT INTO products (sku, name, unit_price, weight_kg, is_active)
VALUES ('ABC-1', 'Hammer', 12.50, 0.8, TRUE),
       ('ABC-2', 'Nails (box of 100)', 3.99, 0.25, 1),
       ('ABC-3', 'Saw', 24.00, 1.2, FALSE),
       ('ABC-4', 'It''s a ''quoted'' name', 1e2, 2.5E-1, 1);

INSERT INTO stock (warehouse_id, sku, quantity)
SELECT w.id, p.sku, 10 * w.id
FROM warehouses AS w CROSS JOIN products AS p;

INSERT OR REPLACE INTO stock (warehouse_id, sku, quantity) VALUES (1, 'ABC-1', 99);
INSERT INTO products (sku, name) VALUES ('ABC-9', 'Upsert')
ON CONFLICT (sku) DO UPDATE SET name = excluded.name;

-- ── DML: update / delete ──
UPDATE stock SET quantity = quantity - 5, updated_at = CURRENT_TIMESTAMP
WHERE sku = 'ABC-1' AND warehouse_id IN (SELECT id FROM warehouses WHERE region = 'EU');

UPDATE products SET unit_price = unit_price * 1.05 WHERE is_active AND unit_price BETWEEN 1 AND 50;
DELETE FROM movements WHERE moved_at < datetime('now', '-1 year') OR reason IS NULL;
DELETE FROM stock WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.sku = stock.sku);

-- ── Literals ──
SELECT 42, -7, +3, 3.14, .5, 1e10, 2.5E-3, 0xFF,
       'plain', 'it''s', X'DEADBEEF', x'00ff',
       TRUE, FALSE, NULL,
       CURRENT_DATE, CURRENT_TIME, CURRENT_TIMESTAMP,
       1 AS "quoted identifier", 2 AS [bracket identifier], 3 AS `backtick identifier`;

-- ── Queries: joins and filters ──
SELECT DISTINCT p.sku, p.name, w.name AS warehouse, s.quantity
FROM products AS p
INNER JOIN stock AS s ON s.sku = p.sku
LEFT OUTER JOIN warehouses AS w ON w.id = s.warehouse_id
LEFT JOIN movements m USING (sku)
CROSS JOIN (SELECT 1) AS one
NATURAL JOIN (SELECT 'ABC-1' AS sku) AS only_one
WHERE p.is_active = 1
  AND s.quantity BETWEEN 0 AND 1000
  AND p.name LIKE '%am%' ESCAPE '\'
  AND p.sku NOT GLOB 'X*'
  AND (s.quantity IS NOT NULL OR s.reserved IS NULL)
  AND s.warehouse_id IN (1, 2, 3)
  AND s.sku NOT IN (SELECT sku FROM products WHERE is_active = 0)
  AND EXISTS (SELECT 1 FROM movements mv WHERE mv.sku = p.sku)
ORDER BY s.quantity DESC NULLS LAST, p.name COLLATE NOCASE ASC
LIMIT 25 OFFSET 5;

-- ── Expressions ──
SELECT sku,
       quantity * 2 + 1 - 3 / 4 % 5 AS arithmetic,
       quantity || '-' || sku AS concatenated,
       quantity & 3 | 4 << 1 >> 1 AS bitwise,
       ~quantity AS inverted,
       -quantity AS negated,
       quantity > 5 AND quantity <= 50 OR NOT (quantity = 0) AS logic,
       quantity <> 3 AND quantity != 4 AS inequality,
       CASE WHEN quantity = 0 THEN 'out'
            WHEN quantity < 25 THEN 'low'
            ELSE 'ok' END AS level,
       CASE sku WHEN 'ABC-1' THEN 1 ELSE 0 END AS simple_case,
       CAST(quantity AS REAL) / 3 AS ratio,
       COALESCE(updated_at, 'never') AS updated,
       IFNULL(reserved, 0) AS reserved,
       NULLIF(quantity, 0) AS nonzero,
       IIF(quantity > 0, 'yes', 'no') AS in_stock,
       ABS(quantity) AS magnitude,
       ROUND(quantity / 3.0, 2) AS rounded,
       UPPER(sku) AS up, LOWER(sku) AS lo, LENGTH(sku) AS len,
       SUBSTR(sku, 1, 3) AS prefix, REPLACE(sku, '-', '_') AS safe, TRIM('  x  ') AS trimmed,
       typeof(quantity) AS t, random() AS r, date('now') AS today,
       strftime('%Y-%m-%d', 'now') AS formatted,
       json_extract(tags, '$.colour') AS colour,
       tags ->> '$.size' AS size_text
FROM stock
JOIN products USING (sku);

-- ── Aggregates, grouping ──
SELECT warehouse_id,
       COUNT(*) AS lines,
       COUNT(DISTINCT sku) AS skus,
       SUM(quantity) AS units,
       AVG(quantity) AS mean,
       MIN(quantity) AS least,
       MAX(quantity) AS most,
       TOTAL(reserved) AS held,
       GROUP_CONCAT(sku, ', ') AS sku_list
FROM stock
GROUP BY warehouse_id
HAVING SUM(quantity) > 100 AND COUNT(*) >= 2
ORDER BY units DESC;

-- ── CTEs: plain and recursive ──
WITH recent AS (
    SELECT sku, SUM(delta) AS net
    FROM movements
    WHERE moved_at >= date('now', '-30 days')
    GROUP BY sku
), ranked AS (
    SELECT sku, net, RANK() OVER (ORDER BY net DESC) AS rnk
    FROM recent
)
SELECT p.name, r.net, r.rnk
FROM ranked AS r JOIN products AS p ON p.sku = r.sku
WHERE r.rnk <= 3;

WITH RECURSIVE countdown(n) AS (
    VALUES (5)
    UNION ALL
    SELECT n - 1 FROM countdown WHERE n > 1
)
SELECT n FROM countdown;

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
       NTILE(4) OVER w AS quartile,
       FIRST_VALUE(sku) OVER (PARTITION BY warehouse_id ORDER BY quantity) AS smallest
FROM stock
WINDOW w AS (PARTITION BY warehouse_id ORDER BY quantity DESC);

-- ── Set operations and subqueries ──
SELECT sku FROM stock WHERE warehouse_id = 1
UNION
SELECT sku FROM stock WHERE warehouse_id = 2
INTERSECT
SELECT sku FROM products WHERE is_active
EXCEPT
SELECT sku FROM low_stock;

SELECT name, (SELECT SUM(quantity) FROM stock s WHERE s.sku = p.sku) AS total
FROM products AS p
WHERE unit_price > 0 AND unit_price > (SELECT AVG(unit_price) FROM products);

-- ── Transactions ──
BEGIN TRANSACTION;
SAVEPOINT before_adjust;
UPDATE stock SET quantity = 0 WHERE sku = 'ABC-3';
ROLLBACK TO SAVEPOINT before_adjust;
RELEASE before_adjust;
COMMIT;

-- ── Misc statements ──
EXPLAIN QUERY PLAN SELECT * FROM stock WHERE sku = 'ABC-1';
ANALYZE;
VACUUM;
REINDEX idx_movements_sku;
ATTACH DATABASE ':memory:' AS archive;
DETACH DATABASE archive;
INSERT OR IGNORE INTO warehouses (id, code, name) VALUES (1, 'NORTH', 'North Depot');

-- ── More DDL and DML forms ──
CREATE TABLE stock_snapshot AS SELECT warehouse_id, sku, quantity FROM stock WHERE quantity > 0;
CREATE TABLE IF NOT EXISTS audit (id INTEGER PRIMARY KEY, who TEXT, at TEXT DEFAULT CURRENT_TIMESTAMP) STRICT;
CREATE VIRTUAL TABLE IF NOT EXISTS product_search USING fts5(name, description);
CREATE VIEW IF NOT EXISTS v_totals (sku, total) AS SELECT sku, SUM(quantity) FROM stock GROUP BY sku;
CREATE TRIGGER trg_view_insert INSTEAD OF INSERT ON v_totals
BEGIN
    SELECT RAISE(ABORT, 'totals view is read-only');
END;
INSERT INTO audit (who) VALUES ('system') RETURNING id, who, at;
UPDATE products SET unit_price = unit_price + 1 WHERE sku = 'ABC-1' RETURNING sku, unit_price;
DELETE FROM audit WHERE who = 'system' RETURNING *;
INSERT INTO products (sku, name) VALUES ('ABC-8', 'Ignored') ON CONFLICT DO NOTHING;
UPDATE stock SET quantity = quantity + 1 FROM (SELECT 1 AS one) AS src WHERE sku = 'ABC-1';
VALUES (1, 'one'), (2, 'two');

-- ── More expressions and joins ──
SELECT a.sku, b.sku FROM products a FULL OUTER JOIN products b ON a.sku = b.sku;
SELECT sku FROM products WHERE name REGEXP '^H' OR sku ISNULL OR sku NOTNULL;
SELECT sku, quantity IS DISTINCT FROM reserved AS differs, quantity IS NOT DISTINCT FROM 0 AS is_zero FROM stock;
SELECT sku, name FROM products WHERE name COLLATE BINARY > 'a' AND sku <> 'x';
SELECT * FROM (SELECT 1 AS n) AS t, (SELECT 2 AS m) AS u;
SELECT sku, COUNT(*) FILTER (WHERE quantity > 0) AS positive FROM stock GROUP BY sku;
SELECT CAST('2026-09-24' AS DATE), CAST(3.7 AS INTEGER), CAST(1 AS TEXT), 5 BETWEEN 1 AND 10, 'a' NOT LIKE 'b%';

-- ── More windows and CTEs ──
WITH t AS MATERIALIZED (SELECT sku, quantity FROM stock), u AS NOT MATERIALIZED (SELECT sku FROM products)
SELECT t.sku,
       SUM(t.quantity) OVER (ORDER BY t.quantity RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS by_range,
       SUM(t.quantity) OVER (ORDER BY t.quantity GROUPS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING EXCLUDE TIES) AS by_group,
       PERCENT_RANK() OVER (ORDER BY t.quantity) AS pct,
       CUME_DIST() OVER (ORDER BY t.quantity) AS cume,
       LAST_VALUE(t.quantity) OVER (ORDER BY t.quantity ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_q,
       NTH_VALUE(t.quantity, 2) OVER (ORDER BY t.quantity) AS second_q
FROM t JOIN u USING (sku);
SELECT * FROM product_search WHERE product_search MATCH 'nail';
