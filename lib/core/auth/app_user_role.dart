// Dosya Adı: app_user_role.dart
// Açıklama: Oturum / users.role → uygulama rol enum (plasiyer, depocu, admin)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template app_user_role}
/// Saha satış / ambar ana ekran ayrımı için kullanıcı rolü.
///
/// Kaynak: `users.role` veya login session `role` alanı.
///
/// Kullanım örneği:
/// ```dart
/// final role = AppUserRole.parse(session['role']);
/// ```
/// {@endtemplate}
enum AppUserRole {
  /// Yönetici — tam menü
  admin,

  /// Süpervizör / saha yöneticisi — tam menü
  supervisor,

  /// Plasiyer / saha satış
  salesperson,

  /// Depocu / ambar
  warehouseKeeper,

  /// Bilinmeyen — güvenli varsayılan: tam menü
  unknown;

  /// Tam menü (filtre yok) mü?
  bool get seesFullMenu =>
      this == AppUserRole.admin ||
      this == AppUserRole.supervisor ||
      this == AppUserRole.unknown;

  /// Rol özel dens hub gösterilsin mi?
  bool get usesRoleHomeHub =>
      this == AppUserRole.salesperson ||
      this == AppUserRole.warehouseKeeper;

  /// l10n anahtarı (`role_home.role_*`)
  String get l10nKey {
    switch (this) {
      case AppUserRole.admin:
        return 'role_home.role_admin';
      case AppUserRole.supervisor:
        return 'role_home.role_supervisor';
      case AppUserRole.salesperson:
        return 'role_home.role_salesperson';
      case AppUserRole.warehouseKeeper:
        return 'role_home.role_warehouse';
      case AppUserRole.unknown:
        return 'role_home.role_unknown';
    }
  }

  /// Ham role string’ini normalize eder.
  ///
  /// Parametreler:
  /// - [raw]: `users.role` / session claim
  ///
  /// Dönüş değeri:
  /// - [AppUserRole]: Eşleşen rol; boş/null → [AppUserRole.unknown]
  static AppUserRole parse(Object? raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s.isEmpty) return AppUserRole.unknown;

    final compact = s
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');

    if (_adminTokens.contains(compact) || _adminTokens.contains(s)) {
      return AppUserRole.admin;
    }
    if (_supervisorTokens.contains(compact) ||
        _supervisorTokens.contains(s)) {
      return AppUserRole.supervisor;
    }
    if (_salespersonTokens.contains(compact) ||
        _salespersonTokens.contains(s)) {
      return AppUserRole.salesperson;
    }
    if (_warehouseTokens.contains(compact) || _warehouseTokens.contains(s)) {
      return AppUserRole.warehouseKeeper;
    }
    return AppUserRole.unknown;
  }

  static const Set<String> _adminTokens = {
    'admin',
    'administrator',
    'yonetici',
    'yönetici',
    'sysadmin',
    'system_admin',
    'superadmin',
  };

  static const Set<String> _supervisorTokens = {
    'supervisor',
    'manager',
    'saha_yoneticisi',
    'saha_yonetici',
    'bolge_muduru',
    'team_lead',
    'supervizor',
  };

  static const Set<String> _salespersonTokens = {
    'plasiyer',
    'salesperson',
    'sales',
    'sales_rep',
    'salesrep',
    'field_sales',
    'saha',
    'saha_satis',
    'satis',
    'satisci',
    'rep',
  };

  static const Set<String> _warehouseTokens = {
    'depocu',
    'warehouse',
    'warehouse_keeper',
    'warehousekeeper',
    'ambar',
    'ambarcı',
    'ambarci',
    'stock_keeper',
    'stockkeeper',
    'whms',
    'storekeeper',
  };
}
