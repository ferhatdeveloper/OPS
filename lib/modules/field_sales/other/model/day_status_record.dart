// Dosya Adı: day_status_record.dart
// Açıklama: MBT gün başla/bitir kayıt modeli (plaka, km, tamamlandı)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template day_status_record}
/// Plasiyer gün durumu kaydı (MBT: PLAKA, BAŞLANGIÇ/BİTİŞ KM, Tamamlandı?).
///
/// Kullanım örneği:
/// ```dart
/// final record = DayStatusRecord(plate: '34 ABC 123', startKm: 1000);
/// ```
/// {@endtemplate}
class DayStatusRecord {
  /// [plate]: Araç plakası
  final String plate;

  /// [startKm]: Gün başlangıç kilometresi
  final int? startKm;

  /// [endKm]: Gün bitiş kilometresi
  final int? endKm;

  /// [completed]: Gün tamamlandı mı (MBT Tamamlandı?)
  final bool completed;

  /// [isDayStarted]: Mesai açık mı
  final bool isDayStarted;

  /// [startTime]: Gün başlangıç zamanı
  final DateTime? startTime;

  /// [endTime]: Gün bitiş zamanı
  final DateTime? endTime;

  /// {@macro day_status_record}
  const DayStatusRecord({
    this.plate = '',
    this.startKm,
    this.endKm,
    this.completed = false,
    this.isDayStarted = false,
    this.startTime,
    this.endTime,
  });

  /// {@template day_status_record_is_day_open}
  /// Mesai açık mı (başladı ve tamamlanmadı).
  ///
  /// Dönüş değeri:
  /// - [bool]: Satış gate için kullanılabilir gün durumu
  /// {@endtemplate}
  bool get isDayOpen => isDayStarted && !completed;

  /// {@template day_status_record_validate_end_km}
  /// Bitiş KM başlangıçtan küçükse l10n hata anahtarı döner.
  ///
  /// Parametreler:
  /// - [startKm]: Başlangıç kilometresi
  /// - [endKm]: Bitiş kilometresi
  ///
  /// Dönüş değeri:
  /// - [String?]: Hata anahtarı veya null
  /// {@endtemplate}
  static String? validateEndKm(int? startKm, int? endKm) {
    if (startKm == null || endKm == null) return null;
    if (endKm < startKm) {
      return 'field_sales.day_end_km_invalid';
    }
    return null;
  }

  /// {@template day_status_record_apply_save}
  /// Kaydet aksiyonundan sonra gün durumunu üretir.
  ///
  /// Parametreler:
  /// - [current]: Mevcut kayıt
  /// - [plate]: Plaka
  /// - [startKm]: Başlangıç KM
  /// - [endKm]: Bitiş KM
  /// - [completed]: Tamamlandı mı
  /// - [now]: İşlem zamanı
  ///
  /// Dönüş değeri:
  /// - [DayStatusRecord]: Güncellenmiş kayıt
  /// {@endtemplate}
  static DayStatusRecord applySave({
    required DayStatusRecord current,
    required String plate,
    required int? startKm,
    required int? endKm,
    required bool completed,
    required DateTime now,
  }) {
    if (completed) {
      return DayStatusRecord(
        plate: plate.trim(),
        startKm: startKm,
        endKm: endKm,
        completed: true,
        isDayStarted: false,
        startTime: current.startTime ?? now,
        endTime: now,
      );
    }

    final opening = !current.isDayStarted;
    return DayStatusRecord(
      plate: plate.trim(),
      startKm: startKm,
      endKm: endKm,
      completed: false,
      isDayStarted: true,
      startTime: opening ? now : (current.startTime ?? now),
      endTime: null,
    );
  }

  /// {@template day_status_record_to_sync_payload}
  /// Sync/audit için plaka/km JSON map üretir.
  ///
  /// Dönüş değeri:
  /// - [Map]: snake_case alanlar + entity_type
  /// {@endtemplate}
  Map<String, dynamic> toSyncPayload() {
    return <String, dynamic>{
      'entity_type': 'day_close',
      'plate': plate,
      'start_km': startKm,
      'end_km': endKm,
      'completed': completed,
      'is_day_started': isDayStarted,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
    };
  }

  /// {@template day_status_record_copy_with}
  /// İmmutable kopya üretir.
  /// {@endtemplate}
  DayStatusRecord copyWith({
    String? plate,
    int? startKm,
    int? endKm,
    bool? completed,
    bool? isDayStarted,
    DateTime? startTime,
    DateTime? endTime,
    bool clearEndKm = false,
    bool clearEndTime = false,
  }) {
    return DayStatusRecord(
      plate: plate ?? this.plate,
      startKm: startKm ?? this.startKm,
      endKm: clearEndKm ? null : (endKm ?? this.endKm),
      completed: completed ?? this.completed,
      isDayStarted: isDayStarted ?? this.isDayStarted,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
    );
  }
}
