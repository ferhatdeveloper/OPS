// Dosya Adı: report_logo_auth.dart
// Açıklama: Rapor logo yükleme yetkisi (admin / supervisor)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';

import '../../../../service/auth_service.dart';
import '../../../../service/database_service.dart';

/// {@template report_logo_auth}
/// Logo yükleme / silme için rol kontrolü.
///
/// Yetkili roller: `admin`, `supervisor`. Rol yoksa veya okunamazsa
/// false (güvenli taraf).
///
/// Kullanım örneği:
/// ```dart
/// if (await ReportLogoAuth.canManageLogo()) { /* yükle */ }
/// ```
/// {@endtemplate}
class ReportLogoAuth {
  /// [authorizedRoles]: Logo yönetimine izin verilen roller
  static const Set<String> authorizedRoles = {
    'admin',
    'supervisor',
  };

  /// Test inject: null → canlı Auth + DB
  final Future<String?> Function()? roleResolver;

  /// {@macro report_logo_auth}
  const ReportLogoAuth({this.roleResolver});

  /// {@template report_logo_auth_can_manage}
  /// Mevcut kullanıcının logo yükleyip silebileceğini döner.
  ///
  /// Dönüş değeri:
  /// - [bool]: true → yetkili
  /// {@endtemplate}
  Future<bool> canManageLogo() async {
    final role = await resolveCurrentRole();
    if (role == null || role.isEmpty) return false;
    return authorizedRoles.contains(role.toLowerCase().trim());
  }

  /// {@template report_logo_auth_resolve_role}
  /// Oturum kullanıcısının `users.role` değerini okur.
  ///
  /// Dönüş değeri:
  /// - [String?]: Rol veya null
  /// {@endtemplate}
  Future<String?> resolveCurrentRole() async {
    if (roleResolver != null) return roleResolver!();
    final username = AuthService.getCurrentUser();
    if (username == null || username.trim().isEmpty) return null;
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      final rows = await db.query(
        'users',
        columns: ['role'],
        where: 'username = ?',
        whereArgs: [username.trim()],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['role']?.toString();
    } catch (e) {
      debugPrint('ReportLogoAuth role okunamadı: $e');
      return null;
    }
  }
}
