-- ================================================================
-- ENX Money Database Schema v2.0
-- Database: MySQL 8.0+
-- Run: node database/migrate.js
-- ================================================================

-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS `enx_money_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `enx_money_db`;

-- ================================================================
-- Table: users
-- ================================================================
CREATE TABLE IF NOT EXISTS `users` (
  `id`            VARCHAR(36)   NOT NULL,
  `name`          VARCHAR(150)  NOT NULL,
  `email`         VARCHAR(255)  NOT NULL UNIQUE,
  `password_hash` VARCHAR(255)  NOT NULL,
  `role`          ENUM('admin', 'user') NOT NULL DEFAULT 'user',
  `created_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX idx_users_email (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================
-- Table: enterprises
-- ================================================================
CREATE TABLE IF NOT EXISTS `enterprises` (
  `id`           VARCHAR(36)   NOT NULL,
  `company_name` VARCHAR(200)  NOT NULL,
  `gstin`        VARCHAR(15)   NOT NULL,
  `email`        VARCHAR(255)  DEFAULT NULL,
  `phone`        VARCHAR(20)   DEFAULT NULL,
  `address`      TEXT          DEFAULT NULL,
  `user_id`      VARCHAR(36)   NOT NULL,
  `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX idx_enterprises_user_id (`user_id`),
  CONSTRAINT fk_enterprises_user FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================
-- Table: customers
-- ================================================================
CREATE TABLE IF NOT EXISTS `customers` (
  `id`                  VARCHAR(36)     NOT NULL,
  `name`                VARCHAR(200)    NOT NULL,
  `company_name`        VARCHAR(200)    DEFAULT NULL,
  `phone`               VARCHAR(20)     DEFAULT NULL,
  `email`               VARCHAR(255)    DEFAULT NULL,
  `address`             TEXT            DEFAULT NULL,
  `total_invoiced`      DECIMAL(15,2)   NOT NULL DEFAULT 0.00,
  `outstanding_balance` DECIMAL(15,2)   NOT NULL DEFAULT 0.00,
  `user_id`             VARCHAR(36)     NOT NULL,
  `created_at`          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX idx_customers_user_id (`user_id`),
  CONSTRAINT fk_customers_user FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================
-- Table: suppliers
-- ================================================================
CREATE TABLE IF NOT EXISTS `suppliers` (
  `id`                 VARCHAR(36)     NOT NULL,
  `name`               VARCHAR(200)    NOT NULL,
  `company_name`       VARCHAR(200)    DEFAULT NULL,
  `category`           VARCHAR(100)    NOT NULL DEFAULT 'General Vendor',
  `phone`              VARCHAR(20)     DEFAULT NULL,
  `email`              VARCHAR(255)    DEFAULT NULL,
  `address`            TEXT            DEFAULT NULL,
  `total_billed`       DECIMAL(15,2)   NOT NULL DEFAULT 0.00,
  `outstanding_payable` DECIMAL(15,2)  NOT NULL DEFAULT 0.00,
  `user_id`            VARCHAR(36)     NOT NULL,
  `created_at`         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX idx_suppliers_user_id (`user_id`),
  CONSTRAINT fk_suppliers_user FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================
-- Table: transactions
-- ================================================================
CREATE TABLE IF NOT EXISTS `transactions` (
  `id`             VARCHAR(36)      NOT NULL,
  `title`          VARCHAR(300)     NOT NULL,
  `amount`         DECIMAL(15,2)    NOT NULL,
  `type`           ENUM('revenue', 'expense', 'receivable', 'payable', 'emi') NOT NULL,
  `profile_type`   ENUM('business', 'personal')                               NOT NULL DEFAULT 'business',
  `category`       VARCHAR(100)     NOT NULL,
  `date`           DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `payment_mode`   ENUM('cash', 'upi', 'bankTransfer', 'creditCard', 'cheque') NOT NULL DEFAULT 'bankTransfer',
  `notes`          TEXT             DEFAULT NULL,
  `gst_rate`       DECIMAL(5,2)     NOT NULL DEFAULT 0.00,
  `invoice_number` VARCHAR(100)     DEFAULT NULL,
  `is_cleared`     TINYINT(1)       NOT NULL DEFAULT 1,
  `enterprise_id`  VARCHAR(36)      DEFAULT NULL,
  `customer_id`    VARCHAR(36)      DEFAULT NULL,
  `supplier_id`    VARCHAR(36)      DEFAULT NULL,
  `user_id`        VARCHAR(36)      NOT NULL,
  `created_at`     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX idx_tx_user_id    (`user_id`),
  INDEX idx_tx_date       (`date`),
  INDEX idx_tx_type       (`type`),
  INDEX idx_tx_profile    (`profile_type`),
  INDEX idx_tx_customer   (`customer_id`),
  INDEX idx_tx_supplier   (`supplier_id`),
  INDEX idx_tx_enterprise (`enterprise_id`),
  CONSTRAINT fk_tx_user       FOREIGN KEY (`user_id`)       REFERENCES `users`(`id`)       ON DELETE CASCADE,
  CONSTRAINT fk_tx_enterprise FOREIGN KEY (`enterprise_id`) REFERENCES `enterprises`(`id`) ON DELETE SET NULL,
  CONSTRAINT fk_tx_customer   FOREIGN KEY (`customer_id`)   REFERENCES `customers`(`id`)   ON DELETE SET NULL,
  CONSTRAINT fk_tx_supplier   FOREIGN KEY (`supplier_id`)   REFERENCES `suppliers`(`id`)   ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
