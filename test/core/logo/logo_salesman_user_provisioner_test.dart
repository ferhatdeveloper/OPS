// Dosya Adı: logo_salesman_user_provisioner_test.dart
// Açıklama: Logo plasiyer → OPS kullanıcı provision birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:exfin_ops/core/logo/logo_salesman_user_provisioner.dart';
import 'package:exfin_ops/service/auth_service.dart';
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
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              username TEXT NOT NULL,
              email TEXT NOT NULL,
              full_name TEXT NOT NULL,
              role TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              is_deleted INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_logged_in INTEGER NOT NULL DEFAULT 0,
              password_hash TEXT
            );
          ''');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('yeni plasiyer → kullanıcı username=CODE şifre=1234', () async {
    final p = LogoSalesmanUserProvisioner();
    final n = await p.ensureUsers(db, [
      {'code': 'S01', 'name': 'Ali Kaya'},
    ]);
    expect(n, 1);
    final rows = await db.query('users', where: 'username = ?', whereArgs: ['S01']);
    expect(rows, hasLength(1));
    expect(rows.first['role'], 'salesperson');
    expect(rows.first['full_name'], 'Ali Kaya');
    expect(rows.first['logo_salesman_code'], 'S01');
    expect(
      rows.first['password_hash'],
      AuthService.hashPassword('1234'),
    );
  });

  test('ikinci çekimde şifre ezilmez / tekrar oluşturmaz', () async {
    final p = LogoSalesmanUserProvisioner();
    await p.ensureUsers(db, [
      {'code': 'S01', 'name': 'Ali'},
    ]);
    await db.update(
      'users',
      {'password_hash': AuthService.hashPassword('changed')},
      where: 'username = ?',
      whereArgs: ['S01'],
    );
    final n = await p.ensureUsers(db, [
      {'code': 'S01', 'name': 'Ali'},
    ]);
    expect(n, 0);
    final rows = await db.query('users', where: 'username = ?', whereArgs: ['S01']);
    expect(rows.first['password_hash'], AuthService.hashPassword('changed'));
  });
}
