-- MySQL dialect showcase: engines, charsets, backticks, JSON, upserts, routines.
-- This file DETECTS AS SQL — pick MySQL from the language picker to see the dialect's keywords.
# A hash comment, MySQL-only.
/* A block comment
   over lines. */
/*! SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!50503 SET NAMES utf8mb4 */;
/*+ MAX_EXECUTION_TIME(1000) */
-- TODO: partition the orders table by month

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET @site = 'north', @limit := 10, @@session.sql_mode = 'STRICT_ALL_TABLES';
SET GLOBAL max_connections = 500;
SET autocommit = 0;
USE `warehouse`;
CREATE DATABASE IF NOT EXISTS `warehouse` DEFAULT CHARACTER SET utf8mb4;
DROP TABLE IF EXISTS `order_lines`, `orders`;

-- ── Literals ──
SELECT 'it''s', "double \"quoted\"", 'tab\there', 'new\nline', _utf8mb4'text',
       0x4142, X'41', x'4142', 0b1010, b'1010', 1.5e3, .5, -3, TRUE, FALSE, NULL,
       DATE '2025-01-01', TIME '12:30:00', TIMESTAMP '2025-01-01 00:00:00',
       @site, @@global.version, @@session.time_zone;

-- ── DDL ──
CREATE TABLE IF NOT EXISTS `orders` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `number` INT NOT NULL,
  `total` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('pending','paid','cancelled') NOT NULL DEFAULT 'pending',
  `flags` SET('gift','rush','fragile') DEFAULT NULL,
  `meta` JSON NULL,
  `note` TEXT COMMENT 'free text',
  `blob_data` MEDIUMBLOB,
  `ratio` DOUBLE UNSIGNED ZEROFILL,
  `tiny` TINYINT(1) NOT NULL DEFAULT 0,
  `big` BIGINT SIGNED,
  `name_len` INT GENERATED ALWAYS AS (CHAR_LENGTH(`note`)) VIRTUAL,
  `placed_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `loc` POINT NOT NULL SRID 4326,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_number` (`number`),
  KEY `idx_status_placed` (`status`, `placed_at` DESC),
  FULLTEXT KEY `ft_note` (`note`),
  SPATIAL INDEX `sp_loc` (`loc`),
  CONSTRAINT `chk_total` CHECK (`total` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  ROW_FORMAT=DYNAMIC COMMENT='All orders'
  PARTITION BY RANGE (YEAR(`placed_at`)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION pmax VALUES LESS THAN MAXVALUE
  );

CREATE TABLE `order_lines` (
  `order_id` INT UNSIGNED NOT NULL,
  `sku` VARCHAR(32) CHARACTER SET ascii NOT NULL,
  `qty` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`order_id`, `sku`),
  CONSTRAINT `fk_lines_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
    ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB;

CREATE TEMPORARY TABLE tmp_totals LIKE `orders`;
ALTER TABLE `orders` ADD COLUMN `region` CHAR(2) AFTER `status`, ADD INDEX `idx_region` (`region`);
ALTER TABLE `orders` MODIFY COLUMN `total` DECIMAL(12,2) NOT NULL, DROP COLUMN `ratio`, ENGINE=InnoDB;
CREATE UNIQUE INDEX `uq_note` ON `orders` (`note`(64));
CREATE OR REPLACE VIEW `v_paid` AS SELECT `id`, `total` FROM `orders` WHERE `status` = 'paid';
RENAME TABLE `tmp_totals` TO `totals_old`;
TRUNCATE TABLE `totals_old`;
DROP TABLE `totals_old`;

-- ── DML ──
INSERT INTO `orders` (`number`, `total`, `status`, `meta`)
VALUES (1, 120.50, 'paid', JSON_OBJECT('gift', TRUE, 'tags', JSON_ARRAY('a', 'b'))),
       (2, 15.00, 'pending', NULL)
ON DUPLICATE KEY UPDATE `total` = VALUES(`total`), `updated_at` = NOW();

INSERT IGNORE INTO `order_lines` SET `order_id` = 1, `sku` = 'A-100', `qty` = 2;
REPLACE INTO `order_lines` (`order_id`, `sku`, `qty`) VALUES (1, 'B-200', 1);
INSERT INTO `totals` SELECT `status`, SUM(`total`) FROM `orders` GROUP BY `status`;

UPDATE `orders` o
  JOIN `order_lines` l ON l.order_id = o.id
  SET o.total = o.total + l.qty * 1.5
  WHERE o.status <> 'cancelled' ORDER BY o.id LIMIT 100;

DELETE FROM `orders` WHERE `status` = 'cancelled' AND `placed_at` < DATE_SUB(NOW(), INTERVAL 1 YEAR) LIMIT 1000;
LOAD DATA INFILE '/var/lib/mysql-files/orders.csv' INTO TABLE `orders`
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- ── Queries ──
SELECT SQL_CALC_FOUND_ROWS `status`, COUNT(*) AS n, SUM(`total`) AS revenue,
       JSON_EXTRACT(`meta`, '$.gift') AS gift,
       `meta`->'$.tags[0]' AS first_tag, `meta`->>'$.gift' AS gift_text,
       IFNULL(`note`, '') AS note, COALESCE(`region`, 'n/a') AS region,
       IF(`total` > 100, 'big', 'small') AS size,
       CASE WHEN `total` > 100 THEN 'high' WHEN `total` > 10 THEN 'mid' ELSE 'low' END AS band,
       GROUP_CONCAT(DISTINCT `sku` ORDER BY `sku` SEPARATOR ', ') AS skus,
       CONCAT_WS('-', `region`, `number`) AS code, DATE_FORMAT(`placed_at`, '%Y-%m-%d') AS day,
       TIMESTAMPDIFF(HOUR, `placed_at`, NOW()) AS age_h, FOUND_ROWS() AS found
FROM `orders` USE INDEX (`idx_status_placed`)
LEFT JOIN `order_lines` AS l ON l.`order_id` = `orders`.`id`
WHERE `placed_at` >= DATE_SUB(NOW(), INTERVAL 7 DAY)
  AND `status` IN ('paid', 'pending') AND `note` IS NOT NULL
  AND `number` BETWEEN 1 AND 100 AND `note` LIKE 'rush%' AND `note` NOT REGEXP '^x'
  AND MATCH(`note`) AGAINST ('urgent' IN NATURAL LANGUAGE MODE)
GROUP BY `status` WITH ROLLUP
HAVING revenue > 0
ORDER BY revenue DESC, `status` ASC
LIMIT 10 OFFSET 5
FOR UPDATE SKIP LOCKED;

WITH RECURSIVE seq (n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 5
), totals AS (
  SELECT `status`, SUM(`total`) AS s FROM `orders` GROUP BY `status`
)
SELECT n, s, ROW_NUMBER() OVER (ORDER BY n) AS rn,
       SUM(s) OVER (PARTITION BY `status` ORDER BY n ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running,
       LAG(s, 1) OVER w AS prev, RANK() OVER w AS rk
FROM seq CROSS JOIN totals
WINDOW w AS (ORDER BY n);

SELECT * FROM `orders` WHERE `id` IN (SELECT `order_id` FROM `order_lines` WHERE `qty` > 1)
UNION DISTINCT SELECT * FROM `orders` WHERE EXISTS (SELECT 1 FROM `v_paid`);
SELECT j.* FROM JSON_TABLE('[{"a":1}]', '$[*]' COLUMNS (a INT PATH '$.a')) AS j;

EXPLAIN ANALYZE SELECT * FROM `orders` WHERE `number` = 1;
SHOW CREATE TABLE `orders`;
SHOW FULL COLUMNS FROM `orders` LIKE 'st%';
SHOW INDEX FROM `orders`;
SHOW VARIABLES LIKE 'innodb%';
DESCRIBE `orders`;

-- ── Routines, triggers, events ──
DELIMITER $$
CREATE DEFINER = `root`@`localhost` PROCEDURE `restock` (IN p_sku VARCHAR(32), INOUT p_qty INT, OUT p_ok TINYINT)
  READS SQL DATA
BEGIN
  DECLARE v_have INT DEFAULT 0;
  DECLARE done TINYINT DEFAULT FALSE;
  DECLARE cur CURSOR FOR SELECT `qty` FROM `order_lines` WHERE `sku` = p_sku;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 @msg = MESSAGE_TEXT;
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_have;
    IF done THEN LEAVE read_loop; END IF;
    IF v_have < 25 THEN
      SET p_qty = p_qty + 1;
    ELSEIF v_have > 100 THEN
      ITERATE read_loop;
    ELSE
      SET p_qty = p_qty;
    END IF;
  END LOOP;
  CLOSE cur;
  WHILE p_qty < 10 DO SET p_qty = p_qty + 1; END WHILE;
  REPEAT SET p_qty = p_qty - 1; UNTIL p_qty < 5 END REPEAT;
  CASE WHEN p_qty > 0 THEN SET p_ok = 1; ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'empty'; END CASE;
  COMMIT;
END$$

CREATE FUNCTION `gross` (p_net DECIMAL(10,2)) RETURNS DECIMAL(10,2) DETERMINISTIC NO SQL
  RETURN p_net * 1.20$$

CREATE TRIGGER `trg_orders_bi` BEFORE INSERT ON `orders` FOR EACH ROW
BEGIN
  SET NEW.`number` = IFNULL(NEW.`number`, 0);
END$$

CREATE EVENT `ev_purge` ON SCHEDULE EVERY 1 DAY STARTS '2025-01-01 03:00:00' DO
  DELETE FROM `orders` WHERE `status` = 'cancelled'$$
DELIMITER ;

CALL `restock`('A-100', @qty, @ok);
SELECT @qty, @ok;
PREPARE stmt FROM 'SELECT * FROM orders WHERE id = ?';
SET @id = 1;
EXECUTE stmt USING @id;
DEALLOCATE PREPARE stmt;

-- ── Admin and transactions ──
CREATE USER IF NOT EXISTS 'app'@'%' IDENTIFIED BY 'example-not-a-real-password';
GRANT SELECT, INSERT, UPDATE ON `warehouse`.* TO 'app'@'%';
REVOKE INSERT ON `warehouse`.* FROM 'app'@'%';
FLUSH PRIVILEGES;
LOCK TABLES `orders` WRITE, `order_lines` READ;
UNLOCK TABLES;
START TRANSACTION;
SAVEPOINT before_update;
ROLLBACK TO SAVEPOINT before_update;
COMMIT;
ANALYZE TABLE `orders`;
OPTIMIZE TABLE `orders`;

-- ── More statements and clauses ──
CREATE ROLE IF NOT EXISTS 'reader', 'writer';
GRANT 'reader' TO 'app'@'%';
GRANT SELECT ON `warehouse`.* TO 'reader' WITH GRANT OPTION;
ALTER USER 'app'@'%' IDENTIFIED BY 'example-not-a-real-password' PASSWORD EXPIRE INTERVAL 90 DAY;
SET PASSWORD FOR 'app'@'%' = 'example-not-a-real-password';
DROP USER IF EXISTS 'old'@'localhost';
ALTER TABLE `orders` ALGORITHM=INPLACE, LOCK=NONE, ADD INDEX `idx_total` (`total`) INVISIBLE;
ALTER TABLE `orders` RENAME COLUMN `note` TO `remark`, CHANGE COLUMN `tiny` `flag` TINYINT(1) NOT NULL, DROP INDEX `idx_total`, DISABLE KEYS;
ALTER TABLE `orders` ADD CONSTRAINT `chk_number` CHECK (`number` > 0) ENFORCED, ADD PARTITION (PARTITION p2025 VALUES LESS THAN (2026));
ALTER TABLE `orders` DROP FOREIGN KEY `fk_x`, DROP PRIMARY KEY, ADD PRIMARY KEY (`id`), AUTO_INCREMENT = 500, CONVERT TO CHARACTER SET utf8mb4;
CREATE TABLE `copy_of_orders` AS SELECT * FROM `orders` WHERE 1 = 0;
CREATE TABLE `hashed` (`id` INT, `h` BINARY(16), `d` DATE, `t` TIME(6), `y` YEAR, `bits` BIT(8), `ls` LONGTEXT, `vb` VARBINARY(10),
  `g` GEOMETRY, `ml` MULTIPOLYGON, `f` FLOAT(7,3), `dc` DEC(5,2), `nu` NUMERIC, `i24` MEDIUMINT, `ch` CHAR(3) BINARY, `bo` BOOL, `js` JSON)
  ENGINE=MEMORY PARTITION BY HASH(`id`) PARTITIONS 4;
CREATE SERVER s FOREIGN DATA WRAPPER mysql OPTIONS (HOST 'remote.example.com');
CREATE TABLESPACE ts ADD DATAFILE 'ts.ibd' ENGINE=InnoDB;
CREATE LOGFILE GROUP lg ADD UNDOFILE 'undo.dat' ENGINE=NDB;
CREATE SPATIAL REFERENCE SYSTEM 4326 NAME 'WGS 84' DEFINITION 'GEOGCS["x"]';
INSTALL PLUGIN validate_password SONAME 'validate_password.so';
UNINSTALL PLUGIN validate_password;
CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.0.2.10', SOURCE_PORT=3306, SOURCE_AUTO_POSITION=1;
START REPLICA;
STOP REPLICA;
SHOW REPLICA STATUS;
SHOW ENGINE INNODB STATUS;
SHOW PROCESSLIST;
SHOW DATABASES LIKE 'ware%';
SHOW TABLE STATUS FROM `warehouse`;
SHOW GRANTS FOR 'app'@'%';
SHOW WARNINGS;
SHOW ERRORS;
SHOW MASTER STATUS;
SHOW BINARY LOGS;
SHOW TRIGGERS;
SHOW PROCEDURE STATUS WHERE Db = 'warehouse';
SHOW CREATE VIEW `v_paid`;
KILL QUERY 1234;
HANDLER `orders` OPEN AS h;
HANDLER h READ FIRST LIMIT 1;
HANDLER h CLOSE;
XA START 'xid1';
XA END 'xid1';
XA PREPARE 'xid1';
XA COMMIT 'xid1';
BINLOG 'base64text';
CACHE INDEX `orders` IN hot_cache;
RESET MASTER;
CHECK TABLE `orders` FOR UPGRADE;
CHECKSUM TABLE `orders` EXTENDED;
REPAIR TABLE `orders` QUICK;
SELECT * INTO OUTFILE '/tmp/orders.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' FROM `orders`;
SELECT `id` INTO @first_id FROM `orders` LIMIT 1;
SELECT * FROM `orders` PROCEDURE ANALYSE();
TABLE `orders` ORDER BY `id` LIMIT 5;
VALUES ROW(1, 'a'), ROW(2, 'b');
(SELECT 1) INTERSECT (SELECT 1) EXCEPT (SELECT 2);
SELECT CAST('5' AS UNSIGNED), CAST(`meta` AS JSON), CONVERT('x' USING utf8mb4), CONVERT(5, CHAR), BINARY 'a', '1' + 1, 5 DIV 2, 5 MOD 2, 1 <=> NULL, !0, 5 XOR 1, ~0, 1 << 2, 8 >> 1, 6 & 3, 6 | 3, 6 ^ 3, `a` SOUNDS LIKE `b`;
SELECT * FROM `orders` o1 INNER JOIN `orders` o2 ON o1.id < o2.id STRAIGHT_JOIN `orders` o3 RIGHT OUTER JOIN `orders` o4 USING (`id`) NATURAL JOIN `v_paid`;
SELECT * FROM `orders` PARTITION (p2024) FORCE INDEX (`PRIMARY`) IGNORE INDEX (`uq_number`);
SELECT HIGH_PRIORITY DISTINCTROW SQL_NO_CACHE SQL_BUFFER_RESULT SQL_SMALL_RESULT * FROM `orders` LOCK IN SHARE MODE;
SELECT * FROM `orders` FOR SHARE NOWAIT;
SELECT EXISTS (SELECT 1 FROM `orders`) AS present, ANY_VALUE(`status`), BIT_COUNT(7), UUID(), UUID_SHORT(), RAND(), SLEEP(0), LAST_INSERT_ID(), ROW_COUNT(), VERSION(), DATABASE(), USER(), CURRENT_USER(), CONNECTION_ID();
SELECT JSON_ARRAYAGG(`id`), JSON_OBJECTAGG(`number`, `total`), JSON_SET(`meta`, '$.a', 1), JSON_INSERT(`meta`, '$.b', 2), JSON_REMOVE(`meta`, '$.a'), JSON_CONTAINS(`meta`, '1'), JSON_LENGTH(`meta`), JSON_VALID('{}'), JSON_TYPE(`meta`), JSON_SEARCH(`meta`, 'one', 'x'), JSON_MERGE_PATCH(`meta`, '{}'), JSON_PRETTY(`meta`), JSON_UNQUOTE(`meta`->'$.a') FROM `orders`;
SELECT ST_AsText(`loc`), ST_Distance_Sphere(`loc`, POINT(0, 0)), ST_GeomFromText('POINT(1 1)', 4326), MBRContains(`loc`, `loc`) FROM `orders`;
SELECT REGEXP_LIKE('abc', '^a'), REGEXP_REPLACE('abc', 'b', 'x'), REGEXP_SUBSTR('abc', 'b+'), REGEXP_INSTR('abc', 'c');
SELECT ROW_NUMBER() OVER (), DENSE_RANK() OVER (ORDER BY `id`), NTILE(4) OVER (ORDER BY `id`), FIRST_VALUE(`id`) OVER (ORDER BY `id` RANGE BETWEEN INTERVAL 1 DAY PRECEDING AND CURRENT ROW), CUME_DIST() OVER (), PERCENT_RANK() OVER () FROM `orders`;
SELECT * FROM `orders` WHERE `id` = ALL (SELECT `id` FROM `orders`) AND `id` <> SOME (SELECT 1) AND `number` NOT BETWEEN 1 AND 2 AND `note` RLIKE 'x' AND `id` IS UNKNOWN AND `number` IS NOT TRUE;
INSERT INTO `orders` (`number`) VALUES (9) AS new ON DUPLICATE KEY UPDATE `number` = new.`number`;
INSERT INTO `orders` (`number`, `total`) SELECT `number`, `total` FROM `orders` ON DUPLICATE KEY UPDATE `total` = `total` + 1;
DELETE o FROM `orders` o JOIN `order_lines` l ON l.order_id = o.id WHERE l.qty = 0;
DELETE FROM `orders` ORDER BY `id` LIMIT 1;
UPDATE LOW_PRIORITY IGNORE `orders` SET `total` = DEFAULT, `status` = 'paid' WHERE `id` = 1;
LOAD XML INFILE 'orders.xml' INTO TABLE `orders` ROWS IDENTIFIED BY '<order>';
DO SLEEP(0);
HELP 'contents';
USE `information_schema`;
SELECT * FROM `TABLES` WHERE `TABLE_SCHEMA` = 'warehouse';
SELECT * FROM `performance_schema`.`threads` LIMIT 1;
SET @@GLOBAL.innodb_buffer_pool_size = 134217728, @@SESSION.sql_log_bin = 0, @@persist.max_connections = 300;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED, READ WRITE;
SET NAMES 'utf8mb4';
SET CHARACTER SET utf8mb4;
SET RESOURCE GROUP rg FOR 1;
CREATE RESOURCE GROUP rg TYPE = USER VCPU = 0-1 THREAD_PRIORITY = 5;
CREATE FUNCTION udf RETURNS STRING SONAME 'udf.so';
CREATE AGGREGATE FUNCTION agg RETURNS REAL SONAME 'agg.so';
DROP FUNCTION IF EXISTS udf;
DROP PROCEDURE IF EXISTS `restock`;
DROP TRIGGER IF EXISTS `trg_orders_bi`;
DROP EVENT IF EXISTS `ev_purge`;
DROP VIEW IF EXISTS `v_paid`;
DROP INDEX `uq_note` ON `orders`;
DROP DATABASE IF EXISTS `scratch`;
