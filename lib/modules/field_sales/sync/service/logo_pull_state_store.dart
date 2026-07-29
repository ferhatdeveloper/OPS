// Dosya Adı: logo_pull_state_store.dart
// Açıklama: Kaynak bazlı Logo indirme durumunu (zaman / adet / hata) saklar
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/logo_pull_source.dart';

/// {@template logo_pull_source_state}
/// Tek kaynağın son indirme durumu.
///
/// Kullanım örneği:
/// ```dart
/// final state = (await store.loadAll())[LogoPullSource.customers];
/// ```
/// {@endtemplate}
class LogoPullSourceState {
  /// [lastSuccessAt]: Son başarılı indirme zamanı (UTC)
  final DateTime? lastSuccessAt;

  /// [recordCount]: Son başarılı indirmede yazılan kayıt sayısı
  final int? recordCount;

  /// [lastOk]: En son denemenin sonucu
  final bool lastOk;

  /// [lastError]: En son hata metni (varsa)
  final String? lastError;

  /// {@macro logo_pull_source_state}
  const LogoPullSourceState({
    this.lastSuccessAt,
    this.recordCount,
    this.lastOk = false,
    this.lastError,
  });

  /// Prefs JSON kaydından model üretir.
  factory LogoPullSourceState.fromJson(Map<String, dynamic> json) {
    final rawAt = json['at']?.toString().trim();
    final rawCount = json['count'];
    return LogoPullSourceState(
      lastSuccessAt: (rawAt == null || rawAt.isEmpty)
          ? null
          : DateTime.tryParse(rawAt)?.toUtc(),
      recordCount: rawCount is int
          ? rawCount
          : int.tryParse(rawCount?.toString() ?? ''),
      lastOk: json['ok'] == true,
      lastError: (json['err']?.toString().trim().isEmpty ?? true)
          ? null
          : json['err'].toString().trim(),
    );
  }

  /// Prefs JSON gösterimi.
  Map<String, dynamic> toJson() => {
        'at': lastSuccessAt?.toIso8601String(),
        'count': recordCount,
        'ok': lastOk,
        'err': lastError,
      };

  /// Alan bazlı kopya.
  LogoPullSourceState copyWith({
    DateTime? lastSuccessAt,
    int? recordCount,
    bool? lastOk,
    String? lastError,
    bool clearError = false,
  }) {
    return LogoPullSourceState(
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      recordCount: recordCount ?? this.recordCount,
      lastOk: lastOk ?? this.lastOk,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// {@template logo_pull_state_store}
/// Kaynak bazlı indirme durumlarını tek JSON prefs anahtarında tutar.
///
/// Hatalı deneme, önceki başarılı zaman ve kayıt sayısını silmez; kullanıcı
/// "son ne zaman veri geldi" bilgisini kaybetmez.
///
/// Kullanım örneği:
/// ```dart
/// final store = LogoPullStateStore();
/// await store.record(LogoPullSource.customers, ok: true, recordCount: 120);
/// ```
/// {@endtemplate}
class LogoPullStateStore {
  /// [prefsKey]: Durum haritasının JSON prefs anahtarı
  static const String prefsKey = 'ops_logo_pull_source_state_v1';

  /// [_prefsFactory]: Test enjeksiyonu
  final Future<SharedPreferences> Function()? _prefsFactory;

  /// [_now]: Test edilebilir zaman kaynağı
  final DateTime Function()? _now;

  /// {@macro logo_pull_state_store}
  const LogoPullStateStore({
    Future<SharedPreferences> Function()? prefsFactory,
    DateTime Function()? now,
  })  : _prefsFactory = prefsFactory,
        _now = now;

  Future<SharedPreferences> _prefs() async {
    final factory = _prefsFactory;
    if (factory != null) return factory();
    return SharedPreferences.getInstance();
  }

  DateTime _timestamp() => (_now ?? DateTime.now)().toUtc();

  /// {@template logo_pull_state_store_load_all}
  /// Tüm kaynakların son durumunu okur.
  ///
  /// Dönüş değeri:
  /// - [Map]: Tanınan kaynaklar; kayıt yok / bozuksa boş harita
  /// {@endtemplate}
  Future<Map<LogoPullSource, LogoPullSourceState>> loadAll() async {
    final prefs = await _prefs();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <LogoPullSource, LogoPullSourceState>{};
      for (final entry in decoded.entries) {
        final source = LogoPullSourceCatalog.fromStorageKey('${entry.key}');
        if (source == null) continue;
        final value = entry.value;
        if (value is! Map) continue;
        result[source] = LogoPullSourceState.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
      return result;
    } on Object {
      return {};
    }
  }

  /// {@template logo_pull_state_store_record}
  /// Bir kaynağın deneme sonucunu yazar.
  ///
  /// Parametreler:
  /// - [source]: İndirilen kaynak
  /// - [ok]: Deneme başarılı mı
  /// - [recordCount]: Başarılıysa yazılan kayıt sayısı
  /// - [error]: Başarısızsa hata metni
  /// {@endtemplate}
  Future<void> record(
    LogoPullSource source, {
    required bool ok,
    int? recordCount,
    String? error,
  }) async {
    final current = await loadAll();
    final previous = current[source] ?? const LogoPullSourceState();
    final next = ok
        ? previous.copyWith(
            lastSuccessAt: _timestamp(),
            recordCount: recordCount ?? previous.recordCount,
            lastOk: true,
            clearError: true,
          )
        : previous.copyWith(lastOk: false, lastError: error);

    current[source] = next;
    final payload = <String, dynamic>{
      for (final entry in current.entries)
        LogoPullSourceCatalog.storageKey(entry.key): entry.value.toJson(),
    };
    final prefs = await _prefs();
    await prefs.setString(prefsKey, jsonEncode(payload));
  }

  /// Tüm durum kayıtlarını siler.
  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(prefsKey);
  }
}
