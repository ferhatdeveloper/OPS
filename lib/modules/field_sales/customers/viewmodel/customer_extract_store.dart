// Dosya Adı: customer_extract_store.dart
// Açıklama: Cari ekstre hareketleri SQLite erişim + minimal seed
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../../../../service/database_service.dart';
import '../../collections/model/finance_movement_type.dart';
import '../model/customer_extract_movement.dart';

/// {@template customer_extract_store}
/// `customer_movements` tablosunu oluşturur, boşsa seedler, sorgular.
///
/// Kullanım örneği:
/// ```dart
/// final store = CustomerExtractStore();
/// final rows = await store.query(
///   customerId: 'C-100',
///   start: DateTime(2026, 7, 1),
///   end: DateTime(2026, 7, 31),
/// );
/// ```
/// {@endtemplate}
class CustomerExtractStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro customer_extract_store}
  const CustomerExtractStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'customer_movements';

  /// {@template customer_extract_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template customer_extract_store_ensure_table}
  /// Yalnızca tabloyu oluşturur (seed yok).
  ///
  /// Parametreler:
  /// - [executor]: İsteğe bağlı açık DB / txn
  /// {@endtemplate}
  Future<void> ensureTable([DatabaseExecutor? executor]) async {
    final db = executor ?? await _db();
    await db.execute(SqlQuerys.createCustomerMovementsTable);
  }

  /// {@template customer_extract_store_ensure}
  /// Tabloyu oluşturur (yoksa) ve boşsa seed ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await ensureTable(db);
    await seedIfEmpty(db);
  }

  /// {@template customer_extract_store_insert}
  /// Cari hareket satırı ekler / aynı id ile değiştirir.
  ///
  /// Parametreler:
  /// - [movement]: Kaydedilecek hareket
  /// - [executor]: txn veya DB (yoksa kendi bağlantısı)
  /// {@endtemplate}
  Future<void> insert(
    CustomerExtractMovement movement, {
    DatabaseExecutor? executor,
  }) async {
    final cari = movement.customerId.trim();
    if (cari.isEmpty) return;
    if (movement.debit <= 0 && movement.credit <= 0) return;

    final db = executor ?? await _db();
    await ensureTable(db);
    await db.insert(
      tableName,
      movement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// {@template customer_extract_store_from_invoice}
  /// Fatura kaydından cari hareket üretir.
  /// Satış → borç; iade / alış → alacak.
  ///
  /// Parametreler:
  /// - [invoiceId]: Fatura id (hareket id: `inv-{id}`)
  /// - [customerId]: Cari id
  /// - [invoiceDate]: Fatura tarihi
  /// - [totalAmount]: Genel toplam
  /// - [invoiceType]: Yerel tip anahtarı
  /// - [notes]: Açıklama yedek metni
  ///
  /// Dönüş değeri:
  /// - [CustomerExtractMovement]: Ekstre satırı
  /// {@endtemplate}
  static CustomerExtractMovement movementFromInvoice({
    required String invoiceId,
    required String customerId,
    required DateTime invoiceDate,
    required double totalAmount,
    String? invoiceType,
    String? notes,
  }) {
    final queue =
        LogoPayloadMapper.resolveInvoiceQueueType(invoiceType);
    final amount = totalAmount.abs();
    final isCredit = queue == LogoPayloadMapper.invoiceQueueReturn ||
        queue == LogoPayloadMapper.invoiceQueuePurchase;
    final note = (notes ?? '').trim();
    final String description;
    if (note.isNotEmpty) {
      description = note;
    } else if (queue == LogoPayloadMapper.invoiceQueueReturn) {
      description = 'Satış iade';
    } else if (queue == LogoPayloadMapper.invoiceQueuePurchase) {
      description = 'Alış faturası';
    } else {
      description = 'Satış faturası';
    }

    return CustomerExtractMovement(
      id: 'inv-$invoiceId',
      customerId: customerId.trim(),
      movementDate: invoiceDate,
      documentNo: invoiceId,
      description: description,
      debit: isCredit ? 0 : amount,
      credit: isCredit ? amount : 0,
    );
  }

  /// {@template customer_extract_store_from_collection}
  /// Tahsilat / ödeme kaydından cari hareket üretir.
  /// Tahsilat → alacak; ödeme → borç; virman → null.
  ///
  /// Parametreler:
  /// - [collectionId]: Tahsilat id
  /// - [customerId]: Cari id
  /// - [collectionDate]: İşlem tarihi
  /// - [amount]: Tutar
  /// - [paymentType]: API / storage tipi
  /// - [documentNo]: Evrak no
  /// - [notes]: Açıklama
  ///
  /// Dönüş değeri:
  /// - [CustomerExtractMovement?]: Virmanda null
  /// {@endtemplate}
  static CustomerExtractMovement? movementFromCollection({
    required String collectionId,
    required String customerId,
    required DateTime collectionDate,
    required double amount,
    required String paymentType,
    String? documentNo,
    String? notes,
  }) {
    final type = FinanceMovementType.fromStorage(paymentType);
    if (type.kind == FinanceMovementKind.virman) return null;

    final cari = customerId.trim();
    if (cari.isEmpty) return null;

    final absAmount = amount.abs();
    final isPayment = type.kind == FinanceMovementKind.payment;
    final note = (notes ?? '').trim();
    final doc = (documentNo ?? '').trim();
    final String description;
    if (note.isNotEmpty) {
      description = note;
    } else if (isPayment) {
      description = 'Ödeme';
    } else {
      switch (type) {
        case FinanceMovementType.creditCardCollection:
          description = 'Kredi kartı tahsilat';
          break;
        case FinanceMovementType.checkCollection:
          description = 'Çek tahsilat';
          break;
        case FinanceMovementType.noteCollection:
          description = 'Senet tahsilat';
          break;
        default:
          description = 'Nakit tahsilat';
      }
    }

    return CustomerExtractMovement(
      id: 'col-$collectionId',
      customerId: cari,
      movementDate: collectionDate,
      documentNo: doc.isNotEmpty ? doc : collectionId,
      description: description,
      debit: isPayment ? absAmount : 0,
      credit: isPayment ? 0 : absAmount,
    );
  }

  /// {@template customer_extract_store_seed_if_empty}
  /// Tablo boşsa MBT dens örnek hareketleri ekler.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// {@endtemplate}
  Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableName '
            'WHERE COALESCE(is_deleted, 0) = 0',
          ),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now();
    final midMonth = DateTime(now.year, now.month, 15);
    final earlyMonth = DateTime(now.year, now.month, 5);
    final prevMonth = DateTime(now.year, now.month - 1, 20);

    final seeds = <CustomerExtractMovement>[
      CustomerExtractMovement(
        id: 'seed-mv-inv-c100',
        customerId: 'C-100',
        movementDate: earlyMonth,
        documentNo: 'FTR-1001',
        description: 'Satış faturası',
        debit: 1500,
        credit: 0,
      ),
      CustomerExtractMovement(
        id: 'seed-mv-col-c100',
        customerId: 'C-100',
        movementDate: midMonth,
        documentNo: 'THS-2001',
        description: 'Nakit tahsilat',
        debit: 0,
        credit: 500,
      ),
      CustomerExtractMovement(
        id: 'seed-mv-inv-prev',
        customerId: 'C-100',
        movementDate: prevMonth,
        documentNo: 'FTR-0901',
        description: 'Önceki ay fatura',
        debit: 800,
        credit: 0,
      ),
      CustomerExtractMovement(
        id: 'seed-mv-demo',
        customerId: 'DEMO',
        movementDate: earlyMonth,
        documentNo: 'FTR-DEMO',
        description: 'Demo satış',
        debit: 250,
        credit: 0,
      ),
    ];

    final batch = db.batch();
    for (final row in seeds) {
      batch.insert(
        tableName,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template customer_extract_store_query}
  /// Cari / dönem / borç-alacak / arama filtresiyle hareketleri döner.
  ///
  /// Parametreler:
  /// - [customerId]: İsteğe bağlı cari id
  /// - [start]: Başlangıç günü (dahil)
  /// - [end]: Bitiş günü (dahil)
  /// - [filter]: Tümü / borç / alacak
  /// - [search]: Fiş no veya açıklama
  ///
  /// Dönüş değeri:
  /// - [List]: Tarih artan sıralı hareketler
  /// {@endtemplate}
  Future<List<CustomerExtractMovement>> query({
    String? customerId,
    required DateTime start,
    required DateTime end,
    ExtractMovementFilter filter = ExtractMovementFilter.all,
    String search = '',
  }) async {
    await ensureReady();
    final db = await _db();

    final where = <String>['COALESCE(is_deleted, 0) = 0'];
    final args = <Object?>[];

    final cari = customerId?.trim() ?? '';
    if (cari.isNotEmpty) {
      where.add('customer_id = ?');
      args.add(cari);
    }

    final startIso = DateTime(start.year, start.month, start.day)
        .toIso8601String();
    final endExclusive = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1));
    where.add('movement_date >= ?');
    args.add(startIso);
    where.add('movement_date < ?');
    args.add(endExclusive.toIso8601String());

    switch (filter) {
      case ExtractMovementFilter.debit:
        where.add('COALESCE(debit, 0) > 0');
        break;
      case ExtractMovementFilter.credit:
        where.add('COALESCE(credit, 0) > 0');
        break;
      case ExtractMovementFilter.all:
        break;
    }

    final q = search.trim();
    if (q.isNotEmpty) {
      final like = '%$q%';
      where.add('(document_no LIKE ? OR description LIKE ?)');
      args.add(like);
      args.add(like);
    }

    final rows = await db.query(
      tableName,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'movement_date ASC, document_no ASC',
    );

    return rows.map(CustomerExtractMovement.fromMap).toList();
  }
}
