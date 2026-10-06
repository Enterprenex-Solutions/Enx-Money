import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../../../core/widgets/feedback/stat_badge.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/emi_calculator_engine.dart';
import '../../data/loan_repository.dart';
import '../../models/loan_model.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanRepository? repository;

  const AddLoanScreen({super.key, this.repository});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  late final LoanRepository _loanRepository;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _principalController = TextEditingController(text: '500000');
  final TextEditingController _rateController = TextEditingController(text: '8.5');
  final TextEditingController _tenureController = TextEditingController(text: '5');

  String _selectedLoanType = 'Personal';
  String _interestType = 'Reducing';
  String _tenureUnit = 'Years'; // 'Years' | 'Months'
  DateTime _startDate = DateTime.now();

  EmiCalculationPreview _preview = const EmiCalculationPreview(
    principal: 500000,
    annualInterestRate: 8.5,
    tenureMonths: 60,
    interestType: 'Reducing',
    emiAmount: 10258.33,
    totalInterest: 115500.0,
    totalPayable: 615500.0,
    monthlyPrincipalComponent: 6716.67,
    monthlyInterestComponent: 3541.67,
  );

  bool _isSubmitting = false;
  String? _principalError;
  String? _rateError;
  String? _tenureError;

  final List<Map<String, dynamic>> _loanTypes = [
    {
      'type': 'Personal',
      'label': 'Personal',
      'icon': Icons.person_outline_rounded,
      'desc': 'Unsecured, Travel, Medical',
    },
    {
      'type': 'Vehicle',
      'label': 'Vehicle',
      'icon': Icons.directions_car_outlined,
      'desc': 'Car, Bike, Auto Loan',
    },
    {
      'type': 'Home',
      'label': 'Home',
      'icon': Icons.home_outlined,
      'desc': 'Housing, Mortgage, Land',
    },
    {
      'type': 'Business',
      'label': 'Business',
      'icon': Icons.business_center_outlined,
      'desc': 'Working Capital, SME',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loanRepository = widget.repository ?? LoanRepository();
    _updateEmiPreview();
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  int get _effectiveTenureMonths {
    final raw = int.tryParse(_tenureController.text.trim()) ?? 0;
    return _tenureUnit == 'Years' ? raw * 12 : raw;
  }

  void _updateEmiPreview() {
    final principal = double.tryParse(_principalController.text.trim().replaceAll(',', '')) ?? 0.0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
    final tenureMonths = _effectiveTenureMonths;

    setState(() {
      _preview = EmiCalculatorEngine.calculate(
        principal: principal,
        annualInterestRate: rate,
        tenureMonths: tenureMonths,
        interestType: _interestType,
      );
    });
  }

  bool _validateInputs() {
    bool isValid = true;
    final principal = double.tryParse(_principalController.text.trim().replaceAll(',', ''));
    final rate = double.tryParse(_rateController.text.trim());
    final tenure = int.tryParse(_tenureController.text.trim());

    setState(() {
      if (principal == null || principal <= 0) {
        _principalError = 'Enter a valid principal amount (> ₹0)';
        isValid = false;
      } else {
        _principalError = null;
      }

      if (rate == null || rate < 0 || rate > 100) {
        _rateError = 'Enter interest rate between 0% and 100%';
        isValid = false;
      } else {
        _rateError = null;
      }

      if (tenure == null || tenure <= 0) {
        _tenureError = 'Enter a valid tenure (> 0)';
        isValid = false;
      } else if (_tenureUnit == 'Years' && tenure > 30) {
        _tenureError = 'Tenure cannot exceed 30 years';
        isValid = false;
      } else if (_tenureUnit == 'Months' && tenure > 360) {
        _tenureError = 'Tenure cannot exceed 360 months';
        isValid = false;
      } else {
        _tenureError = null;
      }
    });

    return isValid;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGreen,
              onPrimary: AppColors.background,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.pureWhite,
            ),
            dialogBackgroundColor: AppColors.surfaceCard,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _updateEmiPreview();
    }
  }

  Future<void> _handleCreateLoan() async {
    if (!_validateInputs()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final principal = double.parse(_principalController.text.trim().replaceAll(',', ''));
      final rate = double.parse(_rateController.text.trim());
      final tenureMonths = _effectiveTenureMonths;
      final formattedDate = DateFormat('yyyy-MM-dd').format(_startDate);

      final createdLoan = await _loanRepository.createLoan(
        loanType: _selectedLoanType,
        principalAmount: principal,
        interestRate: rate,
        tenureMonths: tenureMonths,
        startDate: formattedDate,
        interestType: _interestType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            side: const BorderSide(color: AppColors.primaryGreen, width: 1),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${createdLoan.loanType} Loan of ${CurrencyFormatter.format(createdLoan.principalAmount)} created with ${createdLoan.tenureMonths} EMIs!',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.pureWhite),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pop(createdLoan);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          content: Text(
            'Failed to create loan: $e',
            style: AppTypography.bodySmall.copyWith(color: AppColors.pureWhite),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FintechAppBar(
        title: 'Add New Loan',
        subtitle: 'LOAN & EMI SETUP',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LIVE EMI PREVIEW MASTER CARD
              _buildLiveEmiPreviewCard(),

              const SizedBox(height: 24),

              // 2. LOAN TYPE SELECTION
              Text(
                'SELECT LOAN TYPE',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildLoanTypeSelector(),

              const SizedBox(height: 24),

              // 3. PRINCIPAL AMOUNT INPUT
              FintechTextField(
                controller: _principalController,
                label: 'PRINCIPAL LOAN AMOUNT',
                hintText: 'e.g. 5,00,000',
                prefixText: '₹ ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                errorText: _principalError,
                onChanged: (_) => _updateEmiPreview(),
              ),
              const SizedBox(height: 10),
              _buildQuickPrincipalChips(),

              const SizedBox(height: 20),

              // 4. INTEREST RATE & TYPE ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: FintechTextField(
                      controller: _rateController,
                      label: 'ANNUAL INTEREST RATE',
                      hintText: 'e.g. 8.5',
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '% p.a.',
                            style: AppTypography.badge.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      errorText: _rateError,
                      onChanged: (_) => _updateEmiPreview(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INTEREST METHOD',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInterestTypeToggle(),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. TENURE & TENURE UNIT
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: FintechTextField(
                      controller: _tenureController,
                      label: 'LOAN TENURE',
                      hintText: _tenureUnit == 'Years' ? 'e.g. 5' : 'e.g. 60',
                      keyboardType: TextInputType.number,
                      errorText: _tenureError,
                      onChanged: (_) => _updateEmiPreview(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TENURE UNIT',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTenureUnitToggle(),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 6. START DATE PICKER
              Text(
                'FIRST EMI / START DATE',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildStartDateCard(),

              const SizedBox(height: 32),

              // 7. ACTION BUTTON
              PrimaryButton(
                text: 'Create Loan & Schedule',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSubmitting,
                onPressed: _handleCreateLoan,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildLiveEmiPreviewCard() {
    final principalRatio = _preview.totalPayable > 0 ? (_preview.principal / _preview.totalPayable) : 0.7;
    final interestRatio = _preview.totalPayable > 0 ? (_preview.totalInterest / _preview.totalPayable) : 0.3;

    return FintechCard(
      hasGlow: true,
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE ESTIMATED MONTHLY EMI',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              StatBadge(
                text: _interestType.toUpperCase(),
                type: StatBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(_preview.emiAmount),
                style: AppTypography.currencyLarge.copyWith(
                  fontSize: 32,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ month',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),

          // Total Interest & Total Payable Stats
          Row(
            children: [
              Expanded(
                child: _buildPreviewSubStat(
                  'Total Interest',
                  CurrencyFormatter.format(_preview.totalInterest),
                  AppColors.accentGold,
                ),
              ),
              Expanded(
                child: _buildPreviewSubStat(
                  'Total Payable',
                  CurrencyFormatter.format(_preview.totalPayable),
                  AppColors.pureWhite,
                ),
              ),
              Expanded(
                child: _buildPreviewSubStat(
                  'Tenure',
                  '${_preview.tenureMonths} Mo',
                  AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ratio breakdown visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (principalRatio * 100).toInt().clamp(1, 99),
                    child: Container(color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (interestRatio * 100).toInt().clamp(1, 99),
                    child: Container(color: AppColors.accentGold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Principal: ${(principalRatio * 100).toStringAsFixed(0)}%', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accentGold, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Interest: ${(interestRatio * 100).toStringAsFixed(0)}%', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSubStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTypeSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _loanTypes.length,
      itemBuilder: (context, index) {
        final item = _loanTypes[index];
        final isSelected = _selectedLoanType == item['type'];

        return InkWell(
          onTap: () {
            setState(() {
              _selectedLoanType = item['type'] as String;
            });
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primaryGreen : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.15)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['label'] as String,
                        style: AppTypography.titleSmall.copyWith(
                          color: isSelected ? AppColors.pureWhite : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        item['desc'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickPrincipalChips() {
    final chips = [
      {'label': '₹1 Lakh', 'value': '100000'},
      {'label': '₹5 Lakhs', 'value': '500000'},
      {'label': '₹10 Lakhs', 'value': '1000000'},
      {'label': '₹25 Lakhs', 'value': '2500000'},
      {'label': '₹50 Lakhs', 'value': '5000000'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((chip) {
          final isCurrent = _principalController.text == chip['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                _principalController.text = chip['value']!;
                _updateEmiPreview();
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isCurrent ? AppColors.primaryGreen : AppColors.border,
                  ),
                ),
                child: Text(
                  chip['label']!,
                  style: AppTypography.badge.copyWith(
                    color: isCurrent ? AppColors.primaryGreen : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInterestTypeToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              title: 'Reducing',
              isSelected: _interestType == 'Reducing',
              onTap: () {
                setState(() => _interestType = 'Reducing');
                _updateEmiPreview();
              },
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              title: 'Flat',
              isSelected: _interestType == 'Flat',
              onTap: () {
                setState(() => _interestType = 'Flat');
                _updateEmiPreview();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenureUnitToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              title: 'Years',
              isSelected: _tenureUnit == 'Years',
              onTap: () {
                setState(() => _tenureUnit = 'Years');
                _updateEmiPreview();
              },
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              title: 'Months',
              isSelected: _tenureUnit == 'Months',
              onTap: () {
                setState(() => _tenureUnit = 'Months');
                _updateEmiPreview();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.background : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStartDateCard() {
    return InkWell(
      onTap: _pickStartDate,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 14),
                Text(
                  DateFormat('dd MMMM yyyy').format(_startDate),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              'Change',
              style: AppTypography.badge.copyWith(
                color: AppColors.primaryGreen,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
