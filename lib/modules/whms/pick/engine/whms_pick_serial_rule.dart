// Dosya Adı: whms_pick_serial_rule.dart
// Açıklama: Pick rota sırası + seri/barkod zorunluluk kuralları
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../model/whms_order_dto.dart';
import '../../model/whms_order_line_dto.dart';

/// {@template whms_pick_serial_rule}
/// Rota ile toplama satır sıralaması ve seri okutma zorunluluğu.
///
/// Zorunluluk: emir [WhmsOrderDto.requireSerial] **veya** ürün kuralı.
/// `serial_no` boşsa satır / emir tamamlanamaz.
///
/// Kullanım örneği:
/// ```dart
/// final sorted = WhmsPickSerialRule.sortByRouteSeq(order.lines);
/// final ok = WhmsPickSerialRule.canCompleteOrder(order);
/// ```
/// {@endtemplate}
class WhmsPickSerialRule {
  WhmsPickSerialRule._();

  /// l10n / StateError anahtarı — seri eksik
  static const String errorSerialRequired = 'whms.pick.serial_required';

  /// l10n — ürün barkodu eşleşmedi
  static const String errorBarcodeMismatch = 'whms.pick.barcode_mismatch';

  /// {@template whms_pick_serial_rule_is_required}
  /// Satırda seri zorunlu mu (emir flag ∪ ürün kuralı).
  ///
  /// Parametreler:
  /// - [orderRequireSerial]: Emir `require_serial`
  /// - [productRequireSerial]: Ürün kuralı
  ///
  /// Dönüş değeri:
  /// - [bool]: true ise `serial_no` dolu olmalı
  /// {@endtemplate}
  static bool isSerialRequired({
    required bool orderRequireSerial,
    required bool productRequireSerial,
  }) =>
      orderRequireSerial || productRequireSerial;

  /// {@template whms_pick_serial_rule_has_serial}
  /// Satırda dolu seri var mı.
  /// {@endtemplate}
  static bool hasSerial(WhmsOrderLineDto line) =>
      (line.serialNo ?? '').trim().isNotEmpty;

  /// {@template whms_pick_serial_rule_line_requires}
  /// Verilen satır için seri zorunlu mu.
  /// {@endtemplate}
  static bool lineRequiresSerial(
    WhmsOrderDto order,
    WhmsOrderLineDto line, {
    Set<String> productIdsRequiringSerial = const {},
  }) {
    return isSerialRequired(
      orderRequireSerial: order.requireSerial,
      productRequireSerial:
          productIdsRequiringSerial.contains(line.productId),
    );
  }

  /// {@template whms_pick_serial_rule_can_complete_line}
  /// Tek satır tamamlanabilir mi.
  /// {@endtemplate}
  static bool canCompleteLine(
    WhmsOrderDto order,
    WhmsOrderLineDto line, {
    Set<String> productIdsRequiringSerial = const {},
  }) {
    if (!lineRequiresSerial(
      order,
      line,
      productIdsRequiringSerial: productIdsRequiringSerial,
    )) {
      return true;
    }
    return hasSerial(line);
  }

  /// {@template whms_pick_serial_rule_can_complete_order}
  /// Emir tamamlanabilir mi — zorunlu satırlarda `serial_no` dolu.
  ///
  /// Parametreler:
  /// - [order]: Pick emri
  /// - [productIdsRequiringSerial]: Ürün kuralı id seti
  ///
  /// Dönüş değeri:
  /// - [bool]: false ise tamamlanamaz
  /// {@endtemplate}
  static bool canCompleteOrder(
    WhmsOrderDto order, {
    Set<String> productIdsRequiringSerial = const {},
  }) {
    if (order.lines.isEmpty) return false;
    for (final line in order.lines) {
      if (!canCompleteLine(
        order,
        line,
        productIdsRequiringSerial: productIdsRequiringSerial,
      )) {
        return false;
      }
    }
    return true;
  }

  /// {@template whms_pick_serial_rule_sort}
  /// Satırları `route_seq` ASC, sonra `line_no` ASC.
  /// `route_seq` null → en sona.
  ///
  /// Dönüş değeri:
  /// - [List<WhmsOrderLineDto>]: Yeni sıralı liste
  /// {@endtemplate}
  static List<WhmsOrderLineDto> sortByRouteSeq(
    List<WhmsOrderLineDto> lines,
  ) {
    final copy = List<WhmsOrderLineDto>.from(lines);
    copy.sort((a, b) {
      final ra = a.routeSeq;
      final rb = b.routeSeq;
      if (ra == null && rb == null) {
        return a.lineNo.compareTo(b.lineNo);
      }
      if (ra == null) return 1;
      if (rb == null) return -1;
      final byRoute = ra.compareTo(rb);
      if (byRoute != 0) return byRoute;
      return a.lineNo.compareTo(b.lineNo);
    });
    return copy;
  }

  /// {@template whms_pick_serial_rule_match_line}
  /// Barkod / ürün kodu ile rota sırasındaki ilk eşleşen satır.
  /// {@endtemplate}
  static WhmsOrderLineDto? matchLineByProductCode(
    List<WhmsOrderLineDto> sortedLines,
    String scannedCode, {
    bool preferIncomplete = true,
  }) {
    final needle = scannedCode.trim().toLowerCase();
    if (needle.isEmpty) return null;
    WhmsOrderLineDto? firstAny;
    for (final line in sortedLines) {
      final code = (line.productCode ?? '').trim().toLowerCase();
      final id = line.productId.trim().toLowerCase();
      final hit = code == needle || id == needle;
      if (!hit) continue;
      firstAny ??= line;
      if (!preferIncomplete) return line;
      if (line.quantityDone < line.quantity) return line;
    }
    return firstAny;
  }
}
