// Dosya Adı: stock_movement_screen.dart
// Açıklama: Stok hareketi stub ekranı (MBT: Stok Hareket)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template stock_movement_screen}
/// Stok hareket listesi / fişi (stub — iş kuralı / kayıt henüz bağlanmadı).
///
/// Rota: `/field-sales/stock-movement`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, StockMovementScreen.routeName);
/// ```
/// {@endtemplate}
class StockMovementScreen extends StatelessWidget {
  /// [routeName]: GoRouter / named route yolu
  static const String routeName = '/field-sales/stock-movement';

  const StockMovementScreen({Key? key}) : super(key: key);

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
          l10n.translate('field_sales.stubs.stock_movement'),
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
              Icons.swap_horiz_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('field_sales.stubs.stock_movement'),
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
