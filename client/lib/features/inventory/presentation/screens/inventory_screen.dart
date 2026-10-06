import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/inventory_repository.dart';
import '../../models/product_model.dart';
import 'add_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryRepository _repository = InventoryRepository();
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _products = [];
  double? _serverValuation;
  int? _serverStockQuantity;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _repository.getProducts(),
        _repository.getInventorySummary(),
      ]);

      if (mounted) {
        final products = results[0] as List<ProductModel>;
        final summary = results[1] as Map<String, dynamic>;

        final valNum = summary['total_inventory_valuation'] ?? summary['totalCostValuation'];
        final stockNum = summary['total_stock_quantity'] ?? summary['totalStockQuantity'];

        setState(() {
          _products = products;
          _serverValuation = valNum is num ? valNum.toDouble() : null;
          _serverStockQuantity = stockNum is num ? stockNum.toInt() : null;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = (err is ApiException)
              ? err.message
              : 'Unable to connect to server. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  double get _totalValuation {
    if (_serverValuation != null) return _serverValuation!;
    int totalPaise = 0;
    for (final p in _products) {
      final costPaise = (p.costPrice * 100).round();
      totalPaise += p.currentStock * costPaise;
    }
    return totalPaise / 100.0;
  }

  int get _totalStockCount {
    if (_serverStockQuantity != null) return _serverStockQuantity!;
    return _products.fold<int>(0, (sum, p) => sum + p.currentStock);
  }

  List<ProductModel> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.hsnCode.contains(query);
    }).toList();
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${product.name}" from your inventory? This will update your Total Inventory Valuation.',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _repository.deleteProduct(product.id);
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} removed from inventory.')),
                  );
                  _fetchProducts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete product. Please try again.')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Stock & Inventory', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          if (created == true) {
            _fetchProducts();
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchProducts,
          color: AppColors.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Summary Banner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFFFB300), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL INVENTORY VALUATION', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_currencyFormat.format(_totalValuation)}',
                            style: const TextStyle(color: Color(0xFFFFB300), fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2638),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_totalStockCount Units',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                decoration: InputDecoration(
                  hintText: 'Search product by name, SKU, HSN...',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Products List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _fetchProducts,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredProducts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
                        const SizedBox(height: 12),
                        Text('No Products in Inventory', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Tap + Add Product to track stock and catalog items.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ..._filteredProducts.map((p) {
                  final isLowStock = p.currentStock <= p.reorderLevel;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? (isDark ? const Color(0xFF33161C) : const Color(0xFFFEE2E2))
                                : (isDark ? const Color(0xFF13221E) : const Color(0xFFDCFCE7)),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            color: isLowStock ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('SKU: ${p.sku} • HSN: ${p.hsnCode}', style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                              const SizedBox(height: 2),
                              Text(
                                'Cost: ₹${_currencyFormat.format(p.costPrice)}  |  Sell: ₹${_currencyFormat.format(p.sellingPrice)} (${p.gstRate.toStringAsFixed(0)}% GST)',
                                style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Valuation: ₹${_currencyFormat.format(p.currentStock * p.costPrice)}',
                                style: const TextStyle(color: Color(0xFFFFB300), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${p.currentStock} ${p.unit}',
                              style: TextStyle(
                                color: isLowStock ? const Color(0xFFFF5252) : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowStock ? const Color(0xFF33161C) : const Color(0xFF13221E),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLowStock ? 'LOW STOCK' : 'IN STOCK',
                                style: TextStyle(
                                  color: isLowStock ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 18),
                              color: const Color(0xFF1F2638),
                              onSelected: (val) {
                                if (val == 'delete') {
                                  _confirmDeleteProduct(p);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 18),
                                      SizedBox(width: 8),
                                      Text('Delete Product', style: TextStyle(color: Color(0xFFFF5252), fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
