import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/profile/models/user_profile_model.dart';

void main() {
  group('Profile Progress Engine - 60/30/10 Architecture Tests', () {
    test('Empty profile has 0% completion and identifies all missing fields', () {
      const empty = UserProfileModel(
        fullName: '',
        mobileNumber: '',
        email: '',
        profilePhoto: '',
        dateOfBirth: '',
        gender: '',
        addressState: '',
        addressCity: '',
        addressPincode: '',
        selectedLanguage: '',
        appLockPin: '',
        isBiometricEnabled: false,
        hasPasswordSet: false,
        hasSecurityQuestions: false,
        businessProfile: BusinessProfileModel(
          businessName: '',
          businessType: '',
          businessCategory: '',
          businessAddress: '',
          businessContactNumber: '',
          businessLogo: '',
          businessEmail: '',
        ),
      );

      expect(empty.personalScore, 0);
      expect(empty.businessScore, 0);
      expect(empty.securityScore, 0);
      expect(empty.completionPercentage, 0);
      expect(empty.isPersonalComplete, false);
      expect(empty.isBusinessComplete, false);
      expect(empty.isSecurityComplete, false);
      expect(empty.missingPersonalFields.length, 8);
    });

    test('Personal profile gives exact 60% when all 8 personal fields are provided', () {
      const personalOnly = UserProfileModel(
        fullName: 'Rahul Sharma',
        mobileNumber: '+919876543210',
        email: 'rahul@enx.com',
        profilePhoto: 'https://avatar.com/1.png',
        dateOfBirth: '15/08/1995',
        gender: 'Male',
        addressState: 'Andhra Pradesh',
        addressDistrict: 'Nellore',
        addressCity: 'Kavali',
        addressPincode: '524201',
        selectedLanguage: 'English',
        appLockPin: '',
        isBiometricEnabled: false,
        hasPasswordSet: false,
        hasSecurityQuestions: false,
        businessProfile: BusinessProfileModel(),
      );

      expect(personalOnly.personalScore, 60);
      expect(personalOnly.businessScore, 0);
      expect(personalOnly.securityScore, 0);
      expect(personalOnly.completionPercentage, 60);
      expect(personalOnly.isPersonalComplete, true);
    });

    test('Security settings give exact 10% when all 4 security fields are active', () {
      const securityOnly = UserProfileModel(
        fullName: '',
        mobileNumber: '',
        email: '',
        profilePhoto: '',
        dateOfBirth: '',
        gender: '',
        addressState: '',
        addressCity: '',
        addressPincode: '',
        selectedLanguage: '',
        appLockPin: '1234',
        isBiometricEnabled: true,
        hasPasswordSet: true,
        hasSecurityQuestions: true,
        businessProfile: BusinessProfileModel(),
      );

      expect(securityOnly.personalScore, 0);
      expect(securityOnly.businessScore, 0);
      expect(securityOnly.securityScore, 10);
      expect(securityOnly.completionPercentage, 10);
      expect(securityOnly.isSecurityComplete, true);
    });

    test('Header Display Rule: Personal (60%) + Security (10%) + Partial Business Name (5%) = exactly 75%', () {
      const userAt75 = UserProfileModel(
        fullName: 'Krishna Vamsi',
        mobileNumber: '+919988776655',
        email: 'krishna@enterprenex.com',
        profilePhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        dateOfBirth: '20/05/1996',
        gender: 'Male',
        addressState: 'Telangana',
        addressDistrict: 'Hyderabad',
        addressCity: 'Madhapur',
        addressPincode: '500081',
        selectedLanguage: 'Telugu (తెలుగు)',
        // Security complete (10%)
        appLockPin: '8899',
        isBiometricEnabled: true,
        hasPasswordSet: true,
        hasSecurityQuestions: true,
        // Partial business info (5% for business name)
        businessProfile: BusinessProfileModel(
          businessName: 'Enterprenex Tech Pvt Ltd',
          businessType: '',
          businessCategory: '',
          businessAddress: '',
          businessContactNumber: '',
          businessLogo: '',
          businessEmail: '',
        ),
      );

      expect(userAt75.personalScore, 60);
      expect(userAt75.securityScore, 10);
      expect(userAt75.businessScore, 5);
      expect(userAt75.completionPercentage, 75);
    });

    test('Full profile achieves 100% without any Aadhaar or PAN KYC documents', () {
      const fullProfile = UserProfileModel(
        fullName: 'Krishna Vamsi',
        mobileNumber: '+919988776655',
        email: 'krishna@enterprenex.com',
        profilePhoto: 'https://avatar.com/krishna.png',
        dateOfBirth: '20/05/1996',
        gender: 'Male',
        addressState: 'Telangana',
        addressDistrict: 'Hyderabad',
        addressCity: 'Madhapur',
        addressPincode: '500081',
        selectedLanguage: 'English (US)',
        // Security 10%
        appLockPin: '8899',
        isBiometricEnabled: true,
        hasPasswordSet: true,
        hasSecurityQuestions: true,
        // Business 30%
        businessProfile: BusinessProfileModel(
          businessName: 'Enterprenex Solutions Pvt Ltd',
          businessType: 'Private Limited',
          businessCategory: 'IT & Software',
          businessAddress: 'Floor 4, Cyber Gateway, Hitec City',
          businessContactNumber: '9988776655',
          businessLogo: 'https://logo.com/enx.png',
          businessEmail: 'contact@enterprenex.com',
        ),
      );

      expect(fullProfile.personalScore, 60);
      expect(fullProfile.businessScore, 30);
      expect(fullProfile.securityScore, 10);
      expect(fullProfile.completionPercentage, 100);
      expect(fullProfile.isPersonalComplete, true);
      expect(fullProfile.isBusinessComplete, true);
      expect(fullProfile.isSecurityComplete, true);
      expect(fullProfile.missingPersonalFields, isEmpty);
      expect(fullProfile.missingBusinessFields, isEmpty);
      expect(fullProfile.missingSecurityFields, isEmpty);
    });
  });
}
