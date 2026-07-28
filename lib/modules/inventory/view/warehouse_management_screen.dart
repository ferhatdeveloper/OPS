// Dosya Adı: warehouse_management_screen.dart
// Açıklama: Inventory depo — OPS çoklu ambar dens ekranına yönlendirir
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../field_sales/stock/view/multi_warehouse_screen.dart';

/// {@template warehouse_management_screen}
/// Eski inventory “Depo Yönetimi” girişi — OPS `MultiWarehouseScreen` dens.
/// WHMS domain değil; canlı REST yok.
///
/// Kullanım örneği:
/// ```dart
/// const WarehouseManagementScreen();
/// ```
/// {@endtemplate}
class WarehouseManagementScreen extends StatelessWidget {
  /// {@macro warehouse_management_screen}
  const WarehouseManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MultiWarehouseScreen();
  }
}
