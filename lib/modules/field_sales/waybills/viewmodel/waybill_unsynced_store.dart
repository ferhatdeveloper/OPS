// Dosya Adı: waybill_unsynced_store.dart
// Açıklama: Transfer edilmeyen irsaliyeler SQLite (is_synced=0)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';
import 'waybill_repository.dart';

/// {@template waybill_unsynced_store}
/// `waybills` tablosundan `is_synced = 0` dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = WaybillUnsyncedStore();
/// final rows = await store.loadUnsynced();
/// ```
/// {@endtemplate}
class WaybillUnsyncedStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// [repository]: Liste sorgusu
  final WaybillRepository repository;

  /// [loader]: Test için sabit satır enjeksiyonu (DB atlanır)
  final Future<List<WaybillUnsyncedRow>> Function()? loader;

  /// {@macro waybill_unsynced_store}
  const WaybillUnsyncedStore({
    this.openDb,
    this.repository = const WaybillRepository(),
    this.loader,
  });

  /// {@template waybill_unsynced_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template waybill_unsynced_store_load}
  /// Transfer edilmeyen (`is_synced = 0`) irsaliyeleri yükler.
  ///
  /// Dönüş değeri:
  /// - [List<WaybillUnsyncedRow>]: Dens satırlar (tarih DESC)
  /// {@endtemplate}
  Future<List<WaybillUnsyncedRow>> loadUnsynced() async {
    if (loader != null) return loader!();
    final db = await _db();
    return repository.listUnsynced(db);
  }
}
