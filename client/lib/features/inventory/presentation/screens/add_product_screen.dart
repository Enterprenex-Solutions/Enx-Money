import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/inventory_repository.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final InventoryRepository _repository = InventoryRepository();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _hsnController = TextEditingController(text: '5208');
  final _unitController = TextEditingController(text: 'Pcs');
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _openingStockController = TextEditingController(text: '0');
  final _reorderLevelController = TextEditingController(text: '10');

  double _selectedGstRate = 18.0;
  bool _isLoading = false;

  void _submitProduct() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final cost = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
      final selling = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
      final stock = int.tryParse(_openingStockController.text.trim()) ?? 0;
      final reorder = int.tryParse(_reorderLevelController.text.trim()) ?? 10;

      final body = {
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim().toUpperCase(),
        'hsnCode': _hsnController.text.trim(),
        'hsn_code': _hsnController.text.trim(),
        'unit': _unitController.text.trim(),
        'costPrice': cost,
        'cost_price': cost,
        'sellingPrice': selling,
        'selling_price': selling,
        'gstRate': _selectedGstRate,
        'gst_rate': _selectedGstRate,
        'currentStock': stock,
        'current_stock': stock,
        'stockQuantity': stock,
        'stock_quantity': stock,
        'openingStock': stock,
        'opening_stock': stock,
        'reorderLevel': reorder,
        'reorder_level': reorder,
      };

      await _repository.createProduct(body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Text('Product added to inventory successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product to Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  labelText: 'PRODUCT / ITEM NAME *',
                  hintText: 'e.g. Cotton Fabric Rolls (100m)',
                  prefixIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primaryGreen),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter product name' : null,
              ),

              const SizedBox(height: 14),

              // SKU & Unit Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'SKU CODE *',
                        hintText: 'SKU-COT-01',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter SKU' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'UNIT (Pcs, Kg, Box)',
                        hintText: 'Pcs',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Cost Price & Selling Price Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'COST PRICE (₹)',
                        hintText: '0.00',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'SELLING PRICE (₹) *',
                        hintText: '0.00',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter selling price' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // GST Slab Dropdown & HSN Code
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: _selectedGstRate,
                      decoration: const InputDecoration(labelText: 'GST TAX SLAB'),
                      dropdownColor: isDark ? const Color(0xFF141824) : Colors.white,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      items: [
                        DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)', style: TextStyle(color: textColor))),
                        DropdownMenuItem(value: 5.0, child: Text('5% GST', style: TextStyle(color: textColor))),
                        DropdownMenuItem(value: 12.0, child: Text('12% GST', style: TextStyle(color: textColor))),
                        DropdownMenuItem(value: 18.0, child: Text('18% GST', style: TextStyle(color: textColor))),
                        DropdownMenuItem(value: 28.0, child: Text('28% GST', style: TextStyle(color: textColor))),
                      ],
                      onChanged: (val) => setState(() => _selectedGstRate = val ?? 18.0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _hsnController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'HSN / SAC CODE',
                        hintText: '5208',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Opening Stock & Reorder Threshold
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openingStockController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'OPENING STOCK QTY',
                        hintText: '0',
                        prefixIcon: Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderLevelController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'REORDER ALERT QTY',
                        hintText: '10',
                        prefixIcon: Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submitProduct,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save to Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
