// Dosya Adı: outbound_idempotency.dart
// Açıklama: Logo push için kararlı fiş NUMBER — çift fatura engeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template outbound_idempotency}
/// Aynı yerel belge yeniden gönderilince Logo’da aynı NUMBER kullanılır.
///
/// Kullanım örneği:
/// ```dart
/// final n = OutboundIdempotency.ficheNumber('invoice', entityId);
/// // → OIABCDEF123456 (14 karakter, retry’da değişmez)
/// ```
/// {@endtemplate}
class OutboundIdempotency {
  OutboundIdempotency._();

  /// Logo’da “boş / otomatik” sayılan NUMBER değerleri.
  static const Set<String> autoNumberTokens = {'', '~', '-', '0', 'AUTO'};

  /// {@template outbound_idempotency_fiche_number}
  /// entityType + entityId → kararlı Logo NUMBER.
  ///
  /// Parametreler:
  /// - [entityType]: kuyruk tipi (invoice / order / …)
  /// - [entityId]: yerel SQLite id (UUID)
  ///
  /// Dönüş değeri:
  /// - [String]: 14 karakterlik sabit fiş no
  /// {@endtemplate}
  static String ficheNumber(String entityType, String entityId) {
    final compact = entityId.replaceAll('-', '').toUpperCase();
    final tail = compact.length >= 12
        ? compact.substring(0, 12)
        : compact.padRight(12, '0');
    return '${_prefix(entityType)}$tail';
  }

  /// {@template outbound_idempotency_needs_stable}
  /// Mevcut NUMBER boş veya `~` ise kararlı değer uygulanmalı.
  /// {@endtemplate}
  static bool needsStableNumber(Object? current) {
    final s = (current ?? '').toString().trim().toUpperCase();
    return autoNumberTokens.contains(s);
  }

  /// {@template outbound_idempotency_apply}
  /// restRecord / payload üzerine kararlı NUMBER yazar (yerinde).
  /// Zaten anlamlı NUMBER varsa dokunmaz.
  /// {@endtemplate}
  static void applyToRecord(
    Map<String, dynamic> record, {
    required String entityType,
    required String entityId,
  }) {
    final current = record['NUMBER'] ?? record['number'];
    if (!needsStableNumber(current)) return;
    final n = ficheNumber(entityType, entityId);
    record['NUMBER'] = n;
    record['number'] = n;
  }

  static String _prefix(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'invoice':
      case 'invoices':
        return 'OI';
      case 'order':
      case 'orders':
      case 'supplier_purchase_request':
      case 'supplier_purchase_requests':
      case 'supply_request':
        return 'OO';
      case 'dispatch':
      case 'dispatches':
      case 'waybill':
      case 'waybills':
        return 'OD';
      case 'collection':
      case 'collections':
        return 'OC';
      default:
        return 'OX';
    }
  }
}
