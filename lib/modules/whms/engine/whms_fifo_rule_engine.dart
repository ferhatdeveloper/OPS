// Dosya Adı: whms_fifo_rule_engine.dart
// Açıklama: FIFO/FEFO çıkış kapısı ve lot tüketim motoru (pure Dart)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'whms_fifo_models.dart';

export 'whms_fifo_models.dart';

/// {@template whms_fifo_rule_engine}
/// WHMS FIFO/FEFO kural motoru — DB bağımlılığı yok.
///
/// Girdi: ürün kodu, önerilen SKT, bugün, `WhmsFifoRule`, aday lotlar.
///
/// Kurallar:
/// - FEFO: çıkışta en erken SKT tercih / `fefoEnforce` ile zorla
/// - Süresi geçmiş lot → `fefoEnforce` ise block
/// - `warnDays` içinde kalan SKT → warn
/// - `fifoDays`: SKT − today < fifo_days ise block (DEYS ürün fifo gün)
///
/// Kullanım örneği:
/// ```dart
/// final r = WhmsFifoRuleEngine.checkOutbound(
///   productCode: 'SKU1',
///   proposedExpiry: DateTime(2026, 8, 15),
///   today: DateTime(2026, 7, 28),
///   rule: const WhmsFifoRule(
///     productCode: 'SKU1',
///     fifoDays: 30,
///     fefoEnforce: true,
///     warnDays: 14,
///   ),
///   availableBatches: [
///     WhmsFifoBatch(
///       lot: 'L1',
///       expiry: DateTime(2026, 8, 15),
///       qty: 5,
///     ),
///   ],
/// );
/// ```
/// {@endtemplate}
class WhmsFifoRuleEngine {
  WhmsFifoRuleEngine._();

  /// {@template whms_fifo_rule_engine_check_outbound}
  /// Sevk / yükleme çıkış kapısı.
  ///
  /// Parametreler:
  /// - [productCode]: Ürün kodu (bilgi; kural ile eşleşmesi çağıranın sorumluluğu)
  /// - [proposedExpiry]: Önerilen / seçilen lot SKT
  /// - [today]: Referans gün
  /// - [rule]: `whms_fifo_rules` ürün kuralı
  /// - [availableBatches]: Aday lotlar (FEFO tercih kontrolü)
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoCheckResult]: allow | warn | block + messageKey
  /// {@endtemplate}
  static WhmsFifoCheckResult checkOutbound({
    required String productCode,
    DateTime? proposedExpiry,
    required DateTime today,
    required WhmsFifoRule rule,
    List<WhmsFifoBatch> availableBatches = const [],
  }) {
    final ref = dateOnly(today);
    // Boş rule.productCode ise çağıran kodunu kurala yaz (audit/persist uyumu).
    final effectiveRule = rule.productCode.trim().isEmpty
        ? WhmsFifoRule(
            productCode: productCode.trim(),
            fifoDays: rule.fifoDays,
            fefoEnforce: rule.fefoEnforce,
            warnDays: rule.warnDays,
          )
        : rule;

    if (proposedExpiry == null) {
      return const WhmsFifoCheckResult(
        decision: WhmsFifoOutboundDecision.allow,
        messageKey: WhmsFifoMessageKeys.allow,
      );
    }

    final days = daysRemaining(proposedExpiry, ref);

    // 1) Süresi geçmiş + FEFO enforce → block
    if (days < 0 && effectiveRule.fefoEnforce) {
      return WhmsFifoCheckResult(
        decision: WhmsFifoOutboundDecision.block,
        messageKey: WhmsFifoMessageKeys.blockExpired,
        daysRemaining: days,
      );
    }

    // 2) DEYS fifo_days: kalan ömür < fifo_days → block
    if (effectiveRule.fifoDays > 0 && days < effectiveRule.fifoDays) {
      return WhmsFifoCheckResult(
        decision: WhmsFifoOutboundDecision.block,
        messageKey: WhmsFifoMessageKeys.blockFifoDays,
        daysRemaining: days,
      );
    }

    // 3) FEFO enforce: daha erken SKT'li uygun lot varken geç SKT → block
    if (effectiveRule.fefoEnforce && availableBatches.isNotEmpty) {
      final earliest = earliestEligibleBatch(
        availableBatches,
        today: ref,
        rule: effectiveRule,
      );
      final earliestExp = earliest?.expiry;
      if (earliestExp != null) {
        final proposedDay = dateOnly(proposedExpiry);
        final earliestDay = dateOnly(earliestExp);
        if (proposedDay.isAfter(earliestDay)) {
          return WhmsFifoCheckResult(
            decision: WhmsFifoOutboundDecision.block,
            messageKey: WhmsFifoMessageKeys.blockFefoPreferred,
            daysRemaining: days,
          );
        }
      }
    }

    // 4) warn_days penceresi
    if (effectiveRule.warnDays > 0 &&
        days >= 0 &&
        days <= effectiveRule.warnDays) {
      return WhmsFifoCheckResult(
        decision: WhmsFifoOutboundDecision.warn,
        messageKey: WhmsFifoMessageKeys.warnNearExpiry,
        daysRemaining: days,
      );
    }

    return WhmsFifoCheckResult(
      decision: WhmsFifoOutboundDecision.allow,
      messageKey: WhmsFifoMessageKeys.allow,
      daysRemaining: days,
    );
  }

  /// {@template whms_fifo_rule_engine_pick_fefo}
  /// En erken SKT'den başlayarak tüketim planı üretir.
  ///
  /// Parametreler:
  /// - [qty]: İhtiyaç miktarı
  /// - [today]: Referans gün
  /// - [rule]: Uygunluk filtresi (expired / fifo_days)
  /// - [availableBatches]: Aday lotlar
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoPickPlan]: Dilimler + shortfall
  /// {@endtemplate}
  static WhmsFifoPickPlan pickFefoBatches({
    required double qty,
    required DateTime today,
    required WhmsFifoRule rule,
    required List<WhmsFifoBatch> availableBatches,
  }) {
    if (qty <= 0) {
      return const WhmsFifoPickPlan(
        slices: [],
        fulfilledQty: 0,
        shortfallQty: 0,
        messageKey: WhmsFifoMessageKeys.allow,
      );
    }

    final ref = dateOnly(today);
    final ordered = sortFefo(availableBatches);
    final slices = <WhmsFifoPickSlice>[];
    var remaining = qty;

    for (final batch in ordered) {
      if (remaining <= 0) break;
      if (!isBatchEligible(batch, today: ref, rule: rule)) {
        continue;
      }

      final take = remaining < batch.qty ? remaining : batch.qty;
      if (take <= 0) continue;

      slices.add(WhmsFifoPickSlice(batch: batch, quantity: take));
      remaining -= take;
    }

    final fulfilled = qty - remaining;
    final shortfall = remaining > 0 ? remaining : 0.0;
    final key = shortfall > 0
        ? WhmsFifoMessageKeys.insufficient
        : WhmsFifoMessageKeys.allow;

    return WhmsFifoPickPlan(
      slices: List<WhmsFifoPickSlice>.unmodifiable(slices),
      fulfilledQty: fulfilled,
      shortfallQty: shortfall,
      messageKey: key,
    );
  }

  /// {@template whms_fifo_rule_engine_allocate}
  /// Yükleme / sevk için FEFO dilim tahsisi — [pickFefoBatches] alias.
  ///
  /// Parametreler:
  /// - [qty]: İhtiyaç
  /// - [today]: Referans gün
  /// - [rule]: Ürün kuralı
  /// - [availableBatches]: Aday lotlar
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoPickPlan]: Dilimler + shortfall
  /// {@endtemplate}
  static WhmsFifoPickPlan allocate({
    required double qty,
    required DateTime today,
    required WhmsFifoRule rule,
    required List<WhmsFifoBatch> availableBatches,
  }) {
    return pickFefoBatches(
      qty: qty,
      today: today,
      rule: rule,
      availableBatches: availableBatches,
    );
  }

  /// {@template whms_fifo_rule_engine_sort_fefo}
  /// Lotları FEFO sırasına dizer (expiry ASC, nulls last, lot ASC).
  ///
  /// Parametreler:
  /// - [batches]: Aday lotlar
  ///
  /// Dönüş değeri:
  /// - [List]: Sıralı kopya (qty>0)
  /// {@endtemplate}
  static List<WhmsFifoBatch> sortFefo(List<WhmsFifoBatch> batches) {
    final active = batches.where((b) => b.qty > 0).toList(growable: true);
    active.sort((a, b) {
      final ae = a.expiry;
      final be = b.expiry;
      if (ae == null && be == null) {
        return a.lot.compareTo(b.lot);
      }
      if (ae == null) return 1;
      if (be == null) return -1;
      final byExpiry = dateOnly(ae).compareTo(dateOnly(be));
      if (byExpiry != 0) return byExpiry;
      return a.lot.compareTo(b.lot);
    });
    return active;
  }

  /// {@template whms_fifo_rule_engine_is_eligible}
  /// Lot çıkış için uygun mu? (qty, expired+enforce, fifo_days)
  ///
  /// Parametreler:
  /// - [batch]: Aday lot
  /// - [today]: Referans gün
  /// - [rule]: Kural
  ///
  /// Dönüş değeri:
  /// - [bool]: true ise pick/check için kullanılabilir
  /// {@endtemplate}
  static bool isBatchEligible(
    WhmsFifoBatch batch, {
    required DateTime today,
    required WhmsFifoRule rule,
  }) {
    if (batch.qty <= 0) return false;
    final exp = batch.expiry;
    if (exp == null) return true;

    final days = daysRemaining(exp, today);
    if (days < 0 && rule.fefoEnforce) return false;
    if (rule.fifoDays > 0 && days < rule.fifoDays) return false;
    return true;
  }

  /// {@template whms_fifo_rule_engine_earliest}
  /// FEFO sırasındaki ilk uygun lot.
  ///
  /// Parametreler:
  /// - [batches]: Adaylar
  /// - [today]: Referans
  /// - [rule]: Kural
  ///
  /// Dönüş değeri:
  /// - [WhmsFifoBatch]: İlk uygun; yoksa null
  /// {@endtemplate}
  static WhmsFifoBatch? earliestEligibleBatch(
    List<WhmsFifoBatch> batches, {
    required DateTime today,
    required WhmsFifoRule rule,
  }) {
    for (final b in sortFefo(batches)) {
      if (isBatchEligible(b, today: today, rule: rule)) {
        return b;
      }
    }
    return null;
  }

  /// {@template whms_fifo_rule_engine_days_remaining}
  /// Takvim günü bazlı kalan SKT (SKT − today).
  ///
  /// Parametreler:
  /// - [expiry]: SKT
  /// - [today]: Referans
  ///
  /// Dönüş değeri:
  /// - [int]: Kalan gün (negatif = geçmiş)
  /// {@endtemplate}
  static int daysRemaining(DateTime expiry, DateTime today) {
    return dateOnly(expiry).difference(dateOnly(today)).inDays;
  }

  /// {@template whms_fifo_rule_engine_date_only}
  /// Saat bileşenini sıfırlar.
  ///
  /// Parametreler:
  /// - [value]: Kaynak an
  ///
  /// Dönüş değeri:
  /// - [DateTime]: YYYY-MM-DD 00:00
  /// {@endtemplate}
  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
