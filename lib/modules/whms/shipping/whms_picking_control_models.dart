// Dosya Adı: whms_picking_control_models.dart
// Açıklama: Sevkiyat son kontrol (picking control) karar / varyans modelleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_picking_control_decision}
/// Planlanan vs fiili karşılaştırma sonucu.
///
/// - [allow]: Eşleşme
/// - [warn]: Uyarı + onay ile devam edilebilir
/// - [block]: Engelle
///
/// Kullanım örneği:
/// ```dart
/// final d = WhmsPickingControlDecision.warn;
/// ```
/// {@endtemplate}
enum WhmsPickingControlDecision {
  /// Uygun — fark yok
  allow,

  /// Uyarı (onay gerekir)
  warn,

  /// Engelle (eksik / fazla / yanlış)
  block,
}

/// {@template whms_picking_variance_kind}
/// Satır fark türü.
/// {@endtemplate}
enum WhmsPickingVarianceKind {
  /// Planlanan = fiili
  match,

  /// Eksik (fiili < planlanan)
  short,

  /// Fazla (fiili > planlanan)
  over,

  /// Yanlış ürün (plandda yok)
  wrong,
}

/// {@template whms_picking_control_policy}
/// Fark → karar politikası.
///
/// Kullanım örneği:
/// ```dart
/// const p = WhmsPickingControlPolicy.standard;
/// ```
/// {@endtemplate}
enum WhmsPickingControlPolicy {
  /// Eksik + yanlış → block; fazla → warn
  standard,

  /// Tüm farklar block
  strict,

  /// Tüm farklar warn (onay ile geç)
  warnAll,
}

/// {@template whms_picking_message_keys}
/// l10n key sabitleri — hardcoded UI metin yok.
/// {@endtemplate}
abstract final class WhmsPickingMessageKeys {
  /// [allow]: Eşleşme
  static const String allow = 'whms.picking.allow';

  /// [blockShort]: Eksik — engel
  static const String blockShort = 'whms.picking.block_short';

  /// [blockOver]: Fazla — engel
  static const String blockOver = 'whms.picking.block_over';

  /// [blockWrong]: Yanlış ürün — engel
  static const String blockWrong = 'whms.picking.block_wrong';

  /// [warnShort]: Eksik — uyarı
  static const String warnShort = 'whms.picking.warn_short';

  /// [warnOver]: Fazla — uyarı
  static const String warnOver = 'whms.picking.warn_over';

  /// [warnWrong]: Yanlış ürün — uyarı
  static const String warnWrong = 'whms.picking.warn_wrong';

  /// [mismatch]: Genel fark özeti
  static const String mismatch = 'whms.picking.mismatch';
}

/// {@template whms_picking_line_variance}
/// Tek ürün anahtarı için planlanan / fiili fark.
///
/// Kullanım örneği:
/// ```dart
/// const v = WhmsPickingLineVariance(
///   productKey: 'SKU-1',
///   plannedQty: 10,
///   actualQty: 8,
///   kind: WhmsPickingVarianceKind.short,
///   decision: WhmsPickingControlDecision.block,
///   messageKey: WhmsPickingMessageKeys.blockShort,
/// );
/// ```
/// {@endtemplate}
class WhmsPickingLineVariance {
  /// [productKey]: productId veya productCode
  final String productKey;

  /// [plannedQty]: Planlanan miktar
  final double plannedQty;

  /// [actualQty]: Fiili / okutulan miktar
  final double actualQty;

  /// [kind]: short | over | wrong | match
  final WhmsPickingVarianceKind kind;

  /// [decision]: Satır kararı
  final WhmsPickingControlDecision decision;

  /// [messageKey]: l10n key
  final String messageKey;

  /// {@macro whms_picking_line_variance}
  const WhmsPickingLineVariance({
    required this.productKey,
    required this.plannedQty,
    required this.actualQty,
    required this.kind,
    required this.decision,
    required this.messageKey,
  });

  /// [deltaQty]: fiili − planlanan
  double get deltaQty => actualQty - plannedQty;
}

/// {@template whms_picking_control_result}
/// [WhmsPickingControlEngine.compare] özeti.
///
/// Kullanım örneği:
/// ```dart
/// final r = WhmsPickingControlResult(
///   decision: WhmsPickingControlDecision.allow,
///   messageKey: WhmsPickingMessageKeys.allow,
///   variances: const [],
/// );
/// ```
/// {@endtemplate}
class WhmsPickingControlResult {
  /// [decision]: allow | warn | block
  final WhmsPickingControlDecision decision;

  /// [messageKey]: Birincil l10n key
  final String messageKey;

  /// [variances]: Satır farkları (match hariç veya tümü)
  final List<WhmsPickingLineVariance> variances;

  /// {@macro whms_picking_control_result}
  const WhmsPickingControlResult({
    required this.decision,
    required this.messageKey,
    this.variances = const <WhmsPickingLineVariance>[],
  });

  /// [isBlocked]: Engellendi mi?
  bool get isBlocked => decision == WhmsPickingControlDecision.block;

  /// [isWarned]: Uyarı mı?
  bool get isWarned => decision == WhmsPickingControlDecision.warn;

  /// [isAllowed]: Tam eşleşme mi?
  bool get isAllowed => decision == WhmsPickingControlDecision.allow;

  /// [mismatches]: match olmayan satırlar
  List<WhmsPickingLineVariance> get mismatches => variances
      .where((v) => v.kind != WhmsPickingVarianceKind.match)
      .toList(growable: false);
}
