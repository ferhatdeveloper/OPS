// Dosya Adı: batch_expiry_seed.dart
// Açıklama: Parti / SKT dens stub seed satırları (SQLite boşken)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'batch_expiry_record.dart';

/// {@template batch_expiry_seed}
/// MBT Parti / SKT dens stub seed (SQLite boşken).
///
/// Kullanım örneği:
/// ```dart
/// final rows = BatchExpirySeed.defaultRows;
/// ```
/// {@endtemplate}
class BatchExpirySeed {
  BatchExpirySeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/batch-expiry';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'Parti / SKT';

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'batch_expiry';

  /// [nearDays]: Yaklaşan SKT eşiği (gün)
  static const int nearDays = 30;

  /// Yer tutucu dens satırlar (lot + SKT).
  static final List<BatchExpiryRecord> defaultRows = [
    BatchExpiryRecord(
      id: 'be_stub_ok_mrk',
      productId: 'prd_stub_001',
      productCode: 'STK001',
      productName: 'Demo Ürün A',
      lotNo: 'L2026-A01',
      expiryDate: DateTime(2027, 6, 30),
      quantity: 120,
      unit: 'AD',
      warehouseCode: 'MRK',
      warehouseName: 'Merkez Depo',
      status: BatchExpiryStatus.ok,
      createdAt: DateTime(2026, 7, 26, 9, 0),
      updatedAt: DateTime(2026, 7, 26, 9, 0),
    ),
    BatchExpiryRecord(
      id: 'be_stub_near_arc',
      productId: 'prd_stub_002',
      productCode: 'STK002',
      productName: 'Demo Ürün B',
      lotNo: 'L2026-B14',
      expiryDate: DateTime(2026, 8, 10),
      quantity: 45.5,
      unit: 'KG',
      warehouseCode: 'ARC',
      warehouseName: 'Araç Depo',
      status: BatchExpiryStatus.near,
      createdAt: DateTime(2026, 7, 26, 9, 5),
      updatedAt: DateTime(2026, 7, 26, 9, 5),
    ),
    BatchExpiryRecord(
      id: 'be_stub_expired_iad',
      productId: 'prd_stub_003',
      productCode: 'STK003',
      productName: 'Demo Ürün C',
      lotNo: 'L2025-C99',
      expiryDate: DateTime(2026, 6, 1),
      quantity: 8,
      unit: 'AD',
      warehouseCode: 'IAD',
      warehouseName: 'İade Deposu',
      status: BatchExpiryStatus.expired,
      approvalStatus: 0,
      createdAt: DateTime(2026, 7, 20, 8, 0),
      updatedAt: DateTime(2026, 7, 20, 8, 30),
    ),
    BatchExpiryRecord(
      id: 'be_stub_ok_arc',
      productId: 'prd_stub_001',
      productCode: 'STK001',
      productName: 'Demo Ürün A',
      lotNo: 'L2026-A02',
      expiryDate: DateTime(2027, 1, 15),
      quantity: 60,
      unit: 'AD',
      warehouseCode: 'ARC',
      warehouseName: 'Araç Depo',
      status: BatchExpiryStatus.ok,
      isSynced: 1,
      createdAt: DateTime(2026, 7, 25, 14, 0),
      updatedAt: DateTime(2026, 7, 25, 14, 10),
    ),
    BatchExpiryRecord(
      id: 'be_stub_near_mrk',
      productId: 'prd_stub_004',
      productCode: 'STK010',
      productName: 'Soğuk Zincir Ürün',
      lotNo: 'L2026-D03',
      expiryDate: DateTime(2026, 8, 5),
      quantity: 24,
      unit: 'KT',
      warehouseCode: 'MRK',
      warehouseName: 'Merkez Depo',
      status: BatchExpiryStatus.near,
      createdAt: DateTime(2026, 7, 26, 10, 0),
      updatedAt: DateTime(2026, 7, 26, 10, 0),
    ),
  ];

  /// {@template batch_expiry_seed_ok_rows}
  /// SKT uygun dens stub satırları.
  /// {@endtemplate}
  static List<BatchExpiryRecord> get okRows => defaultRows
      .where((r) => r.resolvedStatus == BatchExpiryStatus.ok)
      .toList(growable: false);

  /// {@template batch_expiry_seed_near_rows}
  /// Yaklaşan SKT dens stub satırları.
  /// {@endtemplate}
  static List<BatchExpiryRecord> get nearRows => defaultRows
      .where((r) => r.resolvedStatus == BatchExpiryStatus.near)
      .toList(growable: false);

  /// {@template batch_expiry_seed_expired_rows}
  /// SKT geçmiş dens stub satırları.
  /// {@endtemplate}
  static List<BatchExpiryRecord> get expiredRows => defaultRows
      .where((r) => r.resolvedStatus == BatchExpiryStatus.expired)
      .toList(growable: false);

  /// {@template batch_expiry_seed_maps}
  /// SQLite insert için map listesi.
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);

  /// {@template batch_expiry_seed_format_date}
  /// Tarihi MBT biçiminde `dd-MM-yyyy` döndürür.
  ///
  /// Parametreler:
  /// - [date]: Biçimlenecek gün
  ///
  /// Dönüş değeri:
  /// - [String]: `26-07-2026` gibi metin
  /// {@endtemplate}
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d-$m-$y';
  }
}
