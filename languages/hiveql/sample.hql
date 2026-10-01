-- ── Comments ──
-- HiveQL: partitioned tables, UDFs, window functions, lateral views and rollups.
/* Block comment. TODO: bucket by sku. FIXME: skewed partitions. */

-- ── Session settings ──
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions = 2000;
SET mapreduce.job.reduces=8;
SET hivevar:run_date = '2026-09-24';
SET hiveconf:threshold=100;
SET hive.cli.print.header = true;
ADD JAR /opt/hive/lib/custom-udfs.jar;
ADD FILE /tmp/lookup.txt;
CREATE TEMPORARY FUNCTION normalise AS 'com.example.udf.Normalise';
CREATE FUNCTION default.parse_sku AS 'com.example.udf.ParseSku' USING JAR 'hdfs:///libs/udfs.jar';
DROP FUNCTION IF EXISTS default.old_fn;

-- ── Databases ──
CREATE DATABASE IF NOT EXISTS warehouse COMMENT 'Warehouse analytics' LOCATION '/data/warehouse' WITH DBPROPERTIES ('owner'='ops');
USE warehouse;
SHOW DATABASES;
SHOW TABLES IN warehouse LIKE 'ev*';
DESCRIBE FORMATTED events;
DESCRIBE EXTENDED events PARTITION (dt='2026-09-24');

-- ── Tables: external, managed, partitioned, bucketed, formats ──
CREATE EXTERNAL TABLE IF NOT EXISTS events (
  user_id   BIGINT COMMENT 'Numeric user id',
  event     STRING,
  props     MAP<STRING, STRING>,
  tags      ARRAY<STRING>,
  location  STRUCT<lat:DOUBLE, lon:DOUBLE, city:STRING>,
  amount    DECIMAL(10,2),
  flag      BOOLEAN,
  small     TINYINT,
  medium    SMALLINT,
  num       INT,
  ratio     FLOAT,
  blob      BINARY,
  born      DATE,
  ts        TIMESTAMP,
  code      CHAR(3),
  label     VARCHAR(50),
  choice    UNIONTYPE<INT, STRING>
)
COMMENT 'Raw event stream'
PARTITIONED BY (dt STRING, region STRING)
CLUSTERED BY (user_id) SORTED BY (ts DESC) INTO 32 BUCKETS
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY '\t'
  COLLECTION ITEMS TERMINATED BY ','
  MAP KEYS TERMINATED BY ':'
  LINES TERMINATED BY '\n'
  NULL DEFINED AS ''
STORED AS PARQUET
LOCATION 's3://data-lake/events/'
TBLPROPERTIES ('parquet.compression'='SNAPPY', 'created'='2026-09-24', "double"="quoted");

CREATE TABLE json_events (id INT, body STRING)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
WITH SERDEPROPERTIES ('ignore.malformed.json'='true')
STORED AS TEXTFILE;

CREATE TABLE orc_orders STORED AS ORC TBLPROPERTIES ('transactional'='true') AS SELECT * FROM events WHERE dt > '2026-01-01';
CREATE TABLE IF NOT EXISTS copy_of_events LIKE events;
CREATE TEMPORARY TABLE tmp_sample (id INT);
CREATE VIEW IF NOT EXISTS recent_events AS SELECT * FROM events WHERE dt >= date_sub(current_date(), 7);
CREATE MATERIALIZED VIEW daily_totals AS SELECT dt, COUNT(*) AS n FROM events GROUP BY dt;
CREATE INDEX idx_events_user ON TABLE events (user_id) AS 'COMPACT' WITH DEFERRED REBUILD;

MSCK REPAIR TABLE events;
ANALYZE TABLE events PARTITION (dt='2026-09-24') COMPUTE STATISTICS FOR COLUMNS;
ALTER TABLE events ADD IF NOT EXISTS PARTITION (dt='2026-09-24', region='eu') LOCATION 's3://data-lake/events/dt=2026-09-24/eu';
ALTER TABLE events DROP IF EXISTS PARTITION (dt < '2026-01-01');
ALTER TABLE events SET TBLPROPERTIES ('comment' = 'updated');
ALTER TABLE events CHANGE COLUMN num num BIGINT COMMENT 'widened' AFTER user_id;
ALTER TABLE events ADD COLUMNS (extra STRING);
ALTER TABLE events RENAME TO events_v2;
ALTER TABLE events_v2 CONCATENATE;
TRUNCATE TABLE tmp_sample;
DROP TABLE IF EXISTS tmp_sample PURGE;

-- ── Loading and inserting ──
LOAD DATA INPATH '/staging/events.csv' OVERWRITE INTO TABLE events PARTITION (dt='2026-09-24', region='eu');
LOAD DATA LOCAL INPATH '/tmp/local.csv' INTO TABLE json_events;

INSERT OVERWRITE TABLE daily_active PARTITION (dt)
SELECT
  COUNT(DISTINCT user_id)                          AS active_users,
  SUM(CASE WHEN event = 'purchase' THEN 1 ELSE 0 END) AS purchases,
  percentile_approx(CAST(props['latency_ms'] AS DOUBLE), 0.95) AS p95_latency,
  dt
FROM events
WHERE dt >= date_sub(current_date(), 7)
  AND event IN ('open', 'purchase')
GROUP BY dt
ORDER BY dt DESC;

INSERT INTO TABLE summary VALUES (1, 'a', 2.5, TRUE, NULL), (2, "b", -3, FALSE, NULL);
INSERT OVERWRITE DIRECTORY '/out/events' ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' SELECT * FROM events LIMIT 10;
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/out' STORED AS TEXTFILE SELECT user_id FROM events;

FROM events e
INSERT OVERWRITE TABLE a SELECT e.user_id WHERE e.event = 'open'
INSERT OVERWRITE TABLE b SELECT e.user_id WHERE e.event = 'purchase';

-- ── Literals ──
SELECT
  42 AS int_lit, -7 AS neg, 3.14 AS float_lit, 1.5E-3 AS exp, 100L AS bigint_lit, 5S AS small_lit, 1Y AS tiny_lit,
  12.5BD AS decimal_lit, 0xFF AS hex_lit,
  'single ''quoted'' and \'escaped\' \n \t \\ é' AS s1,
  "double quoted \" string" AS s2,
  TRUE AS t, FALSE AS f, NULL AS n,
  DATE '2026-09-24' AS d, TIMESTAMP '2026-09-24 10:00:00.123' AS ts,
  INTERVAL '1' DAY AS day_interval, INTERVAL '2-3' YEAR TO MONTH AS ym,
  ARRAY(1, 2, 3) AS arr, MAP('a', 1, 'b', 2) AS m, STRUCT(1, 'x') AS st, NAMED_STRUCT('k', 1, 'v', 'x') AS ns,
  `quoted identifier` AS q, `weird name-with.dots` AS q2
FROM events;

-- ── Queries: joins, subqueries, set ops, CTEs ──
WITH recent AS (
  SELECT user_id, event, ts FROM events WHERE dt >= '2026-09-01'
), totals AS (
  SELECT user_id, COUNT(*) AS n FROM recent GROUP BY user_id HAVING COUNT(*) > ${hiveconf:threshold}
)
SELECT r.user_id, t.n, u.name, o.total
FROM recent r
JOIN totals t ON r.user_id = t.user_id
LEFT OUTER JOIN users u ON r.user_id = u.id
RIGHT JOIN orders o ON o.user_id = r.user_id
FULL OUTER JOIN refunds f ON f.user_id = r.user_id
LEFT SEMI JOIN vip v ON v.user_id = r.user_id
CROSS JOIN dim d
LEFT ANTI JOIN blocked b ON b.user_id = r.user_id
WHERE r.event RLIKE '^(open|purchase)$' AND u.name LIKE 'A%' AND o.total BETWEEN 10 AND 100
  AND u.email REGEXP '.*@example\\.com' AND r.ts IS NOT NULL AND NOT EXISTS (SELECT 1 FROM blocked b2 WHERE b2.user_id = r.user_id)
  AND r.user_id IN (SELECT user_id FROM vip)
DISTRIBUTE BY r.user_id SORT BY r.ts
CLUSTER BY r.user_id
LIMIT 100;

SELECT /*+ MAPJOIN(d) */ a.id FROM a JOIN d ON a.k = d.k;
SELECT * FROM a UNION ALL SELECT * FROM b;
SELECT * FROM a UNION DISTINCT SELECT * FROM b;
SELECT id FROM a INTERSECT SELECT id FROM b;
SELECT id FROM a EXCEPT SELECT id FROM b;
SELECT * FROM events TABLESAMPLE (BUCKET 1 OUT OF 32 ON user_id);
SELECT * FROM events TABLESAMPLE (10 PERCENT);

-- ── Window functions, grouping sets, lateral view ──
SELECT
  user_id,
  ts,
  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY ts DESC) AS rn,
  RANK() OVER w AS rk,
  DENSE_RANK() OVER (ORDER BY amount) AS dr,
  LAG(amount, 1, 0) OVER (PARTITION BY user_id ORDER BY ts) AS prev,
  LEAD(amount) OVER (PARTITION BY user_id ORDER BY ts) AS next,
  SUM(amount) OVER (PARTITION BY user_id ORDER BY ts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running,
  AVG(amount) OVER (ORDER BY ts RANGE BETWEEN INTERVAL '7' DAY PRECEDING AND CURRENT ROW) AS moving,
  FIRST_VALUE(amount) OVER w AS first_amt,
  NTILE(4) OVER (ORDER BY amount) AS quartile,
  CUME_DIST() OVER w AS cd
FROM events
WINDOW w AS (PARTITION BY user_id ORDER BY ts);

SELECT dt, region, COUNT(*) FROM events GROUP BY dt, region WITH ROLLUP;
SELECT dt, region, COUNT(*) FROM events GROUP BY dt, region WITH CUBE;
SELECT dt, region, COUNT(*) FROM events GROUP BY dt, region GROUPING SETS ((dt, region), (dt), ());
SELECT dt, region, GROUPING__ID, COUNT(*) FROM events GROUP BY dt, region WITH CUBE;

SELECT e.user_id, tag FROM events e LATERAL VIEW EXPLODE(e.tags) t AS tag;
SELECT e.user_id, k, v FROM events e LATERAL VIEW OUTER EXPLODE(e.props) p AS k, v;
SELECT e.id, pe.* FROM events e LATERAL VIEW POSEXPLODE(e.tags) pe AS pos, val;
SELECT get_json_object(body, '$.user.id') AS uid, json_tuple(body, 'a', 'b') AS (a, b) FROM json_events;
SELECT transform(user_id, event) USING 'python script.py' AS (uid, evt) FROM events;

-- ── Built-in functions ──
SELECT
  concat_ws('-', 'a', 'b'), upper(label), lower(label), trim(label), substr(label, 1, 3), regexp_replace(label, '[^a-z]', ''),
  split(label, ','), size(tags), array_contains(tags, 'x'), map_keys(props), sort_array(tags),
  round(amount, 2), floor(ratio), ceil(ratio), abs(num), pow(2, 10), sqrt(16), rand(42),
  from_unixtime(unix_timestamp()), date_add(born, 7), datediff(current_date(), born), year(ts), month(ts), to_date(ts),
  date_format(ts, 'yyyy-MM-dd HH:mm'), coalesce(label, 'n/a'), nvl(label, ''), if(flag, 'y', 'n'),
  CASE WHEN num > 10 THEN 'big' WHEN num > 5 THEN 'mid' ELSE 'small' END,
  CASE code WHEN 'A' THEN 1 ELSE 0 END,
  CAST(num AS STRING), CAST(label AS INT), md5(label), sha2(label, 256), hash(user_id),
  collect_set(event), collect_list(event), count(*), count(DISTINCT user_id), max(ts), min(ts), stddev_pop(amount), variance(amount)
FROM events;

-- ── Transactions and maintenance ──
UPDATE orc_orders SET total = total * 1.1 WHERE dt = '2026-09-24';
DELETE FROM orc_orders WHERE total < 0;
MERGE INTO orc_orders t USING staging s ON t.id = s.id WHEN MATCHED THEN UPDATE SET total = s.total WHEN NOT MATCHED THEN INSERT VALUES (s.id, s.total);
EXPLAIN EXTENDED SELECT * FROM events;
SHOW PARTITIONS events;
SHOW CREATE TABLE events;
GRANT SELECT ON TABLE events TO USER analyst;
REVOKE SELECT ON TABLE events FROM USER analyst;
EXPORT TABLE events TO '/export/events';
IMPORT TABLE events_copy FROM '/export/events';

-- ── More DDL: constraints, skew, storage handlers, formats ──
CREATE TABLE constrained (
  id INT,
  sku STRING,
  amount DOUBLE PRECISION,
  created TIMESTAMP WITH LOCAL TIME ZONE,
  CONSTRAINT pk PRIMARY KEY (id) DISABLE NOVALIDATE RELY,
  CONSTRAINT fk FOREIGN KEY (sku) REFERENCES skus(code) DISABLE NOVALIDATE,
  CONSTRAINT uq UNIQUE (sku) DISABLE NOVALIDATE,
  CONSTRAINT nn CHECK (amount > 0) ENABLE
)
SKEWED BY (sku) ON ('A-1', 'B-2') STORED AS DIRECTORIES
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat';

CREATE EXTERNAL TABLE hbase_table (key INT, value STRING)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES ('hbase.columns.mapping' = ':key,cf:val')
TBLPROPERTIES ('hbase.table.name' = 'xyz');

CREATE TABLE csv_table (a STRING, b STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE TABLE avro_table STORED AS AVRO TBLPROPERTIES ('avro.schema.url'='hdfs:///schemas/x.avsc');
CREATE TABLE rc_table (a INT) STORED AS RCFILE;
CREATE TABLE seq_table (a INT) STORED AS SEQUENCEFILE;
CREATE TABLE ice_table (a INT) STORED BY ICEBERG;
CREATE TRANSACTIONAL TABLE tx_table (a INT);
CREATE MANAGED TABLE managed (a INT);
CREATE TABLE ctas_part PARTITIONED BY (dt) STORED AS ORC AS SELECT a, dt FROM events;
CREATE MACRO sigmoid(x DOUBLE) 1.0 / (1.0 + EXP(-x));
CREATE TEMPORARY MACRO square(x DOUBLE) x * x;
DROP TEMPORARY MACRO IF EXISTS square;
DROP DATABASE IF EXISTS scratch CASCADE;
DROP VIEW IF EXISTS recent_events;
DROP MATERIALIZED VIEW daily_totals;
ALTER DATABASE warehouse SET DBPROPERTIES ('edited-by' = 'ops');
ALTER DATABASE warehouse SET OWNER USER hive;
ALTER VIEW recent_events AS SELECT * FROM events;
ALTER VIEW recent_events SET TBLPROPERTIES ('x' = 'y');
ALTER MATERIALIZED VIEW daily_totals ENABLE REWRITE;
ALTER TABLE events PARTITION (dt='2026-09-24') SET FILEFORMAT ORC;
ALTER TABLE events PARTITION (dt='2026-09-24') SET LOCATION 's3://x/y';
ALTER TABLE events ARCHIVE PARTITION (dt='2026-01-01');
ALTER TABLE events CLUSTERED BY (user_id) INTO 16 BUCKETS;
ALTER TABLE events SKEWED BY (event) ON ('open') STORED AS DIRECTORIES;
ALTER TABLE events COMPACT 'major' AND WAIT;
ALTER TABLE events ADD CONSTRAINT pk2 PRIMARY KEY (user_id) DISABLE NOVALIDATE;
ALTER TABLE events DROP CONSTRAINT pk2;
ALTER TABLE events EXCHANGE PARTITION (dt='2026-09-24') WITH TABLE events_copy;
ALTER TABLE events RECOVER PARTITIONS;
ALTER INDEX idx_events_user ON events REBUILD;

-- ── Administration, security, session commands ──
SHOW FUNCTIONS LIKE 'date*';
SHOW COLUMNS FROM events;
SHOW TBLPROPERTIES events;
SHOW LOCKS events;
SHOW COMPACTIONS;
SHOW TRANSACTIONS;
SHOW ROLES;
SHOW GRANT USER analyst ON TABLE events;
SHOW CURRENT ROLES;
SHOW INDEXES ON events;
SHOW CONF 'hive.exec.parallel';
DESCRIBE FUNCTION EXTENDED upper;
DESCRIBE DATABASE EXTENDED warehouse;
DESCRIBE events.user_id;
LOCK TABLE events SHARED;
UNLOCK TABLE events;
CREATE ROLE analysts;
GRANT ROLE analysts TO USER analyst;
GRANT ALL ON DATABASE warehouse TO ROLE analysts WITH GRANT OPTION;
REVOKE ROLE analysts FROM USER analyst;
SET ROLE ADMIN;
DROP ROLE analysts;
START TRANSACTION;
COMMIT;
ROLLBACK;
RELOAD FUNCTION;
ADD ARCHIVE /tmp/libs.tar.gz;
ADD JARS /opt/a.jar /opt/b.jar;
LIST JARS;
LIST FILES;
DELETE JAR /opt/a.jar;
dfs -ls /user/hive/warehouse;
source /tmp/script.hql;
!ls /tmp;
RESET;
RESET hive.exec.parallel;
SET;
SET -v;
SET hive.exec.parallel;

-- ── Query features not yet shown ──
SELECT user_id, event FROM events ORDER BY ts DESC NULLS LAST, user_id ASC NULLS FIRST LIMIT 10 OFFSET 5;
SELECT DISTINCT event FROM events;
SELECT ALL event FROM events;
SELECT * EXCEPT (props) FROM events;
SELECT `(ts|props)?+.+` FROM events;
SELECT a.* FROM (SELECT * FROM events) a;
SELECT 1 + 2 * 3 - 4 / 2 % 3 AS arith, 7 DIV 2 AS int_div, 5 & 3 AS band, 5 | 3 AS bor, 5 ^ 3 AS bxor, ~5 AS bnot, 'a' || 'b' AS concat;
SELECT x <=> y, x <> y, x != y, x = y, x == y, x < y, x <= y, x > y, x >= y FROM t;
SELECT x IS NULL, x IS NOT NULL, x IS TRUE, x IS NOT FALSE, NOT x, x AND y, x OR y, x BETWEEN 1 AND 2, x NOT BETWEEN 1 AND 2, x NOT IN (1, 2), x NOT LIKE 'a%', x NOT RLIKE 'b', x IS DISTINCT FROM y FROM t;
SELECT CAST('2026-01-01' AS DATE), CAST(x AS DECIMAL(10, 2)), CAST(x AS ARRAY<INT>), x::INT FROM t;
SELECT EXTRACT(YEAR FROM ts), TRIM(BOTH ' ' FROM label), SUBSTRING(label FROM 1 FOR 3), POSITION('a' IN label) FROM events;
SELECT COUNT(*) FILTER (WHERE flag) FROM events;
SELECT map_values(props)[0], tags[0], location.city, props['k'], arr[1][2] FROM events;
SELECT * FROM events WHERE dt = '${hivevar:run_date}' AND user_id = ${hiveconf:uid};
SELECT * FROM (VALUES (1, 'a'), (2, 'b')) AS t(id, name);
SELECT * FROM events e, LATERAL (SELECT 1) l;
SELECT inline(ARRAY(STRUCT(1, 'a'), STRUCT(2, 'b'))) FROM dual;
SELECT stack(2, 'a', 1, 'b', 2) AS (k, v);
SELECT ASSERT_TRUE(1 = 1), REFLECT('java.lang.Math', 'max', 1, 2), CURRENT_USER(), LOGGED_IN_USER();
SELECT * FROM a JOIN b USING (id);
SELECT * FROM a NATURAL JOIN b;
SELECT * FROM a INNER JOIN b ON (a.k = b.k AND a.v > b.v) WHERE a.x IN (SELECT x FROM c);
SELECT * FROM a WHERE EXISTS (SELECT 1 FROM b WHERE b.k = a.k) AND a.v > ALL (SELECT v FROM c) AND a.w = ANY (SELECT w FROM d);
EXPLAIN DEPENDENCY SELECT * FROM events;
EXPLAIN AUTHORIZATION SELECT * FROM events;
EXPLAIN VECTORIZATION ONLY SELECT * FROM events;
EXPLAIN CBO SELECT * FROM events;
EXPLAIN LOCKS INSERT INTO t SELECT * FROM events;
-- Non-ASCII: café 日本語 ☕
