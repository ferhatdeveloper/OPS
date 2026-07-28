// Dosya Adı: logo_salesman_user_provisioner.dart
// Açıklama: Logo plasiyer kodundan OPS kullanıcısı (şifre 1234) oluşturur
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../service/auth_service.dart';

/// {@template logo_salesman_user_provisioner}
/// Logo salesman CODE → OPS `users` (username=CODE, password=1234).
/// Mevcut kullanıcıda şifre **ezilmez** (idempotent create-only).
///
/// Kullanım örneği:
/// ```dart
/// final n = await LogoSalesmanUserProvisioner().ensureUsers([
///   {'code': 'S01', 'name': 'Ali'},
/// ]);
/// ```
/// {@endtemplate}
class LogoSalesmanUserProvisioner {
  /// Varsayılan ilk şifre (kullanıcı isteği).
  static const String defaultPassword = '1234';

  /// OPS rol değeri (AppUserRole.salesperson).
  static const String defaultRole = 'salesperson';

  final Uuid _uuid;

  /// {@macro logo_salesman_user_provisioner}
  LogoSalesmanUserProvisioner({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// {@template logo_salesman_user_provisioner_ensure}
  /// Her satır için eksik kullanıcıyı oluşturur.
  ///
  /// Parametreler:
  /// - [db]: SQLite
  /// - [salesmen]: `{code, name?}` listesi
  ///
  /// Dönüş:
  /// - oluşturulan kullanıcı sayısı
  /// {@endtemplate}
  Future<int> ensureUsers(
    Database db,
    List<Map<String, String>> salesmen,
  ) async {
    await _ensureSchema(db);
    var created = 0;
    final hash = AuthService.hashPassword(defaultPassword);
    final now = DateTime.now().toUtc().toIso8601String();

    for (final s in salesmen) {
      final code = (s['code'] ?? '').trim();
      if (code.isEmpty) continue;
      final name = (s['name'] ?? code).trim();
      try {
        final existing = await db.query(
          'users',
          columns: ['id', 'username'],
          where: 'username = ? OR logo_salesman_code = ?',
          whereArgs: [code, code],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;

        await db.insert('users', {
          'id': _uuid.v4(),
          'username': code,
          'email': '$code@logo.local',
          'full_name': name,
          'role': defaultRole,
          'is_active': 1,
          'is_deleted': 0,
          'created_at': now,
          'updated_at': now,
          'is_logged_in': 0,
          'password_hash': hash,
          'logo_salesman_code': code,
        });
        created++;
        debugPrint('LogoSalesmanUserProvisioner: kullanıcı oluşturuldu → $code');
      } catch (e) {
        debugPrint('LogoSalesmanUserProvisioner: $code → $e');
      }
    }
    return created;
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS salesmen (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        logo_ref TEXT,
        is_synced INTEGER NOT NULL DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      );
    ''');
    try {
      await db.execute(
        'ALTER TABLE users ADD COLUMN logo_salesman_code TEXT',
      );
    } catch (_) {}
  }
}
