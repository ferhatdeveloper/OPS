// Dosya Adı: whms_fifo_models.dart
// Açıklama: WHMS FIFO/FEFO kural, lot ve çıkış karar modelleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_fifo_outbound_decision}
/// Çıkış (sevk/yükleme) kapısı sonucu.
///
/// - [allow]: Uygun
/// - [warn]: Uyarı ile devam edilebilir
/// - [block]: Engelle
///
/// Kullanım örneği:
/// ```dart
/// final d = WhmsFifoOutboundDecision.warn;
/// ```
/// {@endtemplate}
enum WhmsFifoOutboundDecision {
  /// Uygun — engel yok
  allow,

  /// Uyarı (warn_days penceresi)
  warn,

  /// Engelle (SKT / fifo_days / FEFO)
  block,
}

/// {@template whms_fifo_message_keys}
/// l10n key sabitleri — kullanıcıya gösterilecek metin yok.
/// {@endtemplate}
abstract final class WhmsFifoMessageKeys {
  /// [allow]: Çıkış uygun
  static const String allow = 'whms.fifo.outbound_allow';

  /// [warnNearExpiry]: SKT warn_days içinde
  static const String warnNearExpiry = 'whms.fifo.warn_near_expiry';

  /// [blockExpired]: SKT geçmiş + fefo_enforce
  static const String blockExpired = 'whms.fifo.block_expired';

  /// [blockFifoDays]: Kalan ömür < fifo_days
  static const String blockFifoDays = 'whms.fifo.block_fifo_days';

  /// [blockFefoPreferred]: Daha erken SKT lot var
  static const String blockFefoPreferred = 'whms.fifo.block_fefo_preferred';

  /// [insufficient]: FEFO dilim miktarı yetersiz
  static const String insufficient = 'whms.fifo.pick_insufficient';
}

/// {@template whms_fifo_rule}
/// Ürün bazlı FIFO/FEFO kuralı (`whms_fifo_rules` satırı).
///
/// Kullanım örneği:
/// ```dart
/// final rule = WhmsFifoRule(
///   productCode: 'SKU1',
///   fifoDays: 30,
///   fefoEnforce: true,
///   warnDays: 14,
/// );
/// ```
/// {@endtemplate}
class WhmsFifoRule {
  /// [id]: Birincil anahtar (CRUD; motor için opsiyonel)
  final String id;

  /// [productCode]: Ürün kodu
  final String productCode;

  /// [fifoDays]: Minimum kalan SKT günü (DEYS ürün fifo gün)
  final int fifoDays;

  /// [fefoEnforce]: true → süresi geçmiş / FEFO ihlali engellenir
  final bool fefoEnforce;

  /// [warnDays]: Bu gün içinde kalan SKT → uyarı
  final int warnDays;

  /// [isActive]: Aktif kural
  final bool isActive;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro whms_fifo_rule}
  const WhmsFifoRule({
    this.id = '',
    required this.productCode,
    this.fifoDays = 0,
    this.fefoEnforce = true,
    this.warnDays = 0,
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template whms_fifo_rule_from_map}
  /// SQLite / PostgREST satırından model üretir.
  ///
  /// Parametreler:
  /// - [map]: `product_code`, `fifo_days`, `fefo_enforce`, `warn_days`
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoRule]: Parse edilmiş kural
  /// {@endtemplate}
  factory WhmsFifoRule.fromMap(Map<String, Object?> map) {
    final code = (map['product_code'] ?? map['productCode'] ?? '')
        .toString()
        .trim();
    final fifo = _asInt(map['fifo_days'] ?? map['fifoDays']);
    final warn = _asInt(map['warn_days'] ?? map['warnDays']);
    final enforceRaw = map['fefo_enforce'] ?? map['fefoEnforce'] ?? 1;
    final enforce = enforceRaw == true ||
        enforceRaw == 1 ||
        enforceRaw == '1' ||
        enforceRaw.toString().toLowerCase() == 'true';
    final activeRaw = map['is_active'] ?? map['isActive'] ?? 1;
    final active = activeRaw == true ||
        activeRaw == 1 ||
        activeRaw == '1' ||
        activeRaw.toString().toLowerCase() == 'true';
    final deletedRaw = map['is_deleted'] ?? map['isDeleted'] ?? 0;
    final deleted = deletedRaw == true ||
        deletedRaw == 1 ||
        deletedRaw == '1' ||
        deletedRaw.toString().toLowerCase() == 'true';

    return WhmsFifoRule(
      id: (map['id'] ?? '').toString().trim(),
      productCode: code,
      fifoDays: fifo < 0 ? 0 : fifo,
      fefoEnforce: enforce,
      warnDays: warn < 0 ? 0 : warn,
      isActive: active,
      isDeleted: deleted,
      createdAt: map['created_at']?.toString() ?? map['createdAt']?.toString(),
      updatedAt: map['updated_at']?.toString() ?? map['updatedAt']?.toString(),
    );
  }

  /// {@template whms_fifo_rule_to_map}
  /// Persist için map (snake_case kolonlar).
  ///
  /// Dönüş değeri:
  /// - [Map]: `whms_fifo_rules` alanları
  /// {@endtemplate}
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'product_code': productCode,
      'fifo_days': fifoDays,
      'fefo_enforce': fefoEnforce ? 1 : 0,
      'warn_days': warnDays,
      'is_active': isActive ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// {@template whms_fifo_rule_copy_with}
  /// CRUD güncelleme kopyası.
  /// {@endtemplate}
  WhmsFifoRule copyWith({
    String? id,
    String? productCode,
    int? fifoDays,
    bool? fefoEnforce,
    int? warnDays,
    bool? isActive,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return WhmsFifoRule(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      fifoDays: fifoDays ?? this.fifoDays,
      fefoEnforce: fefoEnforce ?? this.fefoEnforce,
      warnDays: warnDays ?? this.warnDays,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _asInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// {@template whms_fifo_batch}
/// Çıkış adayı lot satırı (`batch_expiry` benzeri sade model).
///
/// Kullanım örneği:
/// ```dart
/// final b = WhmsFifoBatch(
///   lot: 'L1',
///   expiry: DateTime(2026, 9, 1),
///   qty: 10,
/// );
/// ```
/// {@endtemplate}
class WhmsFifoBatch {
  /// [lot]: Lot / parti no
  final String lot;

  /// [expiry]: Son kullanma tarihi (yoksa null)
  final DateTime? expiry;

  /// [qty]: Kullanılabilir miktar
  final double qty;

  /// {@macro whms_fifo_batch}
  const WhmsFifoBatch({
    required this.lot,
    this.expiry,
    required this.qty,
  });
}

/// {@template whms_fifo_check_result}
/// [WhmsFifoRuleEngine.checkOutbound] sonucu.
///
/// Kullanım örneği:
/// ```dart
/// final r = WhmsFifoCheckResult(
///   decision: WhmsFifoOutboundDecision.allow,
///   messageKey: WhmsFifoMessageKeys.allow,
/// );
/// ```
/// {@endtemplate}
class WhmsFifoCheckResult {
  /// [decision]: allow | warn | block
  final WhmsFifoOutboundDecision decision;

  /// [messageKey]: l10n key (hardcoded UI metin yok)
  final String messageKey;

  /// [daysRemaining]: Önerilen SKT için kalan gün (yoksa null)
  final int? daysRemaining;

  /// {@macro whms_fifo_check_result}
  const WhmsFifoCheckResult({
    required this.decision,
    required this.messageKey,
    this.daysRemaining,
  });

  /// [isBlocked]: Engellendi mi?
  bool get isBlocked => decision == WhmsFifoOutboundDecision.block;

  /// [isWarned]: Uyarı mı?
  bool get isWarned => decision == WhmsFifoOutboundDecision.warn;
}

/// {@template whms_fifo_pick_slice}
/// FEFO tüketim dilimi (tek lot).
///
/// Kullanım örneği:
/// ```dart
/// final s = WhmsFifoPickSlice(batch: b, quantity: 2);
/// ```
/// {@endtemplate}
class WhmsFifoPickSlice {
  /// [batch]: Kaynak lot
  final WhmsFifoBatch batch;

  /// [quantity]: Bu lottan alınan miktar
  final double quantity;

  /// {@macro whms_fifo_pick_slice}
  const WhmsFifoPickSlice({
    required this.batch,
    required this.quantity,
  });
}

/// {@template whms_fifo_pick_plan}
/// [WhmsFifoRuleEngine.pickFefoBatches] tüketim planı.
/// {@endtemplate}
class WhmsFifoPickPlan {
  /// [slices]: SKT sırasıyla dilimler
  final List<WhmsFifoPickSlice> slices;

  /// [fulfilledQty]: Karşılanan miktar
  final double fulfilledQty;

  /// [shortfallQty]: Eksik kalan
  final double shortfallQty;

  /// [messageKey]: Durum l10n key
  final String messageKey;

  /// {@macro whms_fifo_pick_plan}
  const WhmsFifoPickPlan({
    required this.slices,
    required this.fulfilledQty,
    required this.shortfallQty,
    required this.messageKey,
  });

  /// [isComplete]: İhtiyaç tamamen karşılandı mı?
  bool get isComplete => shortfallQty <= 0;
}
