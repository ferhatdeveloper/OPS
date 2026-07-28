// Dosya Adı: gida_sfa_seed.dart
// Açıklama: Anadolu Gıda Dağıtım demo — cari / ürün / lot / ambar seed
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../core/database/migrations/SqlQuerys.dart';
import '../products/model/product_catalog_row.dart';
import '../stock/model/batch_expiry_record.dart';

/// {@template gida_sfa_company}
/// Demo gıda dağıtım firması sabitleri.
///
/// Kullanım örneği:
/// ```dart
/// print(GidaSfaCompany.name); // Anadolu Gıda Dağıtım
/// ```
/// {@endtemplate}
class GidaSfaCompany {
  GidaSfaCompany._();

  /// [name]: Demo firma ünvanı
  static const String name = 'Anadolu Gıda Dağıtım';

  /// [code]: Firma / işyeri kodu
  static const String code = 'AGD';

  /// [warehouseCode]: Merkez ambar
  static const String warehouseCode = 'MRK';

  /// [warehouseName]: Merkez ambar adı
  static const String warehouseName = 'Merkez Depo';

  /// [defaultRiskLimit]: Varsayılan cari risk limiti (TL)
  static const double defaultRiskLimit = 50000;
}

/// {@template gida_sfa_customer_seed}
/// Gıda plasiyer demo cari kartı.
/// {@endtemplate}
class GidaSfaCustomerSeed {
  /// [id]: customers.id
  final String id;

  /// [code]: Cari kod
  final String code;

  /// [name]: Ünvan
  final String name;

  /// [taxNo]: VKN
  final String taxNo;

  /// [phone]: Telefon
  final String phone;

  /// [address]: Adres
  final String address;

  /// [il]: İl
  final String il;

  /// [creditLimit]: Risk limiti (TL) — demo mantık; SQLite opsiyonel kolon
  final double creditLimit;

  /// [balance]: Açılış bakiye (borç)
  final double balance;

  /// {@macro gida_sfa_customer_seed}
  const GidaSfaCustomerSeed({
    required this.id,
    required this.code,
    required this.name,
    required this.taxNo,
    required this.phone,
    required this.address,
    required this.il,
    this.creditLimit = GidaSfaCompany.defaultRiskLimit,
    this.balance = 0,
  });

  /// SQLite insert map (standart customers şeması).
  Map<String, dynamic> toMap({required String now}) {
    return {
      'id': id,
      'code': code,
      'name': name,
      'tax_no': taxNo,
      'tax_office': 'Anadolu',
      'phone': phone,
      'address': address,
      'il': il,
      'ilce': 'Merkez',
      'balance': balance,
      'is_active': 1,
      'card_role': 'customer',
      'created_at': now,
      'updated_at': now,
    };
  }
}

/// {@template gida_sfa_seed}
/// Anadolu Gıda Dağıtım — gıda SKU + cari + lot örnek data.
///
/// Kullanım örneği:
/// ```dart
/// await GidaSfaSeed.applySchema(db);
/// await GidaSfaSeed.seedMasters(db);
/// ```
/// {@endtemplate}
class GidaSfaSeed {
  GidaSfaSeed._();

  /// Market carisi (ana demo müşteri).
  static const GidaSfaCustomerSeed marketCustomer = GidaSfaCustomerSeed(
    id: 'cari-agd-market-01',
    code: 'C-AGD-1001',
    name: 'Yeşil Market Zinciri A.Ş.',
    taxNo: '1234567890',
    phone: '02121234567',
    address: 'Atatürk Cad. No:12',
    il: 'İstanbul',
    creditLimit: 50000,
    balance: 2500,
  );

  /// Restoran / HORECA carisi.
  static const GidaSfaCustomerSeed restaurantCustomer = GidaSfaCustomerSeed(
    id: 'cari-agd-rest-01',
    code: 'C-AGD-2001',
    name: 'Anadolu Lokantası Ltd.',
    taxNo: '9876543210',
    phone: '03129876543',
    address: 'Çankaya Mah. No:5',
    il: 'Ankara',
    creditLimit: 25000,
    balance: 800,
  );

  /// Gıda ürün katalogu (KDV: un/süt %1, yağ %10, gazoz %20).
  static const List<ProductCatalogRow> products = [
    ProductCatalogRow(
      id: 'prd-agd-un-01',
      code: 'GID-UN-50',
      name: 'Un 50 kg',
      barcode: '8690123456001',
      unit: 'CUVAL',
      price: 485,
      vatRate: 1,
      stockQuantity: 200,
      category: 'UN',
    ),
    ProductCatalogRow(
      id: 'prd-agd-yag-01',
      code: 'GID-YAG-18',
      name: 'Ayçiçek Yağı 18 L',
      barcode: '8690123456002',
      unit: 'BIDON',
      price: 920,
      vatRate: 10,
      stockQuantity: 80,
      category: 'YAG',
    ),
    ProductCatalogRow(
      id: 'prd-agd-sut-01',
      code: 'GID-SUT-1L',
      name: 'UHT Süt 1 L',
      barcode: '8690123456003',
      unit: 'ADET',
      price: 28.5,
      vatRate: 1,
      stockQuantity: 500,
      category: 'SUT',
    ),
    ProductCatalogRow(
      id: 'prd-agd-gazoz-01',
      code: 'GID-GAZ-33',
      name: 'Gazlı İçecek 330 ml',
      barcode: '8690123456004',
      unit: 'KOLI',
      price: 185,
      vatRate: 20,
      stockQuantity: 150,
      category: 'ICECEK',
    ),
  ];

  /// Tüm demo cariler.
  static const List<GidaSfaCustomerSeed> customers = [
    marketCustomer,
    restaurantCustomer,
  ];

  /// {@template gida_sfa_seed_apply_schema}
  /// Playback için gerekli SQLite tablolarını oluşturur.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// {@endtemplate}
  static Future<void> applySchema(Database db) async {
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createProductsTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createOrderItemsTable);
    await db.execute(SqlQuerys.createCollectionsTable);
    await db.execute(SqlQuerys.createInvoicesTable);
    await db.execute(SqlQuerys.createInvoiceItemsTable);
    await db.execute(SqlQuerys.createCustomerMovementsTable);
    await db.execute(SqlQuerys.createVisitsTable);
    await db.execute(SqlQuerys.createWarehousesTable);
    await db.execute(SqlQuerys.createWarehouseStocksTable);
    await db.execute(SqlQuerys.createBatchExpiryTable);
    await db.execute(SqlQuerys.createSyncQueueTable);
    // Risk limiti demo kolonu (yerel şemada yoksa ekle)
    try {
      await db.execute(
        'ALTER TABLE customers ADD COLUMN credit_limit REAL '
        'DEFAULT ${GidaSfaCompany.defaultRiskLimit}',
      );
    } catch (_) {
      // kolon zaten var
    }
  }

  /// {@template gida_sfa_seed_masters}
  /// Ambar + cari + ürün + lot + stok master seed.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite
  /// - [includeCustomers]: Cari yaz (CRUD testi Create öncesi false)
  /// - [includeProducts]: Ürün yaz
  /// {@endtemplate}
  static Future<void> seedMasters(
    Database db, {
    bool includeCustomers = true,
    bool includeProducts = true,
  }) async {
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'warehouses',
      {
        'id': 'wh-agd-mrk',
        'code': GidaSfaCompany.warehouseCode,
        'name': GidaSfaCompany.warehouseName,
        'type': 'main',
        'is_active': 1,
        'is_synced': 0,
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (includeCustomers) {
      for (final c in customers) {
        final map = c.toMap(now: now);
        map['credit_limit'] = c.creditLimit;
        await db.insert(
          'customers',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    if (includeProducts) {
      for (final p in products) {
        await db.insert(
          'products',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await db.insert(
          'warehouse_stocks',
          {
            'warehouse_code': GidaSfaCompany.warehouseCode,
            'product_id': p.id,
            'quantity': p.stockQuantity,
            'is_synced': 0,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final lot in foodLots()) {
        await db.insert(
          'batch_expiry',
          lot.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// {@template gida_sfa_seed_food_lots}
  /// SKT/lot örnekleri (süt / yağ).
  ///
  /// Dönüş değeri:
  /// - [List]: batch_expiry satırları
  /// {@endtemplate}
  static List<BatchExpiryRecord> foodLots() {
    final now = DateTime.now();
    return [
      BatchExpiryRecord(
        id: 'lot-agd-sut-a',
        productId: 'prd-agd-sut-01',
        productCode: 'GID-SUT-1L',
        productName: 'UHT Süt 1 L',
        lotNo: 'LOT-SUT-2026-07',
        expiryDate: now.add(const Duration(days: 90)),
        quantity: 200,
        unit: 'ADET',
        warehouseCode: GidaSfaCompany.warehouseCode,
        warehouseName: GidaSfaCompany.warehouseName,
        status: BatchExpiryStatus.ok,
        approvalStatus: 1,
        createdAt: now,
        updatedAt: now,
      ),
      BatchExpiryRecord(
        id: 'lot-agd-yag-a',
        productId: 'prd-agd-yag-01',
        productCode: 'GID-YAG-18',
        productName: 'Ayçiçek Yağı 18 L',
        lotNo: 'LOT-YAG-2026-05',
        expiryDate: now.add(const Duration(days: 20)),
        quantity: 40,
        unit: 'BIDON',
        warehouseCode: GidaSfaCompany.warehouseCode,
        warehouseName: GidaSfaCompany.warehouseName,
        status: BatchExpiryStatus.near,
        approvalStatus: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// {@template gida_sfa_seed_vat_line}
  /// Satır KDV + genel toplam (KDV dahil).
  ///
  /// Parametreler:
  /// - [qty]: Miktar
  /// - [unitPrice]: Birim fiyat (KDV hariç)
  /// - [vatRate]: KDV %
  ///
  /// Dönüş değeri:
  /// - [({vat, total})]: KDV tutarı ve satır toplamı
  /// {@endtemplate}
  static ({double vat, double total}) lineTotals({
    required double qty,
    required double unitPrice,
    required int vatRate,
  }) {
    final net = qty * unitPrice;
    final vat = net * vatRate / 100.0;
    return (vat: vat, total: net + vat);
  }

  /// {@template gida_sfa_seed_risk_ok}
  /// Sipariş tutarı risk limitini aşıyor mu.
  ///
  /// Parametreler:
  /// - [balance]: Cari bakiye
  /// - [creditLimit]: Risk limiti
  /// - [orderAmount]: Sipariş genel toplam
  ///
  /// Dönüş değeri:
  /// - [bool]: Limit içindeyse true
  /// {@endtemplate}
  static bool isWithinRiskLimit({
    required double balance,
    required double creditLimit,
    required double orderAmount,
  }) {
    return balance + orderAmount <= creditLimit;
  }
}
