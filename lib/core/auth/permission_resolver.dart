// Dosya Adı: permission_resolver.dart
// Açıklama: Doğrudan + grup menü yetkilerini efektif can_* haritasına birleştirir
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'menu_permission_flags.dart';

/// {@template permission_resolver}
/// Yetki birleştirme motoru (saf — DB yok).
///
/// Kaynaklar: `menu_permissions` satırları + `permission_group_menus`.
/// Aynı `menu_uuid` için bayraklar OR ile birleşir.
///
/// Kullanım örneği:
/// ```dart
/// final map = PermissionResolver.mergeSources([direct, fromGroups]);
/// ```
/// {@endtemplate}
class PermissionResolver {
  PermissionResolver._();

  /// {@template permission_resolver_merge_sources}
  /// Birden fazla uuid→flags haritasını OR birleştirir.
  ///
  /// Parametreler:
  /// - [sources]: Kaynak haritalar
  ///
  /// Dönüş değeri:
  /// - [Map]: Efektif yetkiler (menu_uuid → flags)
  /// {@endtemplate}
  static Map<String, MenuPermissionFlags> mergeSources(
    Iterable<Map<String, MenuPermissionFlags>> sources,
  ) {
    final out = <String, MenuPermissionFlags>{};
    for (final source in sources) {
      for (final entry in source.entries) {
        final uuid = entry.key.trim();
        if (uuid.isEmpty) continue;
        final prev = out[uuid] ?? MenuPermissionFlags.none;
        out[uuid] = prev.merge(entry.value);
      }
    }
    return out;
  }

  /// {@template permission_resolver_from_rows}
  /// SQLite/Map satır listesinden uuid→flags üretir.
  ///
  /// Parametreler:
  /// - [rows]: `menu_uuid` + can_* içeren satırlar
  /// - [uuidKey]: UUID kolon adı
  ///
  /// Dönüş değeri:
  /// - [Map]: Birleştirilmiş harita
  /// {@endtemplate}
  static Map<String, MenuPermissionFlags> fromRows(
    Iterable<Map<String, dynamic>> rows, {
    String uuidKey = 'menu_uuid',
  }) {
    final out = <String, MenuPermissionFlags>{};
    for (final row in rows) {
      final uuid = (row[uuidKey] as String?)?.trim() ?? '';
      if (uuid.isEmpty) continue;
      final flags = MenuPermissionFlags.fromMap(row);
      final prev = out[uuid] ?? MenuPermissionFlags.none;
      out[uuid] = prev.merge(flags);
    }
    return out;
  }

  /// {@template permission_resolver_allows_view}
  /// Efektif haritada can_view mi?
  ///
  /// [hasAnyPermissionData] false ise legacy: tüm menüler görünür
  /// (henüz grup/doğrudan yetki yok — rol filtresi yeter).
  ///
  /// Parametreler:
  /// - [effective]: Resolve sonucu
  /// - [menuUuid]: Menü uuid
  /// - [hasAnyPermissionData]: Kullanıcı için herhangi kayıt var mı
  ///
  /// Dönüş değeri:
  /// - [bool]: Görüntülenebilir mi
  /// {@endtemplate}
  static bool allowsView({
    required Map<String, MenuPermissionFlags> effective,
    required String? menuUuid,
    required bool hasAnyPermissionData,
  }) {
    if (!hasAnyPermissionData) return true;
    final uuid = (menuUuid ?? '').trim();
    if (uuid.isEmpty) return false;
    return effective[uuid]?.canView ?? false;
  }

  /// {@template permission_resolver_filter_uuids}
  /// can_view=true uuid seti.
  ///
  /// Dönüş değeri:
  /// - [Set]: Görüntülenebilir menü uuid’leri
  /// {@endtemplate}
  static Set<String> viewableUuids(
    Map<String, MenuPermissionFlags> effective,
  ) {
    return effective.entries
        .where((e) => e.value.canView)
        .map((e) => e.key)
        .toSet();
  }
}
