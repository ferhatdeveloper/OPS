// Bu sınıf finans modülünde kullanılacak olan faturaları temsil eder
class Invoice {
  final int id;
  final String invoiceNumber;
  final DateTime date;
  final double amount;
  final double taxAmount;
  final String customerName;
  final String customerCode;
  final InvoiceStatus status;
  final List<InvoiceLine> lines;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.amount,
    required this.taxAmount,
    required this.customerName,
    required this.customerCode,
    required this.status,
    required this.lines,
  });

  // JSON dönüşümü
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      date: DateTime.parse(json['date']),
      amount: json['amount'],
      taxAmount: json['taxAmount'],
      customerName: json['customerName'],
      customerCode: json['customerCode'],
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      lines:
          (json['lines'] as List)
              .map((lineJson) => InvoiceLine.fromJson(lineJson))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'amount': amount,
      'taxAmount': taxAmount,
      'customerName': customerName,
      'customerCode': customerCode,
      'status': status.toString().split('.').last,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }
}

class InvoiceLine {
  final int id;
  final String itemCode;
  final String description;
  final double quantity;
  final String unitOfMeasure;
  final double unitPrice;
  final double lineAmount;
  final double taxRate;
  final double taxAmount;

  InvoiceLine({
    required this.id,
    required this.itemCode,
    required this.description,
    required this.quantity,
    required this.unitOfMeasure,
    required this.unitPrice,
    required this.lineAmount,
    required this.taxRate,
    required this.taxAmount,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      id: json['id'],
      itemCode: json['itemCode'],
      description: json['description'],
      quantity: json['quantity'],
      unitOfMeasure: json['unitOfMeasure'],
      unitPrice: json['unitPrice'],
      lineAmount: json['lineAmount'],
      taxRate: json['taxRate'],
      taxAmount: json['taxAmount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemCode': itemCode,
      'description': description,
      'quantity': quantity,
      'unitOfMeasure': unitOfMeasure,
      'unitPrice': unitPrice,
      'lineAmount': lineAmount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
    };
  }
}

enum InvoiceStatus {
  draft, // Taslak
  approved, // Onaylandı
  sent, // Gönderildi
  paid, // Ödendi
  cancelled, // İptal Edildi
  overdue, // Vadesi Geçmiş
}
