// Dosya Adı: sales_target_seed.dart
// Açıklama: Satış hedefleri dens stub seed satırları (SQLite targets)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'sales_target_record.dart';

/// {@template sales_target_seed}
/// MBT Satış Hedefleri dens seed — `targets` tablosu boşken.
///
/// Kullanım örneği:
/// ```dart
/// final rows = SalesTargetSeed.defaultRows;
/// ```
/// {@endtemplate}
class SalesTargetSeed {
  SalesTargetSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/sales-targets';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'Satış Hedefleri';

  /// [tableName]: SQLite tablo adı (`SqlQuerys.createTargetsTable`)
  static const String tableName = 'targets';

  /// Yer tutucu dens satırlar (plasiyer · tür · dönem · hedef/gerçekleşen).
  static const List<SalesTargetRecord> defaultRows = [
    SalesTargetRecord(
      id: 'st_seed_sales_ahmet',
      userId: 'Ahmet Yılmaz',
      targetAmount: 250000,
      achievedAmount: 180000,
      period: '2026-07',
      type: 'Sales',
      createdAt: '2026-07-01T08:00:00.000',
      updatedAt: '2026-07-26T10:00:00.000',
      isSynced: 0,
    ),
    SalesTargetRecord(
      id: 'st_seed_sales_mehmet',
      userId: 'Mehmet Kaya',
      targetAmount: 300000,
      achievedAmount: 320000,
      period: '2026-07',
      type: 'Sales',
      createdAt: '2026-07-01T08:00:00.000',
      updatedAt: '2026-07-26T10:00:00.000',
      isSynced: 1,
    ),
    SalesTargetRecord(
      id: 'st_seed_sales_ayse',
      userId: 'Ayşe Demir',
      targetAmount: 200000,
      achievedAmount: 150000,
      period: '2026-07',
      type: 'Sales',
      createdAt: '2026-07-01T08:00:00.000',
      updatedAt: '2026-07-26T10:00:00.000',
      isSynced: 0,
    ),
    SalesTargetRecord(
      id: 'st_seed_collection_ali',
      userId: 'Ali Can',
      targetAmount: 100000,
      achievedAmount: 90000,
      period: '2026-07',
      type: 'Collection',
      createdAt: '2026-07-01T08:00:00.000',
      updatedAt: '2026-07-26T10:00:00.000',
      isSynced: 0,
    ),
    SalesTargetRecord(
      id: 'st_seed_visit_ahmet',
      userId: 'Ahmet Yılmaz',
      targetAmount: 80,
      achievedAmount: 62,
      period: '2026-07',
      type: 'Visit',
      createdAt: '2026-07-01T08:00:00.000',
      updatedAt: '2026-07-26T10:00:00.000',
      isSynced: 0,
    ),
  ];

  /// {@template sales_target_seed_maps}
  /// SQLite insert için map listesi.
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);

  /// {@template sales_target_seed_sales_rows}
  /// Yalnız satış tipi dens satırları.
  /// {@endtemplate}
  static List<SalesTargetRecord> get salesRows => defaultRows
      .where((r) => r.type == 'Sales')
      .toList(growable: false);
}
