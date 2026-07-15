// Dosya Adı: approval_status.dart
// Açıklama: Onay durumu için enum tanımları
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

/// Onay durumu için enum
enum ApprovalStatus {
  /// Beklemede (0)
  pending(0),

  /// Onaylandı (1)
  approved(1),

  /// Senkronize Edildi (2)
  synced(2),

  /// Reddedildi (3)
  rejected(3),

  /// Hata (4)
  error(4);

  final int value;
  const ApprovalStatus(this.value);

  /// Değerden enum oluşturur
  static ApprovalStatus fromValue(int value) {
    return ApprovalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ApprovalStatus.pending,
    );
  }

  /// Enum'dan string oluşturur
  String get displayName {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Beklemede';
      case ApprovalStatus.approved:
        return 'Onaylandı';
      case ApprovalStatus.synced:
        return 'Senkronize Edildi';
      case ApprovalStatus.rejected:
        return 'Reddedildi';
      case ApprovalStatus.error:
        return 'Hata';
    }
  }

  /// Senkronizasyon için uygun mu kontrol eder
  bool get isReadyForSync => this == ApprovalStatus.approved;

  /// Senkronize edilmiş mi kontrol eder
  bool get isSynced => this == ApprovalStatus.synced;

  /// Hata durumunda mı kontrol eder
  bool get hasError => this == ApprovalStatus.error;
}
