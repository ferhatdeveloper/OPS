// Dosya Adı: postgrest_auth_service.dart
// Açıklama: PostgREST /users + bcrypt (veya SHA-256) kiracı girişi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';

import '../../service/database_service.dart';
import 'postgrest_http_client.dart';

/// {@template postgrest_auth_result}
/// Kiracı PostgREST giriş sonucu.
/// {@endtemplate}
class PostgrestAuthResult {
  /// [ok]: Başarılı mı
  final bool ok;

  /// [session]: Oturum map (AuthService uyumlu)
  final Map<String, dynamic>? session;

  /// [userRow]: Ham /users satırı
  final Map<String, dynamic>? userRow;

  /// [errorKey]: l10n anahtarı
  final String? errorKey;

  /// [errorDetail]: Teknik detay
  final String? errorDetail;

  /// {@macro postgrest_auth_result}
  const PostgrestAuthResult({
    required this.ok,
    this.session,
    this.userRow,
    this.errorKey,
    this.errorDetail,
  });
}

/// {@template postgrest_auth_service}
/// `GET /users?username=eq.{u}` + bcrypt/SHA-256 doğrulama.
/// Başarılıysa yerel SQLite `users` önbelleğine yazar (offline yedek).
///
/// Kullanım örneği:
/// ```dart
/// final r = await PostgrestAuthService().login(
///   username: 'admin',
///   password: 'admin',
/// );
/// ```
/// {@endtemplate}
class PostgrestAuthService {
  /// [client]: HTTP istemcisi
  final PostgrestHttpClient client;

  /// [mirrorToSqlite]: Başarılı girişi SQLite'a yansıt
  final bool mirrorToSqlite;

  /// {@macro postgrest_auth_service}
  PostgrestAuthService({
    PostgrestHttpClient? client,
    this.mirrorToSqlite = true,
  }) : client = client ?? PostgrestHttpClient();

  /// Şifre hash doğrulama (bcrypt `$2…` veya SHA-256 hex).
  static bool verifyPassword(String password, String storedHash) {
    final hash = storedHash.trim();
    if (hash.isEmpty) return false;
    if (hash.startsWith(r'$2')) {
      try {
        return BCrypt.checkpw(password, hash);
      } catch (e) {
        debugPrint('PostgrestAuthService bcrypt: $e');
        return false;
      }
    }
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes).toString();
    return digest == hash;
  }

  /// Kullanıcı adı + şifre ile PostgREST girişi.
  Future<PostgrestAuthResult> login({
    required String username,
    required String password,
  }) async {
    final u = username.trim();
    if (u.isEmpty) {
      return const PostgrestAuthResult(
        ok: false,
        errorKey: 'auth.username_required',
      );
    }
    if (!client.isConfigured) {
      return const PostgrestAuthResult(
        ok: false,
        errorKey: 'auth.tenant_required',
        errorDetail: 'PostgREST URL yok',
      );
    }

    try {
      final rows = await client.getRows(
        '/users',
        query: {
          'username': 'eq.$u',
          'select': '*',
          'limit': '1',
        },
      );
      if (rows.isEmpty) {
        return const PostgrestAuthResult(
          ok: false,
          errorKey: 'auth.postgrest_user_not_found',
        );
      }
      final user = rows.first;
      final isActive = user['is_active'] == true || user['is_active'] == 1;
      if (!isActive) {
        return const PostgrestAuthResult(
          ok: false,
          errorKey: 'auth.postgrest_user_inactive',
        );
      }
      final stored = (user['password_hash'] ?? '').toString();
      if (!verifyPassword(password, stored)) {
        return const PostgrestAuthResult(
          ok: false,
          errorKey: 'auth.postgrest_bad_password',
        );
      }

      final sessionId = const Uuid().v4();
      final userId = (user['id'] ?? u).toString();
      final session = <String, dynamic>{
        'user_id': userId,
        'username': (user['username'] ?? u).toString(),
        'role': (user['role'] ?? 'user').toString(),
        'email': (user['email'] ?? '').toString(),
        'full_name': (user['full_name'] ?? user['username'] ?? u).toString(),
        'session_id': sessionId,
        'firm_nr': (user['firm_nr'] ?? '').toString(),
        'allowed_firm_nrs': user['allowed_firm_nrs'],
        'source': 'postgrest',
      };

      if (mirrorToSqlite) {
        await _mirrorUser(user, sessionId: sessionId);
      }

      try {
        await client.patchRows(
          '/users',
          query: {'id': 'eq.$userId'},
          body: {
            'last_login_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
      } catch (e) {
        debugPrint('PostgrestAuthService last_login_at: $e');
      }

      return PostgrestAuthResult(ok: true, session: session, userRow: user);
    } on PostgrestHttpException catch (e) {
      return PostgrestAuthResult(
        ok: false,
        errorKey: 'auth.postgrest_network_error',
        errorDetail: e.toString(),
      );
    } catch (e) {
      return PostgrestAuthResult(
        ok: false,
        errorKey: 'auth.postgrest_network_error',
        errorDetail: e.toString(),
      );
    }
  }

  Future<void> _mirrorUser(
    Map<String, dynamic> user, {
    required String sessionId,
  }) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      final now = DateTime.now().toUtc().toIso8601String();
      final id = (user['id'] ?? user['username']).toString();
      await db.insert(
        'users',
        {
          'id': id,
          'username': (user['username'] ?? '').toString(),
          'email': (user['email'] ?? '${user['username']}@tenant.local')
              .toString(),
          'full_name':
              (user['full_name'] ?? user['username'] ?? '').toString(),
          'role': (user['role'] ?? 'user').toString(),
          'is_active': 1,
          'is_deleted': 0,
          'password_hash': (user['password_hash'] ?? '').toString(),
          'created_at': (user['created_at'] ?? now).toString(),
          'updated_at': now,
          'is_logged_in': 1,
          'session_id': sessionId,
          'last_active_at': now,
          'last_login_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('PostgrestAuthService mirror SQLite: $e');
    }
  }
}
