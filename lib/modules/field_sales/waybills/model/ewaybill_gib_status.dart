// Dosya Adı: ewaybill_gib_status.dart
// Açıklama: e-İrsaliye dens satırı GİB durum kodları (master)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';

/// {@template EwaybillGibStatus}
/// GİB e-İrsaliye yaşam döngüsü durumu (dil bağımsız kod).
///
/// Kullanım örneği:
/// ```dart
/// final s = EwaybillGibStatus.sent;
/// print(s.code); // SENT
/// ```
/// {@endtemplate}
enum EwaybillGibStatus {
  /// Yerel hazır / henüz kuyruğa alınmadı
  draft,

  /// Sync / entegratör kuyruğunda
  queued,

  /// GİB’e iletildi
  sent,

  /// Alıcı / GİB yanıt bekleniyor
  waiting,

  /// Kabul edildi
  accepted,

  /// Reddedildi
  rejected,

  /// İptal
  cancelled,

  /// Teknik / GİB hata
  error;

  /// {@template ewaybill_gib_status_code}
  /// SQLite / senkron sabit kodu.
  /// {@endtemplate}
  String get code {
    switch (this) {
      case EwaybillGibStatus.draft:
        return 'DRAFT';
      case EwaybillGibStatus.queued:
        return 'QUEUED';
      case EwaybillGibStatus.sent:
        return 'SENT';
      case EwaybillGibStatus.waiting:
        return 'WAITING';
      case EwaybillGibStatus.accepted:
        return 'ACCEPTED';
      case EwaybillGibStatus.rejected:
        return 'REJECTED';
      case EwaybillGibStatus.cancelled:
        return 'CANCELLED';
      case EwaybillGibStatus.error:
        return 'ERROR';
    }
  }

  /// {@template ewaybill_gib_status_l10n_key}
  /// `field_sales.*` çeviri anahtarı (e-Fatura ile ortak).
  /// {@endtemplate}
  String get l10nKey {
    switch (this) {
      case EwaybillGibStatus.draft:
        return 'field_sales.gib_status_draft';
      case EwaybillGibStatus.queued:
        return 'field_sales.gib_status_queued';
      case EwaybillGibStatus.sent:
        return 'field_sales.gib_status_sent';
      case EwaybillGibStatus.waiting:
        return 'field_sales.gib_status_waiting';
      case EwaybillGibStatus.accepted:
        return 'field_sales.gib_status_accepted';
      case EwaybillGibStatus.rejected:
        return 'field_sales.gib_status_rejected';
      case EwaybillGibStatus.cancelled:
        return 'field_sales.gib_status_cancelled';
      case EwaybillGibStatus.error:
        return 'field_sales.gib_status_error';
    }
  }

  /// {@template ewaybill_gib_status_label}
  /// Yerelleştirilmiş GİB durum etiketi.
  ///
  /// Parametreler:
  /// - [l10n]: Uygulama yerelleştirmesi
  ///
  /// Dönüş değeri:
  /// - [String]: Dens satır etiketi
  /// {@endtemplate}
  String label(AppLocalization l10n) => l10n.translate(l10nKey);

  /// {@template ewaybill_gib_status_from_code}
  /// Kod → enum (bilinmeyen → [draft]).
  ///
  /// Parametreler:
  /// - [raw]: SQLite / API kodu
  ///
  /// Dönüş değeri:
  /// - [EwaybillGibStatus]: Eşleşen durum
  /// {@endtemplate}
  static EwaybillGibStatus fromCode(String? raw) {
    final code = (raw ?? '').trim().toUpperCase();
    for (final s in EwaybillGibStatus.values) {
      if (s.code == code) return s;
    }
    return EwaybillGibStatus.draft;
  }

  /// {@template ewaybill_gib_status_is_known}
  /// Kod master’da tanımlı mı.
  /// {@endtemplate}
  static bool isKnown(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    final code = raw.trim().toUpperCase();
    return EwaybillGibStatus.values.any((s) => s.code == code);
  }
}
