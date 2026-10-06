const express = require('express');
const BankController = require('../controllers/bank.controller');

const router = express.Router();

// 1-Step Backend Launch: Initiates Setu AA consent and returns redirectUrl
router.post('/initiate-consent', BankController.initiateConsent);

// Complete Setu AA consent and link account
router.post('/complete-consent', BankController.completeConsent);

// Automated Setu AA Pre-built Webview SDK Simulator
router.get('/setu-webview', BankController.renderSetuWebview);

// Real SMS OTP generation via Setu AA / SMS Gateway
router.post('/send-otp', BankController.sendOtp);

// Strict OTP submission & bank account verification
router.post('/verify-otp', BankController.verifyOtp);

module.exports = router;
