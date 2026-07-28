// Dosya Adı: whms_count_result_line.dart
// Açıklama: Merkez sayım sonuç satırı (sistem vs fiili fark iskeleti)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../contract/whms_bridge_dto.dart';

/// {@template whms_count_result_line}
/// Sayım satırı: sistem bakiyesi + fiili sayım.
///
/// Kullanım örneği:
/// ```dart
/// const line = WhmsCountResultLine(
///   productId: 'p1',
///   productCode: 'SKU-1',
///   systemQty: 10,
///   countedQty: 9,
/// );
/// ```
/// {@endtemplate}
class WhmsCountResultLine {
  /// [productId]: Yerel ürün id
  final String productId;

  /// [productCode]: Logo / WHMS ürün kodu
  final String productCode;

  /// [systemQty]: Sistem bakiyesi
  final double systemQty;

  /// [countedQty]: Fiili sayılan
  final double countedQty;

  /// [locationCode]: Raf / göz (opsiyonel)
  final String? locationCode;

  /// [unitName]: Birim (opsiyonel)
  final String? unitName;

  /// [productName]: Dens gösterim adı (opsiyonel)
  final String? productName;

  /// {@macro whms_count_result_line}
  const WhmsCountResultLine({
    required this.productId,
    required this.productCode,
    required this.systemQty,
    required this.countedQty,
    this.locationCode,
    this.unitName,
    this.productName,
  });

  /// [variance]: Fark (fiili − sistem); + fazla / − eksik
  double get variance => countedQty - systemQty;

  /// Köprü satırına (fiili miktar) dönüştür.
  WhmsBridgeLine toBridgeLine() => WhmsBridgeLine(
        productId: productId,
        productCode: productCode,
        quantity: countedQty,
        unitName: unitName,
      );

  /// Map → satır (SQLite lines_json).
  factory WhmsCountResultLine.fromMap(Map<String, dynamic> map) {
    final code = (map['product_code'] ?? map['MASTER_CODE'] ?? '')
        .toString()
        .trim();
    final id = (map['product_id'] ?? code).toString().trim();
    final counted = (map['counted_qty'] as num?)?.toDouble() ??
        (map['actual_qty'] as num?)?.toDouble() ??
        (map['quantity'] as num?)?.toDouble() ??
        (map['QUANTITY'] as num?)?.toDouble() ??
        0;
    return WhmsCountResultLine(
      productId: id.isEmpty ? code : id,
      productCode: code,
      systemQty: (map['system_qty'] as num?)?.toDouble() ?? 0,
      countedQty: counted,
      locationCode: _nullable(map['location_code']),
      unitName: _nullable(map['unit_name'] ?? map['unit']),
      productName: _nullable(map['product_name'] ?? map['name']),
    );
  }

  /// Map serileştirme.
  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_code': productCode,
        'MASTER_CODE': productCode,
        'system_qty': systemQty,
        'counted_qty': countedQty,
        'actual_qty': countedQty,
        'quantity': countedQty,
        'QUANTITY': countedQty,
        'variance': variance,
        if (locationCode != null) 'location_code': locationCode,
        if (unitName != null) 'unit_name': unitName,
        if (productName != null) 'product_name': productName,
      };

  /// İmmutable kopya.
  WhmsCountResultLine copyWith({
    String? productId,
    String? productCode,
    double? systemQty,
    double? countedQty,
    String? locationCode,
    String? unitName,
    String? productName,
  }) {
    return WhmsCountResultLine(
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      systemQty: systemQty ?? this.systemQty,
      countedQty: countedQty ?? this.countedQty,
      locationCode: locationCode ?? this.locationCode,
      unitName: unitName ?? this.unitName,
      productName: productName ?? this.productName,
    );
  }

  static String? _nullable(Object? value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }
}
