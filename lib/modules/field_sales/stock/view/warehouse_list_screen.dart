// Dosya Adı: warehouse_list_screen.dart
// Açıklama: Ambar route — birleşik Şirketler bağlam ekranına yönlendirir
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../companies/view/company_list_screen.dart';

export '../model/warehouse_list_row.dart';

/// {@template warehouse_list_screen}
/// Dens ambar/mağaza seçimi [CompanyListScreen] Depo sekmesine yönlendirir.
/// Route: `/field-sales/warehouses`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WarehouseListScreen.routeName);
/// ```
/// {@endtemplate}
class WarehouseListScreen extends StatelessWidget {
  /// [routeName]: Named route
  static const String routeName = '/field-sales/warehouses';

  /// {@macro warehouse_list_screen}
  const WarehouseListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CompanyListScreen(
      initialTab: CompanyContextTab.warehouses,
    );
  }
}
