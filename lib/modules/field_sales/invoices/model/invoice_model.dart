
// Dosya Adı: invoice_model.dart
// Açıklama: Fatura modeli (e-Fatura ETTN / GİB durum alanları dahil)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template invoice_model}
/// Yerel fatura kaydı (SQLite `invoices`).
///
/// Kullanım örneği:
/// ```dart
/// final inv = InvoiceModel(
///   id: '1',
///   customerId: 'c1',
///   invoiceDate: DateTime.now(),
///   totalAmount: 100,
///   ettn: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
///   gibStatus: 'SENT',
/// );
/// ```
/// {@endtemplate}
class InvoiceModel {
  /// [id]: Birincil anahtar
  final String id;

  /// [customerId]: Cari id
  final String customerId;

  /// [invoiceDate]: Fatura tarihi
  final DateTime invoiceDate;

  /// [totalAmount]: Genel toplam
  final double totalAmount;

  /// [status]: Yerel durum
  final String status;

  /// [notes]: Not
  final String? notes;

  /// [invoiceType]: Tip (Sales / Return / …)
  final String? invoiceType;

  /// [isEInvoice]: e-Belge mi
  final bool isEInvoice;

  /// [ettn]: GİB ETTN (UBL UUID)
  final String? ettn;

  /// [gibStatus]: GİB durum kodu (DRAFT/SENT/…)
  final String? gibStatus;

  /// [approvalStatus]: ONAY (0 bekliyor · 1 onaylı · 2 sync · 3 red · 4 hata)
  final int approvalStatus;

  /// [isSynced]: Senkron bayrağı
  final int isSynced;

  /// {@macro invoice_model}
  InvoiceModel({
    required this.id,
    required this.customerId,
    required this.invoiceDate,
    required this.totalAmount,
    this.status = 'Pending',
    this.notes,
    this.invoiceType,
    this.isEInvoice = true,
    this.ettn,
    this.gibStatus,
    this.approvalStatus = 0,
    this.isSynced = 0,
  });

  /// {@template invoice_model_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  InvoiceModel copyWith({
    String? id,
    String? customerId,
    DateTime? invoiceDate,
    double? totalAmount,
    String? status,
    String? notes,
    String? invoiceType,
    bool? isEInvoice,
    String? ettn,
    String? gibStatus,
    int? approvalStatus,
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
      ettn: ettn ?? this.ettn,
      gibStatus: gibStatus ?? this.gibStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// {@template invoice_model_to_map}
  /// SQLite map.
  /// {@endtemplate}
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
      'ettn': ettn,
      'gib_status': gibStatus,
      'approval_status': approvalStatus,
      'is_synced': isSynced,
    };
  }

  /// {@template invoice_model_from_map}
  /// Map → model.
  /// {@endtemplate}
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      invoiceDate: DateTime.parse(map['invoice_date'].toString()),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'Pending',
      notes: map['notes']?.toString(),
      invoiceType: map['invoice_type']?.toString(),
      isEInvoice: map['is_e_invoice'] == 1 || map['is_e_invoice'] == true,
      ettn: map['ettn']?.toString(),
      gibStatus: map['gib_status']?.toString(),
      approvalStatus: (map['approval_status'] as num?)?.toInt() ?? 0,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
    );
  }

  /// {@template invoice_model_is_purchase}
  /// Alış (purchase) kuyruk tipi mi?
  /// {@endtemplate}
  bool get isPurchaseSide {
    final t = (invoiceType ?? '').toLowerCase();
    return t.contains('purchase') ||
        t.contains('alis') ||
        t.contains('alış') ||
        t.contains('buy');
  }

  /// {@template invoice_model_is_pending_approval}
  /// Onay bekleyen / red / hata dens satırı mı? (ONAY öncelikli)
  /// {@endtemplate}
  bool get isPendingApproval {
    if (approvalStatus == 1 || approvalStatus == 2) return false;
    if (approvalStatus == 3 || approvalStatus == 4) return true;
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'approved') return false;
    return true;
  }

  /// {@template invoice_model_is_approved}
  /// Onaylı / aktarılmış dens satırı mı? (ONAY öncelikli)
  /// {@endtemplate}
  bool get isApproved {
    if (approvalStatus == 1 || approvalStatus == 2) return true;
    if (approvalStatus != 0) return false;
    final s = status.toLowerCase();
    return s == 'completed' || s == 'approved';
  }
}

/// {@template invoice_item_model}
/// Fatura kalemi (SQLite `invoice_items`).
/// {@endtemplate}
class InvoiceItemModel {
  /// [id]: Birincil anahtar
  final String id;

  /// [invoiceId]: Bağlı fatura id
  final String invoiceId;

  /// [productId]: Ürün id
  final String productId;

  /// [quantity]: Miktar
  final double quantity;

  /// [price]: Birim fiyat
  final double price;

  /// [vatAmount]: KDV tutarı
  final double vatAmount;

  /// [totalAmount]: Satır toplamı (KDV hariç net)
  final double totalAmount;

  /// [productName]: Gösterim adı (join)
  final String? productName;

  /// [unitName]: Satır birimi (Adet / Koli / …)
  final String? unitName;

  /// {@macro invoice_item_model}
  InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.vatAmount,
    required this.totalAmount,
    this.productName,
    this.unitName,
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
      'unit_name': unitName,
    };
  }

  factory InvoiceItemModel.fromMap(
    Map<String, dynamic> map, {
    String? productName,
  }) {
    return InvoiceItemModel(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      price: map['price'],
      vatAmount: map['vat_amount'],
      totalAmount: map['total_amount'],
      productName: productName,
      unitName: map['unit_name'] as String?,
    );
  }
}
