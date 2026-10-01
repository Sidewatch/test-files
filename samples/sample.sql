-- Orders schema + reporting query (DerekStride/tree-sitter-sql v0.3.11)
CREATE TABLE customers (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       VARCHAR(120) NOT NULL,
    email      TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    id          INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    status      TEXT CHECK (status IN ('pending', 'shipped', 'cancelled')),
    total_cents BIGINT DEFAULT 0
);

INSERT INTO customers (name, email)
VALUES ('Ada Lovelace', 'ada@example.com'),
       ('Alan Turing', NULL);

/* Top spenders in the last 90 days, joined + aggregated. */
WITH recent AS (
    SELECT o.customer_id, SUM(o.total_cents) / 100.0 AS total_dollars
    FROM orders AS o
    WHERE o.status = 'shipped'
      AND o.id > 1000
    GROUP BY o.customer_id
    HAVING SUM(o.total_cents) > 5000
)
SELECT c.name,
       COALESCE(r.total_dollars, 0.0) AS spend,
       COUNT(*) OVER () AS cohort_size
FROM customers AS c
LEFT JOIN recent AS r ON r.customer_id = c.id
ORDER BY spend DESC
LIMIT 25;

UPDATE orders SET status = 'cancelled' WHERE customer_id IS NULL;
