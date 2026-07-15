// Dosya Adı: supabase_config.dart
// Açıklama: Supabase yapılandırma ayarları
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/foundation.dart';

/// {@template SupabaseConfig}
/// Supabase yapılandırma ayarlarını içeren sınıf
/// {@endtemplate}
class SupabaseConfig {
  /// Supabase URL'i
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  /// Supabase anonim anahtarı
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  /// Supabase servis rolü anahtarı
  static const String supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: 'your-service-role-key',
  );

  /// Supabase yapılandırmasının geçerli olup olmadığını kontrol eder
  static bool get isValid {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        supabaseServiceRoleKey.isNotEmpty;
  }

  /// Debug modunda yapılandırma bilgilerini yazdırır
  static void printConfig() {
    if (kDebugMode) {
      print('Supabase URL: $supabaseUrl');
      print('Supabase Anon Key: ${supabaseAnonKey.substring(0, 5)}...');
      print(
          'Supabase Service Role Key: ${supabaseServiceRoleKey.substring(0, 5)}...');
    }
  }
}
