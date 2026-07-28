// Dosya Adı: promissory_list_seed.dart
// Açıklama: MBT Senet Listesi dens stub seed
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'promissory_list_row.dart';
import 'promissory_list_status.dart';

/// {@template promissory_list_seed}
/// Senet Listesi dens seed — SQLite boşken durum sekmeleri.
///
/// Kullanım örneği:
/// ```dart
/// final rows = PromissoryListSeed.defaultRows;
/// ```
/// {@endtemplate}
class PromissoryListSeed {
  PromissoryListSeed._();

  /// Named route
  static const String route = '/field-sales/promissory-list';

  /// Menü seed alt başlık
  static const String submenuTitle = 'Senet Listesi';

  /// Yer tutucu dens satırlar (her durumdan en az bir).
  static final List<PromissoryListRow> defaultRows = [
    PromissoryListRow(
      id: 'pnt_seed_collateral',
      customerId: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      amount: 5000,
      noteNumber: 'SNT-SEED-COL',
      bankName: 'Ziraat Bankası',
      dueDate: DateTime(2026, 10, 20),
      documentNo: 'EVR-SNT-01',
      status: PromissoryListStatus.collateral,
    ),
    PromissoryListRow(
      id: 'pnt_seed_collection',
      customerId: 'C0002',
      customerName: 'Örnek Ticaret Ltd.',
      amount: 1750.25,
      noteNumber: 'SNT-SEED-COLLECT',
      bankName: 'İş Bankası',
      dueDate: DateTime(2026, 9, 15),
      status: PromissoryListStatus.collection,
    ),
    PromissoryListRow(
      id: 'pnt_seed_returned',
      customerId: 'C0003',
      amount: 600,
      noteNumber: 'SNT-SEED-RET',
      status: PromissoryListStatus.returned,
    ),
    PromissoryListRow(
      id: 'pnt_seed_collected',
      customerId: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      amount: 2200,
      noteNumber: 'SNT-SEED-DONE',
      status: PromissoryListStatus.collected,
    ),
    PromissoryListRow(
      id: 'pnt_seed_bounced',
      customerId: 'C0004',
      amount: 3100,
      noteNumber: 'SNT-SEED-BOUNCE',
      status: PromissoryListStatus.bounced,
    ),
    PromissoryListRow(
      id: 'pnt_seed_uncollectible',
      customerId: 'C0004',
      amount: 900,
      noteNumber: 'SNT-SEED-UNC',
      status: PromissoryListStatus.uncollectible,
    ),
    PromissoryListRow(
      id: 'pnt_seed_paid_company',
      customerId: 'S0001',
      customerName: 'Tedarikçi XYZ',
      amount: 1400,
      noteNumber: 'SNT-SEED-PAID',
      status: PromissoryListStatus.paidCompany,
    ),
    PromissoryListRow(
      id: 'pnt_seed_issued_company',
      customerId: 'S0002',
      customerName: 'Tedarikçi ABC',
      amount: 2800.5,
      noteNumber: 'SNT-SEED-ISS',
      status: PromissoryListStatus.issuedCompany,
    ),
  ];
}
