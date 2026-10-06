import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../finance_mode/data/finance_mode_repository.dart';
import '../../../finance_mode/models/account_model.dart';
import '../../../suppliers/data/suppliers_repository.dart';
import '../../../suppliers/models/supplier_model.dart';
import '../../data/expenses_repository.dart';
import '../../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseItem? initialExpense;

  const AddExpenseScreen({super.key, this.initialExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExpensesRepository _expensesRepo = ExpensesRepository();
  final FinanceModeRepository _financeRepo = FinanceModeRepository();
  final SuppliersRepository _suppliersRepo = SuppliersRepository();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _gstinController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _notesController;

  String _category = 'Rent & Facility';
  List<String> _categories = [];
  DateTime _selectedDate = DateTime.now();

  List<AccountModel> _accounts = [];
  String? _selectedAccountId;

  List<SupplierModel> _suppliers = [];
  String? _selectedSupplierId;

  String _paymentMode = 'BANK_TRANSFER';
  String _status = 'PAID';

  bool _includeGst = false;
  double _gstRate = 18.0;

  bool _isLoading = false;
  bool _isInitLoading = true;

  final List<double> _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];
  final List<Map<String, String>> _paymentModes = [
    {'value': 'BANK_TRANSFER', 'label': 'Bank Transfer / NEFT / RTGS'},
    {'value': 'UPI', 'label': 'UPI / QR Code'},
    {'value': 'CASH', 'label': 'Cash in Hand'},
    {'value': 'CHEQUE', 'label': 'Bank Cheque'},
    {'value': 'CREDIT_CARD', 'label': 'Corporate Credit Card'},
    {'value': 'DEBIT_CARD', 'label': 'Business Debit Card'},
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialExpense;

    _titleController = TextEditingController(text: item?.note ?? '');
    _amountController = TextEditingController(text: item != null ? item.amount.toStringAsFixed(2) : '');
    _gstinController = TextEditingController(text: item?.gstin ?? '');
    _invoiceNumberController = TextEditingController(text: item?.invoiceNumber ?? '');
    _notesController = TextEditingController();

    if (item != null) {
      _category = item.category;
      if (item.date.isNotEmpty) {
        _selectedDate = DateTime.tryParse(item.date) ?? DateTime.now();
      }
      _selectedAccountId = item.accountId;
      _paymentMode = item.paymentMode;
      _status = item.status;
      _selectedSupplierId = item.supplierId;
      if (item.gstRate != null && item.gstRate! > 0) {
        _includeGst = true;
        _gstRate = item.gstRate!;
      }
    }

    _loadPrerequisites();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _gstinController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPrerequisites() async {
    try {
      final catsFuture = _expensesRepo.getCategories();
      final accountsFuture = _financeRepo.getAccounts(type: FinanceType.business);
      final suppliersFuture = _suppliersRepo.getSuppliers();

      final results = await Future.wait([catsFuture, accountsFuture, suppliersFuture]);

      final cats = results[0] as List<String>;
      final accs = results[1] as List<AccountModel>;
      final supps = results[2] as List<SupplierModel>;

      if (mounted) {
        setState(() {
          _categories = cats;
          if (!_categories.contains(_category) && _categories.isNotEmpty) {
            _category = _categories.first;
          }
          _accounts = accs;
          if (_selectedAccountId == null && _accounts.isNotEmpty) {
            _selectedAccountId = _accounts.first.id;
          }
          _suppliers = supps;
          _isInitLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
    }
  }

  double get _computedTaxableAmount {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (!_includeGst || _gstRate <= 0 || amt <= 0) return amt;
    return amt / (1 + (_gstRate / 100));
  }

  double get _computedGstAmount {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (!_includeGst || _gstRate <= 0 || amt <= 0) return 0.0;
    return amt - _computedTaxableAmount;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
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
      setState(() => _selectedDate = picked);
    }
  }

  void _onSupplierSelected(String? supplierId) {
    setState(() {
      _selectedSupplierId = supplierId;
      if (supplierId != null) {
        final supp = _suppliers.where((s) => s.id == supplierId).firstOrNull;
        if (supp != null && supp.gstin.isNotEmpty) {
          _gstinController.text = supp.gstin;
          _includeGst = true;
        }
      }
    });
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please enter a valid expense amount greater than 0'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supplier = _suppliers.where((s) => s.id == _selectedSupplierId).firstOrNull;
      final account = _accounts.where((a) => a.id == _selectedAccountId).firstOrNull;

      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'note': _titleController.text.trim(),
        'amount': amt,
        'category': _category,
        'date': _selectedDate.toIso8601String(),
        'accountId': _selectedAccountId,
        'accountName': account?.title ?? account?.bankName,
        'paymentMode': _paymentMode,
        'status': _status,
        'supplierId': _selectedSupplierId,
        'supplierName': supplier?.name,
        'mode': 'BUSINESS',
        'accountType': 'BUSINESS',
      };

      if (_invoiceNumberController.text.trim().isNotEmpty) {
        body['invoiceNumber'] = _invoiceNumberController.text.trim();
      }

      if (_includeGst && _gstRate > 0) {
        final taxable = _computedTaxableAmount;
        final totalGst = _computedGstAmount;
        body['gstRate'] = _gstRate;
        body['gstin'] = _gstinController.text.trim().toUpperCase();
        body['taxableAmount'] = double.parse(taxable.toStringAsFixed(2));
        body['totalGst'] = double.parse(totalGst.toStringAsFixed(2));
        body['cgst'] = double.parse((totalGst / 2).toStringAsFixed(2));
        body['sgst'] = double.parse((totalGst / 2).toStringAsFixed(2));
      }

      if (widget.initialExpense != null) {
        await _expensesRepo.updateExpense(widget.initialExpense!.id, body);
      } else {
        await _expensesRepo.createExpense(body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.initialExpense != null
                      ? 'Expense updated successfully!'
                      : 'Business expense recorded successfully!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            content: Text('Failed to save expense: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialExpense != null;

    final bgColor = isDark ? AppColors.background : AppColors.brandBackground;
    final cardBg = isDark ? AppColors.surfaceElevated : Colors.white;
    final borderColor = isDark ? AppColors.border : AppColors.brandBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.brandText;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.brandTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Business Expense' : 'Record Business Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    // Top Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.brandBlue.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.brandBlue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Business Finance Ledger',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Automatically debits the selected account and updates P&L analytics.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Basic Information
                    _buildSectionHeader('EXPENSE DETAILS', Icons.info_outline_rounded, textSecondary),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Expense Title
                          _buildLabel('Expense Title / Reason *', textSecondary),
                          TextFormField(
                            controller: _titleController,
                            style: TextStyle(color: textPrimary, fontSize: 15),
                            decoration: _inputDecoration('e.g., Office Rent, AWS Cloud Hosting, Stationery', borderColor),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
                          ),
                          const SizedBox(height: 16),

                          // Total Amount
                          _buildLabel('Amount (₹) *', textSecondary),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: _inputDecoration('0.00', borderColor, prefixText: '₹ '),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Please enter amount';
                              final n = double.tryParse(val.trim());
                              if (n == null || n <= 0) return 'Must be greater than 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Category
                          _buildLabel('Expense Category *', textSecondary),
                          DropdownButtonFormField<String>(
                            value: _categories.contains(_category) ? _category : null,
                            dropdownColor: cardBg,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: _inputDecoration('', borderColor),
                            items: _categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _category = val);
                            },
                            validator: (val) => val == null ? 'Please select category' : null,
                          ),
                          const SizedBox(height: 16),

                          // Expense Date Picker
                          _buildLabel('Date of Expense *', textSecondary),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                    style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  Icon(Icons.calendar_month_rounded, color: AppColors.brandBlue, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Payment & Account
                    _buildSectionHeader('PAYMENT & ACCOUNT SETTLEMENT', Icons.account_balance_wallet_outlined, textSecondary),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Business Account
                          _buildLabel('Paid from Account *', textSecondary),
                          DropdownButtonFormField<String>(
                            value: _accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                            dropdownColor: cardBg,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: _inputDecoration('', borderColor),
                            items: _accounts.map((acc) {
                              return DropdownMenuItem<String>(
                                value: acc.id,
                                child: Text(
                                  '${acc.title} (${CurrencyFormatter.format(acc.balance)})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedAccountId = val),
                            validator: (val) => val == null ? 'Please select account' : null,
                          ),
                          const SizedBox(height: 16),

                          // Payment Mode
                          _buildLabel('Payment Method', textSecondary),
                          DropdownButtonFormField<String>(
                            value: _paymentMode,
                            dropdownColor: cardBg,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: _inputDecoration('', borderColor),
                            items: _paymentModes.map((m) {
                              return DropdownMenuItem<String>(
                                value: m['value'],
                                child: Text(m['label']!, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentMode = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Payment Status
                          _buildLabel('Payment Status', textSecondary),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('PAID (Settled)')),
                                  selected: _status == 'PAID',
                                  selectedColor: AppColors.success.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: _status == 'PAID' ? AppColors.success : textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  side: BorderSide(color: _status == 'PAID' ? AppColors.success : borderColor),
                                  onSelected: (val) {
                                    if (val) setState(() => _status = 'PAID');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('PENDING / Due')),
                                  selected: _status == 'PENDING',
                                  selectedColor: AppColors.warning.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: _status == 'PENDING' ? AppColors.warning : textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  side: BorderSide(color: _status == 'PENDING' ? AppColors.warning : borderColor),
                                  onSelected: (val) {
                                    if (val) setState(() => _status = 'PENDING');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Vendor & Tax Details
                    _buildSectionHeader('VENDOR & TAX COMPLIANCE', Icons.storefront_outlined, textSecondary),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Linked Supplier
                          _buildLabel('Vendor / Supplier (Optional)', textSecondary),
                          DropdownButtonFormField<String?>(
                            value: _suppliers.any((s) => s.id == _selectedSupplierId) ? _selectedSupplierId : null,
                            dropdownColor: cardBg,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: _inputDecoration('', borderColor),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None (Direct Business Expense)', style: TextStyle(color: Colors.grey)),
                              ),
                              ..._suppliers.map((s) {
                                return DropdownMenuItem<String?>(
                                  value: s.id,
                                  child: Text('${s.name} ${s.companyName.isNotEmpty ? '(${s.companyName})' : ''}', overflow: TextOverflow.ellipsis),
                                );
                              }),
                            ],
                            onChanged: _onSupplierSelected,
                          ),
                          const SizedBox(height: 16),

                          // Invoice Number
                          _buildLabel('Bill / Voucher / Invoice Number', textSecondary),
                          TextFormField(
                            controller: _invoiceNumberController,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: _inputDecoration('e.g., INV-2026/09/441', borderColor),
                          ),
                          const SizedBox(height: 16),

                          // GST Toggle
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Include GST / Input Tax Credit (ITC)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Calculate tax breakdown for compliance filing',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            activeColor: AppColors.brandBlue,
                            value: _includeGst,
                            onChanged: (val) => setState(() => _includeGst = val),
                          ),

                          if (_includeGst) ...[
                            const SizedBox(height: 12),
                            // GSTIN
                            _buildLabel('Vendor GSTIN', textSecondary),
                            TextFormField(
                              controller: _gstinController,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(color: textPrimary, fontSize: 14, letterSpacing: 1.2),
                              decoration: _inputDecoration('e.g., 36AABCU9603R1ZM', borderColor),
                            ),
                            const SizedBox(height: 14),

                            // GST Rate Selector
                            _buildLabel('Applicable GST Rate', textSecondary),
                            Wrap(
                              spacing: 8,
                              children: _gstRates.map((rate) {
                                final isSelected = _gstRate == rate;
                                return ChoiceChip(
                                  label: Text('${rate.toInt()}%'),
                                  selected: isSelected,
                                  selectedColor: AppColors.brandBlue,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  side: BorderSide(color: isSelected ? AppColors.brandBlue : borderColor),
                                  onSelected: (val) {
                                    if (val) setState(() => _gstRate = rate);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Calculated breakdown
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F141E) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Taxable Base Amount:', style: TextStyle(fontSize: 12, color: textSecondary)),
                                      Text(
                                        CurrencyFormatter.format(_computedTaxableAmount),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total GST (${_gstRate.toInt()}%):', style: TextStyle(fontSize: 12, color: textSecondary)),
                                      Text(
                                        CurrencyFormatter.format(_computedGstAmount),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _submitExpense,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing ? Icons.save_rounded : Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditing ? 'Update Business Expense' : 'Save Business Expense',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color borderColor, {String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
