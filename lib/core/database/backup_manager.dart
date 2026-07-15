// Dosya Adı: backup_manager.dart
// Açıklama: Veritabanı yedekleme yönetimi için yardımcı sınıf
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
// supabase removed
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../database/database_path_manager.dart';

/// {@template backup_manager}
/// Veritabanı yedekleme yönetimi için yardımcı sınıf.
/// SQLite ve Supabase yedeklemelerini yönetir.
/// {@endtemplate}
class BackupManager {
  static const String _backupFolderName = 'backups';
  static const int _maxBackupCount = 10; // Maksimum yedek sayısı

  /// SQLite veritabanını yedekler
  static Future<String> backupSqliteDatabase() async {
    if (kIsWeb) return '';

    try {
      final dbPath = await DatabasePathManager.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Veritabanı dosyası bulunamadı: $dbPath');
      }

      // Yedekleme klasörünü oluştur
      final backupDir = await _createBackupDirectory();

      // Yedek dosya adını oluştur
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = 'sqlite_backup_$timestamp.db';
      final backupPath = path.join(backupDir.path, backupFileName);

      // Dosyayı kopyala
      await dbFile.copy(backupPath);
      print('SQLite yedekleme başarılı: $backupPath');

      // Eski yedekleri temizle
      await _cleanupOldBackups(backupDir, 'sqlite_backup_');

      return backupPath;
    } catch (e) {
      print('SQLite yedekleme hatası: $e');
      rethrow;
    }
  }

  /// Supabase veritabanını yedekler
  static Future<void> backupSupabaseDatabase(dynamic supabase) async {
    try {
      // Tüm tabloları al
      final tables = await _getSupabaseTables(supabase);

      // Yedekleme klasörünü oluştur
      final backupDir = await _createBackupDirectory();

      // Yedek dosya adını oluştur
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = 'supabase_backup_$timestamp.json';
      final backupPath = path.join(backupDir.path, backupFileName);

      // Her tablonun verisini al ve dosyaya yaz
      final Map<String, List<Map<String, dynamic>>> backupData = {};

      for (var table in tables) {
        final response = await supabase.from(table).select();
        backupData[table] = List<Map<String, dynamic>>.from(response as List);
      }

      // JSON dosyasını oluştur
      final backupFile = File(backupPath);
      await backupFile.writeAsString(jsonEncode(backupData));

      print('Supabase yedekleme başarılı: $backupPath');

      // Eski yedekleri temizle
      await _cleanupOldBackups(backupDir, 'supabase_backup_');
    } catch (e) {
      print('Supabase yedekleme hatası: $e');
      rethrow;
    }
  }

  /// Yedekleme klasörünü oluşturur
  static Future<Directory> _createBackupDirectory() async {
    late final Directory backupDir;
    if (!kIsWeb && Platform.isWindows) {
      backupDir = Directory(r'C:\exfin_erp_data\backups');
    } else if (!kIsWeb) {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      backupDir = Directory(path.join(appDir.path, _backupFolderName));
    } else {
      throw UnsupportedError('Web platformunda yedekleme desteklenmiyor.');
    }
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Eski yedekleri temizler
  static Future<void> _cleanupOldBackups(
      Directory backupDir, String prefix) async {
    final files = await backupDir
        .list()
        .where((entity) =>
            entity is File && path.basename(entity.path).startsWith(prefix))
        .toList();

    if (files.length > _maxBackupCount) {
      // Dosyaları tarihe göre sırala (en eski başta)
      files.sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified));

      // Fazla olan dosyaları sil
      final filesToDelete = files.sublist(0, files.length - _maxBackupCount);
      for (var file in filesToDelete) {
        await file.delete();
        print('Eski yedek silindi: ${file.path}');
      }
    }
  }

  /// Supabase tablolarını alır
  static Future<List<String>> _getSupabaseTables(
      dynamic supabase) async {
    try {
      final response = await supabase.rpc(
        'get_all_tables',
        params: {'schema_name': 'public'},
      );
      return List<String>.from(response as List);
    } catch (e) {
      print('Tablo listesi alınamadı: $e');
      return [];
    }
  }

  /// Yedekleri listeler
  static Future<List<BackupInfo>> listBackups() async {
    if (kIsWeb) return [];

    try {
      final backupDir = await _createBackupDirectory();
      final files = await backupDir
          .list()
          .where((entity) =>
              entity is File &&
              (path.basename(entity.path).startsWith('sqlite_backup_') ||
                  path.basename(entity.path).startsWith('supabase_backup_')))
          .toList();

      return files.map((entity) {
        final file = entity as File;
        final fileName = path.basename(file.path);
        final stats = file.statSync();

        return BackupInfo(
          path: file.path,
          fileName: fileName,
          size: stats.size,
          createdAt: stats.modified,
          type: fileName.startsWith('sqlite_backup_') ? 'SQLite' : 'Supabase',
        );
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni başta
    } catch (e) {
      print('Yedek listesi alınamadı: $e');
      return [];
    }
  }

  /// Yedekten geri yükler
  static Future<void> restoreFromBackup(BackupInfo backup) async {
    if (kIsWeb) return;

    try {
      if (backup.type == 'SQLite') {
        await _restoreSqliteBackup(backup.path);
      } else {
        await _restoreSupabaseBackup(backup.path);
      }
      print('Yedekten geri yükleme başarılı: ${backup.fileName}');
    } catch (e) {
      print('Geri yükleme hatası: $e');
      rethrow;
    }
  }

  /// SQLite yedeğini geri yükler
  static Future<void> _restoreSqliteBackup(String backupPath) async {
    final dbPath = await DatabasePathManager.getDatabasePath();
    final backupFile = File(backupPath);

    // Mevcut veritabanını yedekle
    await backupSqliteDatabase();

    // Veritabanını kapat ve sil
    await deleteDatabase(dbPath);

    // Yedekten geri yükle
    await backupFile.copy(dbPath);
  }

  /// Supabase yedeğini geri yükler
  static Future<void> _restoreSupabaseBackup(String backupPath) async {
    final backupFile = File(backupPath);
    final backupData =
        jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;

    final supabase = MockSupabase.instance.client;

    for (var entry in backupData.entries) {
      final tableName = entry.key;
      final tableData = List<Map<String, dynamic>>.from(entry.value as List);

      // Tabloyu temizle
      await supabase.from(tableName).delete().neq('id', '');

      // Verileri geri yükle
      for (var chunk in _chunks(tableData, 1000)) {
        await supabase.from(tableName).upsert(chunk);
      }
    }
  }

  /// Listeyi parçalara böler
  static Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }
}

/// Yedek bilgisi sınıfı
class BackupInfo {
  final String path;
  final String fileName;
  final int size;
  final DateTime createdAt;
  final String type; // 'SQLite' veya 'Supabase'

  BackupInfo({
    required this.path,
    required this.fileName,
    required this.size,
    required this.createdAt,
    required this.type,
  });

  @override
  String toString() =>
      'BackupInfo(fileName: $fileName, type: $type, size: $size, createdAt: $createdAt)';
}

class Supabase { static dynamic instance; }
class MockSupabase { static dynamic instance; }
