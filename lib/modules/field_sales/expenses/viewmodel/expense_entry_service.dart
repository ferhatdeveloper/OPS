// Dosya Adı: expense_entry_service.dart
// Açıklama: Masraf dens Kaydet — yerel expenses SQLite yazımı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../model/expense_record.dart';

/// {@template expense_entry_service}
/// Masraf girişi dens Kaydet: önce tablo ensure, sonra `expenses` insert.
///
/// Kullanım örneği:
/// ```dart
/// await ExpenseEntryService.saveLocal(db: db, record: record);
/// ```
/// {@endtemplate}
class ExpenseEntryService {
  /// {@template expense_entry_service_save_local}
  /// Yerel masraf kaydını yazar.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite veritabanı
  /// - [record]: Kaydedilecek masraf
  ///
  /// Dönüş değeri:
  /// - [String]: Kayıt id
  ///
  /// Fırlatılan hatalar:
  /// - [ArgumentError]: Tutar ≤ 0
  /// {@endtemplate}
  static Future<String> saveLocal({
    required Database db,
    required ExpenseRecord record,
  }) async {
    if (record.amount <= 0) {
      throw ArgumentError.value(
        record.amount,
        'amount',
        'Masraf tutarı sıfırdan büyük olmalı',
      );
    }

    await db.execute(SqlQuerys.createExpensesTable);
    await db.insert('expenses', record.toMap());
    return record.id;
  }
}
