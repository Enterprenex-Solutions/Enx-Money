const express = require('express');
const LocationController = require('../controllers/location.controller');

const router = express.Router();

router.get('/countries', LocationController.getCountries);
router.get('/states', LocationController.getStates);
router.get('/districts', LocationController.getDistricts);
router.get('/pincodes', LocationController.getPincodes);
router.get('/lookup-pincode', LocationController.lookupPincode);
router.post('/validate', LocationController.validateHierarchy);
router.post('/reverse-geocode', LocationController.reverseGeocode);
router.get('/reverse-geocode', LocationController.reverseGeocode);

module.exports = router;
