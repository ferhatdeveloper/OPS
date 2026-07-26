// Dosya Adı: einvoice_gib_status.dart
// Açıklama: e-Fatura dens satırı GİB durum kodları (master)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';

/// {@template EinvoiceGibStatus}
/// GİB e-Fatura yaşam döngüsü durumu (dil bağımsız kod).
///
/// Kullanım örneği:
/// ```dart
/// final s = EinvoiceGibStatus.sent;
/// print(s.code); // SENT
/// ```
/// {@endtemplate}
enum EinvoiceGibStatus {
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

  /// {@template einvoice_gib_status_code}
  /// SQLite / senkron sabit kodu.
  /// {@endtemplate}
  String get code {
    switch (this) {
      case EinvoiceGibStatus.draft:
        return 'DRAFT';
      case EinvoiceGibStatus.queued:
        return 'QUEUED';
      case EinvoiceGibStatus.sent:
        return 'SENT';
      case EinvoiceGibStatus.waiting:
        return 'WAITING';
      case EinvoiceGibStatus.accepted:
        return 'ACCEPTED';
      case EinvoiceGibStatus.rejected:
        return 'REJECTED';
      case EinvoiceGibStatus.cancelled:
        return 'CANCELLED';
      case EinvoiceGibStatus.error:
        return 'ERROR';
    }
  }

  /// {@template einvoice_gib_status_l10n_key}
  /// `field_sales.*` çeviri anahtarı.
  /// {@endtemplate}
  String get l10nKey {
    switch (this) {
      case EinvoiceGibStatus.draft:
        return 'field_sales.gib_status_draft';
      case EinvoiceGibStatus.queued:
        return 'field_sales.gib_status_queued';
      case EinvoiceGibStatus.sent:
        return 'field_sales.gib_status_sent';
      case EinvoiceGibStatus.waiting:
        return 'field_sales.gib_status_waiting';
      case EinvoiceGibStatus.accepted:
        return 'field_sales.gib_status_accepted';
      case EinvoiceGibStatus.rejected:
        return 'field_sales.gib_status_rejected';
      case EinvoiceGibStatus.cancelled:
        return 'field_sales.gib_status_cancelled';
      case EinvoiceGibStatus.error:
        return 'field_sales.gib_status_error';
    }
  }

  /// {@template einvoice_gib_status_label}
  /// Yerelleştirilmiş GİB durum etiketi.
  ///
  /// Parametreler:
  /// - [l10n]: Uygulama yerelleştirmesi
  ///
  /// Dönüş değeri:
  /// - [String]: Dens satır etiketi
  /// {@endtemplate}
  String label(AppLocalization l10n) => l10n.translate(l10nKey);

  /// {@template einvoice_gib_status_from_code}
  /// Kod → enum (bilinmeyen → [draft]).
  ///
  /// Parametreler:
  /// - [raw]: SQLite / API kodu
  ///
  /// Dönüş değeri:
  /// - [EinvoiceGibStatus]: Eşleşen durum
  /// {@endtemplate}
  static EinvoiceGibStatus fromCode(String? raw) {
    final code = (raw ?? '').trim().toUpperCase();
    for (final s in EinvoiceGibStatus.values) {
      if (s.code == code) return s;
    }
    return EinvoiceGibStatus.draft;
  }

  /// {@template einvoice_gib_status_is_known}
  /// Kod master’da tanımlı mı.
  /// {@endtemplate}
  static bool isKnown(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    final code = raw.trim().toUpperCase();
    return EinvoiceGibStatus.values.any((s) => s.code == code);
  }
}
