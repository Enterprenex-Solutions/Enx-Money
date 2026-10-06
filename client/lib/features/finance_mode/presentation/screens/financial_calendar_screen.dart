import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/finance/app_card.dart';
import '../../../../core/widgets/finance/status_badge.dart';
import '../../../analytics/data/analytics_repository.dart';
import '../../../analytics/models/kpi_summary_model.dart';
import '../../../../core/services/reminder_service.dart';

enum CalendarScope { personal, business }
enum CalculatorType {
  // Business calculators
  businessProfit,
  gst,
  markupMargin,
  discount,
  // Personal calculators
  loanEmi,
  incomeExpense,
  percentage,
}

class FinancialCalendarScreen extends StatefulWidget {
  final CalendarScope scope;
  final VoidCallback? onOpenDrawer;

  const FinancialCalendarScreen({
    super.key,
    this.scope = CalendarScope.business,
    this.onOpenDrawer,
  });

  @override
  State<FinancialCalendarScreen> createState() => _FinancialCalendarScreenState();
}

class _FinancialCalendarScreenState extends State<FinancialCalendarScreen> {
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final decimalCurrencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  late CalendarScope _currentScope;
  late CalculatorType _selectedCalculator;
  late DateTime _displayedMonth;
  late DateTime _selectedCalendarDate;

  bool _showCalendarView = true;
  int? _filterDay;
  bool _isLoadingKpi = false;
  KpiSummary? _liveKpi;

  // Reminders storage
  List<Map<String, dynamic>> _reminders = [];
  static const String _remindersPrefKey = 'enx_finance_reminders_v2';

  // ── Calculator Controllers & State ─────────────────────────────────────
  // 1. Loan EMI
  final _emiLoanAmountController = TextEditingController(text: '500000');
  final _emiInterestRateController = TextEditingController(text: '10.5');
  final _emiTenureController = TextEditingController(text: '24');
  bool _emiTenureInYears = false;
  double _calculatedMonthlyEmi = 0.0;
  double _calculatedTotalInterest = 0.0;
  double _calculatedTotalAmount = 0.0;

  // 2. GST Calculator
  final _gstAmountController = TextEditingController(text: '10000');
  double _selectedGstRate = 18.0;
  bool _isGstExclusive = true; // Add GST vs Remove GST
  bool _isInterState = false; // IGST vs CGST+SGST
  double _gstBaseAmount = 0.0;
  double _gstTaxAmount = 0.0;
  double _cgstAmount = 0.0;
  double _sgstAmount = 0.0;
  double _igstAmount = 0.0;
  double _gstFinalAmount = 0.0;

  // 3. Business Profit & Margin (Auto-loaded from Live Backend Data)
  final _bizSalesController = TextEditingController(text: '0');
  final _bizPurchasesController = TextEditingController(text: '0');
  final _bizExpensesController = TextEditingController(text: '0');
  final _bizReceivablesController = TextEditingController(text: '0');
  final _bizPayablesController = TextEditingController(text: '0');
  double _bizGrossProfit = 0.0;
  double _bizGrossMarginPct = 0.0;
  double _bizNetProfit = 0.0;
  double _bizNetMarginPct = 0.0;
  double _bizWorkingCapital = 0.0;

  // 4. Markup & Margin
  final _costPriceController = TextEditingController(text: '1000');
  final _sellingPriceController = TextEditingController(text: '1250');
  double _calculatedMarkupPct = 0.0;
  double _calculatedMarginPct = 0.0;
  double _calculatedProfitAmount = 0.0;

  // 5. Discount Calculator
  final _discountOriginalAmountController = TextEditingController(text: '2500');
  final _discountPctController = TextEditingController(text: '15');
  double _discountSavedAmount = 0.0;
  double _discountFinalAmount = 0.0;

  // 6. Income, Expense & Savings
  final _incomeController = TextEditingController(text: '75000');
  final _expenseController = TextEditingController(text: '45000');
  double _netSavings = 0.0;
  double _savingsRatePct = 0.0;

  // 7. Percentage Calculator
  final _percentOfController = TextEditingController(text: '20');
  final _percentBaseController = TextEditingController(text: '5000');
  double _percentResult = 0.0;

  @override
  void initState() {
    super.initState();
    _currentScope = widget.scope;
    _selectedCalculator = _currentScope == CalendarScope.business
        ? CalculatorType.businessProfit
        : CalculatorType.loanEmi;
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _selectedCalendarDate = now;

    _calculateAll();
    _loadStoredReminders();
    _fetchLiveBusinessKpi();
  }

  @override
  void dispose() {
    _emiLoanAmountController.dispose();
    _emiInterestRateController.dispose();
    _emiTenureController.dispose();
    _gstAmountController.dispose();
    _bizSalesController.dispose();
    _bizPurchasesController.dispose();
    _bizExpensesController.dispose();
    _bizReceivablesController.dispose();
    _bizPayablesController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _discountOriginalAmountController.dispose();
    _discountPctController.dispose();
    _incomeController.dispose();
    _expenseController.dispose();
    _percentOfController.dispose();
    _percentBaseController.dispose();
    super.dispose();
  }

  // ─── Real Backend Data Integration ──────────────────────────────────────────
  Future<void> _fetchLiveBusinessKpi() async {
    setState(() => _isLoadingKpi = true);
    try {
      final kpi = await _analyticsRepo.getKpi(profileType: 'business');
      if (mounted) {
        setState(() {
          _liveKpi = kpi;
          _isLoadingKpi = false;

          // Auto-populate Business Calculator with live database figures
          if (kpi.totalSales > 0 || kpi.totalRevenue > 0) {
            _bizSalesController.text = (kpi.totalSales > 0 ? kpi.totalSales : kpi.totalRevenue).toStringAsFixed(0);
          }
          if (kpi.totalPurchases > 0) {
            _bizPurchasesController.text = kpi.totalPurchases.toStringAsFixed(0);
          }
          if (kpi.totalExpense > 0) {
            _bizExpensesController.text = kpi.totalExpense.toStringAsFixed(0);
          }
          if (kpi.outstandingReceivables > 0) {
            _bizReceivablesController.text = kpi.outstandingReceivables.toStringAsFixed(0);
          }
          if (kpi.outstandingPayables > 0) {
            _bizPayablesController.text = kpi.outstandingPayables.toStringAsFixed(0);
          }
        });
        _calculateBusinessProfit();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingKpi = false);
    }
  }

  // ─── Calculations Engine ──────────────────────────────────────────────────
  void _calculateAll() {
    _calculateEmi();
    _calculateGst();
    _calculateBusinessProfit();
    _calculateMarkupMargin();
    _calculateDiscount();
    _calculateIncomeExpense();
    _calculatePercentage();
  }

  void _calculateEmi() {
    final p = double.tryParse(_emiLoanAmountController.text.trim()) ?? 0.0;
    final annualRate = double.tryParse(_emiInterestRateController.text.trim()) ?? 0.0;
    var tenureMonths = int.tryParse(_emiTenureController.text.trim()) ?? 0;
    if (_emiTenureInYears) {
      tenureMonths = tenureMonths * 12;
    }

    if (p <= 0 || annualRate <= 0 || tenureMonths <= 0) {
      setState(() {
        _calculatedMonthlyEmi = 0.0;
        _calculatedTotalInterest = 0.0;
        _calculatedTotalAmount = p;
      });
      return;
    }

    final r = (annualRate / 12) / 100;
    // EMI = P * r * (1+r)^n / ((1+r)^n - 1)
    final double factor = _power(1 + r, tenureMonths);
    final double emi = (p * r * factor) / (factor - 1);
    final double totalAmount = emi * tenureMonths;
    final double totalInterest = totalAmount - p;

    setState(() {
      _calculatedMonthlyEmi = emi;
      _calculatedTotalInterest = totalInterest > 0 ? totalInterest : 0.0;
      _calculatedTotalAmount = totalAmount;
    });
  }

  double _power(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  void _calculateGst() {
    final amount = double.tryParse(_gstAmountController.text.trim()) ?? 0.0;
    final rate = _selectedGstRate;

    if (amount <= 0 || rate <= 0) {
      setState(() {
        _gstBaseAmount = amount;
        _gstTaxAmount = 0.0;
        _cgstAmount = 0.0;
        _sgstAmount = 0.0;
        _igstAmount = 0.0;
        _gstFinalAmount = amount;
      });
      return;
    }

    double base;
    double tax;
    double finalAmt;

    if (_isGstExclusive) {
      // GST is added to base amount
      base = amount;
      tax = (amount * rate) / 100;
      finalAmt = base + tax;
    } else {
      // GST is included in amount (reverse calculation)
      base = (amount * 100) / (100 + rate);
      tax = amount - base;
      finalAmt = amount;
    }

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    if (_isInterState) {
      igst = tax;
    } else {
      cgst = tax / 2;
      sgst = tax / 2;
    }

    setState(() {
      _gstBaseAmount = base;
      _gstTaxAmount = tax;
      _cgstAmount = cgst;
      _sgstAmount = sgst;
      _igstAmount = igst;
      _gstFinalAmount = finalAmt;
    });
  }

  void _calculateBusinessProfit() {
    final sales = double.tryParse(_bizSalesController.text.trim()) ?? 0.0;
    final purchases = double.tryParse(_bizPurchasesController.text.trim()) ?? 0.0;
    final expenses = double.tryParse(_bizExpensesController.text.trim()) ?? 0.0;
    final receivables = double.tryParse(_bizReceivablesController.text.trim()) ?? 0.0;
    final payables = double.tryParse(_bizPayablesController.text.trim()) ?? 0.0;

    final grossProfit = sales - purchases;
    final grossMarginPct = sales > 0 ? (grossProfit / sales) * 100 : 0.0;
    final netProfit = grossProfit - expenses;
    final netMarginPct = sales > 0 ? (netProfit / sales) * 100 : 0.0;
    final workingCapital = receivables - payables;

    setState(() {
      _bizGrossProfit = grossProfit;
      _bizGrossMarginPct = grossMarginPct;
      _bizNetProfit = netProfit;
      _bizNetMarginPct = netMarginPct;
      _bizWorkingCapital = workingCapital;
    });
  }

  void _calculateMarkupMargin() {
    final cost = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
    final sell = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final profit = sell - cost;
    final markup = cost > 0 ? (profit / cost) * 100 : 0.0;
    final margin = sell > 0 ? (profit / sell) * 100 : 0.0;

    setState(() {
      _calculatedProfitAmount = profit;
      _calculatedMarkupPct = markup;
      _calculatedMarginPct = margin;
    });
  }

  void _calculateDiscount() {
    final original = double.tryParse(_discountOriginalAmountController.text.trim()) ?? 0.0;
    final pct = double.tryParse(_discountPctController.text.trim()) ?? 0.0;
    final saved = (original * pct) / 100;
    final finalPrice = original - saved;

    setState(() {
      _discountSavedAmount = saved > 0 ? saved : 0.0;
      _discountFinalAmount = finalPrice > 0 ? finalPrice : 0.0;
    });
  }

  void _calculateIncomeExpense() {
    final inc = double.tryParse(_incomeController.text.trim()) ?? 0.0;
    final exp = double.tryParse(_expenseController.text.trim()) ?? 0.0;
    final savings = inc - exp;
    final rate = inc > 0 ? (savings / inc) * 100 : 0.0;

    setState(() {
      _netSavings = savings;
      _savingsRatePct = rate;
    });
  }

  void _calculatePercentage() {
    final of = double.tryParse(_percentOfController.text.trim()) ?? 0.0;
    final base = double.tryParse(_percentBaseController.text.trim()) ?? 0.0;
    setState(() {
      _percentResult = (of * base) / 100;
    });
  }

  // ─── Persistent Reminders Management (SharedPreferences) ───────────────────
  Future<void> _loadStoredReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_remindersPrefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        setState(() {
          _reminders = decoded.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            if (map['rawDate'] is String) {
              map['rawDate'] = DateTime.parse(map['rawDate'] as String);
            }
            return map;
          }).toList();
        });
      } else {
        // Provide standard statutory/business reminders if fresh
        _seedDefaultReminders();
      }
    } catch (_) {
      _seedDefaultReminders();
    }
  }

  void _seedDefaultReminders() {
    final now = DateTime.now();
    setState(() {
      _reminders = [
        {
          'id': 'rem_1',
          'title': 'GSTR-1 Monthly Filing Deadline',
          'type': 'GST Compliance',
          'amount': 0.0,
          'date': DateFormat('dd MMM').format(DateTime(now.year, now.month, 11)),
          'day': DateFormat('EEEE').format(DateTime(now.year, now.month, 11)),
          'rawDate': DateTime(now.year, now.month, 11),
          'badge': 'Statutory',
          'scope': 'business',
        },
        {
          'id': 'rem_2',
          'title': 'GSTR-3B Tax Return & Payment',
          'type': 'GST Compliance',
          'amount': _liveKpi?.gstPayable ?? 18400.0,
          'date': DateFormat('dd MMM').format(DateTime(now.year, now.month, 20)),
          'day': DateFormat('EEEE').format(DateTime(now.year, now.month, 20)),
          'rawDate': DateTime(now.year, now.month, 20),
          'badge': 'Mandatory',
          'scope': 'business',
        },
        {
          'id': 'rem_3',
          'title': 'Vendor Trade Payables Clearing',
          'type': 'Vendor Payout',
          'amount': _liveKpi?.outstandingPayables ?? 45000.0,
          'date': DateFormat('dd MMM').format(DateTime(now.year, now.month, 25)),
          'day': DateFormat('EEEE').format(DateTime(now.year, now.month, 25)),
          'rawDate': DateTime(now.year, now.month, 25),
          'badge': 'Scheduled',
          'scope': 'business',
        },
        {
          'id': 'rem_4',
          'title': 'Monthly Household EMI Debit',
          'type': 'Loan EMI',
          'amount': 15000.0,
          'date': DateFormat('dd MMM').format(DateTime(now.year, now.month, 5)),
          'day': DateFormat('EEEE').format(DateTime(now.year, now.month, 5)),
          'rawDate': DateTime(now.year, now.month, 5),
          'badge': 'Auto-Debit',
          'scope': 'personal',
        },
      ];
    });
  }

  Future<void> _saveRemindersToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _reminders.map((r) {
        final copy = Map<String, dynamic>.from(r);
        if (copy['rawDate'] is DateTime) {
          copy['rawDate'] = (copy['rawDate'] as DateTime).toIso8601String();
        }
        return copy;
      }).toList();
      await prefs.setString(_remindersPrefKey, jsonEncode(list));
    } catch (_) {}
  }

  void _addNewReminder({
    required String title,
    required double amount,
    required DateTime date,
    required String type,
  }) {
    final int notifId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    final newRem = {
      'id': 'rem_$notifId',
      'notifId': notifId,
      'title': title,
      'type': type,
      'amount': amount,
      'date': DateFormat('dd MMM').format(date),
      'day': DateFormat('EEEE').format(date),
      'rawDate': date,
      'badge': 'Scheduled',
      'scope': _currentScope == CalendarScope.business ? 'business' : 'personal',
    };

    setState(() {
      _reminders.insert(0, newRem);
    });
    _saveRemindersToDisk();

    // Schedule background local alarm
    final body = amount > 0
        ? '$type reminder: ₹${amount.toStringAsFixed(2)} is due today.'
        : '$type reminder is due today.';
    ReminderService.instance.scheduleFinancialReminder(
      id: notifId,
      title: 'Reminder: $title',
      body: body,
      scheduledDate: date,
      payload: 'reminder_$notifId',
    );
  }

  void _deleteReminder(String id) {
    final item = _reminders.firstWhere((r) => r['id'] == id, orElse: () => {});
    if (item.isNotEmpty && item['notifId'] != null) {
      final nid = item['notifId'];
      if (nid is int) {
        ReminderService.instance.cancelReminder(nid);
      } else if (nid is num) {
        ReminderService.instance.cancelReminder(nid.toInt());
      }
    }
    setState(() {
      _reminders.removeWhere((r) => r['id'] == id);
    });
    _saveRemindersToDisk();
  }

  // ─── Add Reminder Modal ─────────────────────────────────────────────────────
  Future<void> _showAddEventDialog(BuildContext context, bool isDark, {DateTime? initialDate}) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = initialDate ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String selectedType = _currentScope == CalendarScope.business ? 'GST Compliance' : 'Bill Due';

    final categories = _currentScope == CalendarScope.business
        ? ['GST Compliance', 'TDS / Advance Tax', 'Payroll', 'Vendor Payout', 'EMI / Loan', 'General']
        : ['Bill Due', 'Loan EMI', 'Investment / SIP', 'Utilities', 'Subscription', 'General'];

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textColor = isDark ? Colors.white : AppColors.brandText;
            final cardBg = isDark ? AppColors.surfaceElevated : Colors.white;

            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.alarm_add_rounded, color: AppColors.brandBlue, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Schedule Financial Reminder',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'REMINDER TITLE *',
                        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandTextSecondary),
                        hintText: 'e.g. GSTR-3B Payment or Vehicle EMI',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        filled: true,
                        fillColor: isDark ? AppColors.surface : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.brandBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.brandBorder)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'AMOUNT (OPTIONAL)',
                        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandTextSecondary),
                        hintText: '₹ 0',
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: isDark ? AppColors.surface : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.brandBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.brandBorder)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandTextSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.border : AppColors.brandBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.surfaceElevated : Colors.white,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
                          items: categories.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Picker Container
                    InkWell(
                      onTap: () async {
                        final pickedD = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          helpText: 'SELECT REMINDER DATE',
                        );
                        if (pickedD == null) return;

                        if (!context.mounted) return;
                        final pickedT = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          helpText: 'SELECT REMINDER TIME',
                        );
                        if (pickedT == null) return;

                        setDialogState(() {
                          selectedDate = pickedD;
                          selectedTime = pickedT;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surface : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.border : AppColors.brandBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.brandBlue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEE, dd MMMM yyyy').format(selectedDate),
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    'Time: ${selectedTime.format(context)}',
                                    style: TextStyle(color: AppColors.brandTextSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit_outlined, size: 16, color: AppColors.brandBlue),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: AppColors.brandTextSecondary, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                    final combinedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    _addNewReminder(
                      title: title,
                      amount: amt,
                      date: combinedDate,
                      type: selectedType,
                    );
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );

    if (res == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.successMint,
          content: Text('Financial reminder scheduled successfully!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  // ─── Build Screen ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isPersonal = _currentScope == CalendarScope.personal;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandText;
    final secondaryTextColor = isDark ? AppColors.textSecondary : AppColors.brandTextSecondary;
    final borderColor = isDark ? AppColors.border : AppColors.brandBorder;

    // Filter reminders based on scope and selected day
    final currentScopeString = isPersonal ? 'personal' : 'business';
    final scopedReminders = _reminders.where((r) => (r['scope'] ?? 'business') == currentScopeString).toList();
    final events = _filterDay == null
        ? scopedReminders
        : scopedReminders.where((ev) {
            if (ev['rawDate'] is DateTime) {
              return (ev['rawDate'] as DateTime).day == _filterDay;
            }
            return false;
          }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Finance Calculator',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0.5,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: Icon(Icons.menu_rounded, color: textColor),
                onPressed: widget.onOpenDrawer,
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _showCalendarView ? Icons.calendar_month_rounded : Icons.calendar_today_outlined,
              color: AppColors.brandBlue,
            ),
            tooltip: _showCalendarView ? 'Hide Calendar' : 'Show Calendar',
            onPressed: () => setState(() => _showCalendarView = !_showCalendarView),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.brandBlue),
            tooltip: 'Add Reminder',
            onPressed: () => _showAddEventDialog(context, isDark, initialDate: _selectedCalendarDate),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scope Toggle: Personal Household vs Business & Tax ──────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentScope = CalendarScope.personal;
                          _selectedCalculator = CalculatorType.loanEmi;
                          _filterDay = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isPersonal ? AppColors.brandBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: isPersonal ? Colors.white : secondaryTextColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Personal Household',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isPersonal ? Colors.white : secondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentScope = CalendarScope.business;
                          _selectedCalculator = CalculatorType.businessProfit;
                          _filterDay = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isPersonal ? AppColors.brandBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_center_rounded,
                              size: 16,
                              color: !isPersonal ? Colors.white : secondaryTextColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Business & Tax',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !isPersonal ? Colors.white : secondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Financial Calculator Section ───────────────────────────────
            _buildCalculatorSelectionChips(isDark, cardBg, textColor, borderColor),
            const SizedBox(height: 14),

            // Active Calculator Card
            _buildActiveCalculatorCard(isDark, cardBg, textColor, secondaryTextColor, borderColor),
            const SizedBox(height: 20),

            // ── Calendar Reminder Option Banner Card (Responsive & Clean) ──
            _buildCalendarActionBanner(context, isDark, cardBg, textColor, secondaryTextColor, borderColor),

            // ── Interactive Calendar Widget (when toggled on) ───────────────
            if (_showCalendarView) ...[
              const SizedBox(height: 14),
              _buildInteractiveCalendar(context, isDark, cardBg, textColor, secondaryTextColor, borderColor, scopedReminders),
            ],

            const SizedBox(height: 20),

            // ── Upcoming Reminders List ─────────────────────────────────────
            _buildRemindersHeader(textColor, secondaryTextColor, events.length),
            const SizedBox(height: 12),
            _buildRemindersList(context, isDark, cardBg, textColor, secondaryTextColor, borderColor, events),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Calculator Selection Chips ───────────────────────────────────────────
  Widget _buildCalculatorSelectionChips(bool isDark, Color cardBg, Color textColor, Color borderColor) {
    final List<_CalcTabOption> options = _currentScope == CalendarScope.business
        ? [
            const _CalcTabOption(CalculatorType.businessProfit, 'Business Margins', Icons.insights_rounded),
            const _CalcTabOption(CalculatorType.gst, 'GST Calculator', Icons.receipt_long_rounded),
            const _CalcTabOption(CalculatorType.markupMargin, 'Markup & Margin', Icons.price_change_rounded),
            const _CalcTabOption(CalculatorType.discount, 'Discount', Icons.local_offer_rounded),
          ]
        : [
            const _CalcTabOption(CalculatorType.loanEmi, 'Loan EMI', Icons.account_balance_rounded),
            const _CalcTabOption(CalculatorType.incomeExpense, 'Income & Savings', Icons.savings_rounded),
            const _CalcTabOption(CalculatorType.percentage, 'Percentage', Icons.percent_rounded),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((opt) {
          final isSelected = _selectedCalculator == opt.type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                opt.icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.brandBlue,
              ),
              label: Text(
                opt.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.brandBlue,
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSelected ? AppColors.brandBlue : borderColor),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCalculator = opt.type);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Active Calculator Card Router ─────────────────────────────────────────
  Widget _buildActiveCalculatorCard(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    switch (_selectedCalculator) {
      case CalculatorType.businessProfit:
        return _buildBusinessProfitCalculator(isDark, cardBg, textColor, secondaryTextColor, borderColor);
      case CalculatorType.gst:
        return _buildGstCalculator(isDark, cardBg, textColor, secondaryTextColor, borderColor);
      case CalculatorType.loanEmi:
        return _buildLoanEmiCalculator(isDark, cardBg, textColor, secondaryTextColor, borderColor);
      case CalculatorType.markupMargin:
        return _buildMarkupMarginCalculator(isDark, cardBg, textColor, secondaryTextColor, borderColor);
      case CalculatorType.discount:
        return _buildDiscountCalculator(isDark, cardBg, textColor, secondaryTextColor, borderColor);
      case CalculatorType.incomeExpense:
        return _buildIncomeExpenseCalculator(isDark, cardBg, textColor, secondaryTextColor, borderColor);
      case CalculatorType.percentage:
        return _buildPercentageCalculator(isDark, cardBg, textColor, secondaryTextColor, borderColor);
    }
  }

  // ─── 1. Business Profit & Margin Calculator (Real Backend Data) ───────────
  Widget _buildBusinessProfitCalculator(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return AppCard(
      backgroundColor: cardBg,
      borderColor: borderColor,
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
                      'Business Margins & Profitability',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live synchronized from logged-in business accounts',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _isLoadingKpi
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.brandBlue),
                tooltip: 'Sync Real Business Data',
                onPressed: _fetchLiveBusinessKpi,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inputs Grid
          Row(
            children: [
              Expanded(
                child: _buildCalcInputField(
                  label: 'TOTAL SALES (₹)',
                  controller: _bizSalesController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateBusinessProfit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalcInputField(
                  label: 'PURCHASES (₹)',
                  controller: _bizPurchasesController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateBusinessProfit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildCalcInputField(
                  label: 'OPERATING EXPENSES (₹)',
                  controller: _bizExpensesController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateBusinessProfit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalcInputField(
                  label: 'RECEIVABLES (₹)',
                  controller: _bizReceivablesController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateBusinessProfit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildCalcInputField(
            label: 'PAYABLES TO VENDORS (₹)',
            controller: _bizPayablesController,
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onChanged: (_) => _calculateBusinessProfit(),
          ),
          const SizedBox(height: 16),

          // Results Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _resultRow('Gross Profit', currencyFormat.format(_bizGrossProfit), _bizGrossProfit >= 0 ? AppColors.successMint : AppColors.error),
                const SizedBox(height: 6),
                _resultRow('Gross Margin', '${_bizGrossMarginPct.toStringAsFixed(1)}%', textColor),
                const Divider(height: 16),
                _resultRow('Net Profit', currencyFormat.format(_bizNetProfit), _bizNetProfit >= 0 ? AppColors.brandBlue : AppColors.error, isBold: true),
                const SizedBox(height: 6),
                _resultRow('Net Margin', '${_bizNetMarginPct.toStringAsFixed(1)}%', textColor),
                const Divider(height: 16),
                _resultRow('Net Working Capital', currencyFormat.format(_bizWorkingCapital), _bizWorkingCapital >= 0 ? AppColors.successMint : AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. GST Calculator ───────────────────────────────────────────────────
  Widget _buildGstCalculator(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    const rates = [0.0, 5.0, 12.0, 18.0, 28.0];

    return AppCard(
      backgroundColor: cardBg,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GST Tax Calculator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 4),
          Text('Calculate intra-state (CGST+SGST) and inter-state (IGST) tax', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
          const SizedBox(height: 14),

          _buildCalcInputField(
            label: 'TRANSACTION AMOUNT (₹) *',
            controller: _gstAmountController,
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onChanged: (_) => _calculateGst(),
          ),
          const SizedBox(height: 12),

          // GST Rate Quick Chips
          Text('GST RATE (%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryTextColor)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: rates.map((r) {
                final isSel = _selectedGstRate == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${r.toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.white : textColor)),
                    selected: isSel,
                    selectedColor: AppColors.brandBlue,
                    backgroundColor: cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSel ? AppColors.brandBlue : borderColor)),
                    onSelected: (_) {
                      setState(() => _selectedGstRate = r);
                      _calculateGst();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Toggles: Exclusive/Inclusive & Intra/Inter-state
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(_isGstExclusive ? 'Add GST' : 'Remove GST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis)),
                      Switch(
                        value: _isGstExclusive,
                        activeColor: AppColors.brandBlue,
                        onChanged: (val) {
                          setState(() => _isGstExclusive = val);
                          _calculateGst();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(_isInterState ? 'IGST (Inter)' : 'CGST+SGST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis)),
                      Switch(
                        value: _isInterState,
                        activeColor: AppColors.brandBlue,
                        onChanged: (val) {
                          setState(() => _isInterState = val);
                          _calculateGst();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Result Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _resultRow('Base Amount', decimalCurrencyFormat.format(_gstBaseAmount), textColor),
                const SizedBox(height: 6),
                _resultRow('GST Amount (${_selectedGstRate.toInt()}%)', decimalCurrencyFormat.format(_gstTaxAmount), AppColors.brandBlue, isBold: true),
                if (!_isInterState) ...[
                  const SizedBox(height: 4),
                  _resultRow('  • CGST (${(_selectedGstRate / 2).toStringAsFixed(1)}%)', decimalCurrencyFormat.format(_cgstAmount), secondaryTextColor),
                  const SizedBox(height: 4),
                  _resultRow('  • SGST (${(_selectedGstRate / 2).toStringAsFixed(1)}%)', decimalCurrencyFormat.format(_sgstAmount), secondaryTextColor),
                ] else ...[
                  const SizedBox(height: 4),
                  _resultRow('  • IGST (${_selectedGstRate.toInt()}%)', decimalCurrencyFormat.format(_igstAmount), secondaryTextColor),
                ],
                const Divider(height: 16),
                _resultRow('Final Invoice Total', decimalCurrencyFormat.format(_gstFinalAmount), AppColors.successMint, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Loan EMI Calculator ───────────────────────────────────────────────
  Widget _buildLoanEmiCalculator(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return AppCard(
      backgroundColor: cardBg,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan EMI Calculator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 4),
          Text('Accurate monthly EMI and total interest amortization', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
          const SizedBox(height: 14),

          _buildCalcInputField(
            label: 'LOAN AMOUNT (₹) *',
            controller: _emiLoanAmountController,
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onChanged: (_) => _calculateEmi(),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildCalcInputField(
                  label: 'INTEREST RATE (% P.A.) *',
                  controller: _emiInterestRateController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateEmi(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalcInputField(
                  label: _emiTenureInYears ? 'TENURE (YEARS) *' : 'TENURE (MONTHS) *',
                  controller: _emiTenureController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateEmi(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tenure unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Tenure Unit: ', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
              InkWell(
                onTap: () {
                  setState(() {
                    _emiTenureInYears = !_emiTenureInYears;
                  });
                  _calculateEmi();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlueLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _emiTenureInYears ? 'Years (Switch to Months)' : 'Months (Switch to Years)',
                    style: const TextStyle(fontSize: 11, color: AppColors.brandBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Result Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _resultRow('Monthly EMI', decimalCurrencyFormat.format(_calculatedMonthlyEmi), AppColors.brandBlue, isBold: true),
                const SizedBox(height: 6),
                _resultRow('Total Interest Payable', decimalCurrencyFormat.format(_calculatedTotalInterest), textColor),
                const Divider(height: 16),
                _resultRow('Total Amount Payable', decimalCurrencyFormat.format(_calculatedTotalAmount), AppColors.successMint, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Markup & Margin Calculator ─────────────────────────────────────────
  Widget _buildMarkupMarginCalculator(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return AppCard(
      backgroundColor: cardBg,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Markup & Margin Calculator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 4),
          Text('Compute trade profit, markup percentage, and profit margin', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildCalcInputField(
                  label: 'COST PRICE (₹) *',
                  controller: _costPriceController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateMarkupMargin(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalcInputField(
                  label: 'SELLING PRICE (₹) *',
                  controller: _sellingPriceController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateMarkupMargin(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _resultRow('Profit Per Unit', decimalCurrencyFormat.format(_calculatedProfitAmount), _calculatedProfitAmount >= 0 ? AppColors.successMint : AppColors.error, isBold: true),
                const SizedBox(height: 6),
                _resultRow('Markup on Cost', '${_calculatedMarkupPct.toStringAsFixed(2)}%', AppColors.brandBlue),
                const SizedBox(height: 6),
                _resultRow('Gross Profit Margin', '${_calculatedMarginPct.toStringAsFixed(2)}%', textColor, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. Discount Calculator ───────────────────────────────────────────────
  Widget _buildDiscountCalculator(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return AppCard(
      backgroundColor: cardBg,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discount & Savings Calculator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 4),
          Text('Calculate promotional discounts and final payable amount', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildCalcInputField(
                  label: 'ORIGINAL PRICE (₹) *',
                  controller: _discountOriginalAmountController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateDiscount(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalcInputField(
                  label: 'DISCOUNT (%) *',
                  controller: _discountPctController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateDiscount(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _resultRow('Discount Amount Saved', decimalCurrencyFormat.format(_discountSavedAmount), AppColors.successMint),
                const Divider(height: 16),
                _resultRow('Final Discounted Price', decimalCurrencyFormat.format(_discountFinalAmount), AppColors.brandBlue, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. Income, Expense & Savings Calculator ──────────────────────────────
  Widget _buildIncomeExpenseCalculator(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return AppCard(
      backgroundColor: cardBg,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Income vs Expense Calculator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 4),
          Text('Calculate monthly disposable savings and savings percentage', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildCalcInputField(
                  label: 'MONTHLY INCOME (₹) *',
                  controller: _incomeController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateIncomeExpense(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalcInputField(
                  label: 'MONTHLY EXPENSES (₹) *',
                  controller: _expenseController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculateIncomeExpense(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _resultRow('Net Monthly Savings', decimalCurrencyFormat.format(_netSavings), _netSavings >= 0 ? AppColors.successMint : AppColors.error, isBold: true),
                const SizedBox(height: 6),
                _resultRow('Savings Rate', '${_savingsRatePct.toStringAsFixed(1)}%', _savingsRatePct >= 20 ? AppColors.brandBlue : textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. Percentage Calculator ─────────────────────────────────────────────
  Widget _buildPercentageCalculator(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return AppCard(
      backgroundColor: cardBg,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Percentage Math Calculator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 4),
          Text('Quickly calculate exact percentages of financial amounts', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildCalcInputField(
                  label: 'WHAT IS (%) *',
                  controller: _percentOfController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculatePercentage(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCalcInputField(
                  label: 'OF AMOUNT (₹) *',
                  controller: _percentBaseController,
                  isDark: isDark,
                  textColor: textColor,
                  borderColor: borderColor,
                  onChanged: (_) => _calculatePercentage(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calculated Value: ', style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
                Text(
                  decimalCurrencyFormat.format(_percentResult),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandBlue, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared UI Helpers ───────────────────────────────────────────────────
  Widget _buildCalcInputField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required Color textColor,
    required Color borderColor,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isDark ? AppColors.textSecondary : AppColors.brandTextSecondary, letterSpacing: 0.2),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13.5),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? AppColors.surfaceElevated : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _resultRow(String title, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? null : AppColors.brandTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14.5 : 13,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─── Calendar Action Banner (Fixes Broken Vertical Layout) ─────────────────
  Widget _buildCalendarActionBanner(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 340;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.brandBlueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: AppColors.brandBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendar Reminder Option',
                      style: TextStyle(
                        fontSize: isVeryNarrow ? 12.5 : 13.5,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a date on calendar to add reminder',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isVeryNarrow ? 8 : 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                label: Text(
                  isVeryNarrow ? 'Add' : 'Add Date',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedCalendarDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2035),
                    helpText: 'SELECT REMINDER DATE',
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _displayedMonth = DateTime(picked.year, picked.month);
                      _selectedCalendarDate = picked;
                      _showCalendarView = true;
                    });
                    _showAddEventDialog(context, isDark, initialDate: picked);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Interactive Calendar Grid Widget ─────────────────────────────────────
  Widget _buildInteractiveCalendar(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    List<Map<String, dynamic>> events,
  ) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOffset = (DateTime(year, month, 1).weekday - 1) % 7;

    // Map of day -> count of events
    final Map<int, int> dayEventCounts = {};
    for (final ev in events) {
      if (ev['rawDate'] is DateTime) {
        final dt = ev['rawDate'] as DateTime;
        if (dt.year == year && dt.month == month) {
          dayEventCounts[dt.day] = (dayEventCounts[dt.day] ?? 0) + 1;
        }
      }
    }

    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Header & Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.brandBlue, size: 18),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _displayedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        helpText: 'SELECT CALENDAR MONTH',
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _displayedMonth = DateTime(picked.year, picked.month);
                          _selectedCalendarDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_displayedMonth),
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_drop_down_rounded, color: secondaryTextColor, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: textColor,
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Previous Month',
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: textColor,
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Next Month',
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekdays row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) {
              return SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.05,
            ),
            itemCount: firstDayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }
              final day = index - firstDayOffset + 1;
              final date = DateTime(year, month, day);
              final isSelected = _selectedCalendarDate.year == year &&
                  _selectedCalendarDate.month == month &&
                  _selectedCalendarDate.day == day;
              final isToday = DateTime.now().year == year &&
                  DateTime.now().month == month &&
                  DateTime.now().day == day;
              final count = dayEventCounts[day] ?? 0;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCalendarDate = date;
                    if (count > 0) {
                      _filterDay = day;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandBlue
                        : (isToday ? AppColors.brandBlue.withValues(alpha: 0.12) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.brandBlue, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (count > 0 ? textColor : secondaryTextColor),
                          fontWeight: isSelected || count > 0 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.brandBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(height: 20),

          // Selected date info bar & "Add for Date" button (Responsive horizontal layout)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SELECTED DATE',
                        style: TextStyle(
                          fontSize: 9,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEE, dd MMM yyyy').format(_selectedCalendarDate),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_alarm_rounded, size: 15),
                  label: const Text(
                    'Add for Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => _showAddEventDialog(context, isDark, initialDate: _selectedCalendarDate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Upcoming Reminders List Header & Items ──────────────────────────────
  Widget _buildRemindersHeader(Color textColor, Color secondaryTextColor, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Scheduled Reminders ($count)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
            ),
            if (_filterDay != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _filterDay = null),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Text('Clear Filter', style: TextStyle(color: AppColors.brandBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.close_rounded, size: 12, color: AppColors.brandBlue),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          DateFormat('MMMM yyyy').format(_displayedMonth),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildRemindersList(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    List<Map<String, dynamic>> events,
  ) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_available_rounded, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text('No scheduled reminders for this date', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13.5)),
            const SizedBox(height: 4),
            Text('Tap "+ Add Reminder" above to set a financial alert', style: TextStyle(color: secondaryTextColor, fontSize: 11.5)),
          ],
        ),
      );
    }

    return Column(
      children: events.map((ev) {
        final id = ev['id'] as String? ?? '';
        final amt = ev['amount'] is num ? (ev['amount'] as num).toDouble() : 0.0;
        final type = ev['type'] as String? ?? 'General';
        final title = ev['title'] as String? ?? 'Reminder';
        final dateStr = ev['date'] as String? ?? '';
        final dayStr = ev['day'] as String? ?? '';

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppColors.error,
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            _deleteReminder(id);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              backgroundColor: cardBg,
              borderColor: borderColor,
              child: Row(
                children: [
                  // Date box
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dateStr.split(' ').isNotEmpty ? dateStr.split(' ')[0] : '01',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
                        ),
                        Text(
                          dateStr.split(' ').length > 1 ? dateStr.split(' ')[1] : 'Jan',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(dayStr, style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                            const SizedBox(width: 6),
                            Text('• $type', style: const TextStyle(fontSize: 11, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount / Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (amt > 0)
                        Text(
                          currencyFormat.format(amt),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textColor),
                        )
                      else
                        const StatusBadge(label: 'Due', variant: BadgeVariant.info),
                      const SizedBox(height: 3),
                      StatusBadge(
                        label: ev['badge'] as String? ?? 'Scheduled',
                        variant: (ev['badge'] == 'Urgent' || ev['badge'] == 'Mandatory')
                            ? BadgeVariant.error
                            : BadgeVariant.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalcTabOption {
  final CalculatorType type;
  final String label;
  final IconData icon;

  const _CalcTabOption(this.type, this.label, this.icon);
}
