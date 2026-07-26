// Dosya Adı: discount_approval_store.dart
// Açıklama: İskonto onay SharedPreferences kalıcılık
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/discount_approval_record.dart';

/// {@template discount_approval_store}
/// Bekleyen iskonto onay listesini SharedPreferences ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// const store = DiscountApprovalStore();
/// final list = await store.loadAll();
/// await store.add(record);
/// ```
/// {@endtemplate}
class DiscountApprovalStore {
  /// [prefsKey]: JSON dizi anahtarı
  static const String prefsKey = 'discount_approval_records_json';

  /// {@macro discount_approval_store}
  const DiscountApprovalStore();

  /// {@template discount_approval_store_load_all}
  /// Tüm bekleyen kayıtları yükler (yeniden eskiye).
  ///
  /// Dönüş değeri:
  /// - [List<DiscountApprovalRecord>]: Kayıt listesi
  /// {@endtemplate}
  Future<List<DiscountApprovalRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <DiscountApprovalRecord>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final record = DiscountApprovalRecord.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (record != null) out.add(record);
      }
      out.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// {@template discount_approval_store_save_all}
  /// Listeyi komple yazar.
  ///
  /// Parametreler:
  /// - [records]: Kaydedilecek kayıtlar
  /// {@endtemplate}
  Future<void> saveAll(List<DiscountApprovalRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(prefsKey, payload);
  }

  /// {@template discount_approval_store_add}
  /// Kaydı ekler veya aynı [id] ile günceller.
  ///
  /// Parametreler:
  /// - [record]: Bekleyen iskonto talebi
  /// {@endtemplate}
  Future<void> add(DiscountApprovalRecord record) async {
    final current = await loadAll();
    final next = [
      record,
      ...current.where((e) => e.id != record.id),
    ];
    await saveAll(next);
  }

  /// {@template discount_approval_store_remove}
  /// Kaydı listeden çıkarır (onay / red).
  ///
  /// Parametreler:
  /// - [id]: Kayıt kimliği
  /// {@endtemplate}
  Future<void> remove(String id) async {
    final current = await loadAll();
    await saveAll(current.where((e) => e.id != id).toList());
  }
}
