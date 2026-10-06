import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/indian_locations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/customers_repository.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _repository = CustomersRepository();

  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _mandalController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstinController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');
  final _creditLimitController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  // Cascading Location Hierarchy State
  String _selectedCountry = IndianLocations.defaultCountry;
  String? _selectedState = 'Telangana';
  String? _selectedDistrict = 'Hyderabad';

  String _category = 'REGULAR';
  String _openingBalanceType = 'GAVE'; // GAVE (Customer owes you), GOT (You owe customer)
  bool _blockOnCreditBreach = true;
  bool _isLoading = false;

  String? _nameError;
  String? _phoneError;
  bool _isLocating = false;
  double? _currentLat;
  double? _currentLng;

  Future<void> _getCurrentLocationAndFill() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location services on your device.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required to detect current address.')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is permanently denied. Please enable in device settings.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // Reverse geocode via server-side protected endpoint
      final response = await ApiClient.instance.post(
        ApiConfig.reverseGeocode,
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          if (data['country'] != null && data['country'].toString().isNotEmpty) {
            _selectedCountry = data['country'].toString();
          }
          if (data['state'] != null && data['state'].toString().isNotEmpty) {
            _selectedState = data['state'].toString();
          }
          if (data['district'] != null && data['district'].toString().isNotEmpty) {
            _selectedDistrict = data['district'].toString();
          }
          if (data['mandal'] != null && data['mandal'].toString().isNotEmpty) {
            _mandalController.text = data['mandal'].toString();
          }
          if (data['pincode'] != null && data['pincode'].toString().isNotEmpty) {
            _pincodeController.text = data['pincode'].toString();
          }
          if (data['formattedAddress'] != null &&
              data['formattedAddress'].toString().isNotEmpty &&
              _addressController.text.isEmpty) {
            _addressController.text = data['formattedAddress'].toString();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              content: Text(
                'Location detected: ${_selectedDistrict ?? ''}, ${_selectedState ?? ''} (${_pincodeController.text})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch address from GPS: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _mandalController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _openingBalanceController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Customer name is required';
        valid = false;
      } else {
        _nameError = null;
      }

      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _phoneError = 'Phone number is required';
        valid = false;
      } else if (phone.length < 10) {
        _phoneError = 'Enter a valid 10-digit phone number';
        valid = false;
      } else {
        _phoneError = null;
      }
    });
    return valid;
  }

  void _submit() async {
    if (!_validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final rawOpening = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;
    final openingBalance = _openingBalanceType == 'GAVE' ? rawOpening.abs() : -rawOpening.abs();
    final creditLimit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;

    try {
      await _repository.createCustomer({
        'name': _nameController.text.trim(),
        'companyName': _companyController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'addressLine': _addressController.text.trim(),
        'country': _selectedCountry,
        'countryCode': _selectedCountry == 'India' ? 'IN' : 'US',
        'state': _selectedState ?? '',
        'district': _selectedDistrict ?? '',
        'city': _selectedDistrict ?? '',
        'mandal': _mandalController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'latitude': _currentLat,
        'longitude': _currentLng,
        'gstin': _gstinController.text.trim(),
        'category': _category,
        'openingBalance': openingBalance,
        'creditLimit': creditLimit,
        'blockOnCreditBreach': _blockOnCreditBreach,
        'notes': _notesController.text.trim(),
      });

      DataSyncService().notifyDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00E676),
            content: Text(
              'Customer added successfully!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  void _showStateSelector(BuildContext context, bool isDark) {
    final states = IndianLocations.states;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = states
                .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select State / Union Territory (India)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Search state...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E676)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1B2030) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setModalState(() => query = val),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        final isSelected = s == _selectedState;
                        return ListTile(
                          title: Text(
                            s,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00E676) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)) : null,
                          onTap: () {
                            setState(() {
                              _selectedState = s;
                              // Automatic reset of dependent district, mandal, pincode on state change
                              _selectedDistrict = null;
                              _mandalController.clear();
                              _pincodeController.clear();
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDistrictSelector(BuildContext context, bool isDark) {
    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.amber,
          content: Text('Please select a State first.', style: TextStyle(color: Colors.black)),
        ),
      );
      return;
    }

    final districts = IndianLocations.getDistricts(_selectedState);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = districts
                .where((d) => d.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select District for $_selectedState',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Search district...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E676)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1B2030) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setModalState(() => query = val),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final d = filtered[index];
                        final isSelected = d == _selectedDistrict;
                        return ListTile(
                          title: Text(
                            d,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00E676) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)) : null,
                          onTap: () {
                            setState(() {
                              _selectedDistrict = d;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0.5,
        title: Text(
          'Add New Customer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Basic Info Section
            _buildSectionHeader('BASIC INFORMATION', Icons.person_outline_rounded),
            const SizedBox(height: 12),
            FintechTextField(
              controller: _nameController,
              label: 'CUSTOMER FULL NAME *',
              hint: 'e.g. Kishore Kumar',
              prefixIcon: Icons.badge_outlined,
              errorText: _nameError,
            ),
            const SizedBox(height: 14),
            FintechTextField(
              controller: _phoneController,
              label: 'MOBILE NUMBER *',
              hint: 'e.g. 9876543210',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              errorText: _phoneError,
            ),
            const SizedBox(height: 14),
            FintechTextField(
              controller: _companyController,
              label: 'COMPANY / SHOP NAME (OPTIONAL)',
              hint: 'e.g. Kishore Enterprises',
              prefixIcon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 14),
            FintechTextField(
              controller: _emailController,
              label: 'EMAIL ADDRESS (OPTIONAL)',
              hint: 'e.g. kishore@enterprises.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),

            // 2. Business Category & GSTIN
            _buildSectionHeader('CATEGORY & TAX DETAILS', Icons.business_outlined),
            const SizedBox(height: 12),
            _buildCategoryDropdown(cardBg, borderColor, textColor),
            const SizedBox(height: 14),
            FintechTextField(
              controller: _gstinController,
              label: 'GSTIN (OPTIONAL)',
              hint: 'e.g. 36AABCU9603R1ZM',
              prefixIcon: Icons.receipt_long_outlined,
            ),

            const SizedBox(height: 24),

            // 3. Location Hierarchy (Country -> State -> District -> Mandal -> Pincode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSectionHeader(
                  'LOCATION & ADMINISTRATIVE ADDRESS',
                  Icons.location_on_outlined,
                  isExpanded: true,
                ),
                InkWell(
                  key: const Key('use_current_location_btn'),
                  onTap: _isLocating ? null : _getCurrentLocationAndFill,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLocating)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                          )
                        else
                          const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primaryGreen),
                        const SizedBox(width: 5),
                        Text(
                          _isLocating ? 'Detecting...' : 'Use Current Location',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Country Selector
            _buildCountrySelector(cardBg, borderColor, textColor),
            const SizedBox(height: 14),

            // Cascading State & District Selectors
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showStateSelector(context, isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STATE (36 STATES / UTS) *', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedState ?? 'Select State',
                                  style: TextStyle(
                                    color: _selectedState != null ? textColor : Colors.grey,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF00E676)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _showDistrictSelector(context, isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DISTRICT (FILTERED) *', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDistrict ?? 'Select District',
                                  style: TextStyle(
                                    color: _selectedDistrict != null ? textColor : Colors.grey,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF00E676)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mandal & Pincode
            Row(
              children: [
                Expanded(
                  child: FintechTextField(
                    controller: _mandalController,
                    label: 'MANDAL / TEHSIL / AREA',
                    hint: 'e.g. Secunderabad',
                    prefixIcon: Icons.holiday_village_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FintechTextField(
                    controller: _pincodeController,
                    label: 'PINCODE (6 DIGITS)',
                    hint: 'e.g. 500003',
                    prefixIcon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Street / Full Address
            FintechTextField(
              controller: _addressController,
              label: 'BILLING / STREET ADDRESS (OPTIONAL)',
              hint: 'e.g. Shop 14, Main Market, MG Road',
              prefixIcon: Icons.home_work_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // 4. Opening Balance & Credit Limits
            _buildSectionHeader('KHATA OPENING BALANCE & CREDIT LIMIT', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FintechTextField(
                    controller: _openingBalanceController,
                    label: 'OPENING BALANCE (₹)',
                    hint: '0',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildOpeningBalanceTypeToggle(cardBg, borderColor),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FintechTextField(
              controller: _creditLimitController,
              label: 'CREDIT LIMIT (₹ - 0 FOR UNLIMITED)',
              hint: 'e.g. 50000',
              prefixIcon: Icons.speed_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _buildCreditBreachSwitch(cardBg, borderColor, textColor),

            const SizedBox(height: 24),

            // 5. Notes
            _buildSectionHeader('INTERNAL NOTES', Icons.note_alt_outlined),
            const SizedBox(height: 12),
            FintechTextField(
              controller: _notesController,
              label: 'NOTES (PRIVATE TO YOU)',
              hint: 'e.g. Settles bills every Friday via UPI',
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            PrimaryButton(
              text: 'Save & Create Customer',
              isLoading: _isLoading,
              onPressed: _submit,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    bool isExpanded = false,
  }) {
    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF00A86B),
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );

    if (isExpanded) {
      return Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00A86B), size: 14),
              const SizedBox(width: 4),
              Expanded(child: titleWidget),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00A86B), size: 14),
        const SizedBox(width: 6),
        Expanded(child: titleWidget),
      ],
    );
  }

  Widget _buildCountrySelector(Color cardBg, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          dropdownColor: cardBg,
          isExpanded: true,
          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.public_rounded, color: Color(0xFF00E676)),
          items: IndianLocations.countries.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCountry = val;
                // Auto-reset state and district on country change
                _selectedState = val == 'India' ? 'Telangana' : null;
                _selectedDistrict = val == 'India' ? 'Hyderabad' : null;
                _mandalController.clear();
                _pincodeController.clear();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Color cardBg, Color borderColor, Color textColor) {
    const categories = ['REGULAR', 'WHOLESALE', 'RETAIL', 'VIP'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          dropdownColor: cardBg,
          isExpanded: true,
          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          items: categories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _category = val);
          },
        ),
      ),
    );
  }

  Widget _buildOpeningBalanceTypeToggle(Color cardBg, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _openingBalanceType = 'GAVE'),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _openingBalanceType == 'GAVE'
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  "You'll Get",
                  style: TextStyle(
                    color: _openingBalanceType == 'GAVE' ? const Color(0xFF00E676) : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _openingBalanceType = 'GOT'),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _openingBalanceType == 'GOT'
                      ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  "You'll Give",
                  style: TextStyle(
                    color: _openingBalanceType == 'GOT' ? const Color(0xFFFF5252) : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditBreachSwitch(Color cardBg, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Block new sale if limit breached',
                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Prevents creating credit invoices when limit exceeded',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _blockOnCreditBreach,
            activeColor: const Color(0xFF00E676),
            onChanged: (val) => setState(() => _blockOnCreditBreach = val),
          ),
        ],
      ),
    );
  }
}

