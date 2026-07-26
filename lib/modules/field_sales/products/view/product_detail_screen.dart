// Dosya Adı: product_detail_screen.dart
// Açıklama: Ürün detay stub ekranı (MBT STOK → Detay)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

/// {@template product_detail_screen}
/// Ürün detay için stub ekran.
/// Route: `/field-sales/product-detail`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ProductDetailScreen.routeName);
/// ```
/// {@endtemplate}
class ProductDetailScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/product-detail`
  static const String routeName = '/field-sales/product-detail';

  const ProductDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.product_detail');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
