// Dosya Adı: whms_order_status.dart
// Açıklama: WHMS emir yaşam döngüsü (draft→assigned→in_progress→done)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_order_status}
/// Operasyonel emir durumu — ONAY sync’ten ayrı.
///
/// Akış: draft → assigned → in_progress → done
/// Yan yollar: rejected | error
/// Onay/sync: `WhmsApprovalStatus` / ONAY 0–4.
///
/// Kullanım örneği:
/// ```dart
/// final s = WhmsOrderStatus.draft;
/// print(s.wireName); // draft
/// print(WhmsOrderStatus.done.wireName); // done
/// ```
/// {@endtemplate}
enum WhmsOrderStatus {
  /// Taslak
  draft,

  /// Kullanıcı / cihaza atandı
  assigned,

  /// Terminal yürütülüyor
  inProgress,

  /// Operasyon tamamlandı (blueprint: completed)
  done,

  /// Reddedildi (operasyonel)
  rejected,

  /// Hata durumu
  error;

  /// SQLite / JSON wire kodu.
  String get wireName {
    switch (this) {
      case WhmsOrderStatus.draft:
        return 'draft';
      case WhmsOrderStatus.assigned:
        return 'assigned';
      case WhmsOrderStatus.inProgress:
        return 'in_progress';
      case WhmsOrderStatus.done:
        return 'done';
      case WhmsOrderStatus.rejected:
        return 'rejected';
      case WhmsOrderStatus.error:
        return 'error';
    }
  }

  /// [wireName] ile aynı — geriye uyumluluk.
  String get storageCode => wireName;

  /// l10n key — sabit string ID.
  String get l10nKey => 'whms.orders.status_$wireName';

  /// Terminal / kapalı durum mu.
  bool get isTerminal =>
      this == WhmsOrderStatus.done ||
      this == WhmsOrderStatus.rejected ||
      this == WhmsOrderStatus.error;

  /// Kod → enum; `completed` alias → [done].
  static WhmsOrderStatus fromWire(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'completed' || v == 'complete') {
      return WhmsOrderStatus.done;
    }
    for (final s in WhmsOrderStatus.values) {
      if (s.wireName == v) return s;
    }
    return WhmsOrderStatus.draft;
  }

  /// [fromWire] alias.
  static WhmsOrderStatus fromStorageCode(String? raw) => fromWire(raw);

  /// Bilinen kod mu (`completed` dahil).
  static bool isKnown(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'completed' || v == 'complete') return true;
    return WhmsOrderStatus.values.any((s) => s.wireName == v);
  }

  /// Sonraki durum (sıralı ana akış); yoksa null.
  WhmsOrderStatus? get next {
    switch (this) {
      case WhmsOrderStatus.draft:
        return WhmsOrderStatus.assigned;
      case WhmsOrderStatus.assigned:
        return WhmsOrderStatus.inProgress;
      case WhmsOrderStatus.inProgress:
        return WhmsOrderStatus.done;
      case WhmsOrderStatus.done:
      case WhmsOrderStatus.rejected:
      case WhmsOrderStatus.error:
        return null;
    }
  }
}
