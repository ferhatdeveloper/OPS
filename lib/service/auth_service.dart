import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// supabase removed
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../service/database_service.dart';
import '../core/services/postgre_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcı oturum yönetimi için servis
class AuthService {
  // Oturum açmış kullanıcı bilgisi (gerçek uygulamada daha güvenli yöntemlerle saklanır)
  static String? _currentUser;
  static String? _currentSessionId;
  static dynamic? _realtimeChannel;
  static bool _forceLogoutDialogShown = false;
  // Uygulama genelinde force logout event'ini dinle
  static dynamic? _forceLogoutChannel;

  /// Şifreyi SHA-256 ile hashler
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Kendi Auth sisteminiz için login (hashli şifre kontrolü)
  static Future<Map<String, dynamic>?> loginWithUsernameAndPassword({
    required String username,
    required String password,
    required bool forceLogout,
    required void Function(String message) onForceLogoutDialog,
    required void Function() onForceLogoutAccepted,
    required void Function() onForceLogoutRejected,
  }) async {
    debugPrint(
        'AUTH DEBUG: loginWithUsernameAndPassword başladı. username: $username, forceLogout: $forceLogout');
    
    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    Map<String, dynamic>? user;

    if (isMobile) {
      debugPrint('AUTH DEBUG: Mobil platform tespit edildi, SQLite kullanılıyor.');
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      final users = await db.query('users', where: 'username = ?', whereArgs: [username]);
      if (users.isNotEmpty) user = users.first;
    } else {
      debugPrint('AUTH DEBUG: Masaüstü/Web platform tespit edildi, PostgreSQL kullanılıyor.');
      final postgre = await PostgreService.getInstance();
      final users = await postgre.query('users', filter: 'username = @p0', filterArgs: [username]);
      if (users.isNotEmpty) user = users.first;
    }
    
    debugPrint('GİRİŞ DEBUG: Kullanıcı sorgusu sonucu: ${user != null ? 'BULUNDU' : 'BULUNAMADI'}');
    
    if (user == null) return {'error': 'Kullanıcı bulunamadı'};
    
    final isDeleted = user['is_deleted'] == true || user['is_deleted'] == 1;
    final isActive = user['is_active'] == true || user['is_active'] == 1;
    if (isDeleted) return {'error': 'Kullanıcı silinmis'};
    if (!isActive) return {'error': 'Kullanıcı pasif'};
    
    final hashedInput = hashPassword(password);
    if (user['password_hash'] != hashedInput) {
      return {'error': 'Şifre hatali. Lütfen şifrenizi tekrar kontrol edin.'};
    }

    final userId = user['id'];
    final sessionId = const Uuid().v4();
    _currentUser = username;
    _currentSessionId = sessionId;

    // Durumu veri tabanına işle
    final updateData = {
      'is_logged_in': true,
      'session_id': sessionId,
      'last_active_at': DateTime.now().toUtc().toIso8601String(),
      'force_logout_request': false,
      'force_logout_response': null,
    };

    if (isMobile) {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await db.update('users', updateData, where: 'id = ?', whereArgs: [userId]);
    } else {
      final postgre = await PostgreService.getInstance();
      await postgre.update('users', updateData, userId);
    }

    return {
      'user_id': userId,
      'username': username,
      'role': user['role'],
      'email': user['email'],
      'full_name': user['full_name'],
      'session_id': sessionId,
    };
  }

  /// Mevcut oturum açmış kullanıcının adını al
  static String? getCurrentUser() {
    return _currentUser;
  }

  /// Logout işlemi
  static Future<void> logout(BuildContext context) async {
    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    
    if (_currentUser != null && _currentSessionId != null) {
      final updateData = {'is_logged_in': false, 'session_id': null};
      
      if (isMobile) {
        final dbService = await DatabaseService.getInstance();
        final db = await dbService.getDatabase();
        await db.update('users', updateData, 
            where: 'username = ? AND session_id = ?', 
            whereArgs: [_currentUser, _currentSessionId]);
      } else {
        final postgre = await PostgreService.getInstance();
        await postgre.execute(
          'UPDATE users SET is_logged_in = false, session_id = null WHERE username = @user AND session_id = @sid',
          parameters: {'user': _currentUser, 'sid': _currentSessionId},
        );
      }
    }
    // Local session ve kimlik bilgilerini temizle
    try {
      final db = await DatabaseService.getInstance();
      await db.logout();
    } catch (e) {
      debugPrint('Local logout sırasında hata: $e');
    }
    _currentUser = null;
    _currentSessionId = null;
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // Uygulama genelinde force logout event'ini dinle
  static void startForceLogoutListener(
      BuildContext context, WidgetRef ref, String userId) {
    // Yerel PostgreSQL'de realtime dinleme şimdilik pasif
  }
}
