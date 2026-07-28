// Dosya Adı: supply_request_logo_sync_mapper_test.dart
// Açıklama: Tedarik talep sync_queue payload + enqueue
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/ai_insights/model/supplier_purchase_request.dart';
import 'package:exfin_ops/modules/field_sales/ai_insights/viewmodel/supply_request_logo_sync_mapper.dart';
import 'package:exfin_ops/service/job_queue_entity_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute(SqlQuerys.createSyncQueueTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('payload purchase order alanları + entity_type map', () {
    final row = SupplierPurchaseRequest(
      id: 'req1',
      productId: 'p1',
      productCode: 'P001',
      productName: 'Ürün',
      quantity: 12,
      supplierCode: 'S1',
      onay: 1,
      status: SupplierPurchaseRequestStatus.approved,
    );
    final prev = SupplyRequestLogoSyncMapper.useRealLogoPurchasePath;
    SupplyRequestLogoSyncMapper.useRealLogoPurchasePath = true;
    final p = SupplyRequestLogoSyncMapper.payload(row: row);
    SupplyRequestLogoSyncMapper.useRealLogoPurchasePath = prev;
    expect(p['entity'], SupplyRequestLogoSyncMapper.entityType);
    expect(p['type'], 'purchase');
    expect(p['order_type'], 'purchase');
    expect(p['ARP_CODE'], 'S1');
    expect(p['lines'], isA<List>());
    expect((p['lines'] as List).first['MASTER_CODE'], 'P001');
    expect(p['stub'], isFalse);
    expect(
      jobQueueEntityTable('supplier_purchase_request'),
      'supplier_purchase_requests',
    );
  });

  test('enqueue sync_queue satırı yazar', () async {
    final row = SupplierPurchaseRequest(
      id: 'req2',
      productId: 'p2',
      productCode: 'P002',
      quantity: 5,
      onay: 1,
      status: SupplierPurchaseRequestStatus.approved,
    );
    final jobId = await SupplyRequestLogoSyncMapper.enqueueApproved(
      db: db,
      row: row,
    );
    expect(jobId, isNotEmpty);
    final jobs = await db.query('sync_queue');
    expect(jobs.length, 1);
    expect(jobs.first['entity_type'], 'supplier_purchase_request');
    expect(jobs.first['entity_id'], 'req2');
    final payload = jsonDecode(jobs.first['payload'] as String) as Map;
    expect(payload['product_code'], 'P002');
  });
}
