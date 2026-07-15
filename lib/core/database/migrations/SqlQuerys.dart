// Dosya Adı: SqlQuerys.dart
// Açıklama: Projedeki tüm tablo ve migration SQL sorgularını merkezi olarak tutar. Her tablo için CREATE, DROP, ALTER örnekleri, varsayılan insertler ve önemli sorgular burada bulunur. Tüm servisler ve migrationlar bu dosyadan kullanmalıdır.
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-06-08

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

  // --- FIELD SALES: CUSTOMERS ---
  static const String createCustomersTable = '''
    CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY,
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
      updated_at TEXT
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
      status TEXT, -- 'Pending', 'Approved', 'Cancelled'
      notes TEXT,
      is_synced INTEGER DEFAULT 0,
      signature_data TEXT,
      created_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  // --- FIELD SALES: ORDER_ITEMS ---
  static const String createOrderItemsTable = '''
    CREATE TABLE IF NOT EXISTS order_items (
      id TEXT PRIMARY KEY,
      order_id TEXT,
      product_id TEXT,
      quantity REAL,
      price REAL,
      vat_amount REAL,
      total_amount REAL,
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
      approval_status INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  static const String createInvoiceItemsTable = '''
    CREATE TABLE IF NOT EXISTS invoice_items (
      id TEXT PRIMARY KEY,
      invoice_id TEXT,
      product_id TEXT,
      quantity REAL,
      price REAL,
      vat_amount REAL,
      total_amount REAL,
      updated_at TEXT,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  ''';

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
      status TEXT, -- 'Open', 'Completed'
      duration_minutes INTEGER,
      is_synced INTEGER DEFAULT 0,
      signature_data TEXT,
      created_at TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
  ''';

  // --- FIELD SALES: GPS_LOGS ---
  static const String createGpsLogsTable = '''
    CREATE TABLE IF NOT EXISTS gps_logs (
      id TEXT PRIMARY KEY,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      timestamp TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0
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
      created_at TEXT
    );
  ''';

  // --- PHASE 9: KILLER FEATURES ---
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

  static const String createExpensesTable = '''
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
}
