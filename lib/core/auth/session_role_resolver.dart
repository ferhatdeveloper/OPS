// Dosya Adı: session_role_resolver.dart
// Açıklama: user_session + users tablosundan aktif rol çözümleme
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../service/database_service.dart';
import 'app_user_role.dart';

/// {@template session_role_resolver}
/// Login session `role` claim’ini okur; gerekirse SQLite `users.role`
/// ile tazeler.
///
/// Kullanım örneği:
/// ```dart
/// final role = await SessionRoleResolver.resolve();
/// ```
/// {@endtemplate}
class SessionRoleResolver {
  /// [db]: Test enjeksiyonu
  final DatabaseService? db;

  /// {@macro session_role_resolver}
  const SessionRoleResolver({this.db});

  /// Aktif oturum rolünü çözer.
  ///
  /// Dönüş değeri:
  /// - [AppUserRole]: Session veya users satırından
  Future<AppUserRole> resolve() async {
    final service = db ?? await DatabaseService.getInstance();
    final session = await service.getUserSession();
    final fromSession = AppUserRole.parse(session?['role']);
    if (fromSession != AppUserRole.unknown) {
      return fromSession;
    }

    final userId = (session?['id'] ?? session?['user_id'] ?? '').toString();
    final username =
        (session?['username'] ?? '').toString().trim();
    if (userId.isEmpty && username.isEmpty) {
      return AppUserRole.unknown;
    }

    try {
      final database = await service.getDatabase();
      List<Map<String, Object?>> rows = const [];
      if (userId.isNotEmpty) {
        rows = await database.query(
          'users',
          columns: ['role'],
          where: 'id = ?',
          whereArgs: [userId],
          limit: 1,
        );
      }
      if (rows.isEmpty && username.isNotEmpty) {
        rows = await database.query(
          'users',
          columns: ['role'],
          where: 'username = ?',
          whereArgs: [username],
          limit: 1,
        );
      }
      if (rows.isEmpty) return AppUserRole.unknown;
      final role = AppUserRole.parse(rows.first['role']);
      if (role != AppUserRole.unknown && session != null) {
        final updated = Map<String, dynamic>.from(session);
        updated['role'] = rows.first['role']?.toString() ?? '';
        await service.setUserSession(updated);
      }
      return role;
    } catch (_) {
      return AppUserRole.unknown;
    }
  }
}
