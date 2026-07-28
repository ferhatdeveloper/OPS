// Dosya Adı: gida_sfa_crud_playback_test.dart
// Açıklama: Anadolu Gıda — cari/ürün/sipariş/tahsilat/ekstre CRUD playback
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:exfin_ops/modules/field_sales/collections/model/finance_movement_type.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_extract_store.dart';
import 'package:exfin_ops/modules/field_sales/demo/gida_sfa_seed.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_dens_scope.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_approval_store.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_dens_store.dart';
import 'package:exfin_ops/modules/field_sales/products/model/product_catalog_row.dart';
import 'package:exfin_ops/modules/field_sales/products/viewmodel/product_catalog_store.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/warehouse_stock_query_store.dart';
import 'package:exfin_ops/modules/whms/data/local_warehouse_stock_balance_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ProductCatalogStore productStore;
  late OrderDensStore orderDensStore;
  late OrderApprovalStore orderApprovalStore;
  late CustomerExtractStore extractStore;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await GidaSfaSeed.applySchema(db);
      },
    );
    Future<Database> openDb() async => db;
    productStore = ProductCatalogStore(openDb: openDb);
    orderDensStore = OrderDensStore(openDb: openDb);
    orderApprovalStore = OrderApprovalStore(openDb: openDb);
    extractStore = CustomerExtractStore(openDb: openDb);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    await db.insert('sync_queue', {
      'id': const Uuid().v4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'priority': 0,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> queueFor(
    String entityType,
    String entityId,
  ) {
    return db.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );
  }

  test(
    'Gıda SFA playback: cari → ürün → sipariş → tahsilat → ekstre → '
    'ziyaret/stok/fatura stub',
    () async {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final periodFrom = DateTime(now.year, now.month, 1);
      final periodTo = DateTime(now.year, now.month + 1, 0);

      // ─── 0) Ambar master ───────────────────────────────────────────────
      await GidaSfaSeed.seedMasters(
        db,
        includeCustomers: false,
        includeProducts: false,
      );
      expect(
        await db.query(
          'warehouses',
          where: 'code = ?',
          whereArgs: [GidaSfaCompany.warehouseCode],
        ),
        isNotEmpty,
      );

      // ─── 1) Cari CRUD ──────────────────────────────────────────────────
      for (final c in GidaSfaSeed.customers) {
        final map = c.toMap(now: nowIso);
        map['credit_limit'] = c.creditLimit;
        await db.insert('customers', map);
        await enqueue(
          entityType: 'customer',
          entityId: c.id,
          payload: {...map, 'op': 'upsert', 'ONAY': 1},
        );
      }
      var customers = await db.query(
        'customers',
        where: 'COALESCE(is_active, 1) = 1',
      );
      expect(customers, hasLength(2), reason: 'Cari Create');
      expect(customers.any((r) => r['code'] == 'C-AGD-1001'), isTrue);

      final market = customers.firstWhere(
        (r) => r['id'] == GidaSfaSeed.marketCustomer.id,
      );
      expect(market['name'], 'Yeşil Market Zinciri A.Ş.');
      expect((market['credit_limit'] as num).toDouble(), 50000);

      await db.update(
        'customers',
        {
          'phone': '02129998877',
          'address': 'Atatürk Cad. No:12 / A',
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [GidaSfaSeed.marketCustomer.id],
      );
      await enqueue(
        entityType: 'customer',
        entityId: GidaSfaSeed.marketCustomer.id,
        payload: {
          'id': GidaSfaSeed.marketCustomer.id,
          'op': 'upsert',
          'phone': '02129998877',
          'ONAY': 1,
        },
      );
      expect(
        (await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [GidaSfaSeed.marketCustomer.id],
          limit: 1,
        ))
            .single['phone'],
        '02129998877',
        reason: 'Cari Update',
      );

      const tempCariId = 'cari-agd-temp-del';
      await db.insert('customers', {
        'id': tempCariId,
        'code': 'C-AGD-TEMP',
        'name': 'Geçici Bakkal',
        'is_active': 1,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
      await db.update(
        'customers',
        {'is_active': 0, 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: [tempCariId],
      );
      await enqueue(
        entityType: 'customer',
        entityId: tempCariId,
        payload: {'id': tempCariId, 'op': 'deactivate', 'ONAY': 1},
      );
      final active = await db.query(
        'customers',
        where: 'COALESCE(is_active, 1) = 1',
      );
      expect(active.any((r) => r['id'] == tempCariId), isFalse);
      expect(await queueFor('customer', tempCariId), isNotEmpty);

      // ─── 2) Ürün CRUD + lot ────────────────────────────────────────────
      for (final p in GidaSfaSeed.products) {
        await productStore.upsert(p);
      }
      for (final lot in GidaSfaSeed.foodLots()) {
        await db.insert('batch_expiry', lot.toMap());
      }
      for (final p in GidaSfaSeed.products) {
        await db.insert(
          'warehouse_stocks',
          {
            'warehouse_code': GidaSfaCompany.warehouseCode,
            'product_id': p.id,
            'quantity': p.stockQuantity,
            'is_synced': 0,
            'created_at': nowIso,
            'updated_at': nowIso,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      var products = await productStore.loadAll(limit: 0);
      expect(products.length, greaterThanOrEqualTo(4), reason: 'Ürün Read');
      expect(
        products.firstWhere((p) => p.code == 'GID-SUT-1L').vatRate,
        1,
      );
      expect(
        products.firstWhere((p) => p.code == 'GID-GAZ-33').vatRate,
        20,
      );
      expect(
        await db.query('batch_expiry'),
        hasLength(2),
        reason: 'Lot/SKT',
      );

      final unUpdated = await productStore.upsert(
        const ProductCatalogRow(
          id: 'prd-agd-un-01',
          code: 'GID-UN-50',
          name: 'Un 50 kg',
          barcode: '8690123456001',
          unit: 'CUVAL',
          price: 495,
          vatRate: 1,
          stockQuantity: 200,
          category: 'UN',
        ),
      );
      expect(unUpdated.price, 495, reason: 'Ürün Update');

      await productStore.upsert(
        const ProductCatalogRow(
          id: 'prd-agd-temp-del',
          code: 'GID-TEMP',
          name: 'Geçici SKU',
          price: 1,
          vatRate: 20,
        ),
      );
      expect(await productStore.deleteById('prd-agd-temp-del'), isTrue);
      expect(await productStore.getById('prd-agd-temp-del'), isNull);
      expect(await queueFor('product', 'prd-agd-temp-del'), isNotEmpty);

      // ─── 3) Sipariş Create + satır + onay ───────────────────────────────
      const orderId = 'ord-agd-001';
      final un = GidaSfaSeed.products.firstWhere((p) => p.code == 'GID-UN-50');
      final yag =
          GidaSfaSeed.products.firstWhere((p) => p.code == 'GID-YAG-18');
      final sut =
          GidaSfaSeed.products.firstWhere((p) => p.code == 'GID-SUT-1L');

      final lineUn = GidaSfaSeed.lineTotals(
        qty: 10,
        unitPrice: 495,
        vatRate: un.vatRate,
      );
      final lineYag = GidaSfaSeed.lineTotals(
        qty: 5,
        unitPrice: yag.price,
        vatRate: yag.vatRate,
      );
      final lineSut = GidaSfaSeed.lineTotals(
        qty: 48,
        unitPrice: sut.price,
        vatRate: sut.vatRate,
      );
      final orderTotal = lineUn.total + lineYag.total + lineSut.total;

      expect(
        GidaSfaSeed.isWithinRiskLimit(
          balance: GidaSfaSeed.marketCustomer.balance,
          creditLimit: GidaSfaSeed.marketCustomer.creditLimit,
          orderAmount: orderTotal,
        ),
        isTrue,
        reason: 'Risk limiti',
      );

      await db.insert('orders', {
        'id': orderId,
        'customer_id': GidaSfaSeed.marketCustomer.id,
        'order_date': nowIso,
        'total_amount': orderTotal,
        'status': 'Pending',
        'notes': 'Anadolu Gıda plasiyer siparişi',
        'is_synced': 0,
        'is_deleted': 0,
        'approval_status': 0,
        'order_type': 'sales',
        'created_at': nowIso,
        'updated_at': nowIso,
      });

      Future<void> insertLine({
        required String id,
        required ProductCatalogRow product,
        required double qty,
        required double unitPrice,
        required ({double vat, double total}) totals,
      }) async {
        await db.insert('order_items', {
          'id': id,
          'order_id': orderId,
          'product_id': product.id,
          'unit_name': product.unit,
          'quantity': qty,
          'price': unitPrice,
          'vat_amount': totals.vat,
          'total_amount': totals.total,
          'discount_percent': 0,
        });
      }

      await insertLine(
        id: '${orderId}_l1',
        product: un,
        qty: 10,
        unitPrice: 495,
        totals: lineUn,
      );
      await insertLine(
        id: '${orderId}_l2',
        product: yag,
        qty: 5,
        unitPrice: yag.price,
        totals: lineYag,
      );
      await insertLine(
        id: '${orderId}_l3',
        product: sut,
        qty: 48,
        unitPrice: sut.price,
        totals: lineSut,
      );

      expect(
        await orderDensStore.fetchOrderItems(orderId),
        hasLength(3),
        reason: 'Sipariş satır',
      );
      expect(
        (await orderDensStore.query(OrderDensScope.pending))
            .any((r) => r.id == orderId),
        isTrue,
        reason: 'Sipariş Read pending',
      );

      final approved = await orderApprovalStore.updateStatus(
        id: orderId,
        status: 'Approved',
      );
      expect(approved, 1);
      await db.update(
        'orders',
        {'approval_status': 1, 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: [orderId],
      );
      await enqueue(
        entityType: 'order',
        entityId: orderId,
        payload: {
          'id': orderId,
          'op': 'upsert',
          'status': 'Approved',
          'ONAY': 1,
          'approval_status': 1,
          'total_amount': orderTotal,
        },
      );

      final header = await orderDensStore.fetchOrderHeader(orderId);
      expect(header?['status'], 'Approved', reason: 'Sipariş onay');
      expect(header?['approval_status'], 1);
      final orderQueue = await queueFor('order', orderId);
      expect(orderQueue, isNotEmpty);
      expect(
        (jsonDecode(orderQueue.first['payload']! as String)
            as Map)['ONAY'],
        1,
      );

      // Soft-delete başka sipariş (D)
      const delOrderId = 'ord-agd-del';
      await db.insert('orders', {
        'id': delOrderId,
        'customer_id': GidaSfaSeed.marketCustomer.id,
        'order_date': nowIso,
        'total_amount': 10,
        'status': 'Pending',
        'is_synced': 0,
        'is_deleted': 0,
        'approval_status': 0,
        'order_type': 'sales',
      });
      expect(await orderDensStore.softDeleteLocal(delOrderId), isTrue);
      expect(
        (await orderDensStore.query(OrderDensScope.untransferred))
            .any((r) => r.id == delOrderId),
        isFalse,
        reason: 'Sipariş Delete',
      );

      // ─── 4) Tahsilat (nakit + çek + senet) ──────────────────────────────
      Future<String> saveCollection({
        required String id,
        required String paymentType,
        required double amount,
        String? checkNumber,
        String? bankName,
        DateTime? dueDate,
        String? notes,
      }) async {
        final normalized =
            FinanceMovementType.normalizeApiCode(paymentType);
        await db.insert('collections', {
          'id': id,
          'customer_id': GidaSfaSeed.marketCustomer.id,
          'amount': amount,
          'payment_type': normalized,
          'collection_date': nowIso,
          'status': 'Completed',
          'notes': notes,
          'bank_name': bankName,
          'check_number': checkNumber,
          'due_date': dueDate?.toIso8601String(),
          'cash_code': 'KASA01',
          'document_no': 'THS-$id',
          'currency_code': 'TRY',
          'salesperson_code': 'PLS-AGD-01',
          'approval_status': 1,
          'is_synced': 0,
          'created_at': nowIso,
          'updated_at': nowIso,
        });
        final movement = CustomerExtractStore.movementFromCollection(
          collectionId: id,
          customerId: GidaSfaSeed.marketCustomer.id,
          collectionDate: now,
          amount: amount,
          paymentType: normalized,
          documentNo: 'THS-$id',
          notes: notes,
        );
        if (movement != null) {
          await extractStore.insert(movement);
        }
        await enqueue(
          entityType: 'collection',
          entityId: id,
          payload: {
            'id': id,
            'op': 'upsert',
            'payment_type': normalized,
            'amount': amount,
            'ONAY': 1,
            'approval_status': 1,
          },
        );
        return id;
      }

      await saveCollection(
        id: 'col-agd-cash',
        paymentType: 'Cash',
        amount: 1500,
        notes: 'Nakit tahsilat — Yeşil Market',
      );
      await saveCollection(
        id: 'col-agd-check',
        paymentType: 'Check',
        amount: 3000,
        checkNumber: 'CK-2026-7788',
        bankName: 'Ziraat',
        dueDate: now.add(const Duration(days: 30)),
        notes: 'Çek tahsilat',
      );
      await saveCollection(
        id: 'col-agd-note',
        paymentType: 'note',
        amount: 2000,
        checkNumber: 'SN-2026-11',
        dueDate: now.add(const Duration(days: 60)),
        notes: 'Senet tahsilat',
      );

      final collections = await db.query(
        'collections',
        where: 'customer_id = ?',
        whereArgs: [GidaSfaSeed.marketCustomer.id],
      );
      expect(collections, hasLength(3), reason: 'Tahsilat Create');
      expect(
        collections.every((r) => (r['approval_status'] as int?) == 1),
        isTrue,
      );
      expect(await queueFor('collection', 'col-agd-cash'), isNotEmpty);

      // U — nakit tutar düzelt
      await db.update(
        'collections',
        {'amount': 1600, 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: ['col-agd-cash'],
      );
      expect(
        (await db.query(
          'collections',
          where: 'id = ?',
          whereArgs: ['col-agd-cash'],
        ))
            .single['amount'],
        1600,
        reason: 'Tahsilat Update',
      );

      // ─── 5) Fatura stub + cari ekstre ───────────────────────────────────
      const invoiceId = 'inv-agd-001';
      final invoiceAmount = orderTotal;
      await db.insert('invoices', {
        'id': invoiceId,
        'customer_id': GidaSfaSeed.marketCustomer.id,
        'invoice_date': nowIso,
        'total_amount': invoiceAmount,
        'status': 'Completed',
        'notes': 'Satış faturası stub',
        'invoice_type': 'Sales',
        'is_e_invoice': 1,
        'approval_status': 1,
        'is_synced': 0,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
      await extractStore.insert(
        CustomerExtractStore.movementFromInvoice(
          invoiceId: invoiceId,
          customerId: GidaSfaSeed.marketCustomer.id,
          invoiceDate: now,
          totalAmount: invoiceAmount,
          invoiceType: 'Sales',
          notes: 'Satış faturası',
        ),
      );
      await enqueue(
        entityType: 'invoice',
        entityId: invoiceId,
        payload: {
          'id': invoiceId,
          'op': 'upsert',
          'ONAY': 1,
          'approval_status': 1,
          'invoice_type': 'Sales',
        },
      );

      final movements = await extractStore.query(
        customerId: GidaSfaSeed.marketCustomer.id,
        start: periodFrom,
        end: periodTo,
      );
      expect(movements, isNotEmpty, reason: 'Cari ekstre Read');
      expect(
        movements.any((m) => m.id == 'inv-$invoiceId'),
        isTrue,
        reason: 'Fatura borç hareketi',
      );
      expect(
        movements.any((m) => m.id.startsWith('col-')),
        isTrue,
        reason: 'Tahsilat alacak hareketi',
      );

      final recon = await extractStore.reconciliationSummary(
        customerId: GidaSfaSeed.marketCustomer.id,
        start: periodFrom,
        end: periodTo,
      );
      expect(recon.periodDebit, greaterThan(0));
      expect(recon.periodCredit, greaterThan(0));

      // ─── 6) Ziyaret CRUD ───────────────────────────────────────────────
      const visitId = 'vis-agd-001';
      await db.insert('visits', {
        'id': visitId,
        'customer_id': GidaSfaSeed.marketCustomer.id,
        'user_id': 'pls-agd-01',
        'check_in_at': nowIso,
        'check_in_lat': 41.0082,
        'check_in_long': 28.9784,
        'notes': 'Gıda sipariş + tahsilat ziyareti',
        'status': 'Open',
        'is_synced': 0,
        'created_at': nowIso,
      });
      await enqueue(
        entityType: 'visit',
        entityId: visitId,
        payload: {'id': visitId, 'op': 'upsert', 'ONAY': 1},
      );
      expect(
        await db.query('visits', where: 'id = ?', whereArgs: [visitId]),
        hasLength(1),
        reason: 'Ziyaret Create',
      );
      await db.update(
        'visits',
        {
          'check_out_at': now.add(const Duration(minutes: 35)).toIso8601String(),
          'status': 'Completed',
          'duration_minutes': 35,
        },
        where: 'id = ?',
        whereArgs: [visitId],
      );
      expect(
        (await db.query(
          'visits',
          where: 'id = ?',
          whereArgs: [visitId],
        ))
            .single['status'],
        'Completed',
        reason: 'Ziyaret Update',
      );

      // ─── 7) Stok sorgu ─────────────────────────────────────────────────
      final stockStore = WarehouseStockQueryStore(
        dbOverride: db,
        portOverride: LocalWarehouseStockBalancePort(db),
      );
      final stockRows = await stockStore.listForWarehouse(
        GidaSfaCompany.warehouseCode,
      );
      expect(stockRows, isNotEmpty, reason: 'Stok sorgu Read');
      expect(
        stockRows.any((r) => r.productCode == 'GID-UN-50'),
        isTrue,
      );

      // ─── 8) WHMS mal kabul kısa stub (ONAY=1 kuyruk) ───────────────────
      const whmsOrderId = 'whms-agd-mk-01';
      await enqueue(
        entityType: 'whms_order_mal_kabul',
        entityId: whmsOrderId,
        payload: {
          'id': whmsOrderId,
          'warehouse_code': GidaSfaCompany.warehouseCode,
          'product_code': 'GID-UN-50',
          'quantity': 20,
          'ONAY': 1,
          'op': 'mal_kabul',
        },
      );
      final whmsQ = await queueFor('whms_order_mal_kabul', whmsOrderId);
      expect(whmsQ, isNotEmpty);
      expect(
        (jsonDecode(whmsQ.first['payload']! as String) as Map)['ONAY'],
        1,
      );
    },
  );
}
