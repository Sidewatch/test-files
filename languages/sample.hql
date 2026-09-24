-- HiveQL: a partitioned events table and a daily rollup.
CREATE EXTERNAL TABLE IF NOT EXISTS events (
  user_id   BIGINT,
  event     STRING,
  props     MAP<STRING, STRING>,
  ts        TIMESTAMP
)
PARTITIONED BY (dt STRING)
STORED AS PARQUET
LOCATION 's3://data-lake/events/';

MSCK REPAIR TABLE events;

SET hive.exec.dynamic.partition.mode = nonstrict;

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
