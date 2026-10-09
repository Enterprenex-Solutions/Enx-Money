import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_image_util.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/profile_repository.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final ProfileRepository _repo = ProfileRepository();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _mandalCityController;
  late TextEditingController _pincodeController;

  late String _selectedGender;
  late String _selectedLanguage;
  late String _profilePhoto;

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  String? _nameError;
  String? _emailError;
  String? _mobileError;

  final List<String> _genders = const [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> _languages = const [
    'English (US)',
    'Hindi (हिंदी)',
    'Telugu (తెలుగు)',
    'Tamil (தமிழ்)',
    'Kannada (ಕನ್ನಡ)',
    'Marathi (मराठी)',
    'Gujarati (ગુજરાતી)',
    'Bengali (বাংলা)',
  ];

  final List<String> _avatarPresets = const [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
  ];

  @override
  void initState() {
    super.initState();
    final profile = _repo.profile;
    _nameController = TextEditingController(text: profile.fullName);
    _emailController = TextEditingController(text: profile.email);
    _mobileController = TextEditingController(text: profile.mobileNumber);
    _dobController = TextEditingController(text: profile.dateOfBirth);
    _stateController = TextEditingController(text: profile.addressState);
    _districtController = TextEditingController(text: profile.addressDistrict);
    _mandalCityController = TextEditingController(text: profile.addressCity);
    _pincodeController = TextEditingController(text: profile.addressPincode);

    _selectedGender = _genders.contains(profile.gender) ? profile.gender : _genders[0];
    _selectedLanguage = _languages.any((l) => l.startsWith(profile.selectedLanguage.split(' ').first))
        ? _languages.firstWhere((l) => l.startsWith(profile.selectedLanguage.split(' ').first))
        : _languages[0];
    _profilePhoto = profile.profilePhoto;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _mandalCityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initial = DateTime(1998, 1, 1);
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateFormat('dd/MM/yyyy').parse(_dobController.text);
      } catch (_) {
        try {
          initial = DateTime.parse(_dobController.text);
        } catch (_) {}
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: AppColors.surfaceElevated,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _fetchLiveLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location Services on your device.')),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission was denied.')),
            );
          }
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is permanently denied. Please allow it in app settings.')),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      // Query OpenStreetMap Nominatim for Reverse Geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'ENXMoneyApp/1.0 (support@enterprenex.com)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final state = address['state'] as String? ?? '';
        final district = address['state_district'] as String? ?? address['county'] as String? ?? '';
        final mandalCity = address['city'] as String? ??
            address['town'] as String? ??
            address['suburb'] as String? ??
            address['village'] as String? ??
            '';
        final pincode = address['postcode'] as String? ?? '';

        setState(() {
          if (state.isNotEmpty) _stateController.text = state;
          if (district.isNotEmpty) _districtController.text = district;
          if (mandalCity.isNotEmpty) _mandalCityController.text = mandalCity;
          if (pincode.isNotEmpty) _pincodeController.text = pincode;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Text(
                'Live Location Detected: ${mandalCity.isNotEmpty ? "$mandalCity, " : ""}$state',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to reverse geocode');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not auto-fetch address: $e. You can type it manually.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final urlController = TextEditingController(
          text: _profilePhoto.startsWith('http') ? _profilePhoto : '',
        );
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile Photo',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload your photo from device files, Google Drive, camera, or choose a preset avatar.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons: Files/Drive & Camera
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1000,
                              maxHeight: 1000,
                              imageQuality: 88,
                            );
                            if (image != null && mounted) {
                              setState(() => _profilePhoto = image.path);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile photo selected from files/drive!'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not open file picker: $e')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.folder_open_rounded, color: AppColors.brandBlue, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Files / Drive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.brandBlue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            final picker = ImagePicker();
                            final XFile? photo = await picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 1000,
                              maxHeight: 1000,
                              imageQuality: 88,
                            );
                            if (photo != null && mounted) {
                              setState(() => _profilePhoto = photo.path);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Camera photo captured!'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Camera error: $e')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Avatar Presets
                Text(
                  'OR SELECT AVATAR PRESET',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 1.1,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _profilePhoto = '');
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(35),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          border: Border.all(
                            color: _profilePhoto.isEmpty ? AppColors.brandBlue : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.person_outline_rounded, size: 26, color: AppColors.brandBlue),
                      ),
                    ),
                    ..._avatarPresets.map((url) {
                      final isSelected = _profilePhoto == url;
                      return InkWell(
                        onTap: () {
                          setState(() => _profilePhoto = url);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(35),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.brandBlue : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2.5 : 1,
                            ),
                            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // Custom URL Option
                Text(
                  'OR ENTER IMAGE URL',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 1.1,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                        cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        decoration: InputDecoration(
                          hintText: 'https://example.com/photo.jpg',
                          hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final val = urlController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() => _profilePhoto = val);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                if (_profilePhoto.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _profilePhoto = '');
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      label: const Text('Remove Photo', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _mobileError = null;

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final mobile = _mobileController.text.trim();

      if (name.isEmpty) {
        _nameError = 'Full name is required';
        valid = false;
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
        valid = false;
      }

      if (email.isEmpty) {
        _emailError = 'Email is required';
        valid = false;
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Please enter a valid email address';
        valid = false;
      }

      if (mobile.isEmpty) {
        _mobileError = 'Mobile number is required';
        valid = false;
      }
    });
    return valid;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      await _repo.updatePersonalInfo(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        profilePhoto: _profilePhoto,
        dateOfBirth: _dobController.text.trim(),
        gender: _selectedGender,
        addressState: _stateController.text.trim(),
        addressDistrict: _districtController.text.trim(),
        addressCity: _mandalCityController.text.trim(),
        addressPincode: _pincodeController.text.trim(),
        preferredLanguage: _selectedLanguage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Personal Profile updated successfully!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update personal profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        centerTitle: true,
        title: Text(
          'Personal Profile',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Photo / Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceElevated,
                        border: Border.all(color: AppColors.primaryGreen, width: 2),
                        image: _profilePhoto.isNotEmpty && getAppImageProvider(_profilePhoto) != null
                            ? DecorationImage(
                                image: getAppImageProvider(_profilePhoto)!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profilePhoto.isEmpty || getAppImageProvider(_profilePhoto) == null
                          ? Center(
                              child: Text(
                                _repo.profile.initials,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showAvatarPicker,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              FintechTextField(
                label: 'Full Name *',
                hint: 'e.g. Rahul Sharma',
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
                errorText: _nameError,
              ),
              const SizedBox(height: 16),

              // Mobile Number
              FintechTextField(
                label: 'Mobile Number *',
                hint: '+91 98765 43210',
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                errorText: _mobileError,
              ),
              const SizedBox(height: 16),

              // Email Address
              FintechTextField(
                label: 'Email Address *',
                hint: 'name@business.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                errorText: _emailError,
              ),
              const SizedBox(height: 16),

              // Date of Birth & Gender Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDateOfBirth,
                      child: IgnorePointer(
                        child: FintechTextField(
                          label: 'Date of Birth',
                          hint: 'DD/MM/YYYY',
                          controller: _dobController,
                          prefixIcon: Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender Selector
              Text(
                'GENDER',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _genders.map((gender) {
                  final isSelected = _selectedGender == gender;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(gender),
                      selected: isSelected,
                      selectedColor: AppColors.primaryGreen,
                      backgroundColor: isDark ? const Color(0xFF141824) : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : (isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1)),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedGender = gender);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Address with Live Location Option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADDRESS & LOCATION',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      letterSpacing: 1.1,
                    ),
                  ),
                  InkWell(
                    onTap: _isFetchingLocation ? null : _fetchLiveLocation,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isFetchingLocation)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                            )
                          else
                            const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          const Text(
                            'Use Live Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // State & District Row
              Row(
                children: [
                  Expanded(
                    child: FintechTextField(
                      label: 'State',
                      hint: 'e.g. Andhra Pradesh',
                      controller: _stateController,
                      prefixIcon: Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FintechTextField(
                      label: 'District',
                      hint: 'e.g. SPSR Nellore',
                      controller: _districtController,
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mandal/City & Pincode Row
              Row(
                children: [
                  Expanded(
                    child: FintechTextField(
                      label: 'Mandal / City',
                      hint: 'e.g. Kavali / Hyderabad',
                      controller: _mandalCityController,
                      prefixIcon: Icons.home_work_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FintechTextField(
                      label: 'Pincode',
                      hint: 'e.g. 524201',
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.pin_drop_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preferred Language
              Text(
                'PREFERRED LANGUAGE',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isDark ? AppColors.border : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
                    items: _languages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(
                          lang,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              PrimaryButton(
                text: 'Save Personal Profile',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
