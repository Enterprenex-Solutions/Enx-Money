class InvoiceItemModel {
  final String id;
  final String? productId;
  final String description;
  final String hsnCode;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double taxableValue;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double total;

  InvoiceItemModel({
    required this.id,
    this.productId,
    required this.description,
    this.hsnCode = '9999',
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.taxableValue,
    this.gstRate = 18.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    required this.total,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? json['product_id']?.toString(),
      description: json['description']?.toString() ?? 'Item',
      hsnCode: json['hsnCode']?.toString() ?? json['hsn_code']?.toString() ?? '9999',
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1,
      unitPrice: (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : (json['unit_price'] is num ? (json['unit_price'] as num).toDouble() : 0.0),
      discount: (json['discount'] is num) ? (json['discount'] as num).toDouble() : 0.0,
      taxableValue: (json['taxableValue'] is num) ? (json['taxableValue'] as num).toDouble() : (json['taxable_value'] is num ? (json['taxable_value'] as num).toDouble() : 0.0),
      gstRate: (json['gstRate'] is num) ? (json['gstRate'] as num).toDouble() : (json['gst_rate'] is num ? (json['gst_rate'] as num).toDouble() : 18.0),
      cgstAmount: (json['cgstAmount'] is num) ? (json['cgstAmount'] as num).toDouble() : (json['cgst_amount'] is num ? (json['cgst_amount'] as num).toDouble() : 0.0),
      sgstAmount: (json['sgstAmount'] is num) ? (json['sgstAmount'] as num).toDouble() : (json['sgst_amount'] is num ? (json['sgst_amount'] as num).toDouble() : 0.0),
      igstAmount: (json['igstAmount'] is num) ? (json['igstAmount'] as num).toDouble() : (json['igst_amount'] is num ? (json['igst_amount'] as num).toDouble() : 0.0),
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'description': description,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'taxableValue': taxableValue,
      'gstRate': gstRate,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'total': total,
    };
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String invoiceType;
  final String invoiceDate;
  final String customerId;
  final String customerName;
  final String customerGstin;
  final bool isIntraState;
  final List<InvoiceItemModel> items;
  final double taxableTotal;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double grandTotal;
  final String paymentStatus;
  final double amountPaid;
  final double balanceDue;
  final String notes;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.invoiceType = 'GST',
    required this.invoiceDate,
    required this.customerId,
    required this.customerName,
    this.customerGstin = '',
    this.isIntraState = true,
    required this.items,
    required this.taxableTotal,
    this.cgstTotal = 0.0,
    this.sgstTotal = 0.0,
    this.igstTotal = 0.0,
    required this.grandTotal,
    this.paymentStatus = 'UNPAID',
    this.amountPaid = 0.0,
    this.balanceDue = 0.0,
    this.notes = '',
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<InvoiceItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems.map((i) => InvoiceItemModel.fromJson(i as Map<String, dynamic>)).toList();
    }

    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString() ?? '',
      invoiceType: json['invoiceType']?.toString() ?? json['invoice_type']?.toString() ?? 'GST',
      invoiceDate: json['invoiceDate']?.toString() ?? json['invoice_date']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? 'Customer',
      customerGstin: json['customerGstin']?.toString() ?? json['customer_gstin']?.toString() ?? '',
      isIntraState: json['isIntraState'] as bool? ?? json['is_intra_state'] as bool? ?? true,
      items: itemsList,
      taxableTotal: (json['taxableTotal'] is num) ? (json['taxableTotal'] as num).toDouble() : (json['taxable_total'] is num ? (json['taxable_total'] as num).toDouble() : 0.0),
      cgstTotal: (json['cgstTotal'] is num) ? (json['cgstTotal'] as num).toDouble() : (json['cgst_total'] is num ? (json['cgst_total'] as num).toDouble() : 0.0),
      sgstTotal: (json['sgstTotal'] is num) ? (json['sgstTotal'] as num).toDouble() : (json['sgst_total'] is num ? (json['sgst_total'] as num).toDouble() : 0.0),
      igstTotal: (json['igstTotal'] is num) ? (json['igstTotal'] as num).toDouble() : (json['igst_total'] is num ? (json['igst_total'] as num).toDouble() : 0.0),
      grandTotal: (json['grandTotal'] is num) ? (json['grandTotal'] as num).toDouble() : (json['grand_total'] is num ? (json['grand_total'] as num).toDouble() : 0.0),
      paymentStatus: json['paymentStatus']?.toString() ?? json['payment_status']?.toString() ?? 'UNPAID',
      amountPaid: (json['amountPaid'] is num) ? (json['amountPaid'] as num).toDouble() : (json['amount_paid'] is num ? (json['amount_paid'] as num).toDouble() : 0.0),
      balanceDue: (json['balanceDue'] is num) ? (json['balanceDue'] as num).toDouble() : (json['balance_due'] is num ? (json['balance_due'] as num).toDouble() : 0.0),
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceType': invoiceType,
      'invoiceDate': invoiceDate,
      'customerId': customerId,
      'customerName': customerName,
      'customerGstin': customerGstin,
      'isIntraState': isIntraState,
      'items': items.map((i) => i.toJson()).toList(),
      'taxableTotal': taxableTotal,
      'cgstTotal': cgstTotal,
      'sgstTotal': sgstTotal,
      'igstTotal': igstTotal,
      'grandTotal': grandTotal,
      'paymentStatus': paymentStatus,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'notes': notes,
    };
  }
}
