// Dosya Adı: warehouse_stock_query_screen.dart
// Açıklama: Depo stok sorgulama stub ekranı (MBT STOK parity)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template warehouse_stock_query_screen}
/// Depo stok sorgulama (stub — iş kuralı / kayıt henüz bağlanmadı).
///
/// Rota: `/field-sales/warehouse-stock-query`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WarehouseStockQueryScreen.routeName,
/// );
/// ```
/// {@endtemplate}
class WarehouseStockQueryScreen extends StatelessWidget {
  /// [routeName]: Named route yolu
  static const String routeName = '/field-sales/warehouse-stock-query';

  const WarehouseStockQueryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.stubs.warehouse_stock_query'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warehouse_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('inventory.warehouse_management_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
