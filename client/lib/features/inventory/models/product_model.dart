class ProductModel {
  final String id;
  final String sku;
  final String name;
  final String category;
  final String unit;
  final String hsnCode;
  final double costPrice;
  final double sellingPrice;
  final double gstRate;
  final int reorderLevel;
  final int currentStock;
  final String status;

  ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    this.category = 'General',
    this.unit = 'Pcs',
    this.hsnCode = '9999',
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.gstRate = 18.0,
    this.reorderLevel = 10,
    this.currentStock = 0,
    this.status = 'ACTIVE',
  });

  double get inventoryValuation => currentStock * costPrice;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      unit: json['unit']?.toString() ?? 'Pcs',
      hsnCode: json['hsnCode']?.toString() ?? json['hsn_code']?.toString() ?? '9999',
      costPrice: double.tryParse(json['costPrice']?.toString() ?? json['cost_price']?.toString() ?? '') ?? 0.0,
      sellingPrice: double.tryParse(json['sellingPrice']?.toString() ?? json['selling_price']?.toString() ?? '') ?? 0.0,
      gstRate: double.tryParse(json['gstRate']?.toString() ?? json['gst_rate']?.toString() ?? '') ?? 18.0,
      reorderLevel: int.tryParse(json['reorderLevel']?.toString() ?? json['reorder_level']?.toString() ?? '') ?? 10,
      currentStock: int.tryParse(json['currentStock']?.toString() ??
              json['current_stock']?.toString() ??
              json['stockQuantity']?.toString() ??
              json['stock_quantity']?.toString() ??
              json['openingStock']?.toString() ??
              json['opening_stock']?.toString() ??
              '') ??
          0,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      'unit': unit,
      'hsnCode': hsnCode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'gstRate': gstRate,
      'reorderLevel': reorderLevel,
      'currentStock': currentStock,
      'status': status,
    };
  }
}
