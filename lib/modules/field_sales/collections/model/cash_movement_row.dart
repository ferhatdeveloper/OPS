// Dosya Adı: cash_movement_row.dart
// Açıklama: Kasa kart detay hareket satırı (Tarih / İşlem / Evrak No)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template cash_movement_row}
/// Kasa hareket dens satırı — MBT KASA detay tablosu.
///
/// Kullanım örneği:
/// ```dart
/// const row = CashMovementRow(
///   date: '27.07.2026',
///   operation: 'Giriş',
///   documentNo: 'EVR-001',
///   amount: 0,
/// );
/// ```
/// {@endtemplate}
class CashMovementRow {
  /// [date]: Tarih metni (gg.aa.yyyy)
  final String date;

  /// [operation]: İşlem tipi (Giriş / Çıkış)
  final String operation;

  /// [documentNo]: Evrak No
  final String documentNo;

  /// [amount]: Tutar (stub 0)
  final double amount;

  /// {@macro cash_movement_row}
  const CashMovementRow({
    required this.date,
    required this.operation,
    required this.documentNo,
    this.amount = 0,
  });

  /// Yer tutucu boş liste (canlı veri yokken).
  static const List<CashMovementRow> emptyStub = <CashMovementRow>[];

  /// {@template cash_movement_row_from_collection_map}
  /// `collections` satır map → dens hareket.
  /// {@endtemplate}
  factory CashMovementRow.fromCollectionMap(Map<String, Object?> map) {
    final rawDate = (map['event_date'] ?? map['collection_date'] ?? '')
        .toString()
        .trim();
    final payment = (map['payment_type'] ?? '').toString().trim();
    final doc = (map['document_no'] ?? map['id'] ?? '').toString().trim();
    final amount = (map['amount'] as num?)?.toDouble() ?? 0;
    return CashMovementRow(
      date: _fmtDate(rawDate),
      operation: payment.isEmpty ? '—' : payment,
      documentNo: doc.isEmpty ? '—' : doc,
      amount: amount,
    );
  }

  static String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) {
      if (raw.length >= 10) return raw.substring(0, 10);
      return raw;
    }
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }
}
