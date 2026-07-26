// Dosya Adı: collection_transferred_row.dart
// Açıklama: Transfer edilen tahsilat dens satırı (collections is_synced=1)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'finance_movement_type.dart';

/// {@template collection_transferred_row}
/// Transfer edilmiş tahsilat dens satırı (cari · tutar · tip · tarih).
///
/// Kullanım örneği:
/// ```dart
/// final rows = CollectionTransferredRow.fromCollectionMaps(maps);
/// print(rows.first.dateDisplay); // 25-07-2026
/// ```
/// {@endtemplate}
class CollectionTransferredRow {
  /// [id]: collections.id
  final String id;

  /// [customerName]: Cari ünvan (veya customer_id)
  final String customerName;

  /// [amountDisplay]: Biçimli tutar metni
  final String amountDisplay;

  /// [dateDisplay]: Tahsilat tarihi (DD-MM-YYYY)
  final String dateDisplay;

  /// [paymentTypeL10nKey]: Finans tip çeviri anahtarı
  final String paymentTypeL10nKey;

  /// [documentNo]: Evrak no (opsiyonel)
  final String? documentNo;

  /// [cashCode]: Kasa kodu (opsiyonel)
  final String? cashCode;

  /// {@macro collection_transferred_row}
  const CollectionTransferredRow({
    required this.id,
    required this.customerName,
    required this.amountDisplay,
    required this.dateDisplay,
    required this.paymentTypeL10nKey,
    this.documentNo,
    this.cashCode,
  });

  /// {@template fromCollectionMap}
  /// Tek collections satırını dens satıra çevirir.
  ///
  /// Parametreler:
  /// - [map]: SQLite collections (+ customer_name) satırı
  ///
  /// Dönüş değeri:
  /// - [CollectionTransferredRow]: Dens satır
  /// {@endtemplate}
  factory CollectionTransferredRow.fromCollectionMap(
    Map<String, dynamic> map,
  ) {
    final customerId = (map['customer_id'] ?? '').toString();
    final name = (map['customer_name'] ?? '').toString().trim();
    final amount = (map['amount'] as num?)?.toDouble() ?? 0;
    final currency = (map['currency_code'] ?? '').toString().trim();
    final suffix = currency.isEmpty ? 'TRY' : currency;
    final type = FinanceMovementType.fromStorage(
      map['payment_type']?.toString(),
    );
    final doc = (map['document_no'] ?? '').toString().trim();
    final cash = (map['cash_code'] ?? '').toString().trim();

    return CollectionTransferredRow(
      id: (map['id'] ?? '').toString(),
      customerName: name.isNotEmpty ? name : customerId,
      amountDisplay: '${amount.toStringAsFixed(2)} $suffix',
      dateDisplay: formatCollectionTransferredDate(
        (map['collection_date'] ?? '').toString(),
      ),
      paymentTypeL10nKey: type.titleL10nKey,
      documentNo: doc.isEmpty ? null : doc,
      cashCode: cash.isEmpty ? null : cash,
    );
  }

  /// {@template fromCollectionMaps}
  /// Yalnız `is_synced = 1` satırları tarih (yeni → eski) sıralar.
  ///
  /// Parametreler:
  /// - [maps]: SQLite collections satırları
  ///
  /// Dönüş değeri:
  /// - [List]: Transfer dens satırları
  /// {@endtemplate}
  static List<CollectionTransferredRow> fromCollectionMaps(
    List<Map<String, dynamic>> maps,
  ) {
    final synced = maps.where(_isSynced).toList();
    synced.sort((a, b) {
      final da = _parseSortDate((a['collection_date'] ?? '').toString());
      final db = _parseSortDate((b['collection_date'] ?? '').toString());
      return db.compareTo(da);
    });
    return synced
        .map(CollectionTransferredRow.fromCollectionMap)
        .toList(growable: false);
  }
}

/// {@template formatCollectionTransferredDate}
/// ISO veya ham tarihi MBT DD-MM-YYYY gösterimine çevirir.
///
/// Parametreler:
/// - [raw]: Ham tarih metni
///
/// Dönüş değeri:
/// - [String]: Görüntü tarihi
/// {@endtemplate}
String formatCollectionTransferredDate(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(t)) return t;
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
  if (iso != null) {
    return '${iso.group(3)}-${iso.group(2)}-${iso.group(1)}';
  }
  return t;
}

/// {@template collection_transferred_is_synced}
/// SQLite `is_synced` bayrağını bool'a çevirir.
/// {@endtemplate}
bool _isSynced(Map<String, dynamic> map) {
  final flag = map['is_synced'];
  if (flag is int) return flag == 1;
  if (flag is bool) return flag;
  return flag?.toString() == '1' ||
      flag?.toString().toLowerCase() == 'true';
}

DateTime _parseSortDate(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
  if (iso != null) {
    return DateTime(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }
  final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(t);
  if (dmy != null) {
    return DateTime(
      int.parse(dmy.group(3)!),
      int.parse(dmy.group(2)!),
      int.parse(dmy.group(1)!),
    );
  }
  return DateTime.tryParse(t) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
