// Dosya Adı: customer_extract_movement.dart
// Açıklama: Cari ekstre dens satırı (borç/alacak hareketi)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template ExtractMovementFilter}
/// Cari hareket filtresi: tümü / borç / alacak.
/// {@endtemplate}
enum ExtractMovementFilter {
  /// Tümü
  all,

  /// Borç hareketleri
  debit,

  /// Alacak hareketleri
  credit,
}

/// {@template customer_extract_movement}
/// Cari hesap ekstresi tek hareket satırı.
///
/// Kullanım örneği:
/// ```dart
/// final m = CustomerExtractMovement(
///   id: 'mv-1',
///   customerId: 'C-100',
///   movementDate: DateTime(2026, 7, 1),
///   documentNo: 'FTR-001',
///   description: 'Satış faturası',
///   debit: 1500,
///   credit: 0,
/// );
/// ```
/// {@endtemplate}
class CustomerExtractMovement {
  /// [id]: Birincil anahtar
  final String id;

  /// [customerId]: Cari kart kimliği
  final String customerId;

  /// [movementDate]: Hareket tarihi
  final DateTime movementDate;

  /// [documentNo]: Fiş / belge no
  final String documentNo;

  /// [description]: Açıklama
  final String description;

  /// [debit]: Borç tutarı
  final double debit;

  /// [credit]: Alacak tutarı
  final double credit;

  /// {@macro customer_extract_movement}
  const CustomerExtractMovement({
    required this.id,
    required this.customerId,
    required this.movementDate,
    this.documentNo = '',
    this.description = '',
    this.debit = 0,
    this.credit = 0,
  });

  /// {@template customer_extract_movement_is_debit}
  /// Borç hareketi mi (debit > 0).
  /// {@endtemplate}
  bool get isDebit => debit > 0;

  /// {@template customer_extract_movement_is_credit}
  /// Alacak hareketi mi (credit > 0).
  /// {@endtemplate}
  bool get isCredit => credit > 0;

  /// {@template customer_extract_movement_from_map}
  /// SQLite satırından model üretir.
  ///
  /// Parametreler:
  /// - [map]: Kolon map'i
  ///
  /// Dönüş değeri:
  /// - [CustomerExtractMovement]: Parse edilen satır
  /// {@endtemplate}
  factory CustomerExtractMovement.fromMap(Map<String, dynamic> map) {
    return CustomerExtractMovement(
      id: (map['id'] ?? '').toString(),
      customerId: (map['customer_id'] ?? '').toString(),
      movementDate: _parseDate(map['movement_date']),
      documentNo: (map['document_no'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      debit: _toDouble(map['debit']),
      credit: _toDouble(map['credit']),
    );
  }

  /// {@template customer_extract_movement_to_map}
  /// SQLite insert/update map'i.
  ///
  /// Dönüş değeri:
  /// - [Map]: Kolon değerleri
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'customer_id': customerId,
      'movement_date': movementDate.toIso8601String(),
      'document_no': documentNo,
      'description': description,
      'debit': debit,
      'credit': credit,
      'created_at': now,
      'updated_at': now,
      'is_synced': 0,
      'is_deleted': 0,
    };
  }

  /// {@template customer_extract_movement_parse_date}
  /// Tarih alanını güvenli parse eder.
  /// {@endtemplate}
  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// {@template customer_extract_movement_to_double}
  /// Sayısal alanı double'a çevirir.
  /// {@endtemplate}
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }
}
