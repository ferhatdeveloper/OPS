// Dosya Adı: menu_permission_flags.dart
// Açıklama: Menü CRUD yetki bayrakları (can_view/add/edit/delete)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template menu_permission_flags}
/// Tek menü için efektif CRUD bayrakları.
///
/// Kullanım örneği:
/// ```dart
/// final merged = a.merge(b);
/// ```
/// {@endtemplate}
class MenuPermissionFlags {
  /// [canView]: Görüntüleme
  final bool canView;

  /// [canAdd]: Ekleme
  final bool canAdd;

  /// [canEdit]: Düzenleme
  final bool canEdit;

  /// [canDelete]: Silme
  final bool canDelete;

  /// {@macro menu_permission_flags}
  const MenuPermissionFlags({
    required this.canView,
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
  });

  /// Tüm bayraklar kapalı
  static const MenuPermissionFlags none = MenuPermissionFlags(
    canView: false,
    canAdd: false,
    canEdit: false,
    canDelete: false,
  );

  /// Tam yetki (admin seed)
  static const MenuPermissionFlags full = MenuPermissionFlags(
    canView: true,
    canAdd: true,
    canEdit: true,
    canDelete: true,
  );

  /// Yalnızca görüntüleme
  static const MenuPermissionFlags viewOnly = MenuPermissionFlags(
    canView: true,
    canAdd: false,
    canEdit: false,
    canDelete: false,
  );

  /// {@template menu_permission_flags_merge}
  /// İki kaydı OR birleştirir (grup → efektif).
  ///
  /// Parametreler:
  /// - [other]: Diğer kaynak
  ///
  /// Dönüş değeri:
  /// - [MenuPermissionFlags]: Birleşik bayraklar
  /// {@endtemplate}
  MenuPermissionFlags merge(MenuPermissionFlags other) {
    return MenuPermissionFlags(
      canView: canView || other.canView,
      canAdd: canAdd || other.canAdd,
      canEdit: canEdit || other.canEdit,
      canDelete: canDelete || other.canDelete,
    );
  }

  /// Map satırından (SQLite 0/1 veya bool).
  factory MenuPermissionFlags.fromMap(Map<String, dynamic> row) {
    bool flag(String key) {
      final v = row[key];
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is num) return v != 0;
      return v?.toString() == '1' || v?.toString().toLowerCase() == 'true';
    }

    return MenuPermissionFlags(
      canView: flag('can_view'),
      canAdd: flag('can_add'),
      canEdit: flag('can_edit'),
      canDelete: flag('can_delete'),
    );
  }

  /// SQLite insert map.
  Map<String, dynamic> toSqlMap() {
    return {
      'can_view': canView ? 1 : 0,
      'can_add': canAdd ? 1 : 0,
      'can_edit': canEdit ? 1 : 0,
      'can_delete': canDelete ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MenuPermissionFlags &&
        other.canView == canView &&
        other.canAdd == canAdd &&
        other.canEdit == canEdit &&
        other.canDelete == canDelete;
  }

  @override
  int get hashCode => Object.hash(canView, canAdd, canEdit, canDelete);
}
