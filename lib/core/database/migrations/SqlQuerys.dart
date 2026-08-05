// Dosya Adı: SqlQuerys.dart
// Açıklama: Projedeki tüm tablo ve migration SQL sorgularını merkezi olarak tutar. Her tablo için CREATE, DROP, ALTER örnekleri, varsayılan insertler ve önemli sorgular burada bulunur. Tüm servisler ve migrationlar bu dosyadan kullanmalıdır.
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// [SqlQuerys]: Projedeki tüm tablo ve migration SQL sorgularını merkezi olarak tutar
class SqlQuerys {
  // --- COMPANIES ---
  static const String createCompaniesTable = '''
    CREATE TABLE IF NOT EXISTS companies (
      id TEXT PRIMARY KEY,
      company_no TEXT,
      name TEXT NOT NULL,
      description TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      default_currency TEXT,
      created_at TEXT,
      updated_at TEXT,
      is_selected INTEGER DEFAULT 0,
      approval_status INTEGER DEFAULT 0
    );
  ''';
  static const String dropCompaniesTable = 'DROP TABLE IF EXISTS companies;';
  static const String alterCompaniesAddApproval =
      "ALTER TABLE companies ADD COLUMN approval_status INTEGER DEFAULT 0;";
  static const String selectCompaniesCount = 'SELECT COUNT(*) FROM companies;';

  // --- COMPANY_PERIOD ---
  static const String createCompanyPeriodTable = '''
    CREATE TABLE IF NOT EXISTS company_period (
      id TEXT PRIMARY KEY,
      company_id TEXT,
      period_name TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT,
      updated_at TEXT,
      company_no TEXT
    );
  ''';
  static const String dropCompanyPeriodTable =
      'DROP TABLE IF EXISTS company_period;';

  // --- USERS ---
  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      email TEXT NOT NULL,
      full_name TEXT NOT NULL,
      role TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      phone_number TEXT,
      department TEXT,
      position TEXT,
      last_login_at TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_logged_in INTEGER NOT NULL DEFAULT 0,
      last_active_at TEXT,
      session_id TEXT,
      force_logout INTEGER NOT NULL DEFAULT 0,
      force_logout_request INTEGER NOT NULL DEFAULT 0,
      force_logout_response TEXT,
      force_logout_timer TEXT,
      password_hash TEXT
    );
  ''';
  static const String dropUsersTable = 'DROP TABLE IF EXISTS users;';

  // --- MENU ---
  static const String createMenuTable = '''
    CREATE TABLE IF NOT EXISTS menu (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      description TEXT,
      title_en TEXT,
      description_en TEXT,
      title_ar TEXT,
      description_ar TEXT,
      title_ru TEXT,
      description_ru TEXT,
      route TEXT,
      parent_id INTEGER,
      parent_uuid TEXT,
      icon TEXT,
      display_order INTEGER,
      is_visible INTEGER NOT NULL DEFAULT 1,
      is_favorite INTEGER NOT NULL DEFAULT 0,
      module_name TEXT,
      created_at TEXT,
      updated_at TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (parent_id) REFERENCES menu(id) ON DELETE CASCADE,
      FOREIGN KEY (parent_uuid) REFERENCES menu(uuid) ON DELETE CASCADE
    );
  ''';
  static const String dropMenuTable = 'DROP TABLE IF EXISTS menu;';
  static const String selectMenuCount = 'SELECT COUNT(*) FROM menu;';

  // --- MENU FAVORITES (sık kullanılanlar — seed wipe’a dayanıklı) ---
  static const String createMenuFavoritesTable = '''
    CREATE TABLE IF NOT EXISTS menu_favorites (
      menu_uuid TEXT PRIMARY KEY NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';
  static const String dropMenuFavoritesTable =
      'DROP TABLE IF EXISTS menu_favorites;';

  // --- DEPARTMENTS ---
  static const String createDepartmentsTable = '''
    CREATE TABLE IF NOT EXISTS departments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      company_no INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT,
      updated_at TEXT
    );
  ''';
  static const String dropDepartmentsTable =
      'DROP TABLE IF EXISTS departments;';

  // --- FACTORIES ---
  static const String createFactoriesTable = '''
    CREATE TABLE IF NOT EXISTS factories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      location TEXT,
      company_id TEXT,
      created_at TEXT,
      updated_at TEXT
    );
  ''';
  static const String dropFactoriesTable = 'DROP TABLE IF EXISTS factories;';

  // --- DEVICE ---
  static const String createDeviceTable = '''
    CREATE TABLE IF NOT EXISTS device (
      id TEXT PRIMARY KEY,
      device_name TEXT NOT NULL,
      device_type TEXT,
      device_serial_number TEXT,
      brand TEXT,
      operating_system TEXT,
      created_at TEXT,
      updated_at TEXT,
      is_active INTEGER DEFAULT 1,
      is_deleted INTEGER DEFAULT 0,
      approval_status INTEGER DEFAULT 0,
      approved_by TEXT,
      approval_date TEXT,
      description TEXT,
      valid_until TEXT
    );
  ''';
  static const String dropDeviceTable = 'DROP TABLE IF EXISTS device;';

  // --- ROLES ---
  static const String createRolesTable = '''
    CREATE TABLE IF NOT EXISTS roles (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      is_system_role INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';
  static const String dropRolesTable = 'DROP TABLE IF EXISTS roles;';

  // --- MENU_PERMISSIONS ---
  static const String createMenuPermissionsTable = '''
    CREATE TABLE IF NOT EXISTS menu_permissions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT NOT NULL UNIQUE,
      menu_id INTEGER,
      menu_uuid TEXT,
      role_id INTEGER,
      role_uuid TEXT,
      can_view INTEGER NOT NULL DEFAULT 1,
      can_edit INTEGER NOT NULL DEFAULT 0,
      can_delete INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      user_id TEXT,
      company_no INTEGER,
      can_add INTEGER DEFAULT 0,
      updated_at TEXT
    );
  ''';
  static const String dropMenuPermissionsTable =
      'DROP TABLE IF EXISTS menu_permissions;';

  // --- PERMISSION GROUPS (gelişmiş yetkilendirme) ---
  static const String createPermissionGroupsTable = '''
    CREATE TABLE IF NOT EXISTS permission_groups (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      is_system INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';
  static const String dropPermissionGroupsTable =
      'DROP TABLE IF EXISTS permission_groups;';

  static const String createPermissionGroupMenusTable = '''
    CREATE TABLE IF NOT EXISTS permission_group_menus (
      group_id TEXT NOT NULL,
      menu_uuid TEXT NOT NULL,
      can_view INTEGER NOT NULL DEFAULT 1,
      can_add INTEGER NOT NULL DEFAULT 0,
      can_edit INTEGER NOT NULL DEFAULT 0,
      can_delete INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      PRIMARY KEY (group_id, menu_uuid)
    );
  ''';
  static const String dropPermissionGroupMenusTable =
      'DROP TABLE IF EXISTS permission_group_menus;';

  static const String createPermissionGroupMembersTable = '''
    CREATE TABLE IF NOT EXISTS permission_group_members (
      group_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      company_no INTEGER NOT NULL,
      created_at TEXT,
      updated_at TEXT,
      PRIMARY KEY (group_id, user_id, company_no)
    );
  ''';
  static const String dropPermissionGroupMembersTable =
      'DROP TABLE IF EXISTS permission_group_members;';

  // --- FIELD SALES: CUSTOMERS ---
  static const String createCustomersTable = '''
    CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY,
      code TEXT,
      name TEXT NOT NULL,
      tax_no TEXT,
      tax_office TEXT,
      yetkili TEXT,
      address TEXT,
      adres2 TEXT,
      il TEXT,
      ilce TEXT,
      semt TEXT,
      ulke TEXT,
      posta_kodu TEXT,
      tckn TEXT,
      phone TEXT,
      telefon2 TEXT,
      fax TEXT,
      email TEXT,
      balance REAL DEFAULT 0.0,
      latitude REAL,
      longitude REAL,
      is_active INTEGER DEFAULT 1,
      nfc_tag_id TEXT,
      last_visit_at TEXT,
      created_at TEXT,
      updated_at TEXT,
      card_role TEXT DEFAULT 'customer'
    );
  ''';

  // --- FIELD SALES: PRODUCTS ---
  static const String createProductsTable = '''
    CREATE TABLE IF NOT EXISTS products (
      id TEXT PRIMARY KEY,
      code TEXT UNIQUE,
      name TEXT NOT NULL,
      description TEXT,
      barcode TEXT,
      unit TEXT,
      price REAL DEFAULT 0.0,
      vat_rate INTEGER DEFAULT 20,
      stock_quantity REAL DEFAULT 0.0,
      category TEXT,
      unit_set_id TEXT,
      main_unit TEXT,
      image_url TEXT,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (unit_set_id) REFERENCES unit_sets(id)
    );
  ''';

  // --- FIELD SALES: ORDERS ---
  static const String createOrdersTable = '''
    CREATE TABLE IF NOT EXISTS orders (
      id TEXT PRIMARY KEY,
      customer_id TEXT,
      order_date TEXT,
      total_amount REAL,
      status TEXT, -- 'Pending', 'Approved', 'Cancelled', 'Proposal'
      notes TEXT,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      approval_status INTEGER NOT NULL DEFAULT 0,
      signature_data TEXT,
      order_type TEXT DEFAULT 'sales',
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  // --- FIELD SALES: ORDER_ITEMS ---
  static const String createOrderItemsTable = '''
    CREATE TABLE IF NOT EXISTS order_items (
      id TEXT PRIMARY KEY,
      order_id TEXT,
      product_id TEXT,
      unit_name TEXT,
      quantity REAL,
      price REAL,
      vat_amount REAL,
      total_amount REAL,
      discount_percent REAL DEFAULT 0,
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

  // --- FIELD SALES: INVOICES ---
  static const String createInvoicesTable = '''
    CREATE TABLE IF NOT EXISTS invoices (
      id TEXT PRIMARY KEY,
      customer_id TEXT,
      invoice_date TEXT,
      total_amount REAL,
      status TEXT, -- 'Pending', 'Completed', 'Cancelled'
      notes TEXT,
      invoice_type TEXT, -- 'Sales', 'Return'
      is_e_invoice INTEGER DEFAULT 1,
      ettn TEXT,
      gib_status TEXT,
      approval_status INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      logo_ref TEXT,
      pg_synced INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  /// Mevcut invoices tablosuna ETTN kolonu.
  static const String addInvoicesEttnColumn =
      'ALTER TABLE invoices ADD COLUMN ettn TEXT;';

  /// Mevcut invoices tablosuna GİB durum kolonu.
  static const String addInvoicesGibStatusColumn =
      'ALTER TABLE invoices ADD COLUMN gib_status TEXT;';

  static const String createInvoiceItemsTable = '''
    CREATE TABLE IF NOT EXISTS invoice_items (
      id TEXT PRIMARY KEY,
      invoice_id TEXT,
      product_id TEXT,
      quantity REAL,
      price REAL,
      vat_amount REAL,
      total_amount REAL,
      unit_name TEXT,
      updated_at TEXT,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

  /// Mevcut DB: fatura kalemi birim adı
  static const String addInvoiceItemsUnitNameColumn =
      'ALTER TABLE invoice_items ADD COLUMN unit_name TEXT;';

  // --- FIELD SALES: e-FATURA DURUM (dens) ---
  static const String createEinvoiceStatusTable = '''
    CREATE TABLE IF NOT EXISTS einvoice_status (
      id TEXT PRIMARY KEY,
      invoice_id TEXT,
      document_no TEXT,
      ettn TEXT,
      gib_status TEXT NOT NULL DEFAULT 'DRAFT',
      doc_side TEXT NOT NULL DEFAULT 'sales',
      profile TEXT,
      customer_id TEXT,
      customer_code TEXT,
      customer_name TEXT,
      document_date TEXT,
      amount REAL DEFAULT 0,
      status_message TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  static const String dropEinvoiceStatusTable =
      'DROP TABLE IF EXISTS einvoice_status;';

  // --- FIELD SALES: WAYBILLS (irsaliye / dispatch) ---
  static const String createWaybillsTable = '''
    CREATE TABLE IF NOT EXISTS waybills (
      id TEXT PRIMARY KEY,
      customer_id TEXT,
      waybill_date TEXT,
      waybill_type TEXT NOT NULL DEFAULT 'waybill_wholesale',
      total_amount REAL DEFAULT 0,
      status TEXT,
      notes TEXT,
      invoice_id TEXT,
      approval_status INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id),
      FOREIGN KEY (invoice_id) REFERENCES invoices(id)
    );
  ''';

  /// Mevcut waybills tablosuna fatura bağlantısı (faturasız filtre).
  static const String addWaybillInvoiceIdColumn =
      'ALTER TABLE waybills ADD COLUMN invoice_id TEXT;';

  static const String createWaybillItemsTable = '''
    CREATE TABLE IF NOT EXISTS waybill_items (
      id TEXT PRIMARY KEY,
      waybill_id TEXT,
      product_id TEXT,
      product_code TEXT,
      quantity REAL,
      price REAL,
      total_amount REAL,
      updated_at TEXT,
      FOREIGN KEY (waybill_id) REFERENCES waybills(id)
    );
  ''';

  // --- FIELD SALES: e-İRSALİYE DURUM (dens) ---
  static const String createEwaybillStatusTable = '''
    CREATE TABLE IF NOT EXISTS ewaybill_status (
      id TEXT PRIMARY KEY,
      waybill_id TEXT,
      document_no TEXT,
      ettn TEXT,
      gib_status TEXT NOT NULL DEFAULT 'DRAFT',
      doc_side TEXT NOT NULL DEFAULT 'sales',
      customer_id TEXT,
      customer_code TEXT,
      customer_name TEXT,
      document_date TEXT,
      amount REAL DEFAULT 0,
      status_message TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  static const String dropEwaybillStatusTable =
      'DROP TABLE IF EXISTS ewaybill_status;';

  // --- FIELD SALES: COLLECTIONS ---
  static const String createCollectionsTable = '''
    CREATE TABLE IF NOT EXISTS collections (
      id TEXT PRIMARY KEY,
      customer_id TEXT,
      amount REAL,
      payment_type TEXT, -- 'Cash', 'CreditCard', 'Check'
      collection_date TEXT,
      status TEXT, -- 'Pending', 'Completed', 'Cancelled'
      notes TEXT,
      bank_name TEXT,
      branch_name TEXT,
      check_number TEXT,
      due_date TEXT,
      cash_code TEXT,
      target_cash_code TEXT,
      document_no TEXT,
      currency_code TEXT,
      exchange_rate REAL,
      base_amount REAL,
      base_currency_code TEXT,
      salesperson_code TEXT,
      special_code_1 TEXT,
      endorsement TEXT,
      original_debtor TEXT,
      workplace TEXT,
      account_number TEXT,
      approval_status INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  // --- FIELD SALES: TARGETS ---
  static const String createTargetsTable = '''
    CREATE TABLE IF NOT EXISTS targets (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      target_amount REAL,
      achieved_amount REAL DEFAULT 0,
      period TEXT, -- e.g., '2023-11' or '2023-Q4'
      type TEXT, -- e.g., 'Sales', 'Collection', 'Visit'
      created_at TEXT,
      updated_at TEXT,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  // --- SETTINGS ---
  static const String createSettingsTable = '''
    CREATE TABLE IF NOT EXISTS settings (
      id TEXT PRIMARY KEY,
      menu_reset INTEGER DEFAULT 0,
      super_pass TEXT,
      auth_key TEXT,
      created_at TEXT,
      updated_at TEXT,
      approval_status INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      max_user INTEGER DEFAULT 1,
      setting_key TEXT NOT NULL,
      description TEXT,
      setting_value TEXT
    );
  ''';
  static const String dropSettingsTable = 'DROP TABLE IF EXISTS settings;';

  // --- USER_COMPANY_VISIBILITY ---
  static const String createUserCompanyVisibilityTable = '''
    CREATE TABLE IF NOT EXISTS user_company_visibility (
      user_id TEXT NOT NULL,
      company_no INTEGER NOT NULL,
      is_visible INTEGER NOT NULL DEFAULT 1,
      company_name TEXT,
      company_detail TEXT,
      username TEXT,
      is_selected TEXT DEFAULT '0',
      PRIMARY KEY (user_id, company_no)
    );
  ''';
  static const String dropUserCompanyVisibilityTable =
      'DROP TABLE IF EXISTS user_company_visibility;';

  // --- USER_ROLES ---
  static const String createUserRolesTable = '''
    CREATE TABLE IF NOT EXISTS user_roles (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      role_id TEXT NOT NULL,
      assigned_at TEXT
    );
  ''';
  static const String dropUserRolesTable = 'DROP TABLE IF EXISTS user_roles;';

  // --- SYNC_SETTINGS ---
  static const String createSyncSettingsTable = '''
    CREATE TABLE IF NOT EXISTS sync_settings (
      table_name TEXT PRIMARY KEY,
      is_enabled INTEGER NOT NULL DEFAULT 1,
      sync_direction TEXT NOT NULL DEFAULT 'bidirectional',
      description TEXT
    );
  ''';
  static const String dropSyncSettingsTable =
      'DROP TABLE IF EXISTS sync_settings;';

  // --- LANGUAGES ---
  static const String createLanguagesTable = '''
    CREATE TABLE IF NOT EXISTS languages (
      code TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      local_name TEXT NOT NULL,
      flag_code TEXT NOT NULL
    );
  ''';
  static const String dropLanguagesTable = 'DROP TABLE IF EXISTS languages;';

  // --- TRANSLATIONS ---
  static const String createTranslationsTable = '''
    CREATE TABLE IF NOT EXISTS translations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_text TEXT NOT NULL,
      source_language TEXT NOT NULL,
      target_language TEXT NOT NULL,
      translated_text TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      UNIQUE(original_text, source_language, target_language)
    );
  ''';
  static const String dropTranslationsTable =
      'DROP TABLE IF EXISTS translations;';

  // --- AUDIT_LOG ---
  static const String createAuditLogTable = '''
    CREATE TABLE IF NOT EXISTS audit_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      action TEXT NOT NULL,
      table_name TEXT,
      record_id TEXT,
      old_values TEXT,
      new_values TEXT,
      ip_address TEXT,
      user_agent TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    );
  ''';
  static const String dropAuditLogTable = 'DROP TABLE IF EXISTS audit_log;';

  // --- API_CONFIG ---
  static const String createApiConfigTable = '''
    CREATE TABLE IF NOT EXISTS api_config (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      base_url TEXT,
      api_key TEXT,
      timeout INTEGER,
      use_https INTEGER
    );
  ''';
  static const String dropApiConfigTable = 'DROP TABLE IF EXISTS api_config;';

  // --- SYNC_METADATA (opsiyonel) ---
  static const String createSyncMetadataTable = '''
    CREATE TABLE IF NOT EXISTS sync_metadata (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_name TEXT NOT NULL,
      last_synced_at TEXT,
      sync_status TEXT
    );
  ''';
  static const String dropSyncMetadataTable =
      'DROP TABLE IF EXISTS sync_metadata;';

  // --- Migration/ALTER örnekleri ---
  static const String alterAddApprovalStatus =
      "ALTER TABLE {table} ADD COLUMN approval_status INTEGER NOT NULL DEFAULT 0;";
  static const String alterAddIsSynced =
      "ALTER TABLE {table} ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0;";
  static const String alterAddIsDeleted =
      "ALTER TABLE {table} ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;";
  static const String alterAddCreatedAt =
      "ALTER TABLE {table} ADD COLUMN created_at TEXT;";
  static const String alterAddUpdatedAt =
      "ALTER TABLE {table} ADD COLUMN updated_at TEXT;";
  static const String alterAddDescription =
      "ALTER TABLE {table} ADD COLUMN description TEXT;";

  // --- Örnek SELECT/INSERT/UPDATE sorguları ---
  static const String selectCount = "SELECT COUNT(*) as count FROM {table};";
  static const String deleteAll = "DELETE FROM {table};";
  static const String insertOrReplace =
      "INSERT OR REPLACE INTO {table} ({columns}) VALUES ({values});";

  /// Dinamik tema tablosu oluşturur
  static String createThemeTable(String tableName, String columnThemeMode) {
    return 'CREATE TABLE IF NOT EXISTS ' +
        tableName +
        '(' +
        columnThemeMode +
        ' TEXT)';
  }

  /// Dinamik olarak tabloya kolon eklemek için SQL döner
  static String addColumnSql(String table, String column, String type) {
    return 'ALTER TABLE ' + table + ' ADD COLUMN ' + column + ' ' + type + ';';
  }

  /// Onay alanı migration SQL'i (kısa yol)
  static String addApprovalStatusColumn(String table) {
    return addColumnSql(table, 'approval_status', 'INTEGER NOT NULL DEFAULT 0');
  }

  /// is_synced alanı migration SQL'i (kısa yol)
  static String addIsSyncedColumn(String table) {
    return addColumnSql(table, 'is_synced', 'INTEGER NOT NULL DEFAULT 0');
  }

  /// is_synced alanı migration SQL'i (kısa yol, kısa ad)
  static String addSyncColumn(String table) {
    return addIsSyncedColumn(table);
  }

  /// is_deleted alanı migration SQL'i (kısa yol)
  static String addIsDeletedColumn(String table) {
    return addColumnSql(table, 'is_deleted', 'INTEGER NOT NULL DEFAULT 0');
  }

  /// created_at alanı migration SQL'i (kısa yol)
  static String addCreatedAtColumn(String table) {
    return addColumnSql(table, 'created_at', 'TEXT');
  }

  /// updated_at alanı migration SQL'i (kısa yol)
  static String addUpdatedAtColumn(String table) {
    return addColumnSql(table, 'updated_at', 'TEXT');
  }

  /// description alanı migration SQL'i (kısa yol)
  static String addDescriptionColumn(String table) {
    return addColumnSql(table, 'description', 'TEXT');
  }

  // --- Varsayılan veriler ---

  /// Varsayılan sync_settings verilerini döner
  static List<Map<String, dynamic>> getDefaultSyncSettings() {
    return [
      {'name': 'companies', 'desc': 'Firma bilgileri'},
      {'name': 'company_period', 'desc': 'Firma dönemleri'},
      {'name': 'users', 'desc': 'Kullanıcılar'},
      {'name': 'menu', 'desc': 'Menü tanımları'},
      {'name': 'departments', 'desc': 'Departmanlar'},
      {'name': 'factories', 'desc': 'Fabrikalar'},
      {'name': 'device', 'desc': 'Cihazlar'},
      {'name': 'roles', 'desc': 'Roller'},
      {'name': 'settings', 'desc': 'Uygulama ayarları'},
      {
        'name': 'user_company_visibility',
        'desc': 'Kullanıcı-firma görünürlüğü'
      },
      {'name': 'user_roles', 'desc': 'Kullanıcı rolleri'},
    ];
  }

  /// Varsayılan sync_settings insert SQL'i
  static String getInsertSyncSettingSql() {
    return '''
      INSERT OR IGNORE INTO sync_settings 
      (table_name, description, is_enabled, sync_direction) 
      VALUES (?, ?, ?, ?)
    ''';
  }

  /// Varsayılan sync_settings verilerini eklemek için batch insert SQL'i
  static String getBatchInsertSyncSettingsSql() {
    return '''
      INSERT OR IGNORE INTO sync_settings 
      (table_name, description, is_enabled, sync_direction) 
      VALUES 
      ('companies', 'Firma bilgileri', 1, 'bidirectional'),
      ('company_period', 'Firma dönemleri', 1, 'bidirectional'),
      ('users', 'Kullanıcılar', 1, 'bidirectional'),
      ('menu', 'Menü tanımları', 1, 'bidirectional'),
      ('departments', 'Departmanlar', 1, 'bidirectional'),
      ('factories', 'Fabrikalar', 1, 'bidirectional'),
      ('device', 'Cihazlar', 1, 'bidirectional'),
      ('roles', 'Roller', 1, 'bidirectional'),
      ('menu_permissions', 'Menü yetkileri', 1, 'bidirectional'),
      ('permission_groups', 'Yetki grupları', 1, 'bidirectional'),
      ('permission_group_menus', 'Yetki grubu menüleri', 1, 'bidirectional'),
      ('permission_group_members', 'Yetki grubu üyeleri', 1, 'bidirectional'),
      ('settings', 'Uygulama ayarları', 1, 'bidirectional'),
      ('user_company_visibility', 'Kullanıcı-firma görünürlüğü', 1, 'bidirectional'),
      ('user_roles', 'Kullanıcı rolleri', 1, 'bidirectional')
    ''';
  }

  // --- PRAGMA Komutları ---

  /// Tablo bilgilerini almak için PRAGMA komutu
  static String getTableInfoSql(String tableName) {
    return "PRAGMA table_info($tableName)";
  }

  /// Veritabanı şemasını almak için PRAGMA komutu
  static String getDatabaseSchemaSql() {
    return "PRAGMA database_list";
  }

  /// Tablo indekslerini almak için PRAGMA komutu
  static String getTableIndexesSql(String tableName) {
    return "PRAGMA index_list($tableName)";
  }

  /// Foreign key kısıtlamalarını almak için PRAGMA komutu
  static String getForeignKeysSql(String tableName) {
    return "PRAGMA foreign_key_list($tableName)";
  }

  // --- Şifreleme PRAGMA Komutları ---

  /// SQLite şifreleme anahtarı ayarlama
  static String getSetEncryptionKeySql(String key) {
    return 'PRAGMA key = "$key"';
  }

  /// Şifreleme uyumluluğu ayarlama
  static const String setCipherCompatibility =
      'PRAGMA cipher_compatibility = 3';

  /// Şifreleme sayfa boyutu ayarlama
  static const String setCipherPageSize = 'PRAGMA cipher_page_size = 4096';

  /// Şifreleme HMAC algoritması ayarlama
  static const String setCipherHmacAlgorithm =
      'PRAGMA cipher_hmac_algorithm = HMAC_SHA1';

  /// Şifreleme KDF iterasyon sayısı ayarlama
  static const String setCipherKdfIter = 'PRAGMA cipher_kdf_iter = 4000';

  /// Şifreleme anahtarı test sorgusu
  static String getTestEncryptionKeySql(String key) {
    return 'SELECT quote($key)';
  }

  // --- UPDATE Sorguları ---

  /// Tablo içindeki tüm kayıtların approval_status'ünü güncelleme
  static String getUpdateApprovalStatusSql(String table, int status) {
    return 'UPDATE $table SET approval_status = $status';
  }

  /// Tablo içindeki tüm kayıtların is_synced'ini güncelleme
  static String getUpdateSyncStatusSql(String table, int status) {
    return 'UPDATE $table SET is_synced = $status';
  }

  /// Tablo içindeki tüm kayıtların is_deleted'ini güncelleme
  static String getUpdateDeletedStatusSql(String table, int status) {
    return 'UPDATE $table SET is_deleted = $status';
  }

  /// Belirli bir kaydın approval_status'ünü güncelleme
  static String getUpdateRecordApprovalStatusSql(
      String table, String id, int status) {
    return 'UPDATE $table SET approval_status = $status WHERE id = "$id"';
  }

  // --- COUNT Sorguları ---

  /// Tablo kayıt sayısını alma
  static String getTableCountSql(String table) {
    return 'SELECT COUNT(*) FROM $table';
  }

  /// Tablo içinde approval_status=1 olan kayıt sayısını alma
  static String getApprovalCountSql(String table) {
    return 'SELECT COUNT(*) as cnt FROM $table WHERE approval_status = 1';
  }

  /// Tablo içinde is_synced=1 olan kayıt sayısını alma
  static String getSyncedCountSql(String table) {
    return 'SELECT COUNT(*) as cnt FROM $table WHERE is_synced = 1';
  }

  /// Tablo içinde is_deleted=1 olan kayıt sayısını alma
  static String getDeletedCountSql(String table) {
    return 'SELECT COUNT(*) as cnt FROM $table WHERE is_deleted = 1';
  }

  // --- API Config Sorguları ---

  /// API config tablosundaki kayıt sayısını alma
  static const String getApiConfigCountSql =
      'SELECT COUNT(*) as count FROM api_config';

  /// API config tablosunu güncelleme (id=1 için)
  static const String updateApiConfigSql =
      'UPDATE api_config SET base_url = ?, printer_url = ?, api_key = ?, timeout = ?, use_https = ? WHERE id = 1';

  /// API config tablosuna yeni kayıt ekleme
  static const String insertApiConfigSql =
      'INSERT INTO api_config (base_url, printer_url, api_key, timeout, use_https) VALUES (?, ?, ?, ?, ?)';

  // --- VACUUM ve Backup Sorguları ---

  /// Veritabanını yedekleme (VACUUM INTO)
  static String getVacuumIntoBackupSql(String backupPath) {
    return 'VACUUM INTO "$backupPath"';
  }

  /// Veritabanını optimize etme
  static const String vacuumSql = 'VACUUM';

  /// Veritabanı bütünlüğünü kontrol etme
  static const String integrityCheckSql = 'PRAGMA integrity_check';

  // --- Dinamik Sorgu Oluşturucular ---

  /// Dinamik WHERE koşulu ile SELECT sorgusu
  static String getSelectWithWhereSql(String table, String whereClause,
      {String? orderBy, int? limit}) {
    String sql = 'SELECT * FROM $table WHERE $whereClause';
    if (orderBy != null) sql += ' ORDER BY $orderBy';
    if (limit != null) sql += ' LIMIT $limit';
    return sql;
  }

  /// Dinamik kolon listesi ile SELECT sorgusu
  static String getSelectColumnsSql(String table, List<String> columns,
      {String? where, String? orderBy}) {
    String columnList = columns.join(', ');
    String sql = 'SELECT $columnList FROM $table';
    if (where != null) sql += ' WHERE $where';
    if (orderBy != null) sql += ' ORDER BY $orderBy';
    return sql;
  }

  /// Dinamik INSERT sorgusu
  static String getInsertSql(String table, List<String> columns) {
    String columnList = columns.join(', ');
    String placeholders = columns.map((_) => '?').join(', ');
    return 'INSERT INTO $table ($columnList) VALUES ($placeholders)';
  }

  /// Dinamik UPDATE sorgusu
  static String getUpdateSql(
      String table, List<String> columns, String whereClause) {
    String setClause = columns.map((col) => '$col = ?').join(', ');
    return 'UPDATE $table SET $setClause WHERE $whereClause';
  }

  /// Dinamik DELETE sorgusu
  static String getDeleteSql(String table, String whereClause) {
    return 'DELETE FROM $table WHERE $whereClause';
  }

  // --- Özel Sorgular ---

  /// Favori menü öğelerini alma
  static const String getFavoriteMenusSql =
      'SELECT * FROM menu WHERE is_favorite = 1 ORDER BY title';

  /// Belirli başlığa sahip menü öğesini alma
  static const String getMenuByTitleSql = 'SELECT * FROM menu WHERE title = ?';

  /// Dönemleri tarih sırasına göre alma
  static const String getPeriodsOrderedSql =
      'SELECT * FROM company_period ORDER BY start_date ASC';

  /// Aktif kullanıcıları alma
  static const String getActiveUsersSql =
      'SELECT * FROM users WHERE is_active = 1 AND is_deleted = 0';

  /// Onaylanmış cihazları alma
  static const String getApprovedDevicesSql =
      'SELECT * FROM device WHERE approval_status = 1 AND is_deleted = 0';

  /// Senkronize edilmemiş kayıtları alma
  static String getUnsyncedRecordsSql(String table) {
    return 'SELECT * FROM $table WHERE is_synced = 0 AND is_deleted = 0';
  }

  /// Onaylanmamış kayıtları alma
  static String getUnapprovedRecordsSql(String table) {
    return 'SELECT * FROM $table WHERE approval_status = 0 AND is_deleted = 0';
  }

  // --- Audit Log Sorguları ---

  /// Audit log kaydı ekleme
  static const String insertAuditLogSql = '''
    INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values, ip_address, user_agent, created_at) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  /// Belirli kullanıcının audit loglarını alma
  static const String getAuditLogsByUserSql =
      'SELECT * FROM audit_log WHERE user_id = ? ORDER BY created_at DESC';

  /// Belirli tablonun audit loglarını alma
  static const String getAuditLogsByTableSql =
      'SELECT * FROM audit_log WHERE table_name = ? ORDER BY created_at DESC';

  // --- Sync Metadata Sorguları ---

  /// Sync metadata kaydı ekleme/güncelleme
  static const String upsertSyncMetadataSql = '''
    INSERT OR REPLACE INTO sync_metadata (table_name, last_synced_at, sync_status) 
    VALUES (?, ?, ?)
  ''';

  /// Tablo için son sync bilgisini alma
  static const String getLastSyncInfoSql =
      'SELECT * FROM sync_metadata WHERE table_name = ?';

  // --- Utility Sorguları ---

  /// Tablo var mı kontrol etme
  static String getTableExistsSql(String tableName) {
    return "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'";
  }

  /// Tüm tablo isimlerini alma
  static const String getAllTablesSql =
      "SELECT name FROM sqlite_master WHERE type='table'";

  /// Tablo şemasını alma
  static String getTableSchemaSql(String tableName) {
    return "SELECT sql FROM sqlite_master WHERE type='table' AND name='$tableName'";
  }

  // --- Test Tabloları ---

  /// Test tablosu oluşturma SQL'i
  static const String createTestTable = '''
    CREATE TABLE IF NOT EXISTS test_table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      age INTEGER,
      is_active INTEGER DEFAULT 1,
      created_at TEXT,
      updated_at TEXT,
      is_deleted INTEGER DEFAULT 0
    );
  ''';

  /// Test tablosu silme SQL'i
  static const String dropTestTable = 'DROP TABLE IF EXISTS test_table;';

  /// Test verisi ekleme SQL'i
  static const String insertTestData = '''
    INSERT INTO test_table (name, age, is_active, created_at, updated_at) 
    VALUES (?, ?, ?, ?, ?)
  ''';

  /// Test verisi sorgulama SQL'i
  static const String selectTestData =
      'SELECT * FROM test_table WHERE is_deleted = 0';

  // --- Menu Permissions Özel Sorguları ---

  /// Menu permissions tablosuna veri ekleme SQL'i (tüm kolonlar için)
  static const String insertMenuPermissionSql = '''
    INSERT INTO menu_permissions (
      id, uuid, user_id, menu_id, menu_uuid, role_id, role_uuid, 
      company_no, can_view, can_edit, can_delete, can_add, 
      created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  /// Menu permissions tablosuna veri ekleme SQL'i (temel kolonlar için)
  static const String insertMenuPermissionBasicSql = '''
    INSERT INTO menu_permissions (
      id, uuid, user_id, menu_id, company_no, can_view, can_edit, 
      can_delete, can_add, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  /// Menu permissions tablosunu güncelleme SQL'i
  static const String updateMenuPermissionSql = '''
    UPDATE menu_permissions SET 
      uuid = ?, user_id = ?, menu_id = ?, menu_uuid = ?, role_id = ?, 
      role_uuid = ?, company_no = ?, can_view = ?, can_edit = ?, 
      can_delete = ?, can_add = ?, updated_at = ?
    WHERE id = ?
  ''';

  /// Menu permissions tablosundan veri sorgulama SQL'i
  static const String selectMenuPermissionsSql = '''
    SELECT * FROM menu_permissions 
    WHERE is_deleted = 0 
    ORDER BY created_at DESC
  ''';

  /// Belirli kullanıcının menu permissions'larını sorgulama SQL'i
  static String getMenuPermissionsByUserSql(String userId) {
    return '''
      SELECT * FROM menu_permissions 
      WHERE user_id = '$userId' AND is_deleted = 0 
      ORDER BY created_at DESC
    ''';
  }

  /// Belirli menünün permissions'larını sorgulama SQL'i
  static String getMenuPermissionsByMenuSql(int menuId) {
    return '''
      SELECT * FROM menu_permissions 
      WHERE menu_id = $menuId AND is_deleted = 0 
      ORDER BY created_at DESC
    ''';
  }

  /// Menu permissions tablosundan veri silme SQL'i (soft delete)
  static const String deleteMenuPermissionSql = '''
    UPDATE menu_permissions SET 
      is_deleted = 1, updated_at = ? 
    WHERE id = ?
  ''';

  /// Menu permissions tablosunu temizleme SQL'i (hard delete)
  static const String truncateMenuPermissionsSql =
      'DELETE FROM menu_permissions;';

  // --- FIELD SALES: VISITS ---
  static const String createVisitsTable = '''
    CREATE TABLE IF NOT EXISTS visits (
      id TEXT PRIMARY KEY,
      customer_id TEXT,
      user_id TEXT,
      check_in_at TEXT,
      check_out_at TEXT,
      check_in_lat REAL,
      check_in_long REAL,
      check_out_lat REAL,
      check_out_long REAL,
      notes TEXT,
      reason_code TEXT,
      audio_recording_path TEXT,
      status TEXT, -- 'Open', 'Completed'
      duration_minutes INTEGER,
      is_synced INTEGER DEFAULT 0,
      signature_data TEXT,
      created_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  /// Mevcut visits tablosuna VisitReasonMaster kod kolonu ekler.
  static const String addVisitsReasonCodeColumn =
      "ALTER TABLE visits ADD COLUMN reason_code TEXT;";

  /// Mevcut visits tablosuna STT ses dosyası yolu (metadata) ekler.
  static const String addVisitsAudioRecordingPathColumn =
      "ALTER TABLE visits ADD COLUMN audio_recording_path TEXT;";

  /// Ziyaret ses KVKK onay zamanı.
  static const String addVisitsVoiceConsentAtColumn =
      "ALTER TABLE visits ADD COLUMN voice_consent_at TEXT;";

  /// AI duygu özeti (storage key).
  static const String addVisitsEmotionSummaryColumn =
      "ALTER TABLE visits ADD COLUMN emotion_summary TEXT;";

  /// AI ziyaret durum önerisi (draft; silent write).
  static const String addVisitsAiStatusDraftColumn =
      "ALTER TABLE visits ADD COLUMN ai_status_draft TEXT;";

  // --- FIELD SALES: VISIT VOICE INTELLIGENCE ---
  static const String createVisitAudioSegmentsTable = '''
    CREATE TABLE IF NOT EXISTS visit_audio_segments (
      id TEXT PRIMARY KEY,
      visit_id TEXT NOT NULL,
      file_path TEXT NOT NULL,
      start_ms INTEGER NOT NULL DEFAULT 0,
      end_ms INTEGER NOT NULL DEFAULT 0,
      lang TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (visit_id) REFERENCES visits(id)
    );
  ''';

  static const String createVisitTranscriptsTable = '''
    CREATE TABLE IF NOT EXISTS visit_transcripts (
      id TEXT PRIMARY KEY,
      visit_id TEXT NOT NULL,
      segment_id TEXT,
      speaker_label TEXT NOT NULL DEFAULT 'Speaker 1',
      start_ms INTEGER NOT NULL DEFAULT 0,
      end_ms INTEGER NOT NULL DEFAULT 0,
      text TEXT NOT NULL,
      lang TEXT,
      emotion TEXT,
      queue_status TEXT NOT NULL DEFAULT 'draft',
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (visit_id) REFERENCES visits(id)
    );
  ''';

  // --- FIELD SALES: GPS_LOGS (dens son konum + GpsService) ---
  static const String createGpsLogsTable = '''
    CREATE TABLE IF NOT EXISTS gps_logs (
      id TEXT PRIMARY KEY,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      timestamp TEXT NOT NULL,
      salesperson_code TEXT,
      label TEXT,
      accuracy REAL,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  /// Mevcut gps_logs şemasına dens kolonları (yoksa).
  static const String addGpsLogsSalespersonCodeColumn =
      'ALTER TABLE gps_logs ADD COLUMN salesperson_code TEXT;';
  static const String addGpsLogsLabelColumn =
      'ALTER TABLE gps_logs ADD COLUMN label TEXT;';
  static const String addGpsLogsAccuracyColumn =
      'ALTER TABLE gps_logs ADD COLUMN accuracy REAL;';
  static const String addGpsLogsIsDeletedColumn =
      'ALTER TABLE gps_logs ADD COLUMN is_deleted INTEGER DEFAULT 0;';
  static const String addGpsLogsCreatedAtColumn =
      'ALTER TABLE gps_logs ADD COLUMN created_at TEXT;';
  static const String addGpsLogsUpdatedAtColumn =
      'ALTER TABLE gps_logs ADD COLUMN updated_at TEXT;';

  // --- FIELD SALES: VEHICLE CAMERA FRAMES (snapshot polling) ---
  static const String createVehicleCameraFramesTable = '''
    CREATE TABLE IF NOT EXISTS vehicle_camera_frames (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      salesperson_code TEXT,
      lens TEXT NOT NULL,
      captured_at TEXT NOT NULL,
      image_base64 TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  // --- FIELD SALES: VEHICLE CAMERA SIGNALING (WebRTC SDP/ICE poll) ---
  // Remote PostgREST: CREATE TABLE vehicle_camera_signaling (
  //   id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
  //   from_peer_id TEXT, to_peer_id TEXT, kind TEXT, payload TEXT,
  //   created_at TIMESTAMPTZ DEFAULT now());
  static const String createVehicleCameraSignalingTable = '''
    CREATE TABLE IF NOT EXISTS vehicle_camera_signaling (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL,
      from_peer_id TEXT NOT NULL,
      to_peer_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      payload TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  // --- FIELD SALES: WAREHOUSES (OPS master — WHMS değil) ---
  static const String createWarehousesTable = '''
    CREATE TABLE IF NOT EXISTS warehouses (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  // --- WHMS Faz 1: WAREHOUSE_STOCKS (merkez ambar bakiyesi) ---
  static const String createWarehouseStocksTable = '''
    CREATE TABLE IF NOT EXISTS warehouse_stocks (
      warehouse_code TEXT NOT NULL,
      product_id TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      PRIMARY KEY (warehouse_code, product_id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

  // --- WHMS P0: whms_locations (kod + koridor / raf / göz) ---
  static const String createWhmsLocationsTable = '''
    CREATE TABLE IF NOT EXISTS whms_locations (
      id TEXT PRIMARY KEY,
      warehouse_code TEXT NOT NULL,
      code TEXT NOT NULL,
      aisle TEXT,
      rack TEXT,
      bin TEXT,
      barcode TEXT,
      route_seq INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      UNIQUE (warehouse_code, code)
    );
  ''';

  static const String dropWhmsLocationsTable =
      'DROP TABLE IF EXISTS whms_locations;';

  // --- FIELD SALES: BATCH_EXPIRY (Parti / SKT dens) ---
  static const String createBatchExpiryTable = '''
    CREATE TABLE IF NOT EXISTS batch_expiry (
      id TEXT PRIMARY KEY,
      product_id TEXT,
      product_code TEXT,
      product_name TEXT,
      lot_no TEXT NOT NULL,
      expiry_date TEXT NOT NULL,
      quantity REAL DEFAULT 0,
      unit TEXT,
      warehouse_code TEXT,
      warehouse_name TEXT,
      status TEXT NOT NULL DEFAULT 'OK',
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  static const String dropBatchExpiryTable =
      'DROP TABLE IF EXISTS batch_expiry;';

  // --- FIELD SALES: CASH_CARDS (Kasa Kart Listesi master) ---
  static const String createCashCardsTable = '''
    CREATE TABLE IF NOT EXISTS cash_cards (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      name_key TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  static const String dropCashCardsTable = 'DROP TABLE IF EXISTS cash_cards;';

  // --- FIELD SALES: BANK_CARDS (Banka Kart Listesi dens) ---
  static const String createBankCardsTable = '''
    CREATE TABLE IF NOT EXISTS bank_cards (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      name_key TEXT NOT NULL,
      balance_tl REAL NOT NULL DEFAULT 0,
      balance_usd REAL NOT NULL DEFAULT 0,
      balance_iqd REAL NOT NULL DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  static const String dropBankCardsTable = 'DROP TABLE IF EXISTS bank_cards;';

  // --- FIELD SALES: CHECK_PORTFOLIO (Çek Listesi dens CRUD) ---
  static const String createCheckPortfolioTable = '''
    CREATE TABLE IF NOT EXISTS check_portfolio (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      customer_name TEXT,
      amount REAL NOT NULL DEFAULT 0,
      check_number TEXT NOT NULL,
      bank_name TEXT,
      branch_name TEXT,
      due_date TEXT,
      document_no TEXT,
      check_status TEXT NOT NULL,
      collection_date TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- FIELD SALES: PROMISSORY_PORTFOLIO (Senet Listesi dens CRUD) ---
  static const String createPromissoryPortfolioTable = '''
    CREATE TABLE IF NOT EXISTS promissory_portfolio (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      customer_name TEXT,
      amount REAL NOT NULL DEFAULT 0,
      note_number TEXT NOT NULL,
      bank_name TEXT,
      due_date TEXT,
      document_no TEXT,
      note_status TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- FIELD SALES: WAREHOUSE_TRANSFERS ---
  static const String createWarehouseTransfersTable = '''
    CREATE TABLE IF NOT EXISTS warehouse_transfers (
      id TEXT PRIMARY KEY,
      from_warehouse TEXT,
      to_warehouse TEXT,
      product_id TEXT,
      quantity REAL,
      unit_name TEXT,
      transfer_date TEXT,
      status TEXT,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

  // --- FIELD SALES: STOCK_COUNTS (Sayım Fişi dens) ---
  static const String createStockCountsTable = '''
    CREATE TABLE IF NOT EXISTS stock_counts (
      id TEXT PRIMARY KEY,
      workplace TEXT,
      factory TEXT,
      warehouse TEXT,
      slip_date TEXT NOT NULL,
      lines_json TEXT,
      status TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- WHMS P0: ORDERS (emir omurgası + ONAY) ---
  static const String createWhmsOrdersTable = '''
    CREATE TABLE IF NOT EXISTS whms_orders (
      id TEXT PRIMARY KEY,
      order_type TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'draft',
      warehouse_code TEXT,
      from_warehouse_code TEXT,
      to_warehouse_code TEXT,
      to_vehicle_id TEXT,
      assigned_user_id TEXT,
      device_id TEXT,
      reference_no TEXT,
      notes TEXT,
      require_serial INTEGER NOT NULL DEFAULT 0,
      order_date TEXT NOT NULL,
      completed_at TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createWhmsOrderLinesTable = '''
    CREATE TABLE IF NOT EXISTS whms_order_lines (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL,
      line_no INTEGER NOT NULL DEFAULT 0,
      product_id TEXT NOT NULL,
      product_code TEXT,
      product_name TEXT,
      quantity REAL NOT NULL DEFAULT 0,
      quantity_done REAL NOT NULL DEFAULT 0,
      unit_name TEXT,
      location_code TEXT,
      lot_no TEXT,
      serial_no TEXT,
      expiry_date TEXT,
      route_seq INTEGER,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (order_id) REFERENCES whms_orders(id)
    );
  ''';

  // --- WHMS P0: LOCATIONS — createWhmsLocationsTable (UNIQUE warehouse+code)

  // --- WHMS P0: FIFO RULES (ürün bazlı fifo gün) ---
  static const String createWhmsFifoRulesTable = '''
    CREATE TABLE IF NOT EXISTS whms_fifo_rules (
      id TEXT PRIMARY KEY,
      product_code TEXT NOT NULL UNIQUE,
      fifo_days INTEGER NOT NULL DEFAULT 0,
      fefo_enforce INTEGER NOT NULL DEFAULT 1,
      warn_days INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  // --- WHMS P0: COUNT ORDERS (merkez sayım emri) ---
  static const String createWhmsCountOrdersTable = '''
    CREATE TABLE IF NOT EXISTS whms_count_orders (
      id TEXT PRIMARY KEY,
      warehouse_code TEXT NOT NULL,
      location_code TEXT,
      status TEXT NOT NULL DEFAULT 'draft',
      filter_json TEXT,
      order_date TEXT NOT NULL,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- WHMS P0: COUNT RESULTS (yerel fark kaydı) ---
  static const String createWhmsCountResultsTable = '''
    CREATE TABLE IF NOT EXISTS whms_count_results (
      id TEXT PRIMARY KEY,
      order_id TEXT,
      warehouse_code TEXT NOT NULL,
      location_code TEXT,
      count_date TEXT NOT NULL,
      lines_json TEXT NOT NULL DEFAULT '[]',
      variance_qty REAL NOT NULL DEFAULT 0,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- WHMS P1: DEVICES (terminal MAC + roller) ---
  static const String createWhmsDevicesTable = '''
    CREATE TABLE IF NOT EXISTS whms_devices (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      mac TEXT,
      model TEXT,
      os_name TEXT,
      roles TEXT,
      default_warehouse_code TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- WHMS P2: PACKAGE TYPES / TARES / LABEL TEMPLATES ---
  static const String createWhmsPackageTypesTable = '''
    CREATE TABLE IF NOT EXISTS whms_package_types (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      tare_ref TEXT,
      after_sales_flag INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createWhmsTaresTable = '''
    CREATE TABLE IF NOT EXISTS whms_tares (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      weight REAL NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createWhmsLabelTemplatesTable = '''
    CREATE TABLE IF NOT EXISTS whms_label_templates (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      label_type TEXT NOT NULL DEFAULT 'product_small',
      sample_product_name TEXT,
      sample_product_code TEXT,
      sample_price TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- WHMS: araç tipi / araç / lot / rezervasyon / iade (dens stub) ---
  static const String createWhmsVehicleTypesTable = '''
    CREATE TABLE IF NOT EXISTS whms_vehicle_types (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createWhmsVehiclesTable = '''
    CREATE TABLE IF NOT EXISTS whms_vehicles (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createWhmsLotsTable = '''
    CREATE TABLE IF NOT EXISTS whms_lots (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createWhmsReservationsTable = '''
    CREATE TABLE IF NOT EXISTS whms_reservations (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createWhmsReturnsTable = '''
    CREATE TABLE IF NOT EXISTS whms_returns (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- FIELD SALES: CASH_COUNTS (Kasa Sayımı dens) ---
  static const String createCashCountsTable = '''
    CREATE TABLE IF NOT EXISTS cash_counts (
      id TEXT PRIMARY KEY,
      cash_code TEXT NOT NULL,
      count_date TEXT NOT NULL,
      expected_amount REAL NOT NULL DEFAULT 0,
      counted_amount REAL NOT NULL DEFAULT 0,
      difference REAL NOT NULL DEFAULT 0,
      notes TEXT,
      lines_json TEXT,
      status TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- FIELD SALES: BANK_DEPOSITS (Banka Yatırma dens) ---
  static const String createBankDepositsTable = '''
    CREATE TABLE IF NOT EXISTS bank_deposits (
      id TEXT PRIMARY KEY,
      cash_code TEXT NOT NULL,
      bank_code TEXT NOT NULL,
      amount REAL NOT NULL,
      document_no TEXT,
      deposit_date TEXT NOT NULL,
      notes TEXT,
      status TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  // --- FIELD SALES: ROUTES ---
  static const String createRoutesTable = '''
    CREATE TABLE IF NOT EXISTS routes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      salesperson_id TEXT,
      day_of_week INTEGER, -- 1-7
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT
    );
  ''';

  static const String createRouteCustomersTable = '''
    CREATE TABLE IF NOT EXISTS route_customers (
      id TEXT PRIMARY KEY,
      route_id TEXT,
      customer_id TEXT,
      visit_order INTEGER,
      is_mandatory INTEGER DEFAULT 1,
      FOREIGN KEY (route_id) REFERENCES routes(id),
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  // --- FIELD SALES: AUDITS (MERCHANDISING) ---
  static const String createAuditFormsTable = '''
    CREATE TABLE IF NOT EXISTS audit_forms (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  static const String createAuditFormFieldsTable = '''
    CREATE TABLE IF NOT EXISTS audit_form_fields (
      id TEXT PRIMARY KEY,
      form_id TEXT,
      field_name TEXT,
      field_type TEXT, -- 'text', 'number', 'photo', 'select', 'shelf_share', etc.
      options TEXT, -- JSON string for select options
      is_required INTEGER DEFAULT 0,
      sort_order INTEGER,
      conditional_field_id TEXT, -- ID of field that controls visibility
      conditional_value TEXT, -- Value that triggers visibility
      metadata TEXT, -- JSON config (e.g. SOS targets)
      FOREIGN KEY (form_id) REFERENCES audit_forms(id)
    );
  ''';

  static const String createVisitAuditsTable = '''
    CREATE TABLE IF NOT EXISTS visit_audits (
      id TEXT PRIMARY KEY,
      visit_id TEXT,
      form_id TEXT,
      completed_at TEXT,
      is_synced INTEGER DEFAULT 0,
      FOREIGN KEY (visit_id) REFERENCES visits(id),
      FOREIGN KEY (form_id) REFERENCES audit_forms(id)
    );
  ''';

  static const String createAuditAnswersTable = '''
    CREATE TABLE IF NOT EXISTS audit_answers (
      id TEXT PRIMARY KEY,
      audit_id TEXT,
      field_id TEXT,
      answer_value TEXT,
      photo_url TEXT,
      verification_data TEXT, -- JSON: lat, long, timestamp, accuracy
      FOREIGN KEY (audit_id) REFERENCES visit_audits(id),
      FOREIGN KEY (field_id) REFERENCES audit_form_fields(id)
    );
  ''';

  // --- FIELD SALES: UNIT SETS ---
  static const String createUnitSetsTable = '''
    CREATE TABLE IF NOT EXISTS unit_sets (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT
    );
  ''';

  static const String createUnitSetLinesTable = '''
    CREATE TABLE IF NOT EXISTS unit_set_lines (
      id TEXT PRIMARY KEY,
      unit_set_id TEXT,
      unit_name TEXT NOT NULL,
      conversion_factor REAL NOT NULL,
      is_main_unit INTEGER DEFAULT 0,
      FOREIGN KEY (unit_set_id) REFERENCES unit_sets(id)
    );
  ''';

  // --- FIELD SALES: PRICES & CAMPAIGNS ---
  static const String createPriceListsTable = '''
    CREATE TABLE IF NOT EXISTS price_lists (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      currency TEXT DEFAULT 'TRY',
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  static const String createPriceListItemsTable = '''
    CREATE TABLE IF NOT EXISTS price_list_items (
      id TEXT PRIMARY KEY,
      price_list_id TEXT,
      product_id TEXT,
      unit_name TEXT,
      price REAL,
      min_quantity REAL DEFAULT 0,
      FOREIGN KEY (price_list_id) REFERENCES price_lists(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

  static const String createCustomerPriceMapsTable = '''
    CREATE TABLE IF NOT EXISTS customer_price_maps (
      id TEXT PRIMARY KEY,
      customer_id TEXT,
      price_list_id TEXT,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id),
      FOREIGN KEY (price_list_id) REFERENCES price_lists(id)
    );
  ''';

  static const String createCampaignsTable = '''
    CREATE TABLE IF NOT EXISTS campaigns (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      campaign_type TEXT, -- 'Discount', 'FreeProduct'
      start_date TEXT,
      end_date TEXT,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  static const String createCampaignRulesTable = '''
    CREATE TABLE IF NOT EXISTS campaign_rules (
      id TEXT PRIMARY KEY,
      campaign_id TEXT,
      product_id TEXT,
      min_quantity REAL,
      discount_rate REAL,
      free_product_id TEXT,
      free_quantity REAL,
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id)
    );
  ''';

  // --- FIELD SALES: VEHICLES ---
  static const String createVehiclesTable = '''
    CREATE TABLE IF NOT EXISTS vehicles (
      id TEXT PRIMARY KEY,
      plate TEXT NOT NULL,
      name TEXT,
      salesperson_id TEXT,
      is_active INTEGER DEFAULT 1,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  static const String createVehicleStocksTable = '''
    CREATE TABLE IF NOT EXISTS vehicle_stocks (
      vehicle_id TEXT,
      product_id TEXT,
      quantity REAL DEFAULT 0.0,
      approval_status INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      PRIMARY KEY (vehicle_id, product_id),
      FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

  static const String createVehicleLoadingsTable = '''
    CREATE TABLE IF NOT EXISTS vehicle_loadings (
      id TEXT PRIMARY KEY,
      vehicle_id TEXT,
      salesperson_id TEXT,
      loading_date TEXT,
      status TEXT, -- 'Pending', 'Approved', 'Completed'
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
    );
  ''';

  static const String createVehicleLoadingItemsTable = '''
    CREATE TABLE IF NOT EXISTS vehicle_loading_items (
      id TEXT PRIMARY KEY,
      loading_id TEXT,
      product_id TEXT,
      quantity REAL,
      unit TEXT,
      FOREIGN KEY (loading_id) REFERENCES vehicle_loadings(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

  static const String createLocationHistoryTable = '''
    CREATE TABLE IF NOT EXISTS location_history (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      latitude REAL,
      longitude REAL,
      accuracy REAL,
      speed REAL,
      recorded_at TEXT,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  // --- PHASE 7: JOB QUEUE (RABBITMQ PATTERN) ---
  static const String createSyncQueueTable = '''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL, -- 'invoice', 'collection', 'audit'
      entity_id TEXT NOT NULL,
      payload TEXT, -- JSON data
      priority INTEGER DEFAULT 0,
      retry_count INTEGER DEFAULT 0,
      last_error TEXT,
      scheduled_at TEXT,
      sync_phase TEXT, -- pg_pending | logo | postgrest
      created_at TEXT
    );
  ''';

  // --- PHASE 9: KILLER FEATURES ---
  /// Gamification / ziyaret puanı — check-in öncesi IF NOT EXISTS.
  static const String createPlasiyerProfileTable = '''
    CREATE TABLE IF NOT EXISTS plasiyer_profile (
      id TEXT PRIMARY KEY,
      name TEXT,
      total_points INTEGER DEFAULT 0,
      level INTEGER DEFAULT 1,
      last_achievement TEXT,
      created_at TEXT
    );
  ''';

  /// Eski cihazlarda eksik gamification kolonları (no-op if exists).
  static const String addPlasiyerProfileTotalPointsColumn = '''
    ALTER TABLE plasiyer_profile ADD COLUMN total_points INTEGER DEFAULT 0;
  ''';

  static const String addPlasiyerProfileLevelColumn = '''
    ALTER TABLE plasiyer_profile ADD COLUMN level INTEGER DEFAULT 1;
  ''';

  static const String addPlasiyerProfileLastAchievementColumn = '''
    ALTER TABLE plasiyer_profile ADD COLUMN last_achievement TEXT;
  ''';

  static const String addPlasiyerProfileCreatedAtColumn = '''
    ALTER TABLE plasiyer_profile ADD COLUMN created_at TEXT;
  ''';

  /// OPS sipariş soft-delete (aktarılmamış yerel silme).
  static const String addOrdersIsDeletedColumn = '''
    ALTER TABLE orders ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;
  ''';

  /// OPS ambar master soft-delete + l10n ad anahtarı.
  static const String addWarehousesIsDeletedColumn = '''
    ALTER TABLE warehouses ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;
  ''';

  static const String addWarehousesNameKeyColumn = '''
    ALTER TABLE warehouses ADD COLUMN name_key TEXT;
  ''';

  /// P0: Diğer / GPS / kamera menü satırlarını l10n key'e zorla (uuid).
  /// [uuid] → [title] çiftleri `DatabaseService.ensureFieldSalesMenuL10nTitles`.
  static const Map<String, String> fieldSalesMenuL10nByUuid = {
    'fs_other': 'dashboard.diger',
    'sub_rep_diger': 'submodules.diger',
    'sub_rep_yonetici': 'submodules.yonetici_raporlari',
    'sub_rep_finans': 'submodules.finans',
    'sub_rep_ops': 'submodules.ops_raporlari',
    'sub_oth_live_loc': 'submodules.canli_konum',
    'sub_oth_cam_monitor': 'submodules.arac_kamera_izleme',
    'sub_oth_cam_settings': 'field_sales.stubs.vehicle_camera_settings',
    'sub_oth_offline_map': 'field_sales.stubs.offline_map_download',
    'sub_oth_in_app_route': 'field_sales.stubs.in_app_route_map',
    'sub_oth_weekly_route': 'field_sales.stubs.weekly_route_plan',
    'sub_oth_ai_insights': 'field_sales.stubs.ai_insights',
    'sub_stk_supply_req': 'field_sales.stubs.supply_request',
    'sub_rep_ai_dynamic': 'field_sales.stubs.ai_dynamic_report',
    'sub_oth_shelf_vision': 'field_sales.stubs.competitor_shelf_vision',
    'sub_oth_invoice_scan': 'field_sales.stubs.invoice_scan',
    'sub_oth_vehicle_vision': 'field_sales.stubs.vehicle_vision',
    'sub_visit_weekly_plan': 'field_sales.stubs.weekly_route_plan',
    'sub_visit_in_app_route': 'field_sales.stubs.in_app_route_map',
  };

  static const String createAiSuggestionsTable = '''
    CREATE TABLE IF NOT EXISTS ai_suggestions (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      suggested_qty DOUBLE,
      reason TEXT, -- e.g., 'Aylık ortalama tüketim'
      confidence DOUBLE,
      updated_at TEXT
    );
  ''';

  /// Depocu → tedarikçi ürün talep kuyruğu (Logo sync sonra).
  static const String createSupplierPurchaseRequestsTable = '''
    CREATE TABLE IF NOT EXISTS supplier_purchase_requests (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      product_code TEXT,
      product_name TEXT,
      quantity REAL NOT NULL DEFAULT 0,
      supplier_id TEXT,
      supplier_code TEXT,
      supplier_name TEXT,
      warehouse_code TEXT,
      status TEXT NOT NULL DEFAULT 'draft',
      notes TEXT,
      ONAY INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_by TEXT,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  static const String createPodTable = '''
    CREATE TABLE IF NOT EXISTS proof_of_deliveries (
      id TEXT PRIMARY KEY,
      invoice_id TEXT NOT NULL,
      signature_data TEXT,
      latitude DOUBLE,
      longitude DOUBLE,
      signed_at TEXT
    );
  ''';

  static const String createAssetTrackingTable = '''
    CREATE TABLE IF NOT EXISTS asset_tracking_logs (
      id TEXT PRIMARY KEY,
      asset_id TEXT NOT NULL,
      customer_id TEXT NOT NULL,
      status TEXT,
      note TEXT,
      checked_at TEXT
    );
  ''';

  /// Plasiyer günlük masraf (ExpenseService / expense dens Kaydet).
  static const String createExpensesTable = '''
    CREATE TABLE IF NOT EXISTS expenses (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      amount REAL NOT NULL,
      photo_path TEXT,
      note TEXT,
      created_at TEXT,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  static const String createCompetitorProductsTable = '''
    CREATE TABLE IF NOT EXISTS competitor_products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      brand TEXT,
      category TEXT,
      price_reference REAL
    );
  ''';

  static const String createCompetitorObservationsTable = '''
    CREATE TABLE IF NOT EXISTS competitor_observations (
      id TEXT PRIMARY KEY,
      visit_id TEXT NOT NULL,
      competitor_product_id TEXT NOT NULL,
      observed_price REAL,
      has_stock INTEGER DEFAULT 1,
      on_promotion INTEGER DEFAULT 0,
      notes TEXT,
      photo_url TEXT,
      created_at TEXT,
      FOREIGN KEY (competitor_product_id) REFERENCES competitor_products(id)
    );
  ''';

  static const String createVisitTasksTable = '''
    CREATE TABLE IF NOT EXISTS visit_tasks (
      id TEXT PRIMARY KEY,
      visit_id TEXT,
      customer_id TEXT,
      title TEXT NOT NULL,
      description TEXT,
      is_completed INTEGER DEFAULT 0,
      due_date TEXT
    );
  ''';

  static const String createWastageLogsTable = '''
    CREATE TABLE IF NOT EXISTS wastage_logs (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      quantity REAL NOT NULL,
      type TEXT NOT NULL, -- 'Wastage' or 'Sample'
      reason TEXT,
      created_at TEXT,
      is_synced INTEGER DEFAULT 0
    );
  ''';

  // --- FIELD SALES: CARİ EKSTRE HAREKETLERİ ---
  static const String createCustomerMovementsTable = '''
    CREATE TABLE IF NOT EXISTS customer_movements (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      movement_date TEXT NOT NULL,
      document_no TEXT,
      description TEXT,
      debit REAL DEFAULT 0,
      credit REAL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0
    );
  ''';

  /// Fatura listesi dens: tüm `invoices` + cari kod/ad (tarih DESC)
  static const String invoiceListDensRowsSql = '''
    SELECT
      i.id AS id,
      i.customer_id AS customer_id,
      i.invoice_date AS invoice_date,
      i.total_amount AS total_amount,
      i.status AS status,
      i.notes AS notes,
      i.invoice_type AS invoice_type,
      i.is_e_invoice AS is_e_invoice,
      i.ettn AS ettn,
      i.gib_status AS gib_status,
      COALESCE(i.is_synced, 0) AS is_synced,
      COALESCE(i.approval_status, 0) AS approval_status,
      COALESCE(c.code, '') AS customer_code,
      COALESCE(c.name, '') AS customer_name
    FROM invoices i
    LEFT JOIN customers c ON c.id = i.customer_id
    ORDER BY i.invoice_date DESC
  ''';

  /// Transfer edilmeyen fatura dens: `is_synced = 0` + cari
  static const String invoiceUntransferredDensRowsSql = '''
    SELECT
      i.id AS id,
      i.id AS document_no,
      i.customer_id AS customer_id,
      i.invoice_date AS invoice_date,
      i.total_amount AS total_amount,
      i.status AS status,
      i.invoice_type AS invoice_type,
      COALESCE(i.is_synced, 0) AS is_synced,
      COALESCE(i.approval_status, 0) AS approval_status,
      COALESCE(i.approval_status, 0) AS ONAY,
      COALESCE(c.code, '') AS customer_code,
      COALESCE(c.name, '') AS customer_name,
      i.created_at AS created_at,
      i.updated_at AS updated_at
    FROM invoices i
    LEFT JOIN customers c ON c.id = i.customer_id
    WHERE COALESCE(i.is_synced, 0) = 0
    ORDER BY i.invoice_date DESC
  ''';

  /// Satış rapor dens: tarih aralığındaki faturalar + cari adı
  static const String reportDensSalesRowsSql = '''
    SELECT
      i.id AS id,
      i.invoice_date AS event_date,
      i.total_amount AS amount,
      i.status AS status,
      i.invoice_type AS detail,
      COALESCE(c.name, i.customer_id, '') AS customer_name
    FROM invoices i
    LEFT JOIN customers c ON c.id = i.customer_id
    WHERE date(i.invoice_date) >= date(?)
      AND date(i.invoice_date) <= date(?)
    ORDER BY i.invoice_date DESC
  ''';

  /// Tahsilat rapor dens: tarih aralığındaki tahsilatlar + cari adı
  static const String reportDensCollectionRowsSql = '''
    SELECT
      col.id AS id,
      col.collection_date AS event_date,
      col.amount AS amount,
      col.status AS status,
      col.payment_type AS detail,
      COALESCE(c.name, col.customer_id, '') AS customer_name
    FROM collections col
    LEFT JOIN customers c ON c.id = col.customer_id
    WHERE date(col.collection_date) >= date(?)
      AND date(col.collection_date) <= date(?)
    ORDER BY col.collection_date DESC
  ''';

  /// Transfer edilen tahsilat dens: is_synced=1 + cari adı
  static const String collectionsTransferredDensSql = '''
    SELECT
      col.id AS id,
      col.customer_id AS customer_id,
      col.amount AS amount,
      col.payment_type AS payment_type,
      col.collection_date AS collection_date,
      col.document_no AS document_no,
      col.cash_code AS cash_code,
      col.currency_code AS currency_code,
      col.is_synced AS is_synced,
      COALESCE(c.name, col.customer_id, '') AS customer_name
    FROM collections col
    LEFT JOIN customers c ON c.id = col.customer_id
    WHERE col.is_synced = 1
    ORDER BY col.collection_date DESC
  ''';

  /// Ziyaret rapor dens: tarih aralığındaki ziyaretler + cari adı
  static const String reportDensVisitRowsSql = '''
    SELECT
      v.id AS id,
      v.check_in_at AS event_date,
      v.duration_minutes AS amount,
      v.status AS status,
      v.status AS detail,
      COALESCE(c.name, v.customer_id, '') AS customer_name
    FROM visits v
    LEFT JOIN customers c ON c.id = v.customer_id
    WHERE date(v.check_in_at) >= date(?)
      AND date(v.check_in_at) <= date(?)
    ORDER BY v.check_in_at DESC
  ''';

  /// Geçmiş ziyaret dens: tüm visits + cari adı (yeniden eskiye)
  static const String visitHistoryRowsSql = '''
    SELECT
      v.id AS id,
      v.customer_id AS customer_id,
      v.check_in_at AS check_in_at,
      v.duration_minutes AS duration_minutes,
      v.status AS status,
      v.is_synced AS is_synced,
      COALESCE(c.name, v.customer_id, '') AS customer_name
    FROM visits v
    LEFT JOIN customers c ON c.id = v.customer_id
    ORDER BY v.check_in_at DESC, v.id ASC
  ''';

  /// Geçmiş ziyaret dens SELECT (WHERE store’da eklenir)
  static const String visitHistorySelectSql = '''
    SELECT
      v.id AS id,
      v.customer_id AS customer_id,
      v.check_in_at AS check_in_at,
      v.duration_minutes AS duration_minutes,
      v.status AS status,
      v.is_synced AS is_synced,
      COALESCE(c.name, v.customer_id, '') AS customer_name
    FROM visits v
    LEFT JOIN customers c ON c.id = v.customer_id
  ''';

  /// Ziyaret detay dens: tek satır + cari adı
  /// Parametreler: [visitId]
  static const String visitDetailByIdSql = '''
    SELECT
      v.id AS id,
      v.customer_id AS customer_id,
      v.check_in_at AS check_in_at,
      v.check_out_at AS check_out_at,
      v.check_in_lat AS check_in_lat,
      v.check_in_long AS check_in_long,
      v.check_out_lat AS check_out_lat,
      v.check_out_long AS check_out_long,
      v.notes AS notes,
      v.reason_code AS reason_code,
      v.audio_recording_path AS audio_recording_path,
      v.status AS status,
      v.duration_minutes AS duration_minutes,
      v.is_synced AS is_synced,
      COALESCE(c.name, v.customer_id, '') AS customer_name
    FROM visits v
    LEFT JOIN customers c ON c.id = v.customer_id
    WHERE v.id = ?
    LIMIT 1
  ''';

  /// Ziyaretle ilişkili siparişler (cari + gün aralığı)
  /// Parametreler: [customerId, startYmd, endYmd]
  static const String visitRelatedOrdersSql = '''
    SELECT
      o.id AS id,
      o.order_date AS order_date,
      o.total_amount AS total_amount,
      o.status AS status,
      o.notes AS notes
    FROM orders o
    WHERE o.customer_id = ?
      AND COALESCE(o.is_deleted, 0) = 0
      AND date(COALESCE(o.order_date, o.created_at)) >= date(?)
      AND date(COALESCE(o.order_date, o.created_at)) <= date(?)
    ORDER BY o.order_date DESC, o.id ASC
  ''';

  /// Yönetici KPI: tek güne sipariş/fatura/tahsilat/ziyaret COUNT aggregate
  /// Parametreler: [day, day, day, day] (`yyyy-MM-dd`)
  static const String adminKpiTodayCountsSql = '''
    SELECT
      (SELECT COUNT(*) FROM orders
        WHERE date(COALESCE(order_date, created_at)) = date(?)
          AND COALESCE(status, '') != 'Cancelled') AS order_count,
      (SELECT COUNT(*) FROM invoices
        WHERE date(COALESCE(invoice_date, created_at)) = date(?)
          AND COALESCE(status, '') != 'Cancelled') AS invoice_count,
      (SELECT COUNT(*) FROM collections
        WHERE date(COALESCE(collection_date, created_at)) = date(?)
          AND COALESCE(status, '') != 'Cancelled') AS collection_count,
      (SELECT COUNT(*) FROM visits
        WHERE date(COALESCE(check_in_at, created_at)) = date(?)) AS visit_count
  ''';

  /// Yönetici KPI: dönem aralığı COUNT + satış/sipariş/tahsilat SUM
  /// Parametreler: 16× `yyyy-MM-dd` (her alt sorgu start,end)
  static const String adminKpiPeriodActivitySql = '''
    SELECT
      (SELECT COUNT(*) FROM orders
        WHERE date(COALESCE(order_date, created_at)) >= date(?)
          AND date(COALESCE(order_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled') AS order_count,
      (SELECT COUNT(*) FROM invoices
        WHERE date(COALESCE(invoice_date, created_at)) >= date(?)
          AND date(COALESCE(invoice_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled') AS invoice_count,
      (SELECT COUNT(*) FROM collections
        WHERE date(COALESCE(collection_date, created_at)) >= date(?)
          AND date(COALESCE(collection_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled') AS collection_count,
      (SELECT COUNT(*) FROM visits
        WHERE date(COALESCE(check_in_at, created_at)) >= date(?)
          AND date(COALESCE(check_in_at, created_at)) <= date(?)) AS visit_count,
      (SELECT COUNT(*) FROM waybills
        WHERE date(COALESCE(waybill_date, created_at)) >= date(?)
          AND date(COALESCE(waybill_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled') AS waybill_count,
      (SELECT COALESCE(SUM(total_amount), 0) FROM invoices
        WHERE date(COALESCE(invoice_date, created_at)) >= date(?)
          AND date(COALESCE(invoice_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled') AS sales_amount,
      (SELECT COALESCE(SUM(total_amount), 0) FROM orders
        WHERE date(COALESCE(order_date, created_at)) >= date(?)
          AND date(COALESCE(order_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled') AS order_amount,
      (SELECT COALESCE(SUM(amount), 0) FROM collections
        WHERE date(COALESCE(collection_date, created_at)) >= date(?)
          AND date(COALESCE(collection_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled') AS collection_amount
  ''';

  /// Yönetici KPI: dönem nakit / çek / kart+banka snapshot SUM
  /// Parametreler: cash, check, card, deposit — her biri start/end
  static const String adminKpiPeriodFinanceSql = '''
    SELECT
      (SELECT COALESCE(SUM(amount), 0) FROM collections
        WHERE date(COALESCE(collection_date, created_at)) >= date(?)
          AND date(COALESCE(collection_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled'
          AND COALESCE(payment_type, '') = 'Cash') AS cash_collected,
      (SELECT COALESCE(SUM(amount), 0) FROM collections
        WHERE date(COALESCE(collection_date, created_at)) >= date(?)
          AND date(COALESCE(collection_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled'
          AND LOWER(COALESCE(payment_type, '')) IN ('check', 'note'))
        AS check_collected,
      (SELECT COALESCE(SUM(amount), 0) FROM collections
        WHERE date(COALESCE(collection_date, created_at)) >= date(?)
          AND date(COALESCE(collection_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled'
          AND COALESCE(payment_type, '') = 'CreditCard') AS card_collected,
      (SELECT COALESCE(SUM(amount), 0) FROM bank_deposits
        WHERE date(COALESCE(deposit_date, created_at)) >= date(?)
          AND date(COALESCE(deposit_date, created_at)) <= date(?)
          AND COALESCE(is_deleted, 0) = 0) AS bank_deposits
  ''';

  /// Yönetici KPI: açık alacak (pozitif cari bakiye) + borçlu adedi
  static const String adminKpiReceivablesSql = '''
    SELECT
      COALESCE(SUM(CASE WHEN COALESCE(balance, 0) > 0
        THEN balance ELSE 0 END), 0) AS open_receivables,
      COALESCE(SUM(CASE WHEN COALESCE(balance, 0) > 0
        THEN 1 ELSE 0 END), 0) AS debtor_count
    FROM customers
  ''';

  /// Yönetici KPI: sync bekleyen belge sayıları
  static const String adminKpiPendingTransfersSql = '''
    SELECT
      (SELECT COUNT(*) FROM orders
        WHERE COALESCE(is_synced, 0) = 0) AS pending_orders,
      (SELECT COUNT(*) FROM invoices
        WHERE COALESCE(is_synced, 0) = 0) AS pending_invoices,
      (SELECT COUNT(*) FROM waybills
        WHERE COALESCE(is_synced, 0) = 0) AS pending_waybills
  ''';

  /// Yönetici KPI: son 7 gün günlük fatura tutarı (sparkline)
  /// Parametreler: [start, end]
  static const String adminKpiSparklineSalesSql = '''
    SELECT
      date(COALESCE(invoice_date, created_at)) AS day_key,
      COALESCE(SUM(total_amount), 0) AS amount
    FROM invoices
    WHERE date(COALESCE(invoice_date, created_at)) >= date(?)
      AND date(COALESCE(invoice_date, created_at)) <= date(?)
      AND COALESCE(status, '') != 'Cancelled'
    GROUP BY day_key
    ORDER BY day_key ASC
  ''';

  /// Yönetici KPI: son 7 gün günlük tahsilat tutarı (sparkline)
  /// Parametreler: [start, end]
  static const String adminKpiSparklineCollectionsSql = '''
    SELECT
      date(COALESCE(collection_date, created_at)) AS day_key,
      COALESCE(SUM(amount), 0) AS amount
    FROM collections
    WHERE date(COALESCE(collection_date, created_at)) >= date(?)
      AND date(COALESCE(collection_date, created_at)) <= date(?)
      AND COALESCE(status, '') != 'Cancelled'
    GROUP BY day_key
    ORDER BY day_key ASC
  ''';

  /// Yönetici KPI: dönem hedef / gerçekleşen (period LIKE yyyy-MM%)
  /// Parametreler: [periodPrefix]
  static const String adminKpiTargetsSql = '''
    SELECT
      COALESCE(SUM(target_amount), 0) AS target_amount,
      COALESCE(SUM(achieved_amount), 0) AS target_achieved
    FROM targets
    WHERE COALESCE(period, '') LIKE (? || '%')
  ''';

  /// Yönetici KPI: dönem ziyaret plasiyer kırılımı
  /// Parametreler: [start, end]
  static const String adminKpiPivotVisitsSql = '''
    SELECT
      COALESCE(NULLIF(TRIM(user_id), ''), '_') AS sp_key,
      COUNT(*) AS visit_count
    FROM visits
    WHERE date(COALESCE(check_in_at, created_at)) >= date(?)
      AND date(COALESCE(check_in_at, created_at)) <= date(?)
    GROUP BY sp_key
  ''';

  /// Yönetici KPI: dönem tahsilat plasiyer kırılımı
  /// Parametreler: [start, end]
  static const String adminKpiPivotCollectionsSql = '''
    SELECT
      COALESCE(NULLIF(TRIM(salesperson_code), ''), '_') AS sp_key,
      COUNT(*) AS collection_count,
      COALESCE(SUM(amount), 0) AS collection_amount
    FROM collections
    WHERE date(COALESCE(collection_date, created_at)) >= date(?)
      AND date(COALESCE(collection_date, created_at)) <= date(?)
      AND COALESCE(status, '') != 'Cancelled'
    GROUP BY sp_key
  ''';

  /// Yönetici KPI: dönem hedef plasiyer kırılımı
  /// Parametreler: [periodPrefix]
  static const String adminKpiPivotTargetsSql = '''
    SELECT
      COALESCE(NULLIF(TRIM(user_id), ''), '_') AS sp_key,
      COALESCE(SUM(target_amount), 0) AS target_amount,
      COALESCE(SUM(achieved_amount), 0) AS target_achieved
    FROM targets
    WHERE COALESCE(period, '') LIKE (? || '%')
    GROUP BY sp_key
  ''';

  /// Yönetici KPI: kullanıcı adları (pivot etiket)
  static const String adminKpiUserNamesSql = '''
    SELECT id, COALESCE(NULLIF(TRIM(full_name), ''), username) AS display_name
    FROM users
    WHERE COALESCE(is_deleted, 0) = 0
  ''';

  // --- FIELD SALES: PARTIAL DELIVERIES (kısmi teslimat iskelet) ---
  static const String createPartialDeliveriesTable = '''
    CREATE TABLE IF NOT EXISTS partial_deliveries (
      id TEXT PRIMARY KEY,
      workplace TEXT,
      factory TEXT,
      warehouse TEXT,
      delivery_date TEXT NOT NULL,
      status TEXT DEFAULT 'Pending',
      lines_json TEXT,
      is_synced INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  /// Rota haritası dens: aktif rota ziyaret noktaları + cari konum
  static const String routeMapVisitPointsSql = '''
    SELECT
      rc.id AS id,
      rc.route_id AS route_id,
      rc.customer_id AS customer_id,
      rc.visit_order AS visit_order,
      COALESCE(rc.is_mandatory, 1) AS is_mandatory,
      COALESCE(r.name, '') AS route_name,
      COALESCE(c.code, '') AS customer_code,
      COALESCE(c.name, '') AS customer_name,
      COALESCE(c.address, '') AS customer_address,
      c.latitude AS latitude,
      c.longitude AS longitude
    FROM route_customers rc
    INNER JOIN routes r ON r.id = rc.route_id
    LEFT JOIN customers c ON c.id = rc.customer_id
    WHERE COALESCE(r.is_active, 1) = 1
    ORDER BY rc.visit_order ASC, rc.id ASC
  ''';

  /// Haftalık rota planı dens: gün + sıra + cari + konum
  static const String weeklyRouteStopsSql = '''
    SELECT
      rc.id AS id,
      rc.route_id AS route_id,
      rc.customer_id AS customer_id,
      rc.visit_order AS visit_order,
      COALESCE(rc.is_mandatory, 1) AS is_mandatory,
      COALESCE(r.day_of_week, 0) AS day_of_week,
      COALESCE(c.code, '') AS customer_code,
      COALESCE(c.name, '') AS customer_name,
      COALESCE(c.address, '') AS customer_address,
      c.latitude AS latitude,
      c.longitude AS longitude
    FROM route_customers rc
    INNER JOIN routes r ON r.id = rc.route_id
    LEFT JOIN customers c ON c.id = rc.customer_id
    WHERE COALESCE(r.is_active, 1) = 1
      AND r.day_of_week = ?
    ORDER BY rc.visit_order ASC, rc.id ASC
  ''';

  /// Haftalık rota: tek route_id (personel kapsamı)
  static const String weeklyRouteStopsByRouteIdSql = '''
    SELECT
      rc.id AS id,
      rc.route_id AS route_id,
      rc.customer_id AS customer_id,
      rc.visit_order AS visit_order,
      COALESCE(rc.is_mandatory, 1) AS is_mandatory,
      COALESCE(r.day_of_week, 0) AS day_of_week,
      COALESCE(c.code, '') AS customer_code,
      COALESCE(c.name, '') AS customer_name,
      COALESCE(c.address, '') AS customer_address,
      c.latitude AS latitude,
      c.longitude AS longitude
    FROM route_customers rc
    INNER JOIN routes r ON r.id = rc.route_id
    LEFT JOIN customers c ON c.id = rc.customer_id
    WHERE rc.route_id = ?
    ORDER BY rc.visit_order ASC, rc.id ASC
  ''';

  /// Aktif kullanıcılar (rota personel seçici)
  static const String weeklyRouteSalespersonsSql = '''
    SELECT id, username, full_name
    FROM users
    WHERE COALESCE(is_active, 1) = 1
      AND COALESCE(is_deleted, 0) = 0
    ORDER BY full_name COLLATE NOCASE ASC, username COLLATE NOCASE ASC
  ''';

  /// Cariye atanmış ziyaret günleri (1–7) — paylaşılan plan (salesperson boş)
  static const String weeklyRouteCustomerWeekdaysSql = '''
    SELECT DISTINCT r.day_of_week AS day_of_week
    FROM route_customers rc
    INNER JOIN routes r ON r.id = rc.route_id
    WHERE rc.customer_id = ?
      AND COALESCE(r.is_active, 1) = 1
      AND r.day_of_week IS NOT NULL
      AND r.day_of_week BETWEEN 1 AND 7
      AND (r.salesperson_id IS NULL OR TRIM(r.salesperson_id) = '')
    ORDER BY r.day_of_week ASC
  ''';

  /// Günün planındaki cari id'leri (liste filtresi)
  static const String weeklyRouteCustomerIdsForDaySql = '''
    SELECT DISTINCT rc.customer_id AS customer_id
    FROM route_customers rc
    INNER JOIN routes r ON r.id = rc.route_id
    WHERE COALESCE(r.is_active, 1) = 1
      AND r.day_of_week = ?
      AND rc.customer_id IS NOT NULL
      AND TRIM(rc.customer_id) != ''
  ''';

  // --- FIELD SALES: REPORT_LAYOUTS (in-app dizayn, .repx yok) ---
  /// Rapor dizayn JSON — sync için hazır; uygulama SharedPreferences kullanır.
  static const String createReportLayoutsTable = '''
    CREATE TABLE IF NOT EXISTS report_layouts (
      report_id TEXT PRIMARY KEY,
      layout_json TEXT NOT NULL,
      schema_version INTEGER NOT NULL DEFAULT 1,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
  ''';

  static const String dropReportLayoutsTable =
      'DROP TABLE IF EXISTS report_layouts;';

  /// AI dinamik rapor tanımları — PostgREST query_json (ham SQL değil).
  static const String createAiDynamicReportsTable = '''
    CREATE TABLE IF NOT EXISTS ai_dynamic_reports (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      title_key TEXT,
      query_json TEXT NOT NULL,
      layout_json TEXT NOT NULL,
      created_at TEXT,
      updated_at TEXT,
      created_by TEXT,
      is_favorite_shortcut INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0
    );
  ''';

  /// MBT cari extre: fatura satırları (borç) — ? from, to
  static const String mbtReportCariInvoiceLinesSql = '''
    SELECT
      i.id AS row_id,
      COALESCE(i.invoice_date, i.created_at) AS event_date,
      i.total_amount AS amount,
      COALESCE(i.invoice_type, 'Sales') AS voucher_type,
      COALESCE(i.notes, '') AS description,
      COALESCE(c.code, '') AS customer_code,
      COALESCE(c.name, '') AS customer_name,
      'TRY' AS currency_code
    FROM invoices i
    LEFT JOIN customers c ON c.id = i.customer_id
    WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
      AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
      AND COALESCE(i.status, '') != 'Cancelled'
  ''';

  /// MBT cari extre: tahsilat satırları (alacak) — ? from, to
  static const String mbtReportCariCollectionLinesSql = '''
    SELECT
      col.id AS row_id,
      COALESCE(col.collection_date, col.created_at) AS event_date,
      col.amount AS amount,
      COALESCE(col.payment_type, 'Cash') AS voucher_type,
      COALESCE(col.notes, col.document_no, '') AS description,
      COALESCE(c.code, '') AS customer_code,
      COALESCE(c.name, '') AS customer_name,
      COALESCE(col.currency_code, 'TRY') AS currency_code
    FROM collections col
    LEFT JOIN customers c ON c.id = col.customer_id
    WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
      AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
      AND COALESCE(col.status, '') != 'Cancelled'
  ''';

  /// MBT borç/alacak: cari bakiye listesi
  static const String mbtReportCustomerBalanceSql = '''
    SELECT
      COALESCE(code, '') AS code,
      COALESCE(name, '') AS title,
      COALESCE(balance, 0) AS balance
    FROM customers
    WHERE COALESCE(is_active, 1) = 1
    ORDER BY name COLLATE NOCASE
  ''';

  /// MBT tahsilat listesi — ? from, to
  static const String mbtReportTahsilatRowsSql = '''
    SELECT
      COALESCE(c.code, '') AS code,
      COALESCE(c.name, '') AS title,
      COALESCE(col.collection_date, col.created_at) AS txn_date,
      col.due_date AS due_date,
      COALESCE(col.payment_type, '') AS txn_type,
      col.amount AS amount,
      col.amount AS remaining,
      col.document_no AS document_no
    FROM collections col
    LEFT JOIN customers c ON c.id = col.customer_id
    WHERE date(COALESCE(col.collection_date, col.created_at)) >= date(?)
      AND date(COALESCE(col.collection_date, col.created_at)) <= date(?)
      AND COALESCE(col.status, '') != 'Cancelled'
    ORDER BY col.collection_date DESC
  ''';

  /// Dönem karşılaştırma kayıtlı geçmiş (sorgu + sonuç snapshot).
  static const String createPeriodCompareHistoryTable = '''
    CREATE TABLE IF NOT EXISTS period_compare_history (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      template TEXT NOT NULL,
      query_json TEXT NOT NULL,
      result_json TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0
    )
  ''';
}
