/**
 * ZeroCarbonix EWMS — Main Server Entry Point
 */

const { createApp } = require('./app');
const config = require('./config');

const app = createApp();

const server = app.listen(config.PORT, () => {
  console.log(`[ZeroCarbonix EWMS] Modular Monolith API running on port ${config.PORT}`);
  console.log(`[ZeroCarbonix EWMS] Health endpoint: http://localhost:${config.PORT}/api/v1/health`);
});

module.exports = server;
