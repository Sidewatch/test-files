-- MySQL dialect: engine and charset clauses, backtick quoting, ON DUPLICATE KEY, a JSON column.
-- This file DETECTS AS SQL — pick MySQL from the language picker to see the dialect's keywords.
CREATE TABLE IF NOT EXISTS `orders` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `number` INT NOT NULL,
  `total` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('pending','paid','cancelled') NOT NULL DEFAULT 'pending',
  `meta` JSON NULL,
  `placed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_number` (`number`),
  KEY `idx_status_placed` (`status`, `placed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `orders` (`number`, `total`, `status`, `meta`)
VALUES (1, 120.50, 'paid', JSON_OBJECT('gift', TRUE))
ON DUPLICATE KEY UPDATE `total` = VALUES(`total`);

SELECT `status`, COUNT(*) AS n, SUM(`total`) AS revenue,
       JSON_EXTRACT(`meta`, '$.gift') AS gift
FROM `orders`
WHERE `placed_at` >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY `status` WITH ROLLUP
LIMIT 10;
