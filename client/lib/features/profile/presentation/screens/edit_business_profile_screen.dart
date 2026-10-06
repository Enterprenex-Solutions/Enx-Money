import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_image_util.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/profile_repository.dart';
import '../../models/user_profile_model.dart';

class EditBusinessProfileScreen extends StatefulWidget {
  const EditBusinessProfileScreen({super.key});

  @override
  State<EditBusinessProfileScreen> createState() => _EditBusinessProfileScreenState();
}

class _EditBusinessProfileScreenState extends State<EditBusinessProfileScreen> {
  final ProfileRepository _repo = ProfileRepository();

  late TextEditingController _businessNameController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _gstinController;
  late TextEditingController _addressController;

  late String _selectedBusinessType;
  late String _selectedBusinessSize;
  late String _selectedCategory;
  late String _businessLogo;
  late bool _hasGst;
  bool _isLoading = false;

  String? _businessNameError;
  String? _contactError;
  String? _emailError;
  String? _gstinError;
  String? _addressError;

  final List<String> _businessLogoPresets = const [
    'https://images.unsplash.com/photo-1516876437184-593fda40c7ce?w=150',
    'https://images.unsplash.com/photo-1556742049-0a67c5574f73?w=150',
    'https://images.unsplash.com/photo-1572021335469-31706a17aaef?w=150',
    'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=150',
  ];

  final List<String> _businessTypes = const [
    'Retailer',
    'Wholesaler',
    'Freelancer',
    'Service Business',
    'Manufacturer',
    'Distributor',
    'Other',
  ];

  final List<String> _businessSizes = const [
    'Freelancer',
    'Small Business',
    'Mid-Level Business',
    'Large Business',
  ];

  final List<String> _categories = const [
    'Financial Technology & Services',
    'IT, Software & Web Development',
    'Retail & E-commerce',
    'Wholesale Trading & Distribution',
    'Manufacturing & Industrial',
    'Food, Beverage & Restaurants',
    'Healthcare, Pharma & Clinics',
    'Logistics, Transport & Supply Chain',
    'Consulting & Professional Services',
    'Real Estate & Construction',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final business = _repo.profile.businessProfile;
    _businessNameController = TextEditingController(text: business.businessName);
    _contactController = TextEditingController(text: business.businessContactNumber);
    _emailController = TextEditingController(text: business.businessEmail);
    _gstinController = TextEditingController(text: business.gstin ?? '');
    _addressController = TextEditingController(text: business.businessAddress);
    _businessLogo = business.businessLogo;

    _selectedBusinessType = _businessTypes.contains(business.businessType)
        ? business.businessType
        : _businessTypes[3];

    _selectedBusinessSize = _businessSizes.contains(business.businessSize)
        ? business.businessSize
        : _businessSizes[1];

    _selectedCategory = _categories.contains(business.businessCategory)
        ? business.businessCategory
        : _categories[0];

    _hasGst = business.hasGst;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _businessNameError = null;
      _contactError = null;
      _emailError = null;
      _gstinError = null;
      _addressError = null;

      final bName = _businessNameController.text.trim();
      final contact = _contactController.text.trim();
      final email = _emailController.text.trim();
      final addr = _addressController.text.trim();

      if (bName.isEmpty) {
        _businessNameError = 'Business name is required';
        valid = false;
      }

      if (contact.isNotEmpty && contact.length < 10) {
        _contactError = 'Please enter a valid 10-digit contact number';
        valid = false;
      }

      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(email)) {
          _emailError = 'Please enter a valid business email address';
          valid = false;
        }
      }

      if (_hasGst) {
        final gstin = _gstinController.text.trim().toUpperCase();
        if (gstin.isEmpty) {
          _gstinError = 'GSTIN is mandatory when GST is Yes';
          valid = false;
        } else if (gstin.length != 15) {
          _gstinError = 'GSTIN must be exactly 15 alphanumeric characters';
          valid = false;
        } else {
          final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
          if (!gstRegex.hasMatch(gstin)) {
            _gstinError = 'Invalid GSTIN format (e.g. 22AAAAA0000A1Z5)';
            valid = false;
          }
        }
      }

      if (addr.isEmpty) {
        _addressError = 'Business address is required for invoicing';
        valid = false;
      }
    });
    return valid;
  }

  void _showLogoSelectorModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final customUrlController = TextEditingController(
          text: _businessLogo.startsWith('http') ? _businessLogo : '',
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
                  'Business Logo',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload your brand logo from files, Google Drive, camera, or choose a logo preset.',
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
                              setState(() => _businessLogo = image.path);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Business logo selected from files/drive!'),
                                  backgroundColor: Color(0xFF00E676),
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
                            color: const Color(0xFF00E676).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.folder_open_rounded, color: Color(0xFF00E676), size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Files / Drive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF00E676),
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
                              setState(() => _businessLogo = photo.path);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Camera logo captured!'),
                                  backgroundColor: Color(0xFF00E676),
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

                // Brand Presets
                Text(
                  'OR CHOOSE FROM BRAND PRESETS',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 1.1,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _businessLogoPresets.map((preset) {
                    final isSelected = _businessLogo == preset;
                    return InkWell(
                      onTap: () {
                        setState(() => _businessLogo = preset);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00E676) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          backgroundImage: NetworkImage(preset),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Custom URL Input
                Text(
                  'OR ENTER LOGO URL',
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
                        controller: customUrlController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                        cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        decoration: InputDecoration(
                          hintText: 'https://example.com/logo.png',
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
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final val = customUrlController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() => _businessLogo = val);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                if (_businessLogo.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _businessLogo = '');
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      label: const Text('Remove Logo', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
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

  Future<void> _onSave() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    final updatedBusiness = BusinessProfileModel(
      businessName: _businessNameController.text.trim(),
      businessType: _selectedBusinessType,
      businessSize: _selectedBusinessSize,
      businessCategory: _selectedCategory,
      hasGst: _hasGst,
      gstin: _hasGst ? _gstinController.text.trim().toUpperCase() : null,
      businessAddress: _addressController.text.trim(),
      businessContactNumber: _contactController.text.trim(),
      businessEmail: _emailController.text.trim().toLowerCase(),
      businessLogo: _businessLogo,
    );

    await _repo.updateBusinessProfile(updatedBusiness);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Business profile updated successfully!'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      );
      Navigator.pop(context);
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
          'Business Profile',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Logo Card
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                        image: _businessLogo.isNotEmpty && getAppImageProvider(_businessLogo) != null
                            ? DecorationImage(
                                image: getAppImageProvider(_businessLogo)!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _businessLogo.isEmpty || getAppImageProvider(_businessLogo) == null
                          ? Center(
                              child: Icon(
                                Icons.store_mall_directory_rounded,
                                size: 40,
                                color: AppColors.primaryGreen.withValues(alpha: 0.8),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showLogoSelectorModal,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showLogoSelectorModal,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColors.primaryGreen),
                  label: Text(
                    _businessLogo.isNotEmpty ? 'Change Business Logo' : 'Add Business Logo',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'COMPANY & BUSINESS OVERVIEW',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              // Business Name
              FintechTextField(
                label: 'Registered Business Name *',
                hintText: 'e.g. Enterprenex Solutions Pvt Ltd',
                prefixIcon: const Icon(Icons.store_mall_directory_outlined, color: AppColors.primaryGreen, size: 20),
                controller: _businessNameController,
                errorText: _businessNameError,
                onChanged: (_) {
                  if (_businessNameError != null) setState(() => _businessNameError = null);
                },
              ),
              const SizedBox(height: 16),

              // Business Contact Number
              FintechTextField(
                label: 'Business Contact Number',
                hintText: 'e.g. 9876543210',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryGreen, size: 20),
                controller: _contactController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                errorText: _contactError,
                onChanged: (_) {
                  if (_contactError != null) setState(() => _contactError = null);
                },
              ),
              const SizedBox(height: 16),

              // Business Email (Optional)
              FintechTextField(
                label: 'Business Email (Optional)',
                hintText: 'e.g. contact@business.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primaryGreen, size: 20),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: 18),

              // Business Category Dropdown
              Text(
                'BUSINESS CATEGORY / INDUSTRY',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Business Type
              Text(
                'BUSINESS TYPE',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _businessTypes.map((type) {
                  final isSelected = _selectedBusinessType == type;
                  return ChoiceChip(
                    label: Text(
                      type,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? Colors.black : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryGreen : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedBusinessType = type);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Business Size
              Text(
                'BUSINESS SIZE / SCALE',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _businessSizes.map((size) {
                  final isSelected = _selectedBusinessSize == size;
                  return ChoiceChip(
                    label: Text(
                      size,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? Colors.black : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryGreen : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedBusinessSize = size);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // GST Registration Question (Yes / No)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: _hasGst
                        ? AppColors.primaryGreen.withValues(alpha: 0.4)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Do you have a GST Number? (Optional)',
                                style: AppTypography.titleSmall.copyWith(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hasGst
                                    ? 'Provide GSTIN for automated GST tax invoicing'
                                    : 'Marked as Not Applicable (Optional for non-registered businesses)',
                                style: AppTypography.bodySmall.copyWith(
                                  color: _hasGst ? AppColors.primaryGreen : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildGstToggleOption('Yes', true, isDark),
                            const SizedBox(width: 8),
                            _buildGstToggleOption('No', false, isDark),
                          ],
                        ),
                      ],
                    ),

                    // Animated GSTIN Input field if Yes
                    if (_hasGst) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      FintechTextField(
                        label: 'GSTIN (15-Digit GST Number) *',
                        hintText: 'e.g. 22AAAAA0000A1Z5',
                        prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen, size: 20),
                        controller: _gstinController,
                        maxLength: 15,
                        errorText: _gstinError,
                        onChanged: (_) {
                          if (_gstinError != null) setState(() => _gstinError = null);
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Business Address
              Text(
                'BUSINESS LOCATION & ADDRESS',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              FintechTextField(
                label: 'Registered Office / Store Address',
                hintText: 'e.g. Floor 4, Cyber Gateway, Hitec City, Hyderabad - 500081',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primaryGreen, size: 20),
                controller: _addressController,
                errorText: _addressError,
                onChanged: (_) {
                  if (_addressError != null) setState(() => _addressError = null);
                },
              ),

              const SizedBox(height: 36),

              PrimaryButton(
                text: 'Save Business Profile',
                isLoading: _isLoading,
                onPressed: _onSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGstToggleOption(String label, bool value, bool isDark) {
    final isSelected = _hasGst == value;
    return InkWell(
      onTap: () {
        setState(() {
          _hasGst = value;
          if (!value) {
            _gstinController.clear();
            _gstinError = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : (isDark ? const Color(0xFF141824) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : (isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.black : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
