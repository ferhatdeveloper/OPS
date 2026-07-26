// Dosya Adı: delivery_hold_store.dart
// Açıklama: Beklemeye alınan teslimat SharedPreferences kalıcılık
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/delivery_hold_record.dart';

/// {@template delivery_hold_store}
/// Beklemeye alınan teslimat listesini SharedPreferences ile okur / yazar.
///
/// Kullanım örneği:
/// ```dart
/// const store = DeliveryHoldStore();
/// final list = await store.loadAll();
/// await store.add(record);
/// ```
/// {@endtemplate}
class DeliveryHoldStore {
  /// [prefsKey]: JSON dizi anahtarı
  static const String prefsKey = 'delivery_hold_records_json';

  /// {@macro delivery_hold_store}
  const DeliveryHoldStore();

  /// {@template delivery_hold_store_load_all}
  /// Tüm bekleyen kayıtları yükler (yeniden eskiye).
  ///
  /// Dönüş değeri:
  /// - [List<DeliveryHoldRecord>]: Kayıt listesi
  /// {@endtemplate}
  Future<List<DeliveryHoldRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <DeliveryHoldRecord>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final record = DeliveryHoldRecord.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (record != null) out.add(record);
      }
      out.sort((a, b) => b.heldAt.compareTo(a.heldAt));
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// {@template delivery_hold_store_save_all}
  /// Listeyi komple yazar.
  ///
  /// Parametreler:
  /// - [records]: Kaydedilecek kayıtlar
  /// {@endtemplate}
  Future<void> saveAll(List<DeliveryHoldRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(prefsKey, payload);
  }

  /// {@template delivery_hold_store_add}
  /// Kaydı ekler veya aynı [id] ile günceller.
  ///
  /// Parametreler:
  /// - [record]: Beklemeye alınacak fiş
  /// {@endtemplate}
  Future<void> add(DeliveryHoldRecord record) async {
    final current = await loadAll();
    final next = [
      record,
      ...current.where((e) => e.id != record.id),
    ];
    await saveAll(next);
  }

  /// {@template delivery_hold_store_remove}
  /// Kaydı listeden çıkarır (devam et / kaldır).
  ///
  /// Parametreler:
  /// - [id]: Kayıt kimliği
  /// {@endtemplate}
  Future<void> remove(String id) async {
    final current = await loadAll();
    await saveAll(current.where((e) => e.id != id).toList());
  }
}
