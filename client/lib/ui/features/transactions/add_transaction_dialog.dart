import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/repositories/transaction_repository.dart';

class AddTransactionDialog extends StatefulWidget {
  final TransactionItem? initialItem;

  const AddTransactionDialog({super.key, this.initialItem});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late TransactionType _type;
  late ProfileType _profileType;
  late String _category;
  late DateTime _date;
  late PaymentMode _paymentMode;
  late double _gstRate;
  String? _invoiceNumber;
  String? _notes;
  String? _selectedEnterpriseId;
  String? _selectedCustomerId;
  String? _selectedSupplierId;

  final List<String> _businessCategories = [
    'Software Sales',
    'Consulting',
    'Infrastructure',
    'Office Expenses',
    'Invoiced Revenue',
    'Hardware Purchase',
    'Marketing & Ads',
    'Loan / EMI',
    'Vendor Payment',
  ];

  final List<String> _personalCategories = [
    'Salary',
    'Groceries',
    'Automobile EMI',
    'Utilities',
    'Dining & Outing',
    'Investments',
    'Shopping',
    'Medical & Health',
    'Subscriptions',
  ];

  @override
  void initState() {
    super.initState();
    final repo = context.read<TransactionRepository>();
    final item = widget.initialItem;

    _title = item?.title ?? '';
    _amount = item?.amount ?? 0.0;
    _type = item?.type ?? TransactionType.expense;
    _profileType = item?.profileType ?? repo.currentProfile;
    _category = item?.category ?? (_profileType == ProfileType.business ? 'Software Sales' : 'Groceries');
    _date = item?.date ?? DateTime.now();
    _paymentMode = item?.paymentMode ?? PaymentMode.upi;
    _gstRate = item?.gstRate ?? (_profileType == ProfileType.business ? 18.0 : 0.0);
    _invoiceNumber = item?.invoiceNumber;
    _notes = item?.notes;
    _selectedEnterpriseId = item?.enterpriseId;
    _selectedCustomerId = item?.customerId;
    _selectedSupplierId = item?.supplierId;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final categories = _profileType == ProfileType.business ? _businessCategories : _personalCategories;
    if (!categories.contains(_category)) {
      _category = categories.first;
    }

    return AlertDialog(
      title: Text(widget.initialItem == null ? 'New Transaction' : 'Edit Transaction'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Type Selector
              SegmentedButton<ProfileType>(
                segments: const [
                  ButtonSegment(value: ProfileType.business, label: Text('Business')),
                  ButtonSegment(value: ProfileType.personal, label: Text('Personal')),
                ],
                selected: {_profileType},
                onSelectionChanged: (set) {
                  setState(() {
                    _profileType = set.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Title / Description *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
                onSaved: (val) => _title = val!.trim(),
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                initialValue: _amount == 0.0 ? '' : _amount.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (INR ₹) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  if (double.tryParse(val.trim()) == null) return 'Invalid amount';
                  return null;
                },
                onSaved: (val) => _amount = double.parse(val!.trim()),
              ),
              const SizedBox(height: 12),

              // Type
              DropdownButtonFormField<TransactionType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: TransactionType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),

              // Linked Customer (If Business Profile)
              if (_profileType == ProfileType.business && repo.customers.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedCustomerId,
                  decoration: const InputDecoration(
                    labelText: 'Link Customer (Optional)',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('None / General')),
                    ...repo.customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedCustomerId = val),
                ),
                const SizedBox(height: 12),
              ],

              // Linked Supplier (If Business Profile)
              if (_profileType == ProfileType.business && repo.suppliers.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedSupplierId,
                  decoration: const InputDecoration(
                    labelText: 'Link Supplier / Vendor (Optional)',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('None / General')),
                    ...repo.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedSupplierId = val),
                ),
                const SizedBox(height: 12),
              ],

              // Payment Mode
              DropdownButtonFormField<PaymentMode>(
                initialValue: _paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: PaymentMode.values.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMode = val);
                },
              ),
              const SizedBox(height: 12),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_date)),
                ),
              ),
              const SizedBox(height: 12),

              // GST Rate (If Business)
              if (_profileType == ProfileType.business) ...[
                TextFormField(
                  initialValue: _gstRate.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'GST Rate % (e.g. 18)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  onSaved: (val) => _gstRate = double.tryParse(val ?? '0') ?? 0.0,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _invoiceNumber,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Number (Optional)',
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                  onSaved: (val) => _invoiceNumber = val?.trim(),
                ),
                const SizedBox(height: 12),
              ],

              // Notes
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes / Remarks (Optional)',
                  prefixIcon: Icon(Icons.note),
                ),
                onSaved: (val) => _notes = val?.trim(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final repo = context.read<TransactionRepository>();

              final newItem = TransactionItem(
                id: widget.initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: _title,
                amount: _amount,
                type: _type,
                profileType: _profileType,
                category: _category,
                date: _date,
                paymentMode: _paymentMode,
                notes: _notes,
                gstRate: _gstRate,
                invoiceNumber: _invoiceNumber,
                enterpriseId: _selectedEnterpriseId,
                customerId: _selectedCustomerId,
                supplierId: _selectedSupplierId,
              );

              if (widget.initialItem == null) {
                repo.addTransaction(newItem);
              } else {
                repo.updateTransaction(newItem);
              }
              Navigator.pop(context);
            }
          },
          child: const Text('Save Entry'),
        ),
      ],
    );
  }
}
