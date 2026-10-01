// ── Comments ──
// Line comment. TODO: add indexes. FIXME: revisit the shortest-path cost.
/* Block comment
   across lines */

// ── Schema: constraints and indexes ──
CREATE CONSTRAINT sku_unique IF NOT EXISTS FOR (i:Item) REQUIRE i.sku IS UNIQUE;
CREATE CONSTRAINT bin_key IF NOT EXISTS FOR (b:Bin) REQUIRE (b.warehouse, b.code) IS NODE KEY;
CREATE CONSTRAINT qty_exists IF NOT EXISTS FOR (i:Item) REQUIRE i.qty IS NOT NULL;
CREATE INDEX item_name IF NOT EXISTS FOR (i:Item) ON (i.name);
CREATE FULLTEXT INDEX item_text IF NOT EXISTS FOR (i:Item) ON EACH [i.name, i.notes];
CREATE RANGE INDEX stored_at IF NOT EXISTS FOR ()-[r:STORED_IN]-() ON (r.since);
DROP INDEX old_index IF EXISTS;
SHOW INDEXES;
SHOW CONSTRAINTS YIELD name, type;

// ── Literals and parameters ──
RETURN 42 AS integer,
       0x2A AS hex,
       0o52 AS octal,
       1_000_000 AS big,
       3.14159 AS float,
       6.02e23 AS exp,
       1.5E-10 AS negexp,
       .5 AS leading,
       NaN AS nan,
       Infinity AS inf,
       true AS yes,
       false AS no,
       null AS nothing,
       'single \'quoted\' \n string' AS s1,
       "double \"quoted\" \t string é \u{1F4E6}" AS s2,
       `back-ticked identifier` AS ident,
       [1, 2, 3] AS list,
       {sku: 'A-100', qty: 5, tags: ['x', 'y']} AS map,
       $sku AS param,
       $`odd param` AS param2,
       date('2026-03-01') AS d,
       datetime({year: 2026, month: 3, day: 1, hour: 8}) AS dt,
       duration({days: 14, hours: 3}) AS dur,
       point({latitude: 51.5, longitude: -0.12}) AS p;

// ── Create ──
CREATE (w:Warehouse:Depot {name: 'North', opened: date('2020-01-15')})
CREATE (b:Bin {code: 'B-07', warehouse: 'North', capacity: 500})
CREATE (i:Item {sku: 'A-100', name: 'Claw hammer', qty: 42, price: 12.50})
CREATE (s:Supplier {name: 'Acme Tools'})
CREATE (w)-[:HAS_BIN]->(b),
       (i)-[:STORED_IN {since: date(), pallets: 2}]->(b),
       (s)-[:SUPPLIES {leadDays: 7}]->(i);

// ── Match, where, optional match ──
MATCH (i:Item)-[r:STORED_IN]->(b:Bin)
WHERE i.qty > 10 AND NOT i.discontinued
  AND (b.code STARTS WITH 'B' OR b.code ENDS WITH '9' OR b.code CONTAINS '-0')
  AND i.name =~ '(?i)hammer.*'
  AND i.sku IN ['A-100', 'A-101']
  AND i.notes IS NOT NULL
  AND r.since >= date('2026-01-01')
  AND EXISTS { MATCH (i)<-[:SUPPLIES]-(:Supplier) }
RETURN i.name, b.code, r.pallets;

OPTIONAL MATCH (i:Item {sku: 'Z-999'})-[:STORED_IN]->(b)
RETURN i, b;

MATCH p = (a:Item)-[:RELATED*1..3]-(b:Item)
WHERE a <> b AND all(n IN nodes(p) WHERE n.qty > 0)
RETURN p, length(p);

MATCH (a)-[:STORED_IN|HELD_AT]->(b), (c)<-[:SUPPLIES]-(d), (e)--(f), (g)-->(h), (j)<--(k)
RETURN count(*);

MATCH path = shortestPath((a:Warehouse {name: 'North'})-[*..15]-(b:Warehouse {name: 'South'}))
RETURN path;

// ── Merge, set, remove, delete ──
MERGE (i:Item {sku: 'A-100'})
  ON CREATE SET i.created = timestamp(), i.qty = 0
  ON MATCH SET i.seen = timestamp()
SET i.qty = i.qty + 10,
    i += {price: 13.00, updated: datetime()},
    i:Stocked:Priced
REMOVE i.notes, i:Draft
RETURN i;

MATCH (i:Item {discontinued: true}) DETACH DELETE i;
MATCH (n) WHERE n.temp DELETE n;

// ── Projection, aggregation, ordering ──
MATCH (i:Item)-[:STORED_IN]->(b:Bin)
WITH b, count(i) AS items, sum(i.qty * i.price) AS value, avg(i.price) AS avgPrice,
     min(i.qty) AS lo, max(i.qty) AS hi, collect(DISTINCT i.name) AS names,
     percentileDisc(i.qty, 0.5) AS median, stDev(i.price) AS spread
WHERE items > 1
ORDER BY value DESC, b.code ASC
SKIP 5
LIMIT 10
RETURN DISTINCT b.code AS bin, items, value, names[0..3] AS firstThree, names[-1] AS last;

// ── Expressions ──
MATCH (i:Item)
RETURN CASE
         WHEN i.qty = 0 THEN 'out'
         WHEN i.qty < 5 THEN 'low'
         ELSE 'ok'
       END AS status,
       CASE i.category WHEN 'tools' THEN 1 WHEN 'safety' THEN 2 ELSE 0 END AS code,
       coalesce(i.notes, 'none') AS notes,
       [x IN range(1, 10) WHERE x % 2 = 0 | x * x] AS squares,
       [(i)-[:STORED_IN]->(b) | b.code] AS bins,
       reduce(total = 0, q IN [1, 2, 3] | total + q) AS sum,
       toInteger('42') + toFloat('1.5') AS conv,
       size(i.name) + length('abc') AS len,
       i.price ^ 2 + i.qty * 3 - i.qty / 2 + i.qty % 7 AS arith,
       i.qty IS NULL AS isNull,
       i.name STARTS WITH 'C' XOR i.qty > 1 AS flag,
       any(t IN i.tags WHERE t = 'x') AS anyTag,
       none(t IN i.tags WHERE t = 'y') AS noTag,
       single(t IN i.tags WHERE t = 'z') AS oneTag,
       i.name + ' (' + toString(i.qty) + ')' AS label;

// ── Unwind, union, subqueries, call ──
UNWIND [{sku: 'A-1', qty: 1}, {sku: 'A-2', qty: 2}] AS row
MERGE (i:Item {sku: row.sku})
SET i.qty = row.qty;

MATCH (i:Item) WHERE i.qty = 0 RETURN i.sku AS sku
UNION ALL
MATCH (d:Discontinued) RETURN d.sku AS sku;

CALL {
  MATCH (i:Item) RETURN count(i) AS total
}
CALL db.labels() YIELD label
CALL apoc.help('text') YIELD name, text WHERE name STARTS WITH 'apoc.text'
RETURN total, label;

CALL {
  WITH 1 AS x
  RETURN x
}
IN TRANSACTIONS OF 1000 ROWS
RETURN 1;

LOAD CSV WITH HEADERS FROM 'file:///items.csv' AS line FIELDTERMINATOR ';'
CREATE (:Item {sku: line.sku, qty: toInteger(line.qty)});

FOREACH (n IN nodes(path) | SET n.visited = true);

// ── Administration and explain ──
EXPLAIN MATCH (i:Item) RETURN i;
PROFILE MATCH (i:Item {sku: 'A-100'}) RETURN i;
USE inventory MATCH (n) RETURN count(n);
CREATE DATABASE inventory IF NOT EXISTS;
CREATE USER clerk IF NOT EXISTS SET PASSWORD 'example-not-a-real-password' CHANGE NOT REQUIRED;
GRANT MATCH {*} ON GRAPH inventory NODES Item TO clerk;

// ── Further constructs ──
// Quantified path patterns, shortest paths, label expressions (Cypher 5)
MATCH (a:Warehouse)-[r:ROUTE]->{1,3}(b:Warehouse) RETURN a, b;
MATCH p = ((a:Bin)-[:NEXT]->(b:Bin)){2,5} RETURN p;
MATCH (n:Item|Product) RETURN n;
MATCH (n:Item&!Archived) RETURN n;
MATCH (n:%) RETURN n;
MATCH (n IS Item) RETURN n;
MATCH allShortestPaths((a)-[*]-(b)) RETURN count(*);
MATCH SHORTEST 3 (a)-[:ROUTE]-+(b) RETURN a;
MATCH ANY SHORTEST (a:Bin)-[:NEXT]->*(b:Bin) RETURN a;
MATCH (a)-[r:ROUTE*2..5 {weight: 1}]->(b) WHERE ALL(x IN r WHERE x.weight > 0) RETURN a;
MATCH (n:Item) WHERE n.qty IS :: INTEGER AND n.name IS NOT :: STRING RETURN n;
MATCH (n) WHERE n:Item AND NOT n:Archived RETURN n;
MATCH (n) WHERE (n)-[:STORED_IN]->() AND NOT (n)<-[:SUPPLIES]-() RETURN n;

// Ordering, null handling, predicates
MATCH (n:Item) RETURN n ORDER BY n.qty DESC NULLS LAST, n.name ASCENDING;
MATCH (n:Item) RETURN n SKIP $skip LIMIT $limit;
MATCH (n:Item) WHERE n.qty BETWEEN 1 AND 5 OR n.name =~ '.*x' OR n.tags[0] = 'a' RETURN n;
MATCH (n:Item) WHERE exists(n.notes) AND n.notes <> '' AND n.qty >= 0 RETURN n;
RETURN [1, 2, 3][1..], [1, 2, 3][..2], [1, 2, 3][-2..-1], {a: 1}['a'], {a: 1}.a;
RETURN 1 IN [1, 2] AS inList, 'a' + 1 AS mixed, -1 AS neg, 2 ^ 10 AS pow, 7 % 3 AS modulo, 7 / 2 AS div;
RETURN abs(-1), ceil(1.2), floor(1.8), round(1.5), sign(-3), rand(), sqrt(4), exp(1), log(10), log10(100), pi(), e();
RETURN toUpper('a'), toLower('A'), trim('  a  '), ltrim(' a'), rtrim('a '), replace('abc', 'b', 'x'), substring('hello', 1, 3), left('abc', 1), right('abc', 1), split('a,b', ','), reverse('abc');
RETURN head([1, 2]), last([1, 2]), tail([1, 2]), keys({a: 1}), labels(n), type(r), id(n), elementId(n), properties(n), nodes(p), relationships(p);
RETURN date.truncate('month', date()), datetime.fromepoch(0, 0), localtime(), localdatetime(), time(), duration.between(date('2026-01-01'), date('2026-03-01')), date().year;
RETURN point.distance(point({x: 0, y: 0}), point({x: 3, y: 4})), vector.similarity.cosine([1, 2], [3, 4]);
RETURN count(*), count(DISTINCT n), collect(n.name)[0], percentileCont(n.qty, 0.9), sum(n.qty), avg(n.qty), stDevP(n.qty);

// Writing clauses
MERGE (a:Item {sku: 'A-100'})-[r:STORED_IN]->(b:Bin {code: 'B-07'}) ON CREATE SET r.since = date();
MATCH (n:Item) SET n.updated = timestamp(), n += $props, n = {sku: n.sku};
MATCH (n:Item) SET n:Tagged, n.tags = n.tags + ['x'] REMOVE n:Draft, n.temp;
MATCH (n:Item)-[r]->() DELETE r;
MATCH (n:Item) CALL { WITH n SET n.visited = true } IN TRANSACTIONS OF 500 ROWS ON ERROR CONTINUE;
UNWIND range(1, 3) AS i CREATE (:Counter {value: i});
MATCH (n) WITH n LIMIT 1 CALL db.index.fulltext.queryNodes('item_text', 'hammer') YIELD node, score RETURN node, score;
MATCH (n) RETURN n { .*, extra: 1 } AS projected, n { .sku, .qty } AS partial;
MATCH (n:Item) RETURN n.name AS `quoted alias`, n.`odd prop` AS odd;
WITH 1 AS x, 'two' AS y WHERE x > 0 RETURN x, y;
RETURN COUNT { (n:Item) } AS cnt, COLLECT { MATCH (n:Item) RETURN n.sku } AS skus;
RETURN CASE WHEN 1 = 1 THEN 'a' END;
RETURN EXISTS { MATCH (:Item) } AS any;
MATCH (n) RETURN n UNION MATCH (m) RETURN m;
OPTIONAL CALL db.labels() YIELD label RETURN label;
ALTER DATABASE inventory SET ACCESS READ ONLY;
DROP CONSTRAINT sku_unique IF EXISTS;
DROP DATABASE inventory IF EXISTS DUMP DATA;
SHOW FUNCTIONS YIELD name WHERE name STARTS WITH 'date';
SHOW PROCEDURES; SHOW TRANSACTIONS; SHOW SETTINGS;
TERMINATE TRANSACTIONS 'neo4j-transaction-1';
DENY WRITE ON GRAPH inventory TO clerk;
REVOKE GRANT MATCH {*} ON GRAPH inventory FROM clerk;
CREATE ROLE auditor IF NOT EXISTS;
GRANT ROLE auditor TO clerk;
RENAME USER clerk TO picker;
DROP USER picker IF EXISTS;
