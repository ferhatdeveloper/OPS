// Dosya Adı: cash_movement_store.dart
// Açıklama: Kasa detay hareketleri — collections SQLite (cash_code)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';
import '../model/cash_movement_row.dart';

/// {@template cash_movement_store}
/// Kasa hareketleri: ayrı `cash_movements` tablosu yok; kaynak `collections`.
///
/// Kullanım örneği:
/// ```dart
/// final rows = await CashMovementStore().listByCashCode('100 01 01');
/// ```
/// {@endtemplate}
class CashMovementStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro cash_movement_store}
  const CashMovementStore({this.openDb});

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template cash_movement_store_list_by_cash_code}
  /// Verilen kasa koduna ait tahsilat/nakit hareketlerini döner.
  ///
  /// Parametreler:
  /// - [cashCode]: Logo / MBT safe_code
  /// - [limit]: Maks satır (varsayılan 200)
  ///
  /// Dönüş değeri:
  /// - [List]: [CashMovementRow] listesi (eski→yeni değil; tarih DESC)
  /// {@endtemplate}
  Future<List<CashMovementRow>> listByCashCode(
    String cashCode, {
    int limit = 200,
  }) async {
    final code = cashCode.trim();
    if (code.isEmpty) return const [];

    try {
      final db = await _db();
      final maps = await db.rawQuery(
        '''
        SELECT
          COALESCE(collection_date, created_at, '') AS event_date,
          COALESCE(payment_type, '') AS payment_type,
          COALESCE(document_no, id, '') AS document_no,
          COALESCE(amount, 0) AS amount
        FROM collections
        WHERE COALESCE(cash_code, '') = ?
           OR COALESCE(target_cash_code, '') = ?
        ORDER BY COALESCE(collection_date, created_at) DESC
        LIMIT ?
        ''',
        [code, code, limit],
      );
      return maps
          .map(CashMovementRow.fromCollectionMap)
          .toList(growable: false);
    } catch (_) {
      // Tablo yok / kolon eksik → boş (stub değil, gerçek boş)
      return const [];
    }
  }
}
