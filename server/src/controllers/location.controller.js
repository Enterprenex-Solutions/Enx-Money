const LocationService = require('../services/location.service');

class LocationController {
  static getCountries(req, res) {
    try {
      const countries = LocationService.getCountries();
      return res.status(200).json({ success: true, data: countries });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static getStates(req, res) {
    try {
      const country = req.query.country || 'IN';
      const states = LocationService.getStates(country);
      return res.status(200).json({ success: true, data: states });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static getDistricts(req, res) {
    try {
      const { country = 'IN', state } = req.query;
      if (!state) {
        return res.status(400).json({ success: false, message: 'State parameter is required.' });
      }
      const districts = LocationService.getDistricts(state, country);
      return res.status(200).json({ success: true, data: districts });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static getPincodes(req, res) {
    try {
      const { country = 'IN', state, district, query } = req.query;
      if (!district) {
        return res.status(400).json({ success: false, message: 'District parameter is required.' });
      }
      const pincodes = LocationService.getPincodes({
        stateName: state,
        districtName: district,
        countryCode: country,
        query,
      });
      return res.status(200).json({ success: true, data: pincodes });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static lookupPincode(req, res) {
    try {
      const { pincode } = req.query;
      if (!pincode) {
        return res.status(400).json({ success: false, message: 'Pincode parameter is required.' });
      }
      const result = LocationService.lookupPincode(pincode);
      if (!result.valid) {
        return res.status(400).json({ success: false, message: result.message });
      }
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static validateHierarchy(req, res) {
    try {
      const result = LocationService.validateLocationHierarchy(req.body);
      if (!result.valid) {
        return res.status(400).json({ success: false, message: result.message });
      }
      return res.status(200).json({ success: true, message: 'Location hierarchy is valid.' });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async reverseGeocode(req, res) {
    try {
      const latitude = req.body.latitude !== undefined ? req.body.latitude : req.query.latitude;
      const longitude = req.body.longitude !== undefined ? req.body.longitude : req.query.longitude;

      if (latitude === undefined || longitude === undefined) {
        return res.status(400).json({
          success: false,
          message: 'Both latitude and longitude are required for reverse geocoding.',
        });
      }

      const locationData = await LocationService.reverseGeocode({ latitude, longitude });
      return res.status(200).json({
        success: true,
        data: locationData,
      });
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: error.message || 'Failed to reverse geocode coordinates.',
      });
    }
  }
}

module.exports = LocationController;
