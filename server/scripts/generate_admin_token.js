/**
 * ENX Money — Executive Admin Token Generator
 * Utility script to generate a signed Admin JWT token for dashboard access.
 *
 * Usage:
 *   node scripts/generate_admin_token.js [email]
 *
 * Example:
 *   node scripts/generate_admin_token.js anjalidhere539@gmail.com
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const TokenService = require('../src/services/token.service');
const UserModel = require('../src/models/user.model');
const { initDb } = require('../src/config/db.config');

async function main() {
  const email = (process.argv[2] || process.env.ADMIN_EMAIL?.split(',')[0] || 'admin@enxmoney.com').trim().toLowerCase();
  console.log(`\n=============================================================`);
  console.log(` ENX Money — Executive Admin Token Generator`);
  console.log(`=============================================================`);
  console.log(` Target Admin Email : ${email}`);

  await initDb();

  // Try to find or create user in the database/resilience store
  let user = await UserModel.findByEmail(email);
  if (!user) {
    console.log(`\n Account not found in active database. Creating admin account...`);
    user = await UserModel.create({
      name: 'ENX Executive Admin',
      email,
      password: 'AdminSecurePassword2026!',
      role: 'admin',
      businessName: 'ENX Money Corporate',
    });
  }

  // Ensure role is elevated
  await UserModel.setUserRole(user.id, 'admin');
  user.role = 'admin';

  const token = TokenService.signAccessToken({
    id: user.id,
    email: user.email,
    name: user.name || 'ENX Executive Admin',
    role: 'admin',
    status: 'ACTIVE',
  });

  console.log(`\n Role Verification   : ADMIN`);
  console.log(` Access Token        :`);
  console.log(`\n${token}\n`);
  console.log(`-------------------------------------------------------------`);
  console.log(` Dashboard Access Instructions:`);
  console.log(` 1. Open your browser:`);
  console.log(`    Local      -> http://localhost:5000/admin`);
  console.log(`    Production -> https://enx-money-api.onrender.com/admin`);
  console.log(` 2. Paste the token above into the "Or Direct Admin JWT Token" box.`);
  console.log(` 3. Click "Authenticate" to instantly unlock the Admin Dashboard.`);
  console.log(`=============================================================\n`);
}

main().catch(err => {
  console.error('\n Error generating token:', err.message);
  process.exit(1);
});
