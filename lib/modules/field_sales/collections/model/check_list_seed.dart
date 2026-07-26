// Dosya Adı: check_list_seed.dart
// Açıklama: MBT Çek Listesi dens stub seed (payment_type=check)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'check_list_row.dart';
import 'check_list_status.dart';
import 'finance_movement_type.dart';

/// {@template check_list_seed}
/// Çek Listesi dens seed — SQLite boşken durum sekmeleri.
///
/// Kullanım örneği:
/// ```dart
/// final rows = CheckListSeed.defaultRows;
/// ```
/// {@endtemplate}
class CheckListSeed {
  CheckListSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/checks';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'Çek Listesi';

  /// Yer tutucu dens satırlar (her MBT durumundan en az bir).
  static final List<CheckListRow> defaultRows = [
    CheckListRow(
      id: 'chk_seed_collateral',
      customerId: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      amount: 2500.00,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 7, 20),
      checkNumber: 'CHK-SEED-COL',
      bankName: 'Ziraat Bankası',
      branchName: 'Merkez',
      dueDate: DateTime(2026, 9, 20),
      documentNo: 'EVR-CHK-01',
      originalDebtor: 'Demo Cari A.Ş.',
      status: CheckListStatus.collateral,
    ),
    CheckListRow(
      id: 'chk_seed_collection',
      customerId: 'C0002',
      customerName: 'Örnek Ticaret Ltd.',
      amount: 1250.50,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 7, 22),
      checkNumber: 'CHK-SEED-COLLECT',
      bankName: 'İş Bankası',
      branchName: 'Kadıköy',
      dueDate: DateTime(2026, 8, 22),
      documentNo: 'EVR-CHK-02',
      originalDebtor: 'Örnek Ticaret Ltd.',
      status: CheckListStatus.collection,
    ),
    CheckListRow(
      id: 'chk_seed_returned',
      customerId: 'C0003',
      customerName: 'Perakende Müşteri',
      amount: 800.00,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 7, 10),
      checkNumber: 'CHK-SEED-RET',
      bankName: 'Garanti BBVA',
      dueDate: DateTime(2026, 7, 25),
      status: CheckListStatus.returned,
    ),
    CheckListRow(
      id: 'chk_seed_collected',
      customerId: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      amount: 3200.75,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 6, 15),
      checkNumber: 'CHK-SEED-DONE',
      bankName: 'Yapı Kredi',
      dueDate: DateTime(2026, 7, 1),
      status: CheckListStatus.collected,
    ),
    CheckListRow(
      id: 'chk_seed_bounced',
      customerId: 'C0004',
      customerName: 'Riskli Cari',
      amount: 4500.00,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 5, 1),
      checkNumber: 'CHK-SEED-BOUNCE',
      bankName: 'Akbank',
      dueDate: DateTime(2026, 6, 1),
      status: CheckListStatus.bounced,
    ),
    CheckListRow(
      id: 'chk_seed_uncollectible',
      customerId: 'C0004',
      customerName: 'Riskli Cari',
      amount: 1100.00,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 4, 1),
      checkNumber: 'CHK-SEED-UNC',
      bankName: 'Denizbank',
      dueDate: DateTime(2026, 5, 1),
      status: CheckListStatus.uncollectible,
    ),
    CheckListRow(
      id: 'chk_seed_paid_company',
      customerId: 'S0001',
      customerName: 'Tedarikçi XYZ',
      amount: 900.00,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 7, 5),
      checkNumber: 'CHK-SEED-PAID',
      bankName: 'Halkbank',
      dueDate: DateTime(2026, 8, 5),
      status: CheckListStatus.paidCompany,
    ),
    CheckListRow(
      id: 'chk_seed_issued_company',
      customerId: 'S0002',
      customerName: 'Tedarikçi ABC',
      amount: 2100.25,
      paymentType: FinanceMovementType.checkCollection.apiCode,
      collectionDate: DateTime(2026, 7, 8),
      checkNumber: 'CHK-SEED-ISS',
      bankName: 'VakıfBank',
      dueDate: DateTime(2026, 9, 8),
      status: CheckListStatus.issuedCompany,
    ),
  ];

  /// {@template check_list_seed_maps}
  /// SQLite insert için map listesi.
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);
}
