const express = require('express');
const AdminController = require('../controllers/admin.controller');
const { authenticateToken, requireAdmin } = require('../middleware/auth.middleware');

const router = express.Router();

// Allow direct admin portal login
router.post('/login', AdminController.adminLogin);

// Allow authenticated users to submit ratings
router.post('/ratings', authenticateToken, AdminController.submitRating);

// Apply strict admin authorization to all remaining routes
router.use(authenticateToken, requireAdmin);

// Dashboard Overview
router.get('/analytics', AdminController.getAnalytics);

// User Metrics & Directory
router.get('/users/count', AdminController.getUserCounts);
router.get('/users/active', AdminController.getActiveUsers);
router.get('/users/new', AdminController.getNewUsers);
router.get('/users', AdminController.getUsers);
router.get('/users/:id/activity', AdminController.getUserActivity);
router.put('/users/:id/role', AdminController.updateUserRole);

// Download Analytics
router.get('/downloads', AdminController.getDownloads);

// Rating & Review Analytics
router.get('/ratings', AdminController.getRatings);
router.get('/reviews', AdminController.getReviews);

module.exports = router;
