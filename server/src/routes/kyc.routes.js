const express = require('express');
const KycController = require('../controllers/kyc.controller');

const router = express.Router();

// 1. Start authorized DigiLocker / API Setu KYC session
router.post('/start', KycController.startKyc);

// 2. Official DigiLocker OAuth 2.0 Browser Redirect & Callback & Sandbox Hosted Flow
router.get('/digilocker/sandbox', KycController.renderDigilockerSandbox);
router.get('/digilocker/callback', KycController.digilockerCallback);
router.post('/digilocker/callback', KycController.digilockerCallback);

// 3. Current KYC Status
router.get('/status', KycController.getKycStatus);

// 4. Authorized Aadhaar OKYC Endpoints
router.post('/aadhaar/start', KycController.initiateAadhaar);
router.post('/aadhaar/send-otp', KycController.initiateAadhaar); // Alias for compatibility
router.post('/aadhaar/verify', KycController.verifyAadhaar);
router.post('/aadhaar/verify-otp', KycController.verifyAadhaar); // Alias for compatibility

// 5. Authorized PAN Verification Endpoint
router.post('/pan/verify', KycController.verifyPan);

// 6. Verified Documents List
router.get('/documents', KycController.getDocuments);

// 7. Free & Fast Route (Manual KYC for Launch)
router.post('/submit-manual', KycController.submitManualKyc);

// 8. Admin KYC Review & Verification Desk
router.get('/admin/requests', KycController.getAdminManualRequests);
router.post('/admin/approve', KycController.adminApproveManualKyc);
router.post('/admin/reject', KycController.adminRejectManualKyc);
router.post('/admin/auto-approve-all', KycController.adminAutoApproveAll);

module.exports = router;
