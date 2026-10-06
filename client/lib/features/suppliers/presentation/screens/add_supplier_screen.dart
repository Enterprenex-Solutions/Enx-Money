import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/indian_locations.dart';
import '../../data/suppliers_repository.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final SuppliersRepository _repository = SuppliersRepository();

  // Basic Details
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();

  // Address Hierarchy: Country -> State -> District -> Mandal/City -> Pincode -> AddressLine
  String _selectedCountry = IndianLocations.defaultCountry;
  String? _selectedState = 'Telangana';
  String? _selectedDistrict = 'Hyderabad';
  final _mandalCityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _landmarkController = TextEditingController();

  // Financials & Terms
  final _openingBalanceController = TextEditingController(text: '');
  String _category = 'RAW_MATERIALS';
  String _paymentTerms = 'Net 30 Days';
  DateTime? _dueDate;
  bool _dueReminderEnabled = false;
  DateTime? _reminderDate;
  final _notesController = TextEditingController();

  bool _isLoading = false;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  final List<String> _categories = [
    'RAW_MATERIALS',
    'WHOLESALE',
    'MANUFACTURING',
    'PACKAGING',
    'HARDWARE',
    'FABRICS',
    'SERVICES',
    'GENERAL',
  ];

  final List<String> _paymentTermOptions = [
    'Due on Receipt',
    'Net 15 Days',
    'Net 30 Days',
    'Net 45 Days',
    'Net 60 Days',
    'Custom Due Date',
  ];

  @override
  void initState() {
    super.initState();
    _applyPaymentTerms(_paymentTerms);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _mandalCityController.dispose();
    _pincodeController.dispose();
    _addressLineController.dispose();
    _landmarkController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPaymentTerms(String terms) {
    final now = DateTime.now();
    setState(() {
      _paymentTerms = terms;
      if (terms == 'Due on Receipt') {
        _dueDate = now;
      } else if (terms == 'Net 15 Days') {
        _dueDate = now.add(const Duration(days: 15));
      } else if (terms == 'Net 30 Days') {
        _dueDate = now.add(const Duration(days: 30));
      } else if (terms == 'Net 45 Days') {
        _dueDate = now.add(const Duration(days: 45));
      } else if (terms == 'Net 60 Days') {
        _dueDate = now.add(const Duration(days: 60));
      } else if (terms == 'Custom Due Date') {
        _dueDate ??= now.add(const Duration(days: 30));
      }
      if (_dueReminderEnabled && _dueDate != null) {
        _reminderDate = _dueDate!.subtract(const Duration(days: 3));
      }
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        if (_dueReminderEnabled) {
          _reminderDate = picked.subtract(const Duration(days: 3));
        }
      });
    }
  }

  Future<void> _selectReminderDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? (_dueDate != null ? _dueDate!.subtract(const Duration(days: 3)) : DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: _dueDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

  void _submitSupplier() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final openingPayable = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;

      final body = {
        'name': _nameController.text.trim(),
        'companyName': _companyController.text.trim(),
        'contactNumber': _phoneController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gstin': _gstinController.text.trim().toUpperCase(),
        // Address Hierarchy
        'country': _selectedCountry,
        'countryCode': 'IN',
        'state': _selectedState ?? '',
        'district': _selectedDistrict ?? '',
        'city': _mandalCityController.text.trim(),
        'mandal': _mandalCityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'addressLine': _addressLineController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        // Financials & Payment Terms
        'category': _category,
        'openingBalance': openingPayable,
        'outstandingPayable': openingPayable,
        'paymentTerms': _paymentTerms,
        'dueDate': _dueDate?.toIso8601String().split('T')[0],
        'dueReminderEnabled': _dueReminderEnabled,
        'reminderDate': _reminderDate?.toIso8601String().split('T')[0],
        'notes': _notesController.text.trim(),
      };

      await _repository.createSupplier(body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Supplier "${_nameController.text.trim()}" saved successfully!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color inputTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final Color cursorColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
    final Color iconColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
    final Color fieldFill = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final Color screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final Color titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final TextStyle inputTextStyle = AppTypography.bodyMedium.copyWith(color: inputTextColor);

    InputDecoration decoration({
      required String label,
      String? hint,
      Widget? prefix,
      Widget? suffix,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: fieldFill,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          fontSize: 13,
        ),
        floatingLabelStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
    }

    Widget buildSectionHeader(String title, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    final List<String> availableDistricts = _selectedState != null && IndianLocations.stateDistricts.containsKey(_selectedState)
        ? IndianLocations.stateDistricts[_selectedState]!
        : [];

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        backgroundColor: screenBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: titleColor),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Add New Supplier / Vendor',
          style: AppTypography.titleLarge.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // ── 1. BASIC DETAILS SECTION ─────────────────────────────
              buildSectionHeader('BASIC SUPPLIER IDENTITY', Icons.badge_rounded),

              // Supplier Name
              TextFormField(
                controller: _nameController,
                style: inputTextStyle,
                cursorColor: cursorColor,
                decoration: decoration(
                  label: 'SUPPLIER / VENDOR NAME *',
                  hint: 'e.g. Krishna Textiles Pvt Ltd',
                  prefix: Icon(Icons.storefront_rounded, color: iconColor, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter supplier name';
                  }
                  if (val.trim().length < 2) {
                    return 'Supplier name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Company Name & Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _companyController,
                      style: inputTextStyle,
                      cursorColor: cursorColor,
                      decoration: decoration(
                        label: 'COMPANY / FIRM NAME',
                        hint: 'e.g. Krishna Hub LLP',
                        prefix: Icon(Icons.business_rounded, color: iconColor, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: cardBg,
                      style: inputTextStyle,
                      decoration: decoration(label: 'CATEGORY'),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: inputTextStyle),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Mobile Phone & Email Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: inputTextStyle,
                      cursorColor: cursorColor,
                      decoration: decoration(
                        label: 'MOBILE NUMBER *',
                        hint: '10 digits',
                        prefix: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          child: Text(
                            '+91',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter 10-digit mobile number';
                        }
                        final clean = val.trim();
                        if (clean.length != 10) {
                          return 'Must be exactly 10 digits';
                        }
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                          return 'Must start with 6, 7, 8, or 9';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: inputTextStyle,
                      cursorColor: cursorColor,
                      decoration: decoration(
                        label: 'EMAIL ADDRESS',
                        hint: 'sales@vendor.com',
                        prefix: Icon(Icons.email_outlined, color: iconColor, size: 20),
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                            return 'Invalid email address';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // GSTIN Field with Validation
              TextFormField(
                controller: _gstinController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                style: inputTextStyle.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
                cursorColor: cursorColor,
                decoration: decoration(
                  label: 'GSTIN (15-DIGIT TAX ID)',
                  hint: 'e.g. 24AAACK1234F1Z5',
                  prefix: Icon(Icons.receipt_long_rounded, color: iconColor, size: 20),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final clean = val.trim().toUpperCase();
                    if (clean.length != 15) {
                      return 'GSTIN must be exactly 15 alphanumeric characters';
                    }
                    final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                    if (!gstinRegex.hasMatch(clean)) {
                      return 'Invalid GSTIN format (e.g. 24AAACK1234F1Z5)';
                    }
                  }
                  return null;
                },
              ),

              // ── 2. STRUCTURED ADDRESS HIERARCHY ──────────────────────
              buildSectionHeader('LOCATION & STRUCTURED ADDRESS', Icons.location_on_rounded),

              // Country & State Dropdown Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      dropdownColor: cardBg,
                      style: inputTextStyle,
                      decoration: decoration(label: 'COUNTRY'),
                      items: IndianLocations.countries.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: inputTextStyle));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCountry = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedState,
                      dropdownColor: cardBg,
                      style: inputTextStyle,
                      decoration: decoration(label: 'STATE / UT *'),
                      items: IndianLocations.stateDistricts.keys.map((st) {
                        return DropdownMenuItem(value: st, child: Text(st, style: inputTextStyle, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedState = val;
                            final dList = IndianLocations.stateDistricts[val];
                            _selectedDistrict = (dList != null && dList.isNotEmpty) ? dList.first : null;
                          });
                        }
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Select state' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // District Dropdown & Mandal/City Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: availableDistricts.contains(_selectedDistrict) ? _selectedDistrict : (availableDistricts.isNotEmpty ? availableDistricts.first : null),
                      dropdownColor: cardBg,
                      style: inputTextStyle,
                      decoration: decoration(label: 'DISTRICT *'),
                      items: availableDistricts.map((dist) {
                        return DropdownMenuItem(value: dist, child: Text(dist, style: inputTextStyle, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDistrict = val);
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Select district' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _mandalCityController,
                      style: inputTextStyle,
                      cursorColor: cursorColor,
                      decoration: decoration(
                        label: 'MANDAL / CITY / TOWN',
                        hint: 'e.g. Surat / Abids',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pincode & Landmark Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: inputTextStyle,
                      cursorColor: cursorColor,
                      decoration: decoration(
                        label: 'PINCODE',
                        hint: '6 digits',
                        prefix: Icon(Icons.pin_drop_outlined, color: iconColor, size: 20),
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(val.trim())) {
                            return 'Valid 6-digit PIN';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _landmarkController,
                      style: inputTextStyle,
                      cursorColor: cursorColor,
                      decoration: decoration(
                        label: 'LANDMARK',
                        hint: 'e.g. Near SBI Main Branch',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Street Address Line
              TextFormField(
                controller: _addressLineController,
                style: inputTextStyle,
                cursorColor: cursorColor,
                decoration: decoration(
                  label: 'STREET ADDRESS / BUILDING / SHOP NO.',
                  hint: 'e.g. Plot 45, Textile Park Phase 2',
                  prefix: Icon(Icons.home_work_outlined, color: iconColor, size: 20),
                ),
              ),

              // ── 3. FINANCIALS & PAYMENT TERMS ────────────────────────
              buildSectionHeader('PAYMENT TERMS & OPENING PAYABLE', Icons.account_balance_wallet_rounded),

              // Opening Payable Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C151B) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isDark ? const Color(0xFF881337) : const Color(0xFFFECDD3),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'OPENING PAYABLE (YOU OWE THIS VENDOR)',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _openingBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: inputTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFEF4444),
                      ),
                      cursorColor: cursorColor,
                      decoration: decoration(
                        label: 'AMOUNT TO PAY (₹)',
                        hint: '0.00',
                        prefix: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entering an amount here will automatically initialize your outstanding payable and update your liabilities in Dashboard and Analytics.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Payment Terms Dropdown
              DropdownButtonFormField<String>(
                value: _paymentTerms,
                dropdownColor: cardBg,
                style: inputTextStyle,
                decoration: decoration(
                  label: 'PAYMENT TERMS CREDIT CYCLE',
                  prefix: Icon(Icons.event_repeat_rounded, color: iconColor, size: 20),
                ),
                items: _paymentTermOptions.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt, style: inputTextStyle));
                }).toList(),
                onChanged: (val) {
                  if (val != null) _applyPaymentTerms(val);
                },
              ),

              const SizedBox(height: 12),

              // Payment Due Date Selector
              InkWell(
                onTap: () => _selectDueDate(context),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: fieldFill,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAYMENT DUE DATE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dueDate != null ? _dateFormat.format(_dueDate!) : 'Select Due Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: inputTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_calendar_rounded, size: 18, color: iconColor),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Due Payment Reminder Toggle
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  side: BorderSide(color: borderColor),
                ),
                tileColor: fieldFill,
                title: Text(
                  'Set Payment Due Reminder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: inputTextColor,
                  ),
                ),
                subtitle: Text(
                  _dueReminderEnabled && _reminderDate != null
                      ? 'Reminder scheduled for: ${_dateFormat.format(_reminderDate!)}'
                      : 'Notify business owner before payment becomes overdue',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                value: _dueReminderEnabled,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  setState(() {
                    _dueReminderEnabled = val;
                    if (val && _dueDate != null) {
                      _reminderDate = _dueDate!.subtract(const Duration(days: 3));
                    }
                  });
                },
              ),

              if (_dueReminderEnabled) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectReminderDate(context),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Reminder Date: ${_reminderDate != null ? _dateFormat.format(_reminderDate!) : "Select date"}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF38BDF8)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Notes / Terms
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: inputTextStyle,
                cursorColor: cursorColor,
                decoration: decoration(
                  label: 'ADDITIONAL NOTES / BILLING INSTRUCTIONS',
                  hint: 'e.g. Bank details, credit agreement, or delivery instructions',
                  prefix: Icon(Icons.note_alt_outlined, color: iconColor, size: 20),
                ),
              ),

              const SizedBox(height: 28),

              // ── 4. SUBMIT BUTTON ─────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isLoading ? null : _submitSupplier,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Supplier',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
