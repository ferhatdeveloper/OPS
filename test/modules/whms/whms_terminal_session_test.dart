// Dosya Adı: whms_terminal_session_test.dart
// Açıklama: WhmsTerminalSession MAC/rol gate + advanceAsTerminal testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/whms/devices/viewmodel/whms_device_store.dart';
import 'package:exfin_ops/modules/whms/devices/viewmodel/whms_terminal_session.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_status.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_type.dart';
import 'package:exfin_ops/modules/whms/viewmodel/whms_order_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late WhmsDeviceStore devices;
  late WhmsOrderStore orders;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createWhmsOrdersTable);
        await db.execute(SqlQuerys.createWhmsOrderLinesTable);
      },
    );
    devices = WhmsDeviceStore(openDb: () async => db);
    orders = WhmsOrderStore(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('bindByMac rejects unknown MAC', () async {
    expect(
      () => WhmsTerminalSession.bindByMac(
        store: devices,
        mac: 'AA:BB:CC:DD:EE:FF',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'whms.terminal.device_not_registered',
        ),
      ),
    );
  });

  test('bindByMac rejects inactive device', () async {
    final d = await devices.insert(
      name: 'RF',
      mac: 'AA:BB:CC:DD:EE:01',
    );
    await devices.setActive(d.id, false);
    expect(
      () => WhmsTerminalSession.bindByMac(
        store: devices,
        mac: 'AA:BB:CC:DD:EE:01',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'whms.terminal.device_inactive',
        ),
      ),
    );
  });

  test('role gate denies mismatched order type', () async {
    await devices.insert(
      name: 'RF',
      mac: 'AA:BB:CC:DD:EE:02',
      roles: const ['pick'],
    );
    final session = await WhmsTerminalSession.bindByMac(
      store: devices,
      mac: 'AA:BB:CC:DD:EE:02',
    );
    expect(
      () => session.assertCanExecute(WhmsOrderType.sevk),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'whms.terminal.role_denied',
        ),
      ),
    );
    expect(() => session.assertCanExecute(WhmsOrderType.pick), returnsNormally);
  });

  test('empty roles allow any type when device active', () async {
    await devices.insert(
      name: 'RF',
      mac: 'AA:BB:CC:DD:EE:03',
    );
    final session = await WhmsTerminalSession.bindByMac(
      store: devices,
      mac: 'AA:BB:CC:DD:EE:03',
    );
    expect(
      () => session.assertCanExecute(WhmsOrderType.malKabul),
      returnsNormally,
    );
  });

  test('advanceAsTerminal binds device_id and gates execution', () async {
    final device = await devices.insert(
      name: 'RF',
      mac: 'AA:BB:CC:DD:EE:04',
      roles: const ['sevk'],
    );
    final session = await WhmsTerminalSession.bindByMac(
      store: devices,
      mac: 'AA:BB:CC:DD:EE:04',
    );

    final draft = await orders.createDraft(
      orderType: WhmsOrderType.sevk,
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
    );
    // draft → assigned (backoffice; gate yok)
    final assigned = await orders.advanceStatus(draft.id);
    expect(assigned?.status, WhmsOrderStatus.assigned);

    // assigned → in_progress (terminal)
    final started = await orders.advanceAsTerminal(draft.id, session);
    expect(started?.status, WhmsOrderStatus.inProgress);
    expect(started?.deviceId, device.id);

    final done = await orders.advanceAsTerminal(draft.id, session);
    expect(done?.status, WhmsOrderStatus.done);
  });

  test('advanceAsTerminal rejects wrong role', () async {
    await devices.insert(
      name: 'RF',
      mac: 'AA:BB:CC:DD:EE:05',
      roles: const ['sayim'],
    );
    final session = await WhmsTerminalSession.bindByMac(
      store: devices,
      mac: 'AA:BB:CC:DD:EE:05',
    );
    final draft = await orders.createDraft(
      orderType: WhmsOrderType.sevk,
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
    );
    await orders.advanceStatus(draft.id);
    expect(
      () => orders.advanceAsTerminal(draft.id, session),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'whms.terminal.role_denied',
        ),
      ),
    );
  });
}