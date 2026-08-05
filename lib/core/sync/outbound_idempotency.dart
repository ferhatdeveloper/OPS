// Dosya Adı: outbound_idempotency.dart
// Açıklama: Logo push için kararlı fiş NUMBER — çift fatura engeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

/// {@template outbound_idempotency}
/// Aynı yerel belge yeniden gönderilince Logo’da aynı NUMBER kullanılır.
///
/// Ortak anahtar: [opsDocId] = `invoices.id` UUID = PostgREST `id`/`ops_doc_id`
/// (= yazılım ajanı [clientDocId]; aynı string).
///
/// **Logo bağlama (zorunlu):** [ficheNumber] → Tiger `NUMBER` + `findByNumber`
/// → `logo_ref` (LOGICALREF). SPECODE / AUXIL_CODE / docTracking kullanılmaz.
///
/// Retry’da NUMBER asla yenilenmez. Tiger push’ta [applyToRecord] `force: true`
/// ile ops_doc_id türevini yazar (payload’daki yabancı fiş no ezilir).
///
/// NUMBER üç DB’de aynı string (Logo `NUMBER` / PG `idempotency_code`).
///
/// Kullanım örneği:
/// ```dart
/// final id = OutboundIdempotency.opsDocId(invoiceId);
/// final n = OutboundIdempotency.ficheNumber('invoice', id);
/// // → OIABCDEF123456 (14 karakter, retry’da değişmez)
/// ```
/// {@endtemplate}
class OutboundIdempotency {
  OutboundIdempotency._();

  /// Logo’da “boş / otomatik” sayılan NUMBER değerleri.
  static const Set<String> autoNumberTokens = {'', '~', '-', '0', 'AUTO'};

  /// {@template outbound_idempotency_ops_doc_id}
  /// Yerel UUID → ortak `ops_doc_id` (trim; boşsa olduğu gibi).
  /// SQLite `invoices.id` / PostgREST / kuyruk `entity_id` ile birebir aynıdır.
  /// {@endtemplate}
  static String opsDocId(String entityId) => entityId.trim();

  /// {@template outbound_idempotency_client_doc_id}
  /// `client_doc_id` ≡ [opsDocId] — aynı UUID (alias).
  /// {@endtemplate}
  static String clientDocId(String entityId) => opsDocId(entityId);

  /// {@template outbound_idempotency_fiche_number}
  /// entityType + ops_doc_id → kararlı Logo NUMBER.
  ///
  /// Parametreler:
  /// - [entityType]: kuyruk tipi (invoice / order / …)
  /// - [entityId]: yerel SQLite id / ops_doc_id (UUID)
  ///
  /// Dönüş değeri:
  /// - [String]: 14 karakterlik sabit fiş no
  /// {@endtemplate}
  static String ficheNumber(String entityType, String entityId) {
    final id = opsDocId(entityId);
    final compact = id.replaceAll('-', '').toUpperCase();
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

  /// {@template outbound_idempotency_number_from_item}
  /// Logo list satırından fiş no okur (NUMBER / FICHENO).
  /// {@endtemplate}
  static String? numberFromLogoItem(Map<String, dynamic> item) {
    for (final key in const [
      'NUMBER',
      'number',
      'FICHENO',
      'fiche_no',
      'FicheNo',
    ]) {
      final v = item[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && !needsStableNumber(s)) return s;
    }
    return null;
  }

  /// {@template outbound_idempotency_item_matches}
  /// findByNumber eşleşmesi: aday NUMBER tam eşit mi?
  /// {@endtemplate}
  static bool itemMatchesNumber(
    Map<String, dynamic> item,
    String number,
  ) {
    final n = number.trim();
    if (needsStableNumber(n)) return false;
    final candidate = numberFromLogoItem(item);
    return candidate != null && candidate == n;
  }

  /// {@template outbound_idempotency_apply}
  /// restRecord / payload üzerine kararlı NUMBER yazar (yerinde).
  ///
  /// - [force] false: yalnızca boş/`~` ise yazar (yumuşak).
  /// - [force] true: ops_doc_id türevini her zaman yazar (Tiger push).
  /// {@endtemplate}
  static void applyToRecord(
    Map<String, dynamic> record, {
    required String entityType,
    required String entityId,
    bool force = false,
  }) {
    final current = record['NUMBER'] ?? record['number'];
    if (!force && !needsStableNumber(current)) return;
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
