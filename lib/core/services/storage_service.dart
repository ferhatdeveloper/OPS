// Dosya Adı: storage_service.dart
// Açıklama: SQLite veritabanı işlemleri için servis sınıfı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// {@template StorageService}
/// SQLite veritabanı işlemlerini yöneten servis sınıfı
/// {@endtemplate}
class StorageService {
  static StorageService? _instance;
  static Database? _database;

  StorageService._internal();

  /// Servis örneğini döndürür
  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._internal();
    await _instance!._initDatabase();
    return _instance!;
  }

  /// Veritabanı örneğini döndürür
  Future<Database> getDatabase() async {
    await _initDatabase();
    return _database!;
  }

  /// Veritabanını başlatır
  Future<void> _initDatabase() async {
    if (_database != null) return;
    if (kIsWeb) return; // Web'de dosya işlemi yok
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'exfinerp.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Örnek tablo oluşturma
        await db.execute('''
          CREATE TABLE IF NOT EXISTS companies (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            approval_status INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
