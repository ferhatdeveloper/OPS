// Dosya Adı: visit_history_store.dart
// Açıklama: Geçmiş ziyaret dens satırları SQLite okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/visit_history_record.dart';

/// {@template visit_history_store}
/// `visits` tablosundan geçmiş ziyaret dens satırlarını okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = VisitHistoryStore(openDb: () async => db);
/// final rows = await store.loadAll();
/// ```
/// {@endtemplate}
class VisitHistoryStore {
  /// [openDb]: SQLite bağlantısı açıcı (test / üretim enjeksiyonu)
  final Future<Database> Function() openDb;

  /// {@macro visit_history_store}
  const VisitHistoryStore({required this.openDb});

  /// {@template visit_history_store_ensure}
  /// visits tablosunu oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await openDb();
    await db.execute(SqlQuerys.createVisitsTable);
  }

  /// {@template visit_history_store_load_all}
  /// Ziyaret dens satırlarını check-in tarihine göre (yeniden eskiye) döner.
  ///
  /// Dönüş değeri:
  /// - [List<VisitHistoryRecord>]: JOIN’li dens kayıtları
  /// {@endtemplate}
  Future<List<VisitHistoryRecord>> loadAll() async {
    await ensureReady();
    final db = await openDb();
    final maps = await db.rawQuery(SqlQuerys.visitHistoryRowsSql);
    return maps
        .map(VisitHistoryRecord.fromMap)
        .toList(growable: false);
  }

  /// {@template visit_history_store_format_duration}
  /// Dens süre metni (dk / bilinmiyor).
  ///
  /// Parametreler:
  /// - [minutes]: Süre dakikası (null → bilinmiyor)
  /// - [translate]: l10n çevirici
  ///
  /// Dönüş değeri:
  /// - [String]: Dens süre etiketi
  /// {@endtemplate}
  static String formatDuration(
    int? minutes, {
    required String Function(String key, {Map<String, String>? args})
        translate,
  }) {
    if (minutes == null) {
      return translate('field_sales.visit_duration_unknown');
    }
    return translate(
      'field_sales.visit_duration_minutes',
      args: {'minutes': '$minutes'},
    );
  }
}
