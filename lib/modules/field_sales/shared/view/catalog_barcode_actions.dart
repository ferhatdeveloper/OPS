// Dosya Adı: catalog_barcode_actions.dart
// Açıklama: Katalog Barkod/Kamera → ürün dens lookup navigasyonu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/init/navigation/routes.dart';

/// {@template open_field_sales_barcode_scan}
/// Named route ile [BarcodeScanScreen] dens lookup açar.
///
/// Parametreler:
/// - [context]: Navigasyon bağlamı
///
/// Dönüş değeri:
/// - [Future]: Seçilen ürün haritası veya null
///
/// Kullanım örneği:
/// ```dart
/// final product = await openFieldSalesBarcodeScan(context);
/// if (product != null) { /* sepete ekle / süz */ }
/// ```
/// {@endtemplate}
Future<Map<String, dynamic>?> openFieldSalesBarcodeScan(
  BuildContext context,
) {
  return Navigator.of(context).pushNamed<Map<String, dynamic>>(
    AppRoutes.fieldSalesBarcodeScan,
  );
}
