/**
 * Database Migration Runner
 * Run: node database/migrate.js
 * Reads schema.sql and executes it against MySQL to create tables.
 */

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const config = require('../config/env');

async function migrate() {
  let connection;

  try {
    console.log('🔄 Starting database migration...');
    console.log(`📡 Connecting to MySQL at ${config.db.host}:${config.db.port}...`);

    // Connect without specifying the database first (to allow DB creation)
    connection = await mysql.createConnection({
      host: config.db.host,
      port: config.db.port,
      user: config.db.user,
      password: config.db.password,
      multipleStatements: true,
    });

    console.log('✅ Connected to MySQL server.');

    // Read the schema SQL file
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');

    // Execute the schema (creates database and all tables)
    console.log('📋 Executing schema.sql...');
    await connection.query(schemaSql);

    console.log('');
    console.log('✅ Migration completed successfully!');
    console.log('   ✔ Database:    enx_money_db');
    console.log('   ✔ Table:       users');
    console.log('   ✔ Table:       enterprises');
    console.log('   ✔ Table:       customers');
    console.log('   ✔ Table:       suppliers');
    console.log('   ✔ Table:       transactions');
    console.log('');
    console.log('💡 Next steps:');
    console.log('   npm run db:seed    → Populate with sample data');
    console.log('   npm run dev        → Start the development server');
    console.log('');

  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    if (err.code === 'ECONNREFUSED') {
      console.error('   Make sure MySQL is running on', config.db.host + ':' + config.db.port);
    }
    process.exit(1);
  } finally {
    if (connection) await connection.end();
  }
}

migrate();
