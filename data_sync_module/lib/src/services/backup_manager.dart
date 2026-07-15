// Dosya Adı: backup_manager.dart
// Açıklama: Veritabanı yedekleme yöneticisi
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Yedek bilgisi
class BackupInfo {
  final String fileName;
  final String path;
  final DateTime createdAt;
  final int size;
  final String type; // 'sqlite' veya 'supabase'

  BackupInfo({
    required this.fileName,
    required this.path,
    required this.createdAt,
    required this.size,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'path': path,
        'createdAt': createdAt.toIso8601String(),
        'size': size,
        'type': type,
      };

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
        fileName: json['fileName'],
        path: json['path'],
        createdAt: DateTime.parse(json['createdAt']),
        size: json['size'],
        type: json['type'],
      );

  @override
  String toString() {
    return 'BackupInfo(fileName: $fileName, type: $type, size: $size, createdAt: $createdAt)';
  }
}

/// {@template backup_manager}
/// Veritabanı yedekleme yöneticisi
///
/// Kullanım örneği:
/// ```dart
/// final backupManager = BackupManager(database, supabase);
/// await backupManager.backupSqliteDatabase();
/// ```
/// {@endtemplate}
class BackupManager {
  final Database _db;
  final SupabaseClient _supabase;
  final String _backupDir;

  BackupManager(this._db, this._supabase)
      : _backupDir = path.join(Directory.current.path, 'backups');

  /// SQLite veritabanını yedekler
  Future<BackupInfo> backupSqliteDatabase() async {
    try {
      await _ensureBackupDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sqlite_backup_$timestamp.db';
      final backupPath = path.join(_backupDir, fileName);

      // SQLite veritabanını kopyala
      final dbPath = _db.path;
      await File(dbPath).copy(backupPath);

      final file = File(backupPath);
      final size = await file.length();

      final backupInfo = BackupInfo(
        fileName: fileName,
        path: backupPath,
        createdAt: DateTime.now(),
        size: size,
        type: 'sqlite',
      );

      // Yedek bilgisini kaydet
      await _saveBackupInfo(backupInfo);

      print('SQLite yedekleme başarılı: $fileName');
      return backupInfo;
    } catch (e) {
      print('SQLite yedekleme hatası: $e');
      rethrow;
    }
  }

  /// Supabase veritabanını yedekler
  Future<BackupInfo> backupSupabaseDatabase() async {
    try {
      await _ensureBackupDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'supabase_backup_$timestamp.json';
      final backupPath = path.join(_backupDir, fileName);

      // Tüm tabloları al
      final tables = await _getSupabaseTables();
      final backupData = <String, dynamic>{};

      for (final table in tables) {
        try {
          final data = await _supabase.from(table).select();
          backupData[table] = data;
        } catch (e) {
          print('Tablo yedekleme hatası ($table): $e');
        }
      }

      // JSON dosyasına kaydet
      final file = File(backupPath);
      await file.writeAsString(jsonEncode(backupData));

      final size = await file.length();

      final backupInfo = BackupInfo(
        fileName: fileName,
        path: backupPath,
        createdAt: DateTime.now(),
        size: size,
        type: 'supabase',
      );

      // Yedek bilgisini kaydet
      await _saveBackupInfo(backupInfo);

      print('Supabase yedekleme başarılı: $fileName');
      return backupInfo;
    } catch (e) {
      print('Supabase yedekleme hatası: $e');
      rethrow;
    }
  }

  /// Yedekleri listeler
  Future<List<BackupInfo>> listBackups() async {
    try {
      final backupInfoFile = File(path.join(_backupDir, 'backup_info.json'));

      if (!await backupInfoFile.exists()) {
        return [];
      }

      final content = await backupInfoFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      return jsonList.map((json) => BackupInfo.fromJson(json)).toList();
    } catch (e) {
      print('Yedek listesi alınırken hata: $e');
      return [];
    }
  }

  /// Yedekten geri yükleme yapar
  Future<void> restoreFromBackup(String backupPath) async {
    try {
      final backupInfo = await _getBackupInfo(backupPath);

      if (backupInfo.type == 'sqlite') {
        await _restoreSqliteBackup(backupPath);
      } else if (backupInfo.type == 'supabase') {
        await _restoreSupabaseBackup(backupPath);
      }

      print('Yedekten geri yükleme başarılı: ${backupInfo.fileName}');
    } catch (e) {
      print('Geri yükleme hatası: $e');
      rethrow;
    }
  }

  /// Eski yedekleri temizler
  Future<void> cleanupOldBackups({int keepDays = 30}) async {
    try {
      final backups = await listBackups();
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

      for (final backup in backups) {
        if (backup.createdAt.isBefore(cutoffDate)) {
          await _deleteBackup(backup);
        }
      }

      print('Eski yedekler temizlendi');
    } catch (e) {
      print('Yedek temizleme hatası: $e');
    }
  }

  /// Yedek dizinini oluşturur
  Future<void> _ensureBackupDirectory() async {
    final directory = Directory(_backupDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Supabase tablolarını alır
  Future<List<String>> _getSupabaseTables() async {
    try {
      // Bu kısım Supabase'den tablo listesi almak için özelleştirilebilir
      return ['users', 'companies', 'sync_metadata']; // Örnek tablolar
    } catch (e) {
      print('Supabase tablo listesi alınırken hata: $e');
      return [];
    }
  }

  /// Yedek bilgisini kaydeder
  Future<void> _saveBackupInfo(BackupInfo backupInfo) async {
    try {
      final backupInfoFile = File(path.join(_backupDir, 'backup_info.json'));
      final backups = await listBackups();
      backups.add(backupInfo);

      final jsonList = backups.map((b) => b.toJson()).toList();
      await backupInfoFile.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Yedek bilgisi kaydedilirken hata: $e');
    }
  }

  /// Yedek bilgisini alır
  Future<BackupInfo> _getBackupInfo(String backupPath) async {
    final backups = await listBackups();
    return backups.firstWhere(
      (b) => b.path == backupPath,
      orElse: () => throw Exception('Yedek bulunamadı: $backupPath'),
    );
  }

  /// SQLite yedeğini geri yükler
  Future<void> _restoreSqliteBackup(String backupPath) async {
    try {
      final dbPath = _db.path;
      await _db.close();

      // Mevcut veritabanını yedekle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final currentBackup = '${dbPath}_backup_$timestamp';
      await File(dbPath).copy(currentBackup);

      // Yedeği geri yükle
      await File(backupPath).copy(dbPath);

      print('SQLite yedeği geri yüklendi');
    } catch (e) {
      print('SQLite geri yükleme hatası: $e');
      rethrow;
    }
  }

  /// Supabase yedeğini geri yükler
  Future<void> _restoreSupabaseBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      final content = await file.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;

      for (final entry in backupData.entries) {
        final tableName = entry.key;
        final data = entry.value as List<dynamic>;

        if (data.isNotEmpty) {
          // Mevcut verileri temizle
          await _supabase.from(tableName).delete().neq('id', '');

          // Yedek verileri ekle
          await _supabase.from(tableName).insert(data);
        }
      }

      print('Supabase yedeği geri yüklendi');
    } catch (e) {
      print('Supabase geri yükleme hatası: $e');
      rethrow;
    }
  }

  /// Yedeği siler
  Future<void> _deleteBackup(BackupInfo backupInfo) async {
    try {
      final file = File(backupInfo.path);
      if (await file.exists()) {
        await file.delete();
      }

      // Yedek bilgisini güncelle
      final backups = await listBackups();
      backups.removeWhere((b) => b.path == backupInfo.path);

      final backupInfoFile = File(path.join(_backupDir, 'backup_info.json'));
      final jsonList = backups.map((b) => b.toJson()).toList();
      await backupInfoFile.writeAsString(jsonEncode(jsonList));

      print('Yedek silindi: ${backupInfo.fileName}');
    } catch (e) {
      print('Yedek silme hatası: $e');
    }
  }
}
