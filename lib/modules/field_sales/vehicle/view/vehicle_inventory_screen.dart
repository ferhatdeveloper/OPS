// Dosya Adı: vehicle_inventory_screen.dart
// Açıklama: Araç stok / envanter stub ekranı
//   (MBT → Araç Stoğu)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template vehicle_inventory_screen}
/// Araç stok / envanter için stub ekran.
/// Route: `/field-sales/vehicle-inventory`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   VehicleInventoryScreen.routeName,
/// );
/// ```
/// {@endtemplate}
class VehicleInventoryScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/vehicle-inventory`
  static const String routeName = '/field-sales/vehicle-inventory';

  const VehicleInventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.vehicle_inventory');

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
