// Dosya Adı: order_dens_scope.dart
// Açıklama: Sipariş dens liste kapsamları (takip / liste / kuyruk / bekleyen)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template order_dens_scope}
/// MBT sipariş dens listelerinin SQLite süzgeç kapsamı.
///
/// Kullanım örneği:
/// ```dart
/// OrderDensScope.tracking
/// ```
/// {@endtemplate}
enum OrderDensScope {
  /// Sipariş Takibi — dönem filtreli tüm siparişler
  tracking,

  /// Sipariş Listesi — transfer edilen (is_synced = 1)
  transferred,

  /// Transfer edilmeyen siparişler (is_synced = 0)
  untransferred,

  /// Bekleyen siparişler (Pending / Proposal)
  pending,
}
