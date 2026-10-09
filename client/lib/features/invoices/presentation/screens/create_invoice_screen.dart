import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../../../customers/data/customers_repository.dart';
import '../../../customers/models/customer_model.dart';
import '../../../inventory/data/inventory_repository.dart';
import '../../../inventory/models/product_model.dart';
import '../../data/invoices_repository.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceItemData {
  String? productId;
  String description;
  String hsnCode;
  int quantity;
  double unitPrice;
  double gstRate;

  _CreateInvoiceItemData({
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.gstRate = 18.0,
  }) : hsnCode = '5208';

  double get taxableValue => quantity * unitPrice;
  double get gstAmount => (taxableValue * gstRate) / 100;
  double get total => taxableValue + gstAmount;
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final CustomersRepository _customersRepo = CustomersRepository();
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final InvoicesRepository _invoicesRepo = InvoicesRepository();
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  CustomerModel? _selectedCustomer;

  final List<_CreateInvoiceItemData> _items = [
    _CreateInvoiceItemData(description: '', quantity: 1, unitPrice: 0.0, gstRate: 18.0)
  ];

  bool _isIntraState = true;
  double _amountPaid = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrerequisites();
  }

  Future<void> _loadPrerequisites() async {
    try {
      final custsResult = await _customersRepo.getCustomers();
      final prods = await _inventoryRepo.getProducts();
      if (mounted) {
        setState(() {
          _customers = custsResult.customers;
          _products = prods;
          if (_customers.isNotEmpty) {
            _selectedCustomer = _customers.first;
          }
        });
      }
    } catch (_) {}
  }

  double get _taxableTotal => _items.fold(0.0, (sum, i) => sum + i.taxableValue);
  double get _cgstTotal => _isIntraState ? _items.fold(0.0, (sum, i) => sum + (i.gstAmount / 2)) : 0.0;
  double get _sgstTotal => _isIntraState ? _items.fold(0.0, (sum, i) => sum + (i.gstAmount / 2)) : 0.0;
  double get _igstTotal => !_isIntraState ? _items.fold(0.0, (sum, i) => sum + i.gstAmount) : 0.0;
  double get _grandTotal => _taxableTotal + _cgstTotal + _sgstTotal + _igstTotal;

  void _submitInvoice() async {
    if (_items.isEmpty || _items.any((i) => i.description.trim().isEmpty || i.unitPrice <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all item descriptions and positive unit prices.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = {
        'customerId': _selectedCustomer?.id ?? '',
        'customerName': _selectedCustomer?.name ?? 'Walk-in Customer',
        'customerGstin': _selectedCustomer?.gstin ?? '',
        'merchantStateCode': '36',
        'customerStateCode': _isIntraState ? '36' : '29',
        'invoiceType': 'GST',
        'amountPaid': _amountPaid,
        'items': _items.map((i) {
          return {
            'productId': i.productId,
            'description': i.description,
            'hsnCode': i.hsnCode,
            'quantity': i.quantity,
            'unitPrice': i.unitPrice,
            'taxableValue': i.taxableValue,
            'gstRate': i.gstRate,
            'total': i.total,
          };
        }).toList(),
      };

      final createdInvoice = await _invoicesRepo.createInvoice(body);
      DataSyncService().notifyDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Text('GST Invoice created & stock deducted successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );

        // Offer instant PDF download & preview
        await PdfInvoiceService.downloadAndOpenInvoicePdf(createdInvoice, context: context);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = (e is ApiException) ? e.message : 'Error creating invoice. Please verify your details.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text(msg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.grey : AppColors.brandTextSecondary;
    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0);
    final inputFill = isDark ? const Color(0xFF1B2030) : const Color(0xFFF8FAFC);
    final calcBg = isDark ? const Color(0xFF10141E) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New GST Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Customer Selector
            Text('SELECT CUSTOMER / CLIENT', style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CustomerModel>(
                  value: _selectedCustomer,
                  isExpanded: true,
                  dropdownColor: cardBg,
                  hint: Text('Select a Customer', style: TextStyle(color: secondaryTextColor)),
                  items: _customers.map((c) {
                    return DropdownMenuItem<CustomerModel>(
                      value: c,
                      child: Text('${c.name} (${c.phone})', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (c) => setState(() => _selectedCustomer = c),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Supply Type Switch (Intra-state CGST+SGST vs Inter-state IGST)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SUPPLY TYPE', style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        _isIntraState ? 'Intra-State (CGST 9% + SGST 9%)' : 'Inter-State (IGST 18%)',
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isIntraState,
                    activeColor: AppColors.primaryGreen,
                    onChanged: (val) => setState(() => _isIntraState = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Invoice Line Items Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('INVOICE ITEMS', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, color: AppColors.primaryGreen, size: 18),
                  label: const Text('Add Line', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      _items.add(_CreateInvoiceItemData(description: '', quantity: 1, unitPrice: 0.0, gstRate: 18.0));
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Item rows
            ..._items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#${idx + 1}', style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        // Quick Inventory Product Picker
                        if (_products.isNotEmpty)
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ProductModel>(
                                hint: const Text('Pick from Inventory...', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                                isDense: true,
                                dropdownColor: cardBg,
                                items: _products.map((p) {
                                  return DropdownMenuItem<ProductModel>(
                                    value: p,
                                    child: Text('${p.name} (Stock: ${p.currentStock})', style: TextStyle(color: textColor, fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (p) {
                                  if (p != null) {
                                    setState(() {
                                      item.productId = p.id;
                                      item.description = p.name;
                                      item.hsnCode = p.hsnCode;
                                      item.unitPrice = p.sellingPrice;
                                      item.gstRate = p.gstRate;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        if (_items.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 18),
                            onPressed: () => setState(() => _items.removeAt(idx)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      initialValue: item.description,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Item Description *',
                        labelStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                        filled: true,
                        fillColor: inputFill,
                        isDense: true,
                      ),
                      onChanged: (val) => item.description = val,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item.quantity.toString(),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Qty',
                              labelStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                              filled: true,
                              fillColor: inputFill,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setState(() => item.quantity = int.tryParse(val) ?? 1);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: item.unitPrice > 0 ? item.unitPrice.toString() : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: textColor, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Price (₹)',
                              labelStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                              filled: true,
                              fillColor: inputFill,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setState(() => item.unitPrice = double.tryParse(val) ?? 0.0);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<double>(
                            value: item.gstRate,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'GST %',
                              labelStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                              filled: true,
                              fillColor: inputFill,
                              isDense: true,
                            ),
                            dropdownColor: cardBg,
                            style: TextStyle(color: textColor, fontSize: 12),
                            items: [
                              DropdownMenuItem(value: 0.0, child: Text('0%', style: TextStyle(color: textColor))),
                              DropdownMenuItem(value: 5.0, child: Text('5%', style: TextStyle(color: textColor))),
                              DropdownMenuItem(value: 12.0, child: Text('12%', style: TextStyle(color: textColor))),
                              DropdownMenuItem(value: 18.0, child: Text('18%', style: TextStyle(color: textColor))),
                              DropdownMenuItem(value: 28.0, child: Text('28%', style: TextStyle(color: textColor))),
                            ],
                            onChanged: (val) => setState(() => item.gstRate = val ?? 18.0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: ₹${_currencyFormat.format(item.total)}',
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),

            // Live Calculation Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: calcBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildCalcRow('Taxable Value', '₹${_currencyFormat.format(_taxableTotal)}', textColor, secondaryTextColor),
                  if (_isIntraState) ...[
                    _buildCalcRow('CGST (Central Tax)', '₹${_currencyFormat.format(_cgstTotal)}', textColor, secondaryTextColor),
                    _buildCalcRow('SGST (State Tax)', '₹${_currencyFormat.format(_sgstTotal)}', textColor, secondaryTextColor),
                  ] else ...[
                    _buildCalcRow('IGST (Integrated Tax)', '₹${_currencyFormat.format(_igstTotal)}', textColor, secondaryTextColor),
                  ],
                  Divider(color: cardBorder, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GRAND TOTAL', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '₹${_currencyFormat.format(_grandTotal)}',
                        style: const TextStyle(color: AppColors.brandBlue, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitInvoice,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save & Generate PDF Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 13)),
          Text(value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
