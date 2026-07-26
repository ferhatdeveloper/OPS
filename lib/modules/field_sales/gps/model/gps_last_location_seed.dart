// Dosya Adı: gps_last_location_seed.dart
// Açıklama: GPS Takip dens son konum stub seed satırları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'gps_last_location_record.dart';

/// {@template gps_last_location_seed}
/// MBT GPS Takip dens — `gps_logs` boşken seed.
///
/// Kullanım örneği:
/// ```dart
/// final rows = GpsLastLocationSeed.defaultRows;
/// ```
/// {@endtemplate}
class GpsLastLocationSeed {
  GpsLastLocationSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/gps-tracking';

  /// [submenuTitle]: Menü / stub başlık
  static const String submenuTitle = 'GPS Takip';

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'gps_logs';

  /// Yer tutucu dens son konum satırları (plasiyer başına bir).
  static final List<GpsLastLocationRecord> defaultRows = [
    GpsLastLocationRecord(
      id: 'gps_seed_pls01',
      latitude: 41.00820,
      longitude: 28.97840,
      recordedAt: DateTime(2026, 7, 26, 9, 15),
      salespersonCode: 'PLS01',
      label: 'Demo Plasiyer — Eminönü',
      accuracy: 12.5,
      isSynced: 1,
      createdAt: DateTime(2026, 7, 26, 9, 15),
      updatedAt: DateTime(2026, 7, 26, 9, 15),
    ),
    GpsLastLocationRecord(
      id: 'gps_seed_pls02',
      latitude: 41.04220,
      longitude: 29.00670,
      recordedAt: DateTime(2026, 7, 26, 10, 5),
      salespersonCode: 'PLS02',
      label: 'Örnek Plasiyer — Beşiktaş',
      accuracy: 18.0,
      isSynced: 0,
      createdAt: DateTime(2026, 7, 26, 10, 5),
      updatedAt: DateTime(2026, 7, 26, 10, 5),
    ),
    GpsLastLocationRecord(
      id: 'gps_seed_pls03',
      latitude: 40.99290,
      longitude: 29.02700,
      recordedAt: DateTime(2026, 7, 25, 16, 40),
      salespersonCode: 'PLS03',
      label: 'Saha — Kadıköy',
      accuracy: 25.0,
      isSynced: 1,
      createdAt: DateTime(2026, 7, 25, 16, 40),
      updatedAt: DateTime(2026, 7, 25, 16, 40),
    ),
    GpsLastLocationRecord(
      id: 'gps_seed_demo',
      latitude: 39.92080,
      longitude: 32.85410,
      recordedAt: DateTime(2026, 7, 24, 14, 0),
      salespersonCode: 'DEMO',
      label: 'Demo — Ankara Kızılay',
      accuracy: 30.0,
      isSynced: 0,
      createdAt: DateTime(2026, 7, 24, 14, 0),
      updatedAt: DateTime(2026, 7, 24, 14, 0),
    ),
  ];

  /// {@template gps_last_location_seed_maps}
  /// SQLite insert için map listesi.
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);
}
