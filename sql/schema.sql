CREATE TABLE IF NOT EXISTS `crime_laptop_profiles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(60) NOT NULL UNIQUE,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `crypto` INT DEFAULT 0,
    `jobs_completed` INT DEFAULT 0,
    `items_sold` INT DEFAULT 0,
    `total_earned` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crime_laptop_listings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `seller_license` VARCHAR(60) NOT NULL,
    `seller_username` VARCHAR(50) NOT NULL,
    `item_name` VARCHAR(50) NOT NULL,
    `item_label` VARCHAR(100) NOT NULL,
    `amount` INT NOT NULL DEFAULT 1,
    `price` INT NOT NULL,
    `status` ENUM('pending', 'active', 'sold', 'cancelled') DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_seller` (`seller_license`),
    INDEX `idx_item` (`item_name`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crime_laptop_crypto_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(60) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    `amount` INT NOT NULL,
    `description` VARCHAR(255) DEFAULT '',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
