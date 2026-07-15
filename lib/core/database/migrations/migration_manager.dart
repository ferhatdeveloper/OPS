// Dosya Adı: migration_manager.dart
// Açıklama: Migration SQL dosyalarını sıralı şekilde çalıştıran yönetici sınıf
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

// Tüm migration işlemleri SqlQuerys.dart üzerinden yönetilecek. .sql dosyası okuma ve çalıştırma kodları kaldırıldı.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// {@template MigrationManager}
/// Migration dosyalarını okuyup veritabanına uygulayan sınıf
///
/// Kullanım örneği:
/// ```dart
/// final manager = MigrationManager(db);
/// await manager.runMigrations();
/// ```
/// {@endtemplate}
class MigrationManager {
  /// [db]: Kullanılacak sqflite Database nesnesi
  final Database db;

  /// [migrationsPath]: Migration SQL dosyalarının bulunduğu klasör yolu
  final String migrationsPath;

  /// MigrationManager: Yapıcı metot
  MigrationManager(this.db,
      {this.migrationsPath = 'lib/core/database/migrations'});

  /// {@template runMigrations}
  /// Migration SQL dosyalarını sıralı şekilde çalıştırır
  ///
  /// Parametreler:
  /// - Yok
  ///
  /// Dönüş değeri:
  /// - [Future<void>]: İşlem tamamlandığında döner
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Dosya okuma veya SQL çalıştırma hatası
  /// {@endtemplate}
  Future<void> runMigrations() async {
    final dir = Directory(migrationsPath);
    if (!await dir.exists()) return;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    for (final file in files) {
      final sql = await file.readAsString();
      final statements =
          sql.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final stmt in statements) {
        await db.execute(stmt);
      }
    }
  }
}
