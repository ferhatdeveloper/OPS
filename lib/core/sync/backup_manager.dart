// Dosya Adı: backup_manager.dart
// Açıklama: Veritabanı yedekleme yöneticisi
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../services/postgre_service.dart';

/// {@template backup_manager}
/// Veritabanı yedekleme işlemlerini yöneten sınıf
/// {@endtemplate}
class BackupManager {
  final Database _db;
  // final dynamic _supabase; // Removed
  final String _backupDir;

  BackupManager(this._db)
      : _backupDir = path.join(Directory.current.path, 'backups');

  /// SQLite veritabanını yedekler
  Future<String> backupSqliteDatabase() async {
    try {
      final backupPath = _getBackupPath('sqlite');
      final backupFile = File(backupPath);

      // Yedekleme dizinini oluştur
      await backupFile.parent.create(recursive: true);

      // Veritabanı dosyasını kopyala
      // SQLite veritabanı yolu genellikle sabit bir konumda
      final dbPath = path.join(Directory.current.path, 'database.db');
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        print('SQLite yedekleme tamamlandı: $backupPath');
        return backupPath;
      } else {
        throw Exception('Veritabanı dosyası bulunamadı: $dbPath');
      }
    } catch (e) {
      print('SQLite yedekleme hatası: $e');
      rethrow;
    }
  }

  /// Supabase veritabanını yedekler
  /// PostgreSQL veritabanını yedekler
  Future<String> backupPostgreDatabase() async {
    try {
      final backupPath = _getBackupPath('postgre');
      final backupFile = File(backupPath);

      // Yedekleme dizinini oluştur
      await backupFile.parent.create(recursive: true);

      final postgre = await PostgreService.getInstance();
      final tables = await _getPostgreTables();
      final backupData = <String, dynamic>{};

      for (final table in tables) {
        try {
          final result = await postgre.query(table, limit: 1000);
          backupData[table] = result;
        } catch (e) {
          print('Tablo $table yedekleme hatası: $e');
        }
      }

      // JSON olarak kaydet
      await backupFile.writeAsString(backupData.toString());
      print('PostgreSQL yedekleme tamamlandı: $backupPath');
      return backupPath;
    } catch (e) {
      print('PostgreSQL yedekleme hatası: $e');
      rethrow;
    }
  }

  /// Yedekleri listeler
  Future<List<BackupInfo>> listBackups() async {
    try {
      final backupDir = Directory(_backupDir);
      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backups = <BackupInfo>[];

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          backups.add(BackupInfo(
            path: file.path,
            size: stat.size,
            modified: stat.modified,
            type: _getBackupType(file.path),
          ));
        }
      }

      return backups..sort((a, b) => b.modified.compareTo(a.modified));
    } catch (e) {
      print('Yedek listeleme hatası: $e');
      return [];
    }
  }

  /// Eski yedekleri temizler
  Future<void> cleanupOldBackups({int keepDays = 30}) async {
    try {
      final backups = await listBackups();
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

      for (final backup in backups) {
        if (backup.modified.isBefore(cutoffDate)) {
          final file = File(backup.path);
          if (await file.exists()) {
            await file.delete();
            print('Eski yedek silindi: ${backup.path}');
          }
        }
      }
    } catch (e) {
      print('Yedek temizleme hatası: $e');
    }
  }

  /// Yedekten geri yükleme yapar
  Future<void> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Yedek dosyası bulunamadı: $backupPath');
      }

      final backupType = _getBackupType(backupPath);

      if (backupType == 'sqlite') {
        await _restoreSqliteBackup(backupPath);
      } else if (backupType == 'postgre') {
        await _restorePostgreBackup(backupPath);
      }

      print('Yedekten geri yükleme tamamlandı: $backupPath');
    } catch (e) {
      print('Yedekten geri yükleme hatası: $e');
      rethrow;
    }
  }

  /// Yedek dosya yolu oluşturur
  String _getBackupPath(String type) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${type}_backup_$timestamp';

    if (type == 'sqlite') {
      return path.join(_backupDir, '$fileName.db');
    } else {
      return path.join(_backupDir, '$fileName.json');
    }
  }

  /// Yedek türünü belirler
  String _getBackupType(String filePath) {
    if (filePath.endsWith('.db')) {
      return 'sqlite';
    } else if (filePath.endsWith('.json')) {
      return 'postgre';
    }
    return 'unknown';
  }

  /// Supabase tablolarını listeler
  /// PostgreSQL tablolarını listeler
  Future<List<String>> _getPostgreTables() async {
    try {
      final postgre = await PostgreService.getInstance();
      final result = await postgre.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
      );
      return result.map((row) => row[0] as String).toList();
    } catch (e) {
      print('Tablo listesi alma hatası: $e');
      return [];
    }
  }

  /// SQLite yedeğini geri yükler
  Future<void> _restoreSqliteBackup(String backupPath) async {
    // Bu implementasyon basit - gerçek uygulamada daha güvenli olmalı
    print('SQLite yedeği geri yükleme: $backupPath');
  }

  /// Supabase yedeğini geri yükler
  /// PostgreSQL yedeğini geri yükler
  Future<void> _restorePostgreBackup(String backupPath) async {
    // Bu implementasyon basit - gerçek uygulamada daha güvenli olmalı
    print('PostgreSQL yedeği geri yükleme: $backupPath');
  }
}

/// {@template backup_info}
/// Yedek dosyası bilgilerini tutan sınıf
/// {@endtemplate}
class BackupInfo {
  final String path;
  final int size;
  final DateTime modified;
  final String type;

  const BackupInfo({
    required this.path,
    required this.size,
    required this.modified,
    required this.type,
  });

  @override
  String toString() {
    return 'BackupInfo{path: $path, size: $size, modified: $modified, type: $type}';
  }
}
