

class InvoiceModel {
  final String id;
  final String customerId;
  final DateTime invoiceDate;
  final double totalAmount;
  final String status;
  final String? notes;
  final String? invoiceType;
  final bool isEInvoice;
  final int isSynced;

  InvoiceModel({
    required this.id,
    required this.customerId,
    required this.invoiceDate,
    required this.totalAmount,
    this.status = 'Pending',
    this.notes,
    this.invoiceType,
    this.isEInvoice = true,
    this.isSynced = 0,
  });

  InvoiceModel copyWith({
    String? id,
    String? customerId,
    DateTime? invoiceDate,
    double? totalAmount,
    String? status,
    String? notes,
    String? invoiceType,
    bool? isEInvoice,
    int? isSynced,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      invoiceType: invoiceType ?? this.invoiceType,
      isEInvoice: isEInvoice ?? this.isEInvoice,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'invoice_date': invoiceDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'invoice_type': invoiceType,
      'is_e_invoice': isEInvoice ? 1 : 0,
      'is_synced': isSynced,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      customerId: map['customer_id'],
      invoiceDate: DateTime.parse(map['invoice_date']),
      totalAmount: map['total_amount'],
      status: map['status'],
      notes: map['notes'],
      invoiceType: map['invoice_type'],
      isEInvoice: map['is_e_invoice'] == 1,
      isSynced: map['is_synced'] ?? 0,
    );
  }
}

class InvoiceItemModel {
  final String id;
  final String invoiceId;
  final String productId;
  final double quantity;
  final double price;
  final double vatAmount;
  final double totalAmount;
  final String? productName;

  InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.vatAmount,
    required this.totalAmount,
    this.productName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'vat_amount': vatAmount,
      'total_amount': totalAmount,
    };
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map, {String? productName}) {
    return InvoiceItemModel(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      price: map['price'],
      vatAmount: map['vat_amount'],
      totalAmount: map['total_amount'],
      productName: productName,
    );
  }
}
