// Dosya Adı: visit_history_store_test.dart
// Açıklama: Geçmiş ziyaret dens satır / detay / dönem saf sorgu testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_history_record.dart';
import 'package:exfin_ops/modules/field_sales/routes/viewmodel/visit_history_store.dart';

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
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createCustomersTable);
        await db.execute(SqlQuerys.createVisitsTable);
        await db.execute(SqlQuerys.createOrdersTable);
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha Market',
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta Bakkal',
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('VisitHistoryStore', () {
    test('visits JOIN customers ile dens kayıt yükler (yeniden eskiye)',
        () async {
      await db.insert('visits', {
        'id': 'v-old',
        'customer_id': 'c2',
        'check_in_at': '2026-07-20T09:00:00.000',
        'check_out_at': '2026-07-20T09:28:00.000',
        'status': 'Completed',
        'duration_minutes': 28,
        'is_synced': 1,
      });
      await db.insert('visits', {
        'id': 'v-new',
        'customer_id': 'c1',
        'check_in_at': '2026-07-24T10:00:00.000',
        'check_out_at': '2026-07-24T10:42:00.000',
        'status': 'Completed',
        'duration_minutes': 42,
        'is_synced': 0,
      });
      await db.insert('visits', {
        'id': 'v-open',
        'customer_id': 'c1',
        'check_in_at': '2026-07-25T11:00:00.000',
        'status': 'Open',
        'duration_minutes': null,
        'is_synced': 0,
      });

      final store = VisitHistoryStore(openDb: () async => db);
      final rows = await store.loadAll();

      expect(rows, hasLength(3));
      expect(rows[0].id, 'v-open');
      expect(rows[0].customerName, 'Alpha Market');
      expect(rows[0].statusKind, VisitHistoryStatusKind.open);
      expect(rows[0].statusL10nKey, 'field_sales.active_visit_status');
      expect(rows[0].durationMinutes, isNull);

      expect(rows[1].id, 'v-new');
      expect(rows[1].customerName, 'Alpha Market');
      expect(rows[1].statusKind, VisitHistoryStatusKind.completed);
      expect(rows[1].statusL10nKey, 'field_sales.visit_completed');
      expect(rows[1].durationMinutes, 42);
      expect(rows[1].formattedDate, '24.07.2026');

      expect(rows[2].id, 'v-old');
      expect(rows[2].customerName, 'Beta Bakkal');
      expect(rows[2].durationMinutes, 28);
    });

    test('cari ve tarih filtresi dens satırları daraltır', () async {
      await db.insert('visits', {
        'id': 'v-a',
        'customer_id': 'c1',
        'check_in_at': '2026-07-10T09:00:00.000',
        'status': 'Completed',
        'duration_minutes': 10,
      });
      await db.insert('visits', {
        'id': 'v-b',
        'customer_id': 'c1',
        'check_in_at': '2026-07-24T09:00:00.000',
        'status': 'Completed',
        'duration_minutes': 20,
      });
      await db.insert('visits', {
        'id': 'v-c',
        'customer_id': 'c2',
        'check_in_at': '2026-07-24T10:00:00.000',
        'status': 'Completed',
        'duration_minutes': 15,
      });

      final store = VisitHistoryStore(openDb: () async => db);
      final rows = await store.loadFiltered(
        customerId: 'c1',
        start: DateTime(2026, 7, 20),
        end: DateTime(2026, 7, 31),
      );

      expect(rows, hasLength(1));
      expect(rows.first.id, 'v-b');
    });

    test('loadDetail check-in/out GPS not STT ve ilişkili sipariş döner',
        () async {
      await db.insert('visits', {
        'id': 'v-det',
        'customer_id': 'c1',
        'check_in_at': '2026-07-24T10:00:00.000',
        'check_out_at': '2026-07-24T10:42:00.000',
        'check_in_lat': 41.01,
        'check_in_long': 28.97,
        'check_out_lat': 41.02,
        'check_out_long': 28.98,
        'notes': 'STT not metni',
        'reason_code': 'ROUTINE',
        'audio_recording_path': '/tmp/v-det_speech.m4a',
        'status': 'Completed',
        'duration_minutes': 42,
        'is_synced': 1,
      });
      await db.insert('orders', {
        'id': 'o1',
        'customer_id': 'c1',
        'order_date': '2026-07-24T11:00:00.000',
        'total_amount': 150.0,
        'status': 'Pending',
        'is_deleted': 0,
      });
      await db.insert('orders', {
        'id': 'o-other-day',
        'customer_id': 'c1',
        'order_date': '2026-07-01T11:00:00.000',
        'total_amount': 10.0,
        'status': 'Pending',
        'is_deleted': 0,
      });

      final store = VisitHistoryStore(openDb: () async => db);
      final detail = await store.loadDetail('v-det');

      expect(detail, isNotNull);
      expect(detail!.customerName, 'Alpha Market');
      expect(detail.isCompleted, isTrue);
      expect(detail.notes, 'STT not metni');
      expect(detail.audioRecordingPath, '/tmp/v-det_speech.m4a');
      expect(detail.checkInLat, 41.01);
      expect(detail.relatedOrders, hasLength(1));
      expect(detail.relatedOrders.first.id, 'o1');
      expect(detail.relatedOrders.first.totalAmount, 150.0);
    });

    test('cari adı yoksa customer_id düşer', () async {
      await db.insert('visits', {
        'id': 'v-orphan',
        'customer_id': 'missing-c',
        'check_in_at': '2026-07-22T08:00:00.000',
        'status': 'Completed',
        'duration_minutes': 15,
      });

      final store = VisitHistoryStore(openDb: () async => db);
      final rows = await store.loadAll();

      expect(rows, hasLength(1));
      expect(rows.first.customerName, 'missing-c');
    });

    test('rangeForPeriod bugün/hafta/ay/yıl aralıkları (saf)', () {
      final now = DateTime(2026, 7, 28);
      expect(
        VisitHistoryStore.rangeForPeriod(
          VisitHistoryPeriod.today,
          now: now,
        ),
        (DateTime(2026, 7, 28), DateTime(2026, 7, 28)),
      );
      final week = VisitHistoryStore.rangeForPeriod(
        VisitHistoryPeriod.thisWeek,
        now: now,
      );
      expect(week.$1, DateTime(2026, 7, 27)); // Mon
      expect(week.$2, DateTime(2026, 8, 2)); // Sun
      final month = VisitHistoryStore.rangeForPeriod(
        VisitHistoryPeriod.thisMonth,
        now: now,
      );
      expect(month.$1, DateTime(2026, 7, 1));
      expect(month.$2, DateTime(2026, 7, 31));
      final year = VisitHistoryStore.rangeForPeriod(
        VisitHistoryPeriod.thisYear,
        now: now,
      );
      expect(year.$1, DateTime(2026, 1, 1));
      expect(year.$2, DateTime(2026, 12, 31));
    });

    test('formatDuration / formatGps / formatDateTime saf metin', () {
      String translate(String key, {Map<String, String>? args}) {
        if (key == 'field_sales.visit_duration_minutes') {
          return '${args!['minutes']} dk';
        }
        if (key == 'field_sales.visit_duration_unknown') return '—';
        if (key == 'field_sales.visit_gps_unknown') return 'Konum yok';
        if (key == 'field_sales.visit_datetime_unknown') return '—';
        return key;
      }

      expect(
        VisitHistoryStore.formatDuration(42, translate: translate),
        '42 dk',
      );
      expect(
        VisitHistoryStore.formatDuration(null, translate: translate),
        '—',
      );
      expect(
        VisitHistoryStore.formatGps(null, null, translate: translate),
        'Konum yok',
      );
      expect(
        VisitHistoryStore.formatGps(41.0, 29.0, translate: translate),
        '41.00000, 29.00000',
      );
      expect(
        VisitHistoryStore.formatDateTime(null, translate: translate),
        '—',
      );
    });

    test('statusKind bilinmeyen Completed/Open dışı değeri open yapar', () {
      expect(
        VisitHistoryRecord.statusKindFrom('Completed'),
        VisitHistoryStatusKind.completed,
      );
      expect(
        VisitHistoryRecord.statusKindFrom('completed'),
        VisitHistoryStatusKind.completed,
      );
      expect(
        VisitHistoryRecord.statusKindFrom('Open'),
        VisitHistoryStatusKind.open,
      );
      expect(
        VisitHistoryRecord.statusKindFrom('weird'),
        VisitHistoryStatusKind.open,
      );
    });
  });
}
