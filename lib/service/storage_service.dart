import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import '../core/database/migrations/SqlQuerys.dart';

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  StorageException(this.message, {this.details, this.stackTrace});

  @override
  String toString() {
    String result = "StorageException: $message";
    if (details != null) result += "\nDetails: $details";
    if (stackTrace != null) result += "\nStackTrace: $stackTrace";
    return result;
  }
}

/// A cross-platform storage service for persisting data across different platforms:
/// - Windows: SQLite database in C: drive
/// - Mobile: SQLite database in device storage
/// - Web: localStorage (via shared_preferences)
class StorageService {
  static StorageService? _instance;
  static Database? _database;
  static SharedPreferences? _preferences;

  // Singleton pattern
  StorageService._internal();
  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._internal();

    try {
      if (kIsWeb) {
        // Initialize SharedPreferences for web
        try {
          _preferences ??= await SharedPreferences.getInstance();
          print("=== Web localStorage initialized successfully ===");
          // On web platform, set a default API config if none exists
          if (!_preferences!.containsKey('api_config')) {
            print("=== Creating default API config for web ===");
            final defaultConfig = {
              'base_url': 'https://api.ornek.com/api',
              'printer_url': '',
              'api_key': '',
              'timeout': 30,
              'use_https': 1,
            };
            await _preferences!.setString(
              'api_config',
              jsonEncode(defaultConfig),
            );
          }
        } catch (e) {
          print("=== Error initializing web localStorage: $e ===");
          throw StorageException(
            'Failed to initialize web localStorage',
            details: e.toString(),
            stackTrace: StackTrace.current,
          );
        }
      } else {
        // Initialize SQLite for non-web platforms
        try {
          _database ??= await _initDatabase();
        } catch (e) {
          throw StorageException(
            'Failed to initialize database',
            details: e.toString(),
            stackTrace: StackTrace.current,
          );
        }
      }
      if (!kIsWeb) {
        await resetAndMigrateDepartments();
      }
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      print("Error initializing storage: $e");
      throw StorageException(
        'Storage initialization error',
        details: e.toString(),
      );
    }

    return _instance!;
  }

  /// Initialize the SQLite database based on platform
  static Future<Database> _initDatabase() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        sqfliteFfiInit();
        final databaseFactory = databaseFactoryFfi;
        final dbPath = 'C:\\exfin_erp_data';
        try {
          await Directory(dbPath).create(recursive: true);
        } catch (e) {
          throw StorageException(
            'Failed to create database directory on Windows',
            details: 'Path: $dbPath, Error: $e',
          );
        }
        final dbFilePath = path.join(dbPath, 'exfin_erp.db');
        final db = await databaseFactory.openDatabase(dbFilePath);
        await initializeDatabaseTables(db);
        return db;
      } else if (!kIsWeb) {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final dbPath = path.join(documentsDirectory.path, 'exfin_erp.db');
        final db = await openDatabase(dbPath);
        await initializeDatabaseTables(db);
        return db;
      } else {
        // Web platformunda SQLite desteklenmez.
        throw UnsupportedError('Web platformunda SQLite desteklenmez.');
      }
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException(
        'Database initialization error',
        details: e.toString(),
        stackTrace: StackTrace.current,
      );
    }
  }

  // Store API configuration
  Future<void> saveApiConfig({
    required String baseUrl,
    String? printerUrl,
    String? apiKey,
    int timeout = 30,
    bool useHttps = true,
  }) async {
    try {
      final apiConfig = {
        'base_url': baseUrl,
        'printer_url': printerUrl ?? '',
        'api_key': apiKey,
        'timeout': timeout,
        'use_https': useHttps ? 1 : 0,
      };

      if (kIsWeb) {
        // Web: Use localStorage via SharedPreferences
        await _preferences!.setString('api_config', jsonEncode(apiConfig));
        print('Web API Config saved successfully: ${jsonEncode(apiConfig)}');
      } else {
        // Windows/Mobile: Use SQLite
        try {
          final results = await _database!.rawQuery(
            'SELECT COUNT(*) as count FROM api_config',
          );
          final count = Sqflite.firstIntValue(results) ?? 0;

          if (count > 0) {
            // Update existing record
            final updateCount = await _database!.update(
              'api_config',
              apiConfig,
              where: 'id = ?',
              whereArgs: [1],
            );
            print('Updated $updateCount rows in api_config table');
          } else {
            // Insert new record
            final id = await _database!.insert('api_config', apiConfig);
            print('Inserted new record with id: $id');
          }

          // Debug: Print current config after save
          final result = await _database!.query('api_config');
          print('API Config after save: $result');
        } catch (dbError) {
          print('Database error during save: $dbError');
          throw StorageException(
            'Failed to save API config to database',
            details: dbError.toString(),
          );
        }
      }
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      print('Error in saveApiConfig: $e');
      throw StorageException(
        'Failed to save API configuration',
        details: e.toString(),
      );
    }
  }

  // Get API configuration
  Future<Map<String, dynamic>?> getApiConfig() async {
    try {
      if (kIsWeb) {
        // Web: Use localStorage via SharedPreferences
        final apiConfigJson = _preferences!.getString('api_config');
        print('Web API Config retrieved: $apiConfigJson');
        if (apiConfigJson != null) {
          try {
            final config = jsonDecode(apiConfigJson) as Map<String, dynamic>;
            return config;
          } catch (e) {
            throw StorageException(
              'Failed to parse API config JSON from web storage',
              details: 'JSON: $apiConfigJson, Error: $e',
            );
          }
        }
        return null;
      } else {
        // Windows/Mobile: Use SQLite
        try {
          final result = await _database!.query('api_config', limit: 1);
          print('API Config retrieved from SQLite: $result');
          if (result.isNotEmpty) {
            return result.first;
          }
          return null;
        } catch (dbError) {
          print('Database error during retrieval: $dbError');
          throw StorageException(
            'Failed to retrieve API config from database',
            details: dbError.toString(),
          );
        }
      }
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      print('Error in getApiConfig: $e');
      throw StorageException(
        'Failed to get API configuration',
        details: e.toString(),
      );
    }
  }

  // Store a key-value setting
  Future<void> setSetting(String key, dynamic value) async {
    try {
      if (key.isEmpty) {
        throw StorageException('Cannot store setting with empty key');
      }

      // Boolean değerleri integer'a dönüştür
      String stringValue;
      if (value is bool) {
        stringValue = value ? '1' : '0';
      } else {
        stringValue = value.toString();
      }

      if (kIsWeb) {
        // Web: Use localStorage via SharedPreferences
        await _preferences!.setString(key, stringValue);
        print('Web setting saved: $key = $stringValue');
      } else {
        // Windows/Mobile: Use SQLite
        try {
          final now = DateTime.now().toIso8601String();
          await _database!.insert(
              'settings',
              {
                'setting_key': key,
                'setting_value': stringValue,
                'created_at': now,
                'updated_at': now,
                'approval_status': 0,
                'is_synced': 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
          print('SQLite setting saved: $key = $stringValue');
        } catch (e) {
          throw StorageException(
            'Failed to save setting to database',
            details: 'Key: $key, Error: $e',
          );
        }
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to save setting', details: e.toString());
    }
  }

  // Get a setting by key
  Future<String?> getSetting(String key) async {
    try {
      if (key.isEmpty) {
        throw StorageException('Cannot retrieve setting with empty key');
      }

      if (kIsWeb) {
        // Web: Use localStorage via SharedPreferences
        final value = _preferences!.getString(key);
        print('Web setting retrieved: $key = $value');
        return value;
      } else {
        // Windows/Mobile: Use SQLite
        try {
          final result = await _database!.query(
            'settings',
            columns: ['setting_value'],
            where: 'setting_key = ?',
            whereArgs: [key],
          );

          if (result.isNotEmpty) {
            final value = result.first['setting_value'] as String?;
            print('SQLite setting retrieved: $key = $value');
            return value;
          }
          return null;
        } catch (e) {
          throw StorageException(
            'Failed to retrieve setting from database',
            details: 'Key: $key, Error: $e',
          );
        }
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to get setting', details: e.toString());
    }
  }

  // Get a boolean setting by key
  Future<bool> getBoolSetting(String key, {bool defaultValue = false}) async {
    try {
      final value = await getSetting(key);
      if (value == null) return defaultValue;

      // String değerleri boolean'a dönüştür
      if (value == 'true' || value == '1') return true;
      if (value == 'false' || value == '0') return false;

      return defaultValue;
    } catch (e) {
      print('Boolean setting alınırken hata: $key - $e');
      return defaultValue;
    }
  }

  // Store complex object
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    try {
      if (key.isEmpty) {
        throw StorageException('Cannot store object with empty key');
      }

      String jsonString;
      try {
        jsonString = jsonEncode(value);
      } catch (e) {
        throw StorageException(
          'Failed to encode object to JSON',
          details: 'Key: $key, Error: $e',
        );
      }

      if (kIsWeb) {
        // Web: Use localStorage via SharedPreferences
        await _preferences!.setString(key, jsonString);
        print('Web object saved: $key = $jsonString');
      } else {
        // Windows/Mobile: Use SQLite
        try {
          await _database!.insert(
              'settings',
              {
                'setting_key': key,
                'setting_value': jsonString,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
          print('SQLite object saved: $key');
        } catch (e) {
          throw StorageException(
            'Failed to save object to database',
            details: 'Key: $key, Error: $e',
          );
        }
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to save object', details: e.toString());
    }
  }

  // Get complex object
  Future<Map<String, dynamic>?> getObject(String key) async {
    try {
      if (key.isEmpty) {
        throw StorageException('Cannot retrieve object with empty key');
      }

      String? jsonString;

      if (kIsWeb) {
        // Web: Use localStorage via SharedPreferences
        jsonString = _preferences!.getString(key);
        print('Web object retrieved: $key = $jsonString');
      } else {
        // Windows/Mobile: Use SQLite
        try {
          final result = await _database!.query(
            'settings',
            columns: ['setting_value'],
            where: 'setting_key = ?',
            whereArgs: [key],
          );

          if (result.isNotEmpty) {
            jsonString = result.first['setting_value'] as String?;
            print('SQLite object retrieved: $key');
          }
        } catch (e) {
          throw StorageException(
            'Failed to retrieve object from database',
            details: 'Key: $key, Error: $e',
          );
        }
      }

      if (jsonString != null) {
        try {
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          throw StorageException(
            'Failed to decode object from JSON',
            details: 'Key: $key, JSON: $jsonString, Error: $e',
          );
        }
      }

      return null;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to get object', details: e.toString());
    }
  }

  // Clear all stored data
  Future<void> clearAll() async {
    try {
      if (kIsWeb) {
        // Web: Use localStorage via SharedPreferences
        await _preferences!.clear();
        print('Web storage cleared successfully');
      } else {
        // Windows/Mobile: Use SQLite
        try {
          int settingsDeleted = await _database!.delete('settings');
          int apiConfigDeleted = await _database!.delete('api_config');
          print(
            'SQLite tables cleared: settings ($settingsDeleted rows), api_config ($apiConfigDeleted rows)',
          );
        } catch (e) {
          throw StorageException(
            'Failed to clear database tables',
            details: e.toString(),
          );
        }
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to clear all data', details: e.toString());
    }
  }

  /// Check storage health and schema
  Future<bool> checkStorageHealth() async {
    try {
      if (kIsWeb) {
        // For web, check if we can write and read a test value
        await _preferences!.setString('_health_check', 'ok');
        final result = _preferences!.getString('_health_check');
        return result == 'ok';
      } else {
        // For SQLite, check if tables exist and we can query them
        final tables = await _database!.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );

        final hasSettings = tables.any((table) => table['name'] == 'settings');
        final hasApiConfig = tables.any(
          (table) => table['name'] == 'api_config',
        );

        if (!hasSettings || !hasApiConfig) {
          print(
            'Missing tables: settings=${hasSettings}, api_config=${hasApiConfig}',
          );
          return false;
        }

        // Try a test read/write
        await setSetting('_health_check', 'ok');
        final result = await getSetting('_health_check');
        return result == 'ok';
      }
    } catch (e) {
      print('Storage health check failed: $e');
      return false;
    }
  }

  /// Returns true if SQLite is supported (non-web platforms)
  Future<bool> hasSQLiteSupport() async {
    return !kIsWeb;
  }

  /// Returns the SQLite database instance
  Future<Database> getDatabase() async {
    if (_database == null) {
      throw StorageException('Database is not initialized');
    }
    return _database!;
  }

  // Firma bilgilerini getir
  Future<Map<String, dynamic>> getCompanyInfo() async {
    try {
      // Seçili firmayı al
      final result = await _database!.query(
        'companies',
        where: 'is_selected = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final company = result.first;
        return {
          'name': company['name'],
          'detail': company['detail'],
          'branch': company['branch'],
          'period': company['period'],
          'license_start': company['license_start'],
          'license_end': company['license_end'],
          'color': company['color'],
          'is_selected': company['is_selected'],
        };
      }

      // Seçili firma yoksa tüm firmalardan ilkini al
      final allCompanies = await _database!.query('companies', limit: 1);
      if (allCompanies.isNotEmpty) {
        final company = allCompanies.first;
        return {
          'name': company['name'],
          'detail': company['detail'],
          'branch': company['branch'],
          'period': company['period'],
          'license_start': company['license_start'],
          'license_end': company['license_end'],
          'color': company['color'],
          'is_selected': company['is_selected'],
        };
      }

      // Hiç firma yoksa boş map döndür
      return {};
    } catch (e) {
      print('Firma bilgileri alınırken hata: $e');
      return {};
    }
  }

  // SQL sorgusunu çalıştır
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    await _database!.execute(sql);
  }

  // Veritabanından sorgu yap
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await _database!.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  // Veritabanına kayıt ekle
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    // Boolean değerleri dönüştür
    final convertedValues = convertBoolsToInts(values);
    return await _database!.insert(
      table,
      convertedValues,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  // Veritabanındaki kaydı güncelle
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    // Boolean değerleri dönüştür
    final convertedValues = convertBoolsToInts(values);
    return await _database!.update(
      table,
      convertedValues,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Kullanıcı kimlik bilgilerini temizle
  Future<void> clearCredentials({bool preserveRememberMe = false}) async {
    bool rememberMe = false;
    String savedUsername = '';
    String savedPassword = '';

    if (preserveRememberMe) {
      rememberMe = await getBoolSetting('remember_me', defaultValue: false);
      savedUsername = (await getSetting('saved_username')) ?? '';
      savedPassword = (await getSetting('saved_password')) ?? '';
    }

    await setSetting('saved_username', '');
    await setSetting('saved_password', '');
    await setSetting('remember_me', false);
    await setSetting('auth_token', '');

    if (preserveRememberMe && rememberMe) {
      await setSetting('remember_me', true);
      await setSetting('saved_username', savedUsername);
      await setSetting('saved_password', savedPassword);
    }
  }

  /// Tüm tablolara approval_status ve is_synced alanı ekler ve ilk açılışta approval_status=1 yapar, sonra hep 0 olarak ayarlar
  // Eski migration fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  /// Tüm temel tabloları sıralı şekilde oluşturur (migration)
  static Future<void> initializeDatabaseTables(Database db) async {
    await db.execute(SqlQuerys.createCompaniesTable);
    await db.execute(SqlQuerys.createMenuTable);
    await db.execute(SqlQuerys.createLanguagesTable);
    await db.execute(SqlQuerys.createTranslationsTable);
    await db.execute(SqlQuerys.createUsersTable);
    await db.execute(SqlQuerys.createRolesTable);
    await db.execute(SqlQuerys.createDepartmentsTable);
    await db.execute(SqlQuerys.createFactoriesTable);
    await db.execute(SqlQuerys.createDeviceTable);
    await db.execute(SqlQuerys.createMenuPermissionsTable);
    await db.execute(SqlQuerys.createUserCompanyVisibilityTable);
    await db.execute(SqlQuerys.createUserRolesTable);
    await db.execute(SqlQuerys.createCompanyPeriodTable);
    await db.execute(SqlQuerys.createSettingsTable);
    
    // Field Sales Tables
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createProductsTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createOrderItemsTable);
    await db.execute(SqlQuerys.createCollectionsTable);
  }

  /// Veritabanı dosyasının tam yolunu döndürür
  Future<String> getDatabasePath() async {
    try {
      if (kIsWeb) {
        throw UnsupportedError(
            'Web platformunda veritabanı dosya yolu mevcut değil');
      }

      if (Platform.isWindows) {
        return 'C:\\exfin_erp_data\\exfin_erp.db';
      } else {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        return path.join(documentsDirectory.path, 'exfin_erp.db');
      }
    } catch (e) {
      throw StorageException(
        'Veritabanı yolu alınamadı',
        details: e.toString(),
      );
    }
  }

  /// Veritabanı dosyasının boyutunu döndürür (bytes)
  Future<int> getDatabaseSize() async {
    try {
      if (kIsWeb) return 0;

      final dbPath = await getDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Veritabanı boyutu alınamadı: $e');
      return 0;
    }
  }

  /// Map içindeki bool değerleri int (0/1) olarak dönüştürür
  Map<String, dynamic> convertBoolsToInts(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is bool) {
        return MapEntry(key, value ? 1 : 0);
      }
      return MapEntry(key, value);
    });
  }

  /// Map içindeki int (0/1) değerleri bool olarak dönüştürür
  Map<String, dynamic> convertIntsToBools(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is int && (value == 0 || value == 1)) {
        // Boolean alanları tespit et ve dönüştür
        if (_isBooleanField(key)) {
          return MapEntry(key, value == 1);
        }
      }
      return MapEntry(key, value);
    });
  }

  /// Alan adının boolean alan olup olmadığını kontrol eder
  bool _isBooleanField(String fieldName) {
    final booleanFields = [
      'is_active',
      'is_selected',
      'is_synced',
      'is_deleted',
      'is_encrypted',
      'is_approved',
      'is_visible',
      'is_enabled',
      'auto_sync_enabled',
      'auto_backup_enabled',
      'audit_log_enabled',
      'database_encrypted',
      'remember_me',
      'use_https',
      'is_logged_in',
      'force_logout',
      'force_logout_request'
    ];
    return booleanFields.contains(fieldName.toLowerCase());
  }

  /// Veritabanı dosyasının son değiştirilme tarihini döndürür
  Future<DateTime?> getDatabaseLastModified() async {
    try {
      if (kIsWeb) return null;

      final dbPath = await getDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      print('Veritabanı son değiştirilme tarihi alınamadı: $e');
      return null;
    }
  }

  /// Otomatik migration: Eksik kolonları ekler
  Future<void> runAutoMigrations() async {
    final db = await getDatabase();

    // departments tablosu için
    final departmentsRequired = <String, String>{
      'company_no': 'INTEGER',
      'name': 'TEXT',
      'description': 'TEXT',
      'is_active': 'INTEGER DEFAULT 1',
      'created_at': 'TEXT',
      'updated_at': 'TEXT',
    };
    await _addMissingColumns(db, 'departments', departmentsRequired);

    // device tablosu için
    final deviceRequired = <String, String>{
      'device_name': 'TEXT NOT NULL',
      'device_type': 'TEXT',
      'device_serial_number': 'TEXT',
      'brand': 'TEXT',
      'operating_system': 'TEXT',
      'created_at': 'TEXT',
      'updated_at': 'TEXT',
      'is_active': 'INTEGER DEFAULT 1',
      'is_deleted': 'INTEGER DEFAULT 0',
      'approval_status': 'INTEGER DEFAULT 0',
      'approved_by': 'TEXT',
      'approval_date': 'TEXT',
      'description': 'TEXT',
      'valid_until': 'TEXT',
    };
    await _addMissingColumns(db, 'device', deviceRequired);

    // menu_permissions tablosu - migration kaldırıldı, delta sync ile yönetiliyor

    // settings tablosu için - PRIMARY KEY eklenemez, tabloyu sıfırla
    try {
      final columns = await db.rawQuery(SqlQuerys.getTableInfoSql("settings"));
      final columnNames = columns.map((col) => col['name'] as String).toSet();

      // Eğer id alanı yoksa tabloyu sıfırla
      if (!columnNames.contains('id')) {
        print('settings tablosu sıfırlanıyor (PRIMARY KEY alanı eksik)...');
        await db.execute(SqlQuerys.dropSettingsTable);
        await db.execute(SqlQuerys.createSettingsTable);
        print('settings tablosu yeniden oluşturuldu');
      } else {
        // Sadece eksik alanları ekle
        final settingsRequired = <String, String>{
          'uuid': 'TEXT',
          'description': 'TEXT',
          'category': 'TEXT',
          'is_system_setting': 'INTEGER NOT NULL DEFAULT 0',
          'is_encrypted': 'INTEGER NOT NULL DEFAULT 0',
        };
        await _addMissingColumns(db, 'settings', settingsRequired);
      }
    } catch (e) {
      print('settings tablosu migration hatası: $e');
    }

    // Diğer tablolar için de aynı şekilde ekleme yapılabilir.
  }

  Future<void> _addMissingColumns(
      Database db, String table, Map<String, String> requiredColumns) async {
    for (final entry in requiredColumns.entries) {
      final columns = await db.rawQuery(SqlQuerys.getTableInfoSql(table));
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      if (!columnNames.contains(entry.key)) {
        await db.execute(SqlQuerys.addColumnSql(table, entry.key, entry.value));
        print(
            '$table tablosuna ${entry.key} alanı eklendi (otomatik migration)');
      }
    }
  }

  /// departments tablosunu sıfırla ve migrationları uygula
  static Future<void> resetAndMigrateDepartments() async {
    final db = await _instance!.getDatabase();
    await db.execute(SqlQuerys.dropDepartmentsTable);
    await db.execute(SqlQuerys.createDepartmentsTable);
    print('departments tablosu sıfırlandı ve yeniden oluşturuldu.');
    await _instance!.runAutoMigrations();
  }
}
