// Dosya Adı: database_path_manager.dart
// Açıklama: Veritabanı yolu yönetimi için yardımcı sınıf
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart' as path_provider;

/// {@template database_path_manager}
/// Veritabanı yolu yönetimi için yardımcı sınıf.
/// {@endtemplate}
class DatabasePathManager {
  static const String _dbName = 'exfin_erp.db';
  static const String _dbFolderName = 'exfin_erp_data';

  /// Veritabanı yolunu döndürür
  static Future<String> getDatabasePath() async {
    if (kIsWeb) {
      // Web'de dosya yolu işlemi yok, sabit bir değer döndür
      return 'web_db';
    }
    late final String dbPath;
    if (Platform.isWindows) {
      final rootPath = r'C:\exfin_erp_data';
      final directory = Directory(rootPath);
      if (!await directory.exists()) {
        print('Veritabanı klasörü oluşturuluyor: $rootPath');
        await directory.create(recursive: true);
      } else {
        print('Veritabanı klasörü mevcut: $rootPath');
      }
      dbPath = path.join(rootPath, _dbName);
    } else {
      // Sadece mobil/masaüstüde uygulama veri dizinini kullan
      final appDir = await _getAppDirectory();
      final dbDir = Directory(path.join(appDir.path, _dbFolderName));
      if (!await dbDir.exists()) {
        print('Veritabanı klasörü oluşturuluyor: ${dbDir.path}');
        await dbDir.create(recursive: true);
      } else {
        print('Veritabanı klasörü mevcut: ${dbDir.path}');
      }
      dbPath = path.join(dbDir.path, _dbName);
    }
    print('Veritabanı yolu: $dbPath');
    return dbPath;
  }

  /// Platform bazlı uygulama dizinini döndürür
  static Future<Directory> _getAppDirectory() async {
    late final Directory appDir;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final path = await path_provider.getApplicationDocumentsDirectory();
      appDir = Directory(path.path);
    } else if (!kIsWeb && (Platform.isMacOS || Platform.isLinux)) {
      final home = Platform.environment['HOME'];
      if (home == null) {
        throw Exception('HOME environment değişkeni bulunamadı');
      }
      appDir = Directory(path.join(home, '.${_dbFolderName}'));
    } else {
      throw UnsupportedError(
          'Platform desteklenmiyor: ${kIsWeb ? 'web' : Platform.operatingSystem}');
    }
    return appDir;
  }

  /// Veritabanı dosyasının var olup olmadığını kontrol eder
  static Future<bool> databaseExists() async {
    if (kIsWeb) return false;
    final dbPath = await getDatabasePath();
    return File(dbPath).exists();
  }

  /// Veritabanı dosyasını yedekler
  static Future<void> backupDatabase() async {
    if (kIsWeb) return;

    final dbPath = await getDatabasePath();
    final backupPath =
        '${dbPath}_backup_${DateTime.now().millisecondsSinceEpoch}';

    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.copy(backupPath);
      print('Veritabanı yedeklendi: $backupPath');
    }
  }

  /// Veritabanı dosyasını siler
  static Future<void> deleteDatabase() async {
    if (kIsWeb) return;

    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      await backupDatabase(); // Silmeden önce yedek al
      await dbFile.delete();
      print('Veritabanı silindi: $dbPath');
    }
  }
}
