// Dosya Adı: p3_smoke_test.dart
// Açıklama: P3 smoke — check-in coords, açık ziyaret redirect, STT store/path, geofence
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/gps/engine/order_geofence_gate.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_speech_audio_helper.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_speech_notes.dart';
import 'package:exfin_ops/modules/field_sales/routes/viewmodel/visit_open_redirect_logic.dart';
import 'package:exfin_ops/modules/field_sales/routes/viewmodel/visit_speech_to_text_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('P3 smoke: check-in coords', () {
    test('customers lat/lng rota dışı check-in için okunur', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() async => db.close());

      await db.execute(SqlQuerys.createCustomersTable);
      await db.insert('customers', {
        'id': 'c-smoke',
        'code': 'CS',
        'name': 'Smoke Cari',
        'latitude': 41.02,
        'longitude': 28.98,
        'is_active': 1,
        'created_at': '2026-07-28T00:00:00.000',
        'updated_at': '2026-07-28T00:00:00.000',
        'card_role': 'customer',
      });

      final rows = await db.query(
        'customers',
        columns: ['latitude', 'longitude'],
        where: 'id = ?',
        whereArgs: ['c-smoke'],
        limit: 1,
      );
      expect(rows, hasLength(1));
      expect((rows.first['latitude'] as num).toDouble(), 41.02);
      expect((rows.first['longitude'] as num).toDouble(), 28.98);
    });
  });

  group('P3 smoke: open visit redirect', () {
    test('visit_already_open → redirect true', () {
      expect(
        shouldRedirectToOpenVisit(kVisitAlreadyOpenErrorKey),
        isTrue,
      );
      expect(shouldRedirectToOpenVisit('other'), isFalse);
      expect(shouldRedirectToOpenVisit(null), isFalse);
    });

    test('boş customerId → yönlendirme yok', () {
      expect(openVisitRedirectCustomerId(null), isNull);
      expect(openVisitRedirectCustomerId('  '), isNull);
      expect(openVisitRedirectCustomerId('cust-1'), 'cust-1');
    });
  });

  group('P3 smoke: STT store + audio path', () {
    test('VisitSpeechNotes.buildAudioFilePath üretimi', () {
      expect(
        VisitSpeechNotes.buildAudioFilePath(
          directory: '/tmp/visits',
          visitId: 'v1',
        ),
        '/tmp/visits/v1_speech.m4a',
      );
      expect(
        VisitSpeechNotes.buildAudioFilePath(
          directory: '/tmp/',
          visitId: 'a/b',
        ),
        '/tmp/a_b_speech.m4a',
      );
    });

    test('VisitSpeechAudioHelper relative + planned path', () async {
      expect(
        VisitSpeechAudioHelper.buildRelativeFileName('vid', 1000),
        'visits/vid/speech_1000.m4a',
      );

      final root = await Directory.systemTemp.createTemp('visit_stt_');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });

      final path = await VisitSpeechAudioHelper.plannedRecordingPath(
        visitId: 'visit-smoke',
        nowMs: 42,
        documentsRoot: () async => root,
      );
      expect(path, isNotNull);
      expect(path!, contains('visits/visit-smoke/speech_42.m4a'));
      expect(await Directory('${root.path}/visits/visit-smoke').exists(), isTrue);
    });

    test('VisitSpeechState audioRecordingPath copyWith', () {
      const idle = VisitSpeechState();
      expect(idle.audioRecordingPath, isNull);
      final next = idle.copyWith(
        status: VisitSpeechStatus.listening,
        audioRecordingPath: '/docs/v_speech.m4a',
      );
      expect(next.isListening, isTrue);
      expect(next.audioRecordingPath, '/docs/v_speech.m4a');
      expect(next.copyWith(clearAudioPath: true).audioRecordingPath, isNull);
    });

    test('mic denied → denied status (store)', () async {
      final store = VisitSpeechToTextStore(
        requestMic: () async => PermissionStatus.denied,
      );
      addTearDown(store.dispose);
      final ok = await store.ensureReady();
      expect(ok, isFalse);
      expect(store.state.status, VisitSpeechStatus.denied);
      expect(
        store.state.errorKey,
        'field_sales.visit_speech_mic_denied',
      );
    });
  });

  group('P3 smoke: order geofence unit', () {
    test('param kapalı → izin', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: false,
        radiusMeters: 100,
        failClosed: true,
        customerLat: 41.0,
        customerLng: 29.0,
        deviceLat: 40.0,
        deviceLng: 28.0,
      );
      expect(d.allowed, isTrue);
    });

    test('yarıçap dışı → engel', () {
      final d = OrderGeofenceGate.evaluate(
        orderRequireGeofence: true,
        radiusMeters: 50,
        failClosed: true,
        customerLat: 41.0,
        customerLng: 29.0,
        deviceLat: 41.01,
        deviceLng: 29.0,
      );
      expect(d.allowed, isFalse);
      expect(d.errorKey, 'field_sales.order_geofence_outside');
    });
  });
}
