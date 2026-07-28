// Dosya Adı: vehicle_inventory_screen.dart
// Açıklama: Araç stok stub → vehicles dens özet ekranına yönlendirir
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../vehicles/view/vehicle_stock_screen.dart';

/// {@template vehicle_inventory_screen}
/// MBT “Araç Stoğu” stub route — canlı [VehicleStockSummaryScreen].
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

  /// {@macro vehicle_inventory_screen}
  const VehicleInventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const VehicleStockSummaryScreen();
  }
}
