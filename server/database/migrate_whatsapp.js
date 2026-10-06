/**
 * WhatsApp Database Migration Runner
 * Run: node database/migrate_whatsapp.js
 * Safely creates WhatsApp integration tables.
 */

const mysql = require('mysql2/promise');
const config = require('../config/env');

const WHATSAPP_SCHEMA = `
-- Table: whatsapp_users
CREATE TABLE IF NOT EXISTS \`whatsapp_users\` (
  \`id\`                   VARCHAR(36)   NOT NULL,
  \`phone_number\`         VARCHAR(30)   NOT NULL UNIQUE,
  \`user_id\`              VARCHAR(36)   DEFAULT NULL,
  \`verification_status\`  ENUM('unregistered', 'pending', 'verified', 'blocked') NOT NULL DEFAULT 'unregistered',
  \`otp_code\`             VARCHAR(10)   DEFAULT NULL,
  \`otp_expires_at\`       DATETIME      DEFAULT NULL,
  \`pin_hash\`             VARCHAR(255)  DEFAULT NULL,
  \`language\`             VARCHAR(10)   NOT NULL DEFAULT 'en',
  \`daily_summary_enabled\` TINYINT(1)   NOT NULL DEFAULT 1,
  \`last_active_at\`       DATETIME      DEFAULT NULL,
  \`created_at\`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  \`updated_at\`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (\`id\`),
  INDEX idx_wa_phone (\`phone_number\`),
  INDEX idx_wa_user_id (\`user_id\`),
  CONSTRAINT fk_wa_users_user FOREIGN KEY (\`user_id\`) REFERENCES \`users\`(\`id\`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: whatsapp_sessions
CREATE TABLE IF NOT EXISTS \`whatsapp_sessions\` (
  \`id\`                  VARCHAR(36)   NOT NULL,
  \`phone_number\`        VARCHAR(30)   NOT NULL UNIQUE,
  \`user_id\`             VARCHAR(36)   DEFAULT NULL,
  \`state\`               VARCHAR(50)   NOT NULL DEFAULT 'IDLE',
  \`context_data\`        JSON          DEFAULT NULL,
  \`last_intent\`         VARCHAR(100)  DEFAULT NULL,
  \`last_interaction_at\` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  \`expires_at\`          DATETIME      DEFAULT NULL,
  PRIMARY KEY (\`id\`),
  INDEX idx_wa_session_phone (\`phone_number\`),
  INDEX idx_wa_session_user (\`user_id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: whatsapp_messages
CREATE TABLE IF NOT EXISTS \`whatsapp_messages\` (
  \`id\`           VARCHAR(36)   NOT NULL,
  \`phone_number\` VARCHAR(30)   NOT NULL,
  \`user_id\`      VARCHAR(36)   DEFAULT NULL,
  \`direction\`    ENUM('inbound', 'outbound') NOT NULL,
  \`message_type\` VARCHAR(30)   NOT NULL DEFAULT 'text',
  \`body\`         TEXT          NOT NULL,
  \`intent\`       VARCHAR(100)  DEFAULT NULL,
  \`tool_calls\`   JSON          DEFAULT NULL,
  \`ai_provider\`  VARCHAR(50)   DEFAULT 'gemini',
  \`status\`       ENUM('received', 'sent', 'delivered', 'read', 'failed') NOT NULL DEFAULT 'sent',
  \`raw_payload\`  JSON          DEFAULT NULL,
  \`created_at\`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (\`id\`),
  INDEX idx_wa_msg_phone (\`phone_number\`),
  INDEX idx_wa_msg_created (\`created_at\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: whatsapp_reminders
CREATE TABLE IF NOT EXISTS \`whatsapp_reminders\` (
  \`id\`              VARCHAR(36)   NOT NULL,
  \`user_id\`         VARCHAR(36)   NOT NULL,
  \`recipient_phone\` VARCHAR(30)   NOT NULL,
  \`entity_type\`     ENUM('customer', 'supplier', 'enterprise', 'self') NOT NULL,
  \`entity_id\`       VARCHAR(36)   DEFAULT NULL,
  \`entity_name\`     VARCHAR(200)  NOT NULL,
  \`reminder_type\`   ENUM('receivable_overdue', 'payable_due', 'emi_due', 'daily_digest', 'custom') NOT NULL,
  \`title\`           VARCHAR(300)  NOT NULL,
  \`amount\`          DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  \`due_date\`        DATETIME      DEFAULT NULL,
  \`status\`          ENUM('pending', 'sent', 'cancelled', 'failed') NOT NULL DEFAULT 'pending',
  \`scheduled_at\`    DATETIME      NOT NULL,
  \`sent_at\`         DATETIME      DEFAULT NULL,
  \`created_at\`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (\`id\`),
  INDEX idx_wa_rem_user (\`user_id\`),
  INDEX idx_wa_rem_status (\`status\`),
  INDEX idx_wa_rem_sched (\`scheduled_at\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: whatsapp_handoff_tokens
CREATE TABLE IF NOT EXISTS \`whatsapp_handoff_tokens\` (
  \`id\`            VARCHAR(36)   NOT NULL,
  \`token\`         VARCHAR(128)  NOT NULL UNIQUE,
  \`user_id\`       VARCHAR(36)   NOT NULL,
  \`phone_number\`  VARCHAR(30)   NOT NULL,
  \`target_screen\` VARCHAR(100)  NOT NULL DEFAULT 'dashboard',
  \`action_type\`   VARCHAR(100)  NOT NULL DEFAULT 'view_report',
  \`payload\`       JSON          DEFAULT NULL,
  \`is_used\`       TINYINT(1)    NOT NULL DEFAULT 0,
  \`expires_at\`    DATETIME      NOT NULL,
  \`created_at\`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (\`id\`),
  INDEX idx_wa_handoff_token (\`token\`),
  INDEX idx_wa_handoff_expires (\`expires_at\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

async function migrateWhatsApp() {
  let connection;
  try {
    console.log('🔄 Running WhatsApp Chatbot schema migration...');
    connection = await mysql.createConnection({
      host: config.db.host,
      port: config.db.port,
      user: config.db.user,
      password: config.db.password,
      database: config.db.database,
      multipleStatements: true,
    });

    await connection.query(WHATSAPP_SCHEMA);
    console.log('✅ WhatsApp Chatbot tables created successfully!');
    console.log('   ✔ Table: whatsapp_users');
    console.log('   ✔ Table: whatsapp_sessions');
    console.log('   ✔ Table: whatsapp_messages');
    console.log('   ✔ Table: whatsapp_reminders');
    console.log('   ✔ Table: whatsapp_handoff_tokens');
  } catch (err) {
    console.error('❌ WhatsApp Migration failed:', err.message);
  } finally {
    if (connection) await connection.end();
  }
}

if (require.main === module) {
  migrateWhatsApp();
}

module.exports = { migrateWhatsApp };
