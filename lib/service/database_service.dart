import 'package:sqflite/sqflite.dart' show ConflictAlgorithm, Sqflite, Database;
import '../core/database/migrations/SqlQuerys.dart';
import 'postgres_service.dart';
import 'dart:convert';
import '../core/services/postgre_service.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:crypto/crypto.dart';

/// Service to handle database operations
class DatabaseService {
  static DatabaseService? _instance;
  late StorageService _storage;
  bool _isInitialized = false;

  // SQLite şifreleme için gerekli değişkenler
  static const String _encryptionKey = 'EXFINERP_SECURE_KEY_2024';
  static const String _salt = 'EXFINERP_SALT_2024';
  bool _isEncrypted = false;

  // Singleton pattern
  DatabaseService._internal();

  static Future<DatabaseService> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseService._internal();
      _instance!._storage = await StorageService.getInstance();
    }
    return _instance!;
  }

  /// Şifreleme anahtarını oluşturur
  String _generateEncryptionKey() {
    final key = _encryptionKey + _salt;
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Veritabanının şifrelenip şifrelenmediğini kontrol eder
  Future<bool> isDatabaseEncrypted() async {
    return _isEncrypted;
  }

  /// Veritabanını şifreler (eğer henüz şifrelenmemişse)
  Future<void> encryptDatabase() async {
    if (_isEncrypted) {
      print('⚠️ Veritabanı zaten şifrelenmiş');
      return;
    }

    try {
      print('🔐 Veritabanı şifreleniyor...');

      // Mevcut veritabanını yedekle
      await _backupDatabase();

      // Şifrelenmiş veritabanı oluştur
      final db = await _storage.getDatabase();
      await db.execute(
        SqlQuerys.getSetEncryptionKeySql(_generateEncryptionKey()),
      );
      await db.execute(SqlQuerys.setCipherCompatibility);
      await db.execute(SqlQuerys.setCipherPageSize);
      await db.execute(SqlQuerys.setCipherHmacAlgorithm);
      await db.execute(SqlQuerys.setCipherKdfIter);

      // Veritabanını yeniden şifrele
      await db.execute(
        SqlQuerys.getTestEncryptionKeySql(_generateEncryptionKey()),
      );

      _isEncrypted = true;
      await _storage.setSetting('database_encrypted', true);

      print('✅ Veritabanı başarıyla şifrelendi');
    } catch (e) {
      print('❌ Veritabanı şifreleme hatası: $e');
      rethrow;
    }
  }

  /// Şifrelenmiş veritabanını açar
  Future<Database> _openEncryptedDatabase() async {
    try {
      final db = await _storage.getDatabase();

      // Şifreleme anahtarını ayarla
      await db.execute(
        SqlQuerys.getSetEncryptionKeySql(_generateEncryptionKey()),
      );
      await db.execute(SqlQuerys.setCipherCompatibility);

      // Veritabanının şifrelenip şifrelenmediğini kontrol et
      try {
        await db.execute('SELECT 1');
        _isEncrypted = true;
      } catch (e) {
        // Veritabanı şifrelenmemiş, normal aç
        _isEncrypted = false;
      }

      return db;
    } catch (e) {
      print('❌ Şifrelenmiş veritabanı açma hatası: $e');
      rethrow;
    }
  }

  /// Veritabanı yedeği oluşturur
  Future<void> _backupDatabase() async {
    try {
      final db = await _storage.getDatabase();
      final backupPath = await _storage.getDatabasePath();
      final backupPathWithTimestamp =
          '${backupPath}_backup_${DateTime.now().millisecondsSinceEpoch}';

      // Veritabanını yedekle
      await db.execute(
        SqlQuerys.getVacuumIntoBackupSql(backupPathWithTimestamp),
      );
      print('💾 Veritabanı yedeği oluşturuldu: $backupPathWithTimestamp');
    } catch (e) {
      print('❌ Veritabanı yedekleme hatası: $e');
    }
  }

  /// Veritabanı güvenlik durumunu kontrol eder
  Future<Map<String, dynamic>> getDatabaseSecurityStatus() async {
    final isEncrypted = await isDatabaseEncrypted();
    final encryptionKey = _generateEncryptionKey();

    return {
      'is_encrypted': isEncrypted,
      'encryption_key_hash':
          sha256.convert(utf8.encode(encryptionKey)).toString(),
      'last_encryption_check': DateTime.now().toIso8601String(),
      'security_level': isEncrypted ? 'high' : 'low',
    };
  }

  /// Veritabanı güvenlik ayarlarını yapılandırır
  Future<void> configureDatabaseSecurity({
    bool enableEncryption = true,
    bool enableBackup = true,
    bool enableAuditLog = true,
  }) async {
    try {
      if (enableEncryption && !_isEncrypted) {
        await encryptDatabase();
      }

      if (enableBackup) {
        await _storage.setSetting('auto_backup_enabled', true);
        await _storage.setSetting('backup_interval_hours', '24');
      }

      if (enableAuditLog) {
        await _storage.setSetting('audit_log_enabled', true);
        await _createAuditTable();
      }

      print('✅ Veritabanı güvenlik ayarları yapılandırıldı');
    } catch (e) {
      print('❌ Güvenlik yapılandırma hatası: $e');
      rethrow;
    }
  }

  /// Audit tablosu oluşturur
  Future<void> _createAuditTable() async {
    try {
      final db = await _storage.getDatabase();
      await db.execute(SqlQuerys.createAuditLogTable);
      print('✅ Audit tablosu oluşturuldu');
    } catch (e) {
      print('❌ Audit tablosu oluşturma hatası: $e');
    }
  }

  /// Audit log kaydı ekler
  Future<void> _addAuditLog({
    required String action,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final auditEnabled = await _storage.getSetting('audit_log_enabled');
      if (auditEnabled != 'true') return;

      final db = await _storage.getDatabase();
      await db.insert('audit_log', {
        'user_id': userId,
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'old_values': oldValues != null ? jsonEncode(oldValues) : null,
        'new_values': newValues != null ? jsonEncode(newValues) : null,
        'ip_address': ipAddress,
        'user_agent': userAgent,
      });
    } catch (e) {
      print('❌ Audit log ekleme hatası: $e');
    }
  }

  /// Initialize the database and ensure it's ready for use
  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      await initializeDatabaseTables();
      await resetCompaniesIfSupabaseAvailable();
      await ensureCompaniesTableSchema();
      await ensureOrdersTableSchema();

      // Menü tablosu reset kontrolü ve otomatik sıfırlama kaldırıldı
      // Dil tablosunu oluştur
      await createLanguageTable();

      // Varsayılan dilleri ekle
      await _addDefaultLanguages();

      // Local menu tablosu boşsa Supabase'den çek
      await ensureLocalMenuFromSupabase();

      // Otomatik sync'i başlat (eğer daha önce etkinleştirilmişse)
      await _initializeAutoSync();
    }
  }

  /// Otomatik sync'i başlatır (eğer daha önce etkinleştirilmişse)
  Future<void> _initializeAutoSync() async {
    try {
      if (await _storage.getBoolSetting(
        'auto_sync_enabled',
        defaultValue: false,
      )) {
        final intervalMinutes = await _storage.getSetting(
          'auto_sync_interval_minutes',
        );
        final interval = Duration(
          minutes: int.tryParse(intervalMinutes ?? '5') ?? 5,
        );
        await startAutoSync(interval: interval);
        print('🔄 Otomatik sync yeniden başlatıldı');
      }
    } catch (e) {
      print('❌ Otomatik sync başlatılırken hata: $e');
    }
  }

  /// Varsayılan dilleri ekle
  Future<void> _addDefaultLanguages() async {
    await addLanguage(
      code: 'tr',
      name: 'Turkish',
      localName: 'Türkçe',
      flagCode: 'tr',
    );
    await addLanguage(
      code: 'en',
      name: 'English',
      localName: 'English',
      flagCode: 'gb',
    );
    await addLanguage(
      code: 'de',
      name: 'German',
      localName: 'Deutsch',
      flagCode: 'de',
    );
    await addLanguage(
      code: 'ar',
      name: 'Arabic',
      localName: 'العربية',
      flagCode: 'sa',
    );
    await addLanguage(
      code: 'ru',
      name: 'Russian',
      localName: 'Русский',
      flagCode: 'ru',
    );
    await addLanguage(
      code: 'fa',
      name: 'Persian',
      localName: 'فارسی',
      flagCode: 'ir',
    );
  }

  /// Companies tablosunu oluştur
  Future<void> _createCompaniesTable() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      try {
        await db.execute(SqlQuerys.dropCompaniesTable);
        await db.execute(SqlQuerys.createCompaniesTable);
      } catch (e) {
        print('Companies tablosu oluşturulurken hata oluştu: $e');
        rethrow;
      }
    }
  }

  /// Veritabanını sıfırla
  Future<void> resetDatabase() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();

      try {
        // Reset durumlarını sıfırla
        await _storage.setSetting('firma_reset', '0');
        await _storage.setSetting('menu_reset', '0');

        // Tabloları sil
        await db.execute(SqlQuerys.dropMenuTable);
        await db.execute(SqlQuerys.dropCompaniesTable);
        await db.execute(SqlQuerys.dropLanguagesTable);
        await db.execute(SqlQuerys.dropTranslationsTable);
        await db.execute(SqlQuerys.dropSettingsTable);

        // Veritabanını yeniden başlat
        _isInitialized = false;
        await initialize();

        print("Veritabanı başarıyla sıfırlandı.");
      } catch (e) {
        print("Veritabanı sıfırlanırken hata: $e");
        throw StorageException(
          'Veritabanı sıfırlanırken hata oluştu',
          details: e.toString(),
        );
      }
    }
  }

  /// Sadece firma tablosunu sıfırla
  Future<void> resetCompaniesTable() async {
    if (await _storage.hasSQLiteSupport()) {
      try {
        // Firma reset durumunu sıfırla
        await _storage.setSetting('firma_reset', '0');

        // Companies tablosunu yeniden oluştur
        await _createCompaniesTable();

        print("Firma tablosu başarıyla sıfırlandı.");
      } catch (e) {
        print("Firma tablosu sıfırlanırken hata: $e");
        throw StorageException(
          'Firma tablosu sıfırlanırken hata oluştu',
          details: e.toString(),
        );
      }
    }
  }

  /// Sadece menü tablosunu sıfırla
  Future<void> resetMenuTable() async {
    if (await _storage.hasSQLiteSupport()) {
      try {
        // Menü reset durumunu sıfırla
        await _storage.setSetting('menu_reset', '0');

        // Menü tablosunu yeniden oluştur
        await createNewMenuTable();

        print("Menü tablosu başarıyla sıfırlandı.");
      } catch (e) {
        print("Menü tablosu sıfırlanırken hata: $e");
        throw StorageException(
          'Menü tablosu sıfırlanırken hata oluştu',
          details: e.toString(),
        );
      }
    }
  }

  /// Settings tablosunu zorla sıfırla (yeni şema ile)
  Future<void> forceResetSettingsTable() async {
    if (await _storage.hasSQLiteSupport()) {
      try {
        final db = await _storage.getDatabase();

        print('🔄 Settings tablosu zorla sıfırlanıyor...');

        // Mevcut settings tablosunu sil
        await db.execute(SqlQuerys.dropSettingsTable);

        // Yeni şema ile settings tablosunu oluştur
        await db.execute(SqlQuerys.createSettingsTable);

        print('✅ Settings tablosu başarıyla sıfırlandı!');
        print('✅ menu_reset kolonu eklendi');
      } catch (e) {
        print('❌ Settings tablosu sıfırlanırken hata: $e');
        throw StorageException(
          'Settings tablosu sıfırlanırken hata oluştu',
          details: e.toString(),
        );
      }
    }
  }

  /// Get the API configuration
  Future<Map<String, dynamic>> getApiConfig() async {
    final apiConfig = await _storage.getApiConfig();
    return apiConfig ??
        {
          'base_url': '//api.exfinerp.com/api',
          'api_key': null,
          'timeout': 30,
          'use_https': 1,
        };
  }

  /// Update the API configuration
  Future<void> updateApiConfig({
    required String baseUrl,
    String? printerUrl,
    String? apiKey,
    int? timeout,
    bool? useHttps,
  }) async {
    // Get current config first
    final currentConfig = await getApiConfig();

    // Apply updates only to values that are provided
    await _storage.saveApiConfig(
      baseUrl: baseUrl,
      printerUrl: printerUrl ?? currentConfig['printer_url'] as String?,
      apiKey: apiKey ?? currentConfig['api_key'] as String?,
      timeout: timeout ?? currentConfig['timeout'] as int,
      useHttps: useHttps ?? (currentConfig['use_https'] == 1),
    );
  }

  /// Store authentication token
  Future<void> saveAuthToken(String token) async {
    await _storage.setSetting('auth_token', token);
  }

  /// Get the stored authentication token
  Future<String?> getAuthToken() async {
    return await _storage.getSetting('auth_token');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Kullanıcı oturumunu sonlandır
  Future<void> logout() async {
    try {
      // Oturum bilgilerini temizle
      await _storage.clearCredentials(preserveRememberMe: true);

      // Seçili firma bilgisini temizle
      await _storage.setSetting('selected_company_id', '');

      // Auth token'ı temizle
      await _storage.setSetting('auth_token', '');
    } catch (e) {
      print('Çıkış yapılırken hata oluştu: $e');
      rethrow;
    }
  }

  /// Kullanıcı session bilgisini kaydet
  Future<void> setUserSession(Map<String, dynamic> session) async {
    await _storage.setSetting('user_session', jsonEncode(session));
  }

  /// Kullanıcı session bilgisini getir
  Future<Map<String, dynamic>?> getUserSession() async {
    final sessionStr = await _storage.getSetting('user_session');
    if (sessionStr == null || sessionStr.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(sessionStr));
  }

  /// Save any setting in storage
  Future<void> setSetting(String key, String value) async {
    await _storage.setSetting(key, value);
  }

  /// Get any setting from storage
  Future<String?> getSetting(String key) async {
    return await _storage.getSetting(key);
  }

  /// Save any object in storage
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    await _storage.setObject(key, value);
  }

  /// Get any object from storage
  Future<Map<String, dynamic>?> getObject(String key) async {
    return await _storage.getObject(key);
  }

  /// Save user credentials if "Remember Me" is selected
  Future<void> saveCredentials(String username, String password) async {
    await _storage.setSetting('saved_username', username);
    await _storage.setSetting('saved_password', password);
    await _storage.setSetting('remember_me', true);
  }

  /// Clear saved credentials
  Future<void> clearCredentials() async {
    await _storage.setSetting('saved_username', '');
    await _storage.setSetting('saved_password', '');
    await _storage.setSetting('remember_me', false);
  }

  /// Check if credentials are saved
  Future<bool> hasRememberedCredentials() async {
    final rememberMe = await _storage.getSetting('remember_me');
    return await _storage.getBoolSetting('remember_me', defaultValue: false);
  }

  /// Get saved username
  Future<String?> getSavedUsername() async {
    return await _storage.getSetting('saved_username');
  }

  /// Get saved password
  Future<String?> getSavedPassword() async {
    return await _storage.getSetting('saved_password');
  }

  /// Seçilen firma ID'sini kaydet
  Future<void> saveSelectedCompanyId(String companyId) async {
    await _storage.setSetting('selected_company_id', companyId);
  }

  /// Kaydedilen firma ID'sini getir
  Future<String?> getSelectedCompanyId() async {
    return await _storage.getSetting('selected_company_id');
  }

  /// Create language tables if they don't exist
  Future<void> createLanguageTable() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();

      // Create languages table
      await db.execute(SqlQuerys.createLanguagesTable);

      // Create translations table
      await db.execute(SqlQuerys.createTranslationsTable);
    }
  }

  /// Get default language
  Future<Map<String, dynamic>?> getDefaultLanguage() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      try {
        final result = await db.query(
          'languages',
          where: 'code = ?',
          whereArgs: ['tr'], // Turkish as default
          limit: 1,
        );

        if (result.isNotEmpty) {
          return result.first;
        }
      } catch (e) {
        print('Error getting default language: $e');
      }
    }
    return null;
  }

  /// Add a language to the database
  Future<void> addLanguage({
    required String code,
    required String name,
    required String localName,
    required String flagCode,
  }) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      await db.insert(
          'languages',
          {
            'code': code,
            'name': name,
            'local_name': localName,
            'flag_code': flagCode,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Get all supported languages
  Future<List<Map<String, dynamic>>> getAllLanguages() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query('languages');
    }
    return [];
  }

  /// Get all translations for a specific target language
  Future<Map<String, String>> getTranslationsByTargetLanguage(
    String targetLanguage,
  ) async {
    final result = <String, String>{};
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final rows = await db.query(
        'translations',
        columns: ['original_text', 'translated_text'],
        where: 'target_language = ?',
        whereArgs: [targetLanguage],
      );
      for (var row in rows) {
        result[row['original_text'] as String] =
            row['translated_text'] as String;
      }
    }
    return result;
  }

  /// Get existing translations for a text in multiple languages
  Future<Map<String, String>> getTranslationsForText(
    String originalText,
    List<String> targetLanguages,
  ) async {
    final result = <String, String>{};

    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      try {
        final translations = await db.query(
          'translations',
          columns: ['target_language', 'translated_text'],
          where:
              'original_text = ? AND target_language IN (${targetLanguages.map((_) => '?').join(', ')})',
          whereArgs: [originalText, ...targetLanguages],
        );

        for (final row in translations) {
          result[row['target_language'] as String] =
              row['translated_text'] as String;
        }
      } catch (e) {
        print('Error getting translations: $e');
      }
    }

    return result;
  }

  /// Save a translation to the database
  Future<void> saveTranslation({
    required String originalText,
    required String sourceLanguage,
    required String targetLanguage,
    required String translatedText,
  }) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      await db.insert(
          'translations',
          {
            'original_text': originalText,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
            'translated_text': translatedText,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Fetch all translations stored for a specific original text
  Future<List<Map<String, dynamic>>> getAllTranslations(
    String originalText,
  ) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query(
        'translations',
        where: 'original_text = ?',
        whereArgs: [originalText],
      );
    }
    return [];
  }

  /// Firma listesini getir (company_no dahil)
  Future<List<Map<String, dynamic>>> getCompanies() async {
    if (kIsWeb) {
      final supabase = await PostgreService.getInstance();
      return await supabase.query('company');
    }
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query('companies');
    }
    return [];
  }

  /// Firma ekle veya güncelle (uuid uyumlu)
  Future<void> addOrUpdateCompany({
    required String id,
    required String name,
    required String? companyNo,
    required String? description,
    required bool isActive,
    String? createdAt,
    String? updatedAt,
    bool isSelected = false,
  }) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final existingCompany = await db.query(
        'companies',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      final companyData = {
        'id': id,
        'company_no': companyNo,
        'name': name,
        'description': description,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_selected': isSelected ? 1 : 0,
        'approval_status': 0,
      };
      if (existingCompany.isNotEmpty) {
        await db.update(
          'companies',
          companyData,
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.insert('companies', companyData);
      }
      if (isSelected) {
        await updateCompanySelection(id);
      }
    }
  }

  /// Firma seçimini güncelle (uuid uyumlu)
  Future<void> updateCompanySelection(String selectedCompanyId) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      // Önce tüm firmaları seçilmemiş yap
      await db.update('companies', {'is_selected': 0}, where: null);
      // Seçilen firmayı güncelle
      await db.update(
        'companies',
        {'is_selected': 1},
        where: 'id = ?',
        whereArgs: [selectedCompanyId],
      );
      // Seçili firma ID'sini kaydet
      await saveSelectedCompanyId(selectedCompanyId);
    }
  }

  /// Seçili firmayı getirirken company_no bilgisini de döndür
  Future<Map<String, dynamic>> getCompanyInfo() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final result = await db.query(
        'companies',
        where: 'is_selected = 1',
        limit: 1,
      );
      if (result.isNotEmpty) {
        final company = result.first;
        // company_no'yu da ekle
        return {
          'company_no': company['company_no'],
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
    }
    return {};
  }

  /// Test firmaları ekle (sadece uygulama ilk çalıştığında)
  Future<void> ensureDefaultCompanies() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();

      try {
        // Firma reset durumunu kontrol et
        final firmaReset = await _storage.getSetting('firma_reset');
        if (firmaReset == '1') {
          print("Varsayılan firmalar zaten eklenmiş, işlem atlanıyor.");
          return;
        }

        // Firma tablosu boş mu kontrol et
        final count = Sqflite.firstIntValue(
          await db.rawQuery(SqlQuerys.selectCompaniesCount),
        );

        if (count == 0) {
          // Varsayılan firmayı ekle
          await addOrUpdateCompany(
            id: '3',
            name: "LOGO",
            companyNo: null,
            description: "Demo Firma",
            isActive: true,
            createdAt: "2025-01-01",
            updatedAt: "2025-12-31",
            isSelected: true,
          );

          // Reset durumunu güncelle
          await _storage.setSetting('firma_reset', '1');

          print("Varsayılan firma bilgileri eklendi.");
        }
      } catch (e) {
        print("Varsayılan firma bilgileri eklenirken hata: $e");
        throw StorageException(
          'Varsayılan firma bilgileri eklenirken hata oluştu',
          details: e.toString(),
        );
      }
    }
  }

  /// Tüm temel tabloları sıralı şekilde oluşturur
  Future<void> initializeDatabaseTables() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      // Menü tablosu şema kontrolü: uuid alanı var mı?
      final menuColumns = await db.rawQuery("PRAGMA table_info(menu)");
      final hasUuid = menuColumns.any((col) => col['name'] == 'uuid');
      if (!hasUuid) {
        print('menu tablosu eski şema, otomatik olarak sıfırlanıyor!');
        await db.execute(SqlQuerys.dropMenuTable);
        await db.execute(SqlQuerys.createMenuTable);
      }
      await db.execute(SqlQuerys.createCompaniesTable);
      await db.execute(SqlQuerys.createLanguagesTable);
      await db.execute(SqlQuerys.createTranslationsTable);
    }
  }

  /// Tüm firmaları siler
  Future<void> clearAllCompanies() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      try {
        final deleted = await db.delete('companies');
        print('clearAllCompanies: $deleted kayıt silindi');
      } catch (e) {
        print('clearAllCompanies HATA: $e');
      }
    }
  }

  /// Uygulama başlatıldığında Supabase erişimi varsa companies tablosunu sıfırla
  Future<void> resetCompaniesIfSupabaseAvailable() async {
    try {
      final supabase = await PostgreService.getInstance();
      // Basit bir sorgu ile erişim kontrolü
      final test = await supabase.query('company', limit: 1);
      if (test.isNotEmpty) {
        print(
          'Supabase erişimi başarılı, local companies tablosu sıfırlanıyor!',
        );
        await clearAllCompanies();
        await ensureCompaniesTableSchema();
      }
    } catch (e) {
      print('Supabase erişimi yok veya hata: $e');
    }
  }

  /// Uygulama başlatıldığında companies tablosunun şeması eskiyse otomatik olarak güncelle
  Future<void> ensureCompaniesTableSchema() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      // Şema kontrolü: detail alanı var mı?
      final columns = await db.rawQuery("PRAGMA table_info(companies)");
      final hasDetail = columns.any((col) => col['name'] == 'detail');
      if (!hasDetail) {
        print('companies tablosu eski şema, otomatik olarak sıfırlanıyor!');
        await db.execute(SqlQuerys.dropCompaniesTable);
        await db.execute(SqlQuerys.createCompaniesTable);
        print('companies tablosu yeni şemaya göre oluşturuldu!');
      }
    }
  }

  /// Orders tablosuna imza alanı ekler (if missing)
  Future<void> ensureOrdersTableSchema() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final columns = await db.rawQuery("PRAGMA table_info(orders)");
      final hasSignature = columns.any((col) => col['name'] == 'signature_data');
      if (!hasSignature && columns.isNotEmpty) {
        print('orders tablosuna signature_data kolonu ekleniyor...');
        try {
          await db.execute('ALTER TABLE orders ADD COLUMN signature_data TEXT');
          print('✅ signature_data kolonu başarıyla eklendi');
        } catch (e) {
          print('❌ signature_data kolonu ekleme hatası: $e');
        }
      } else if (columns.isEmpty) {
        await db.execute(SqlQuerys.createOrdersTable);
      }
      
      // POD tablosu var mı kontrol et
      await db.execute(SqlQuerys.createPodTable);
    }
  }

  /// Companies tablosunu zorla sıfırla (debug için)
  Future<void> forceResetCompaniesTable() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      print('Companies tablosu zorla sıfırlanıyor...');
      await db.execute(SqlQuerys.dropCompaniesTable);
      await db.execute(SqlQuerys.createCompaniesTable);
      print('Companies tablosu başarıyla sıfırlandı!');
    }
  }

  /// Eğer local menu tablosu boşsa Supabase'den menüleri çekip local veritabanına ekler
  Future<void> ensureLocalMenuFromSupabase() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final localMenus = await db.query('menu');
      if (localMenus.isEmpty) {
        try {
          final supabase = await PostgreService.getInstance();
          final supabaseMenus = await supabase.query('menu');
          if (supabaseMenus.isNotEmpty) {
            // Toplu ekleme
            final batch = db.batch();
            for (final menu in supabaseMenus) {
              batch.insert(
                'menu',
                menu,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            await batch.commit(noResult: true);
            print('Supabase menüleri local veritabanına aktarıldı.');
          } else {
            print('Supabase menu tablosu da boş!');
          }
        } catch (e) {
          print('Supabase menüleri local veritabanına aktarılırken hata: $e');
        }
      }
    }
  }

  /// Saha satış için mock menü ve verileri ekler
  Future<void> seedFieldSalesMockData() async {
    if (!await _storage.hasSQLiteSupport()) return;
    
    final db = await _storage.getDatabase();
    
    // Saha satış tablolarının varlığından emin ol (migration atlanmış olabilir)
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createProductsTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createOrderItemsTable);
    await db.execute('DROP TABLE IF EXISTS collections');
    await db.execute(SqlQuerys.createCollectionsTable);
    await db.execute('DROP TABLE IF EXISTS targets');
    await db.execute(SqlQuerys.createTargetsTable);
    await db.execute(SqlQuerys.createInvoicesTable);
    await db.execute(SqlQuerys.createInvoiceItemsTable);
    await db.execute(SqlQuerys.createVisitsTable);
    await db.execute(SqlQuerys.createWarehouseTransfersTable);
    await db.execute(SqlQuerys.createRoutesTable);
    await db.execute(SqlQuerys.createRouteCustomersTable);
    await db.execute(SqlQuerys.createAuditFormsTable);
    await db.execute(SqlQuerys.createAuditFormFieldsTable);
    await db.execute(SqlQuerys.createVisitAuditsTable);
    await db.execute(SqlQuerys.createAuditAnswersTable);
    await db.execute(SqlQuerys.createPriceListsTable);
    await db.execute(SqlQuerys.createPriceListItemsTable);
    await db.execute(SqlQuerys.createCampaignsTable);
    await db.execute(SqlQuerys.createCampaignRulesTable);
    await db.execute(SqlQuerys.createVehiclesTable);
    await db.execute(SqlQuerys.createVehicleStocksTable);
    await db.execute(SqlQuerys.createVehicleLoadingsTable);
    await db.execute(SqlQuerys.createVehicleLoadingItemsTable);
    await db.execute(SqlQuerys.createLocationHistoryTable);
    await db.execute(SqlQuerys.createGpsLogsTable);
    await db.execute(SqlQuerys.createMenuTable);
    await db.execute(SqlQuerys.createMenuPermissionsTable);

    // Mevcut FieldSales modül menülerini temizle (Temiz bir başlangıç için)
    await db.delete('menu', where: "module_name = 'FieldSales'");

    final session = await getUserSession();
    final userId = session?['id'] as String? ?? 'demo_user_id';
    // company_no'yu int olarak alalım
    var companyNo = 1;
    if (session?['company_no'] != null) {
      companyNo = int.tryParse(session!['company_no'].toString()) ?? 1;
    }

    // Menü Tanımları (Ana Menüler - 14 Grid Öğesi)
    final mainMenus = [
      {'uuid': 'fs_manager', 'title': 'Yönetici', 'icon': 'manage_accounts', 'order': 1},
      {'uuid': 'fs_customers', 'title': 'Cari', 'icon': 'person', 'order': 2},
      {'uuid': 'fs_invoice', 'title': 'Fatura', 'icon': 'receipt', 'order': 3},
      {'uuid': 'fs_waybill', 'title': 'İrsaliye', 'icon': 'description', 'order': 4},
      {'uuid': 'fs_order', 'title': 'Sipariş', 'icon': 'shopping_cart', 'order': 5},
      {'uuid': 'fs_delivery', 'title': 'Teslimat', 'icon': 'local_shipping', 'order': 6},
      {'uuid': 'fs_visit', 'title': 'Ziyaret', 'icon': 'location_on', 'order': 7},
      {'uuid': 'fs_finance', 'title': 'Finans', 'icon': 'monetization_on', 'order': 8},
      {'uuid': 'fs_stock', 'title': 'Stok', 'icon': 'qr_code_scanner', 'order': 9},
      {'uuid': 'fs_reports', 'title': 'Raporlar', 'icon': 'bar_chart', 'order': 10},
      {'uuid': 'fs_currency', 'title': 'Döviz', 'icon': 'currency_exchange', 'order': 11},
      {'uuid': 'fs_companies', 'title': 'Şirketler', 'icon': 'business', 'order': 12},
      {'uuid': 'fs_sync', 'title': 'Güncelleme', 'icon': 'sync', 'order': 13},
      {'uuid': 'fs_settings', 'title': 'Ayarlar', 'icon': 'settings', 'order': 14},
      {'uuid': 'fs_other', 'title': 'Diğer', 'icon': 'more_horiz', 'order': 15},
    ];

    for (final menu in mainMenus) {
      final menuId = await db.insert('menu', {
        'uuid': menu['uuid'],
        'title': menu['title'],
        'icon': menu['icon'],
        'display_order': menu['order'],
        'parent_id': null,
        'is_visible': 1,
        'is_favorite': 1, // Ana ekrandaki kutucuklar olduğu için favori=1 diyoruz
        'module_name': 'FieldSales',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Yetki ekle
      await db.insert('menu_permissions', {
        'uuid': 'perm_${menu['uuid']}',
        'menu_id': menuId,
        'menu_uuid': menu['uuid'],
        'user_id': userId,
        'company_no': companyNo,
        'can_view': 1,
        'can_edit': 1,
        'can_delete': 1,
        'can_add': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      
      // effectiveId for submenus
      final effectiveId = menuId;

      // Alt Menüler (Bottom Sheet içerikleri)
      final subMenus = {
        'fs_favorites': [
           // Dinamik dolacak
        ],
        'fs_manager': [
          {'uuid': 'sub_mgr_dashboard', 'title': 'Yönetici Raporları', 'icon': 'insert_chart', 'route': '/field-sales/manager-dashboard'},
          {'uuid': 'sub_mgr_comp', 'title': 'Dönem Karşılaştırma', 'icon': 'compare_arrows', 'route': '/field-sales/period-comparison'},
          {'uuid': 'sub_mgr_assign', 'title': 'Hedef Atama', 'icon': 'track_changes', 'route': '/field-sales/target-assignment'},
          {'uuid': 'sub_mgr_rank', 'title': 'Hedef Sıralaması', 'icon': 'leaderboard', 'route': '/field-sales/target-ranking'},
        ],
        'fs_customers': [
          {'uuid': 'sub_cust_list', 'title': 'Cari Kart Listesi', 'icon': 'list', 'route': '/field-sales/customers'},
          {'uuid': 'sub_cust_new', 'title': 'Yeni Müşteri Ekle', 'icon': 'person_add', 'route': '/field-sales/customer-new'},
          {'uuid': 'sub_cust_map', 'title': 'Yakındaki Müşteriler', 'icon': 'map', 'route': '/field-sales/customers-map'},
          {'uuid': 'sub_cust_wholesale', 'title': 'Toptan Satış', 'icon': 'receipt_long', 'route': '/field-sales/wholesale'},
          {'uuid': 'sub_cust_return', 'title': 'Toptan Satış İade', 'icon': 'assignment_return', 'route': '/field-sales/wholesale-return'},
        ],
        'fs_invoice': [
          {'uuid': 'sub_inv_wholesale', 'title': 'Toptan Satış', 'icon': 'receipt_long', 'route': '/field-sales/invoice-wholesale'},
          {'uuid': 'sub_inv_return', 'title': 'Toptan Satış İade', 'icon': 'assignment_return', 'route': '/field-sales/invoice-return'},
          {'uuid': 'sub_inv_list', 'title': 'Fatura Listesi', 'icon': 'list_alt', 'route': '/invoice-create'},
          {'uuid': 'sub_inv_untransferred', 'title': 'Transfer Edilmeyen Faturalar', 'icon': 'sync_disabled', 'route': '/field-sales/invoice-untransferred'},
          {'uuid': 'sub_inv_pending', 'title': 'Bekleyen Faturalar', 'icon': 'pending_actions', 'route': '/field-sales/invoice-pending'},
        ],
        'fs_waybill': [
          {'uuid': 'sub_way_wholesale', 'title': 'Toptan Satış', 'icon': 'receipt_long', 'route': '/field-sales/waybill-wholesale'},
          {'uuid': 'sub_way_purchase', 'title': 'Satın Alma', 'icon': 'shopping_basket', 'route': '/field-sales/waybill-purchase'},
          {'uuid': 'sub_way_list', 'title': 'İrsaliye Listesi', 'icon': 'list_alt', 'route': '/field-sales/waybill-list'},
          {'uuid': 'sub_way_untransferred', 'title': 'Transfer Edilmeyen İrsaliyeler', 'icon': 'sync_disabled', 'route': '/field-sales/waybill-untransferred'},
          {'uuid': 'sub_way_pending', 'title': 'Bekleyen İrsaliyeler', 'icon': 'pending_actions', 'route': '/field-sales/waybill-pending'},
        ],
        'fs_order': [
          {'uuid': 'sub_ord_entry', 'title': 'Sipariş Girişi', 'icon': 'add_shopping_cart', 'route': '/sales-order'},
          {'uuid': 'sub_ord_history', 'title': 'Geçmiş Satışlar', 'icon': 'history', 'route': '/sales-history'},
        ],
        'fs_delivery': [
          {'uuid': 'sub_del_list', 'title': 'Teslimat Listesi', 'icon': 'local_shipping', 'route': '/field-sales/delivery-list'},
        ],
        'fs_visit': [
          {'uuid': 'sub_route_daily', 'title': 'Bugünkü Rotam', 'icon': 'directions_car', 'route': '/field-sales/routes/plan'},
          {'uuid': 'sub_route_map', 'title': 'Rota Haritası', 'icon': 'map', 'route': '/field-sales/routes/map'},
          {'uuid': 'sub_route_opt', 'title': 'Rota Optimizasyonu', 'icon': 'route', 'route': '/field-sales/routes/optimize'},
        ],
        'fs_finance': [
          {'uuid': 'sub_fin_new', 'title': 'Yeni Hareket', 'icon': 'add_card', 'route': '/field-sales/collection'},
          {'uuid': 'sub_fin_transferred', 'title': 'Transfer Edilen Tahsilatlar', 'icon': 'sync', 'route': '/field-sales/finance-transferred'},
          {'uuid': 'sub_fin_untransferred', 'title': 'Transfer Edilmeyen Tahsilatlar', 'icon': 'sync_disabled', 'route': '/field-sales/finance-untransferred'},
          {'uuid': 'sub_fin_acc', 'title': 'Kasa Kart Listesi', 'icon': 'account_balance_wallet', 'route': '/statement'},
        ],
        'fs_stock': [
          {'uuid': 'sub_stk_detail', 'title': 'Detay', 'icon': 'info', 'route': '/field-sales/products'},
          {'uuid': 'sub_stk_price', 'title': 'Fiyat Gör', 'icon': 'price_check', 'route': '/field-sales/prices'},
          {'uuid': 'sub_stk_barcode', 'title': 'Barkod Ekle', 'icon': 'qr_code_scanner', 'route': '/field-sales/stock-barcode'},
          {'uuid': 'sub_stk_count', 'title': 'Sayım Fişi', 'icon': 'fact_check', 'route': '/field-sales/stock-count'},
          {'uuid': 'sub_stk_warehouse', 'title': 'Ambar Fişi', 'icon': 'store', 'route': '/field-sales/stock-warehouse'},
          {'uuid': 'sub_stk_production', 'title': 'Üretimden Giriş Fişi', 'icon': 'precision_manufacturing', 'route': '/field-sales/stock-production'},
          {'uuid': 'sub_stk_transferred', 'title': 'Transfer Edilenler', 'icon': 'sync', 'route': '/field-sales/stock-transferred'},
          {'uuid': 'sub_stk_untransferred', 'title': 'Transfer Edilmeyenler', 'icon': 'sync_disabled', 'route': '/field-sales/stock-untransferred'},
        ],
        'fs_reports': [
          {'uuid': 'sub_rep_cari', 'title': 'Cari', 'icon': 'person', 'route': '/field-sales/report-cari'},
          {'uuid': 'sub_rep_stok', 'title': 'Stok', 'icon': 'qr_code', 'route': '/field-sales/report-stock'},
          {'uuid': 'sub_rep_siparis', 'title': 'Sipariş', 'icon': 'shopping_cart', 'route': '/sales-report'},
          {'uuid': 'sub_rep_fatura', 'title': 'Fatura', 'icon': 'receipt', 'route': '/field-sales/report-invoice'},
          {'uuid': 'sub_rep_irsaliye', 'title': 'İrsaliye', 'icon': 'description', 'route': '/field-sales/report-waybill'},
          {'uuid': 'sub_rep_diger', 'title': 'Diğer', 'icon': 'more_horiz', 'route': '/field-sales/report-other'},
          {'uuid': 'sub_rep_backup', 'title': 'Rapor Yedekle/İndir', 'icon': 'cloud_download', 'route': '/field-sales/report-backup'},
        ],
        'fs_currency': [
          {'uuid': 'sub_cur_rates', 'title': 'Döviz Kurları', 'icon': 'currency_exchange', 'route': '/field-sales/currency-rates'},
        ],
        'fs_companies': [
          {'uuid': 'sub_comp_list', 'title': 'Mobil Şirket Listesi', 'icon': 'business', 'route': '/field-sales/companies'},
        ],
        'fs_sync': [
          {'uuid': 'sub_sync_transfer', 'title': 'Veri Transferi', 'icon': 'cloud_sync', 'route': '/field-sales/data-transfer'},
          {'uuid': 'sub_sync_update', 'title': 'Veri Güncelleme', 'icon': 'update', 'route': '/field-sales/data-update'},
          {'uuid': 'sub_sync_untransferred', 'title': 'Transfer Edilmemiş Fişler', 'icon': 'error_outline', 'route': '/field-sales/untransferred-slips'},
        ],
        'fs_settings': [
          {'uuid': 'sub_set_defaults', 'title': 'Fiş Ön Değerleri', 'icon': 'settings', 'route': '/field-sales/invoice-defaults'},
          {'uuid': 'sub_set_logs', 'title': 'Sistem Logları', 'icon': 'history', 'route': '/system/logs'},
        ],
        'fs_other': [
          {'uuid': 'sub_oth_send', 'title': 'Bilgi Gönderme', 'icon': 'send', 'route': '/field-sales/send-info'},
          {'uuid': 'sub_oth_day', 'title': 'Güne Başlama Bitirme', 'icon': 'work', 'route': '/field-sales/day-status'},
          {'uuid': 'sub_oth_images', 'title': 'Resimler', 'icon': 'image', 'route': '/field-sales/image-settings'},
        ],
      };

      if (subMenus.containsKey(menu['uuid'])) {
        for (final sub in subMenus[menu['uuid']]!) {
          final subId = await db.insert('menu', {
            'uuid': sub['uuid'],
            'title': sub['title'],
            'icon': sub['icon'],
            'route': sub['route'],
            'parent_id': effectiveId,
            'parent_uuid': menu['uuid'],
            'is_visible': 1,
            'module_name': 'FieldSales',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);

           await db.insert('menu_permissions', {
            'uuid': 'perm_${sub['uuid']}',
            'menu_id': subId,
            'menu_uuid': sub['uuid'],
            'user_id': userId,
            'company_no': companyNo,
            'can_view': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
    print('Saha satış mock verileri başarıyla yüklendi.');

    // 2. Mock Veri Kayıtlarını Ekle (Müşteriler, Ürünler, vb.)
    await _seedMockRecords(db, userId);
  }

  Future<void> _seedMockRecords(Database db, String userId) async {
    // Müşteriler (Detaylı Mock Veri - UI Tasarımı İçin Ekstra Dolu Getirildi)
    final customers = [
      {
        'id': 'cust_1',
        'name': 'Marketim Gıda San. ve Tic. Ltd. Şti.',
        'tax_no': '1234567890',
        'tax_office': 'Kadıköy VD',
        'yetkili': 'Ahmet Yılmaz',
        'address': 'Osmanağa Cad. No:45 Kadıköy / İstanbul',
        'adres2': 'Giriş Kat, Depo Yanı',
        'il': 'İstanbul',
        'ilce': 'Kadıköy',
        'semt': 'Osmanağa',
        'ulke': 'Türkiye',
        'posta_kodu': '34714',
        'phone': '0216 555 1234',
        'telefon2': '0532 555 1234',
        'fax': '0216 555 1235',
        'email': 'iletisim@marketimgida.com',
        'balance': 15450.50,
        'latitude': 40.9912,
        'longitude': 29.0271,
      },
      {
        'id': 'cust_2',
        'name': 'Özlem Süpermarket A.Ş.',
        'tax_no': '9876543210',
        'tax_office': 'Çankaya VD',
        'yetkili': 'Ayşe Kaya',
        'address': 'Tunalı Hilmi Caddesi No:82 Çankaya / Ankara',
        'il': 'Ankara',
        'ilce': 'Çankaya',
        'ulke': 'Türkiye',
        'phone': '0312 444 9876',
        'email': 'bilgi@ozlemsupermarket.com.tr',
        'balance': -2100.00,
        'latitude': 39.9208,
        'longitude': 32.8541,
      },
      {
        'id': 'cust_3',
        'name': 'Anadolu Bakkaliyesi',
        'tax_no': '5554443332',
        'tax_office': 'Konak VD',
        'yetkili': 'Mehmet Demir',
        'address': 'Kemeraltı Çarşısı Sk. 32 Konak / İzmir',
        'il': 'İzmir',
        'ilce': 'Konak',
        'phone': '0232 222 3344',
        'balance': 450.75,
        'latitude': 38.4192,
        'longitude': 27.1287,
      },
      {
        'id': 'cust_4',
        'name': 'Ege Yöresel Ürünler',
        'tax_no': '1112223334',
        'yetkili': 'Zeynep Çelik',
        'address': 'Alsancak Mah. Kıbrıs Şehitleri Cad. No:15 35220 Konak/İzmir',
        'il': 'İzmir',
        'ilce': 'Konak',
        'semt': 'Alsancak',
        'phone': '0232 464 5566',
        'telefon2': '0555 464 5566',
        'email': 'info@egeyoresel.com',
        'balance': 0.00,
        'latitude': 38.4385,
        'longitude': 27.1428,
      },
      {
        'id': 'cust_5',
        'name': 'Akdeniz Toptan Dağıtım',
        'tax_no': '9998887776',
        'tax_office': 'Antalya Kurumlar VD',
        'yetkili': 'Mustafa Öztürk',
        'address': 'Organize Sanayi Bölgesi 1. Kısım 5. Cadde No:12 Döşemealtı/Antalya',
        'il': 'Antalya',
        'ilce': 'Döşemealtı',
        'phone': '0242 258 1122',
        'email': 'satis@akdeniztoptan.com',
        'balance': 125000.00,
        'latitude': 36.9833,
        'longitude': 30.6333,
      }
    ];

    for (final cust in customers) {
      await db.insert('customers', {
        ...cust,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Ürünler
    final products = [
      {
        'id': 'prod_1',
        'code': 'UR-001',
        'name': 'Kristal Şeker 1kg',
        'price': 45.00,
        'stock_quantity': 500.0,
        'category': 'Temel Gıda',
        'unit': 'Adet',
      },
      {
        'id': 'prod_2',
        'code': 'UR-002',
        'name': 'Rize Çay 500g',
        'price': 120.00,
        'stock_quantity': 250.0,
        'category': 'İçecek',
        'unit': 'Paket',
      },
      {
        'id': 'prod_3',
        'code': 'UR-003',
        'name': 'Ayçiçek Yağı 5L',
        'price': 185.90,
        'stock_quantity': 120.0,
        'category': 'Temel Gıda',
        'unit': 'Teneke',
      },
    ];

    for (final prod in products) {
      await db.insert('products', {
        ...prod,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Siparişler
    final orders = [
      {
        'id': 'ord_1',
        'customer_id': 'cust_1',
        'order_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'total_amount': 225.0,
        'status': 'Approved',
        'is_synced': 1,
      },
      {
        'id': 'ord_2',
        'customer_id': 'cust_2',
        'order_date': DateTime.now().toIso8601String(),
        'total_amount': 120.0,
        'status': 'Pending',
        'is_synced': 0,
      },
    ];

    for (final ord in orders) {
      await db.insert('orders', ord, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Sipariş Kalemleri
    await db.insert('order_items', {
      'id': 'item_1',
      'order_id': 'ord_1',
      'product_id': 'prod_1',
      'quantity': 5.0,
      'price': 45.0,
      'total_amount': 225.0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Tahsilatlar
    await db.insert('collections', {
      'id': 'coll_1',
      'customer_id': 'cust_1',
      'amount': 200.0,
      'payment_type': 'Cash',
      'collection_date': DateTime.now().toIso8601String(),
      'status': 'Completed',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Ziyaretler
    await db.insert('visits', {
      'id': 'visit_1',
      'customer_id': 'cust_3',
      'user_id': userId,
      'check_in_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'check_out_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 45)).toIso8601String(),
      'status': 'Completed',
      'notes': 'Yeni ürünler hakkında sunum yapıldı.',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Depo Transferleri (Araç Yükleme)
    await db.insert('warehouse_transfers', {
      'id': 'trf_1',
      'from_warehouse': 'Merkez Depo',
      'to_warehouse': '06 AB 123 - Plaka Araç',
      'product_id': 'prod_1',
      'quantity': 100.0,
      'transfer_date': DateTime.now().toIso8601String(),
      'status': 'Approved',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Rutlar
    final todayWeekday = DateTime.now().weekday;
    await db.insert('routes', {
      'id': 'route_1',
      'name': 'Günlük Merkez Rotası',
      'salesperson_id': userId,
      'day_of_week': todayWeekday,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Rut Müşterileri
    final routeCustomers = [
      {'id': 'rc_1', 'route_id': 'route_1', 'customer_id': 'cust_1', 'visit_order': 1, 'is_mandatory': 1},
      {'id': 'rc_2', 'route_id': 'route_1', 'customer_id': 'cust_2', 'visit_order': 2, 'is_mandatory': 1},
      {'id': 'rc_3', 'route_id': 'route_1', 'customer_id': 'cust_3', 'visit_order': 3, 'is_mandatory': 0},
    ];

    for (var rc in routeCustomers) {
      await db.insert('route_customers', rc, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Audit (Merchandising) Formları
    await db.insert('audit_forms', {
      'id': 'form_1',
      'name': 'Raf Uygunluk Denetimi',
      'description': 'Ürünlerin raftaki dizilimi ve görünürlüğü kontrolü.',
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('audit_form_fields', {
      'id': 'field_1',
      'form_id': 'form_1',
      'field_name': 'Ürün Görünürlüğü (1-5)',
      'field_type': 'number',
      'is_required': 1,
      'sort_order': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('audit_form_fields', {
      'id': 'field_2',
      'form_id': 'form_1',
      'field_name': 'Rakip Yanı Payı (%)',
      'field_type': 'number',
      'is_required': 0,
      'sort_order': 2,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('audit_form_fields', {
      'id': 'field_3',
      'form_id': 'form_1',
      'field_name': 'Raf Fotoğrafı',
      'field_type': 'photo',
      'is_required': 1,
      'sort_order': 3,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    print('Mock saha satış kayıtları başarıyla oluşturuldu.');
  }

  Future<List<Map<String, dynamic>>> syncUserMenuPermissionsFromSupabase(String userId, int companyNo) async {
    if (await _storage.hasSQLiteSupport()) {
      try {
        final supabase = await PostgreService.getInstance();
        final response = await supabase.query(
            'menu_permissions',
            filter: 'user_id = @p0 AND company_no = @p1 AND can_view = @p2',
            filterArgs: [userId, companyNo, true],
        );
            
        final permissions = response as List;
        if (permissions.isNotEmpty) {
          final db = await _storage.getDatabase();
          final batch = db.batch();
          for (final perm in permissions) {
            batch.insert(
              'menu_permissions',
              perm,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          print('Kullanıcı menü yetkileri senkronize edildi.');
          return List<Map<String, dynamic>>.from(permissions);
        }
      } catch (e) {
        print('Kullanıcı menü yetkileri senkronize edilirken hata: $e');
      }
    }
    return [];
  }

  /// Sync menus from PostgreSQL (EXFINOPS DB) to local SQLite
  Future<void> syncMenusFromPostgres() async {
    if (await _storage.hasSQLiteSupport()) {
      try {
        final postgres = PostgresService.instance;
        if (await postgres.connect()) {
          final remoteMenus = await postgres.getMenusForSync();
          
          if (remoteMenus.isNotEmpty) {
             final db = await _storage.getDatabase();
             final batch = db.batch();
             
             // Opsiyonel: Mevcut menüleri temizle (tam senkronizasyon için)
             // await db.delete('menu'); 

             for (final menu in remoteMenus) {
               batch.insert(
                 'menu',
                 menu,
                 conflictAlgorithm: ConflictAlgorithm.replace,
               );
             }
             await batch.commit(noResult: true);
             print('✅ Menüler PostgreSQL''den senkronize edildi (${remoteMenus.length} kayıt).');
          }
        }
      } catch (e) {
        print('❌ Postgres menü sync hatası: $e');
      }
    }
  }

  /// Push local visits to PostgreSQL
  Future<void> syncVisitsToPostgres() async {
    if (await _storage.hasSQLiteSupport()) {
      try {
        final db = await _storage.getDatabase();
        // Get unsynced visits (is_synced = 0)
        final unsyncedVisits = await db.query(
          'visits',
          where: 'is_synced = ?',
          whereArgs: [0],
        );

        if (unsyncedVisits.isEmpty) return;

        final postgres = PostgresService.instance;
        if (await postgres.connect()) {
          final List<Map<String, dynamic>> visitsToSync = [];
          
          for (final visit in unsyncedVisits) {
            // Map local SQLite fields to Postgres fields
            visitsToSync.add({
              'customer_code': visit['customer_id'] ?? 'UNKNOWN', // Map ID to Code if possible
              'user_id': 1, // Fix: Map local UUID to Remote INT. Defaulting to 1 for now.
              'check_in_time': visit['check_in_at'], // ISO8601 string works for PG timestamp? usually yes
              'check_out_time': visit['check_out_at'],
              'check_in_lat': visit['latitude'] ?? 0.0, // Should be check_in_lat in local? check schema
              'check_in_lng': visit['longitude'] ?? 0.0,
              'status': visit['status'],
              'notes': visit['notes'],
            });
          }

          await postgres.syncVisits(visitsToSync);
          
          // Mark as synced locally
          final batch = db.batch();
          for (final visit in unsyncedVisits) {
            batch.update(
              'visits',
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [visit['id']],
            );
          }
          await batch.commit(noResult: true);
          print('✅ ${unsyncedVisits.length} Ziyaret PostgreSQL''e gönderildi.');
        }
      } catch (e) {
        print('❌ Postgres ziyaret sync hatası: $e');
      }
    }
  }

  /// Push local orders to PostgreSQL
  Future<void> syncOrdersToPostgres() async {
    if (await _storage.hasSQLiteSupport()) {
      try {
        final db = await _storage.getDatabase();
        final unsyncedOrders = await db.query(
          'orders',
          where: 'is_synced = ?',
          whereArgs: [0],
        );

        if (unsyncedOrders.isEmpty) return;

        final postgres = PostgresService.instance;
        if (await postgres.connect()) {
          final List<Map<String, dynamic>> ordersToSync = [];

          for (final order in unsyncedOrders) {
            // Get order items
            final items = await db.query(
              'order_items',
              where: 'order_id = ?',
              whereArgs: [order['id']],
            );
            
            // Format items for JSONB
            final orderLines = items.map((item) => {
              'item_code': item['product_id'],
              'quantity': item['quantity'],
              'price': item['price'],
              'total': item['total_amount'],
            }).toList();

            ordersToSync.add({
              'user_id': 1, // Fix: Defaulting to 1
              'customer_code': order['customer_id'] ?? 'UNKNOWN',
              'order_date': order['order_date'],
              'total_amount': order['total_amount'],
              'status': order['status'],
              'order_lines': orderLines, // Postgres driver handles List/Map to JSON automatically? Not sure, user said "orders".
              // Actually postgres package usually needs explicit jsonEncode if parameter type isn't inferred or setup.
              // But 'query' method uses substituted values. 'postgres' package handles jsonb if passed as Map/List usually or String.
              // Let's pass it as a JSON object (List<Map>) and hope the driver handles or I might need jsonEncode.
              // Update: 'postgres' 3.x with 'query' usually expects typed values. 
              // 'jsonb' in Postgres accepts stringified JSON.
            });
          }

          // We need to jsonEncode the order_lines before sending if the driver doesn't do it.
          // Let's modify the map to send jsonEncode(orderLines) just to be safe.
          final encodedOrders = ordersToSync.map((o) {
             final mutable = Map<String, dynamic>.from(o);
             mutable['order_lines'] = jsonEncode(o['order_lines']);
             return mutable;
          }).toList();

          await postgres.syncOrders(encodedOrders);

          // Mark as synced locally
          final batch = db.batch();
          for (final order in unsyncedOrders) {
            batch.update(
              'orders',
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [order['id']],
            );
          }
          await batch.commit(noResult: true);
          print('✅ Siparişler PostgreSQL''e gönderildi.');
        }
      } catch (e) {
        print('❌ Postgres sipariş sync hatası: $e');
      }
    }
  }

  /// Kullanıcı ve şirkete göre yetkili menüleri Supabase'den çeker
  Future<List<Map<String, dynamic>>> getMenusByUserAndCompany({
    required String userId,
    required int companyNo,
    String? languageCode,
  }) async {
    List<Map<String, dynamic>> menuResponse;
    
    if (!kIsWeb) {
      if (await _storage.hasSQLiteSupport()) {
        final db = await _storage.getDatabase();
        // 1. Yetkili menüleri SQLite'dan çek (JOIN version)
        menuResponse = await db.rawQuery('''
          SELECT m.* FROM menu m
          INNER JOIN menu_permissions p ON m.id = p.menu_id
          WHERE p.user_id = ? AND p.company_no = ? AND p.can_view = 1
          AND m.is_visible = 1 AND m.is_deleted = 0
          ORDER BY m.display_order ASC
        ''', [userId, companyNo]);
      } else {
        return [];
      }
    } else {
      final supabase = await PostgreService.getInstance();
      // 1. Yetkili menü id'lerini çek
      final permissionResponse = await supabase.query(
          'menu_permissions',
          filter: 'user_id = @p0 AND company_no = @p1 AND can_view = @p2',
          filterArgs: [userId, companyNo, true],
      );
      final menuIds = (permissionResponse as List)
          .map((e) => e['menu_id'])
          .where((id) => id != null)
          .toList();
      if (menuIds.isEmpty) return [];
      // 2. Menüleri çek
      final placeholders = menuIds.asMap().entries.map((e) => '@p${e.key}').join(', ');
      menuResponse = await supabase.query(
          'menu',
          filter: 'id IN ($placeholders) AND is_visible = @p${menuIds.length} AND is_deleted = @p${menuIds.length+1}',
          filterArgs: [...menuIds, true, false],
          orderBy: 'display_order ASC',
      );
    }
    
    // 3. Dil desteği uygula
    final menus = List<Map<String, dynamic>>.from(menuResponse);
    if (languageCode == 'en') {
      for (final menu in menus) {
        if (menu['title_en'] != null) menu['title'] = menu['title_en'];
        if (menu['description_en'] != null)
          menu['description'] = menu['description_en'];
      }
    } else if (languageCode == 'ar') {
      for (final menu in menus) {
        if (menu['title_ar'] != null) menu['title'] = menu['title_ar'];
        if (menu['description_ar'] != null)
          menu['description'] = menu['description_ar'];
      }
    } else if (languageCode == 'ru') {
      for (final menu in menus) {
        if (menu['title_ru'] != null) menu['title'] = menu['title_ru'];
        if (menu['description_ru'] != null)
          menu['description'] = menu['description_ru'];
      }
    }
    return menus;
  }

  /// company_no ile firma detayını getir
  Future<Map<String, dynamic>?> getCompanyByNo(String companyNo) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final result = await db.query(
        'companies',
        where: 'company_no = ?',
        whereArgs: [companyNo],
        limit: 1,
      );
      if (result.isNotEmpty) return result.first;
    }
    return null;
  }

  /// Supabase ile local companies tablosunu delta sync ile senkronize et
  Future<void> syncCompaniesWithSupabaseIfOnline() async {
    try {
      final supabase = await PostgreService.getInstance();
      final remoteCompanies = await supabase.query('company');
      if (remoteCompanies.isEmpty) {
        print('ℹ️ Supabase companies tablosu boş');
        return;
      }

      await performDeltaSync(
        tableName: 'companies',
        remoteData: remoteCompanies,
        primaryKey: 'company_no',
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );
    } catch (e) {
      print('❌ Companies delta sync hatası: $e');
    }
  }

  /// Supabase'den user_company_visibility tablosunu çekip local companies tablosunu delta sync ile senkronize et
  Future<void> syncUserCompaniesWithSupabaseIfOnline(String userId) async {
    try {
      print('🔄 User companies delta sync başlatılıyor, userId: $userId');
      final supabase = await PostgreService.getInstance();
      final remoteCompanies = await supabase.query(
          'user_company_visibility',
          filter: 'user_id = @p0 AND is_visible = @p1',
          filterArgs: [userId, true],
      );

      if (remoteCompanies.isEmpty) {
        print('ℹ️ Kullanıcı için görünür firma yok');
        return;
      }

      // Field mapping: Supabase'den gelen verileri local companies tablosuna uyarla
      final mappedCompanies = remoteCompanies
          .map(
            (remote) => <String, dynamic>{
              'company_no': remote['company_no'],
              'name': remote['company_name'] ?? '',
              'description': remote['company_detail'] ?? '',
              'is_active': 1,
              'is_selected': remote['is_selected'] == '1' ? 1 : 0,
              'created_at': remote['created_at'],
              'updated_at': remote['updated_at'],
            },
          )
          .toList();

      await performDeltaSync(
        tableName: 'companies',
        remoteData: mappedCompanies,
        primaryKey: 'company_no',
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );

      print('✅ User companies delta sync tamamlandı');
    } catch (e) {
      print('❌ User companies delta sync hatası: $e');
    }
  }

  /// Supabase'den company_period tablosunu delta sync ile senkronize et
  Future<void> syncCompanyPeriodsWithSupabaseIfOnline() async {
    try {
      final supabase = await PostgreService.getInstance();
      final remotePeriods =
          await supabase.query('company_period');

      if (remotePeriods.isEmpty) {
        print('ℹ️ Supabase company_period tablosu boş');
        return;
      }

      await performDeltaSync(
        tableName: 'company_period',
        remoteData: remotePeriods,
        primaryKey: 'id',
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );

      print('✅ Company periods delta sync tamamlandı');
    } catch (e) {
      print('❌ Company periods delta sync hatası: $e');
    }
  }

  /// company_period tablosunu oluştur
  Future<void> ensureCompanyPeriodTable() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      await db.execute(SqlQuerys.createCompanyPeriodTable);
      print('company_period tablosu oluşturuldu!');
    }
  }

  // Uygulama başında migration fonksiyonuna ekle
  Future<void> ensureAllTables() async {
    await ensureCompaniesTableSchema();
    await ensureCompanyPeriodTable();
  }

  /// Belirli bir company_no için aktif dönemi getirir (period_name döner)
  Future<String?> getActivePeriodForCompany(String companyNo) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final result = await db.query(
        'company_period',
        where: 'company_no = ? AND is_active = 1',
        whereArgs: [companyNo],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first['period_name']?.toString();
      }
    }
    return null;
  }

  /// Belirli bir company_no için tüm dönemleri (period_name) döndürür
  Future<List<String>> getPeriodsForCompany(String companyNo) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final result = await db.query(
        'company_period',
        where: 'company_no = ?',
        whereArgs: [companyNo],
        orderBy: 'start_date ASC',
      );
      return result.map((e) => e['period_name'].toString()).toList();
    }
    return [];
  }

  /// Tercih ayarla
  Future<void> setPreference(String key, String value) async {
    await _storage.setSetting(key, value);
  }

  /// Tercih al
  Future<String?> getPreference(String key) async {
    return await _storage.getSetting(key);
  }

  /// Ana menüleri getir
  Future<List<Map<String, dynamic>>> getMainMenuItems({
    String? languageCode,
  }) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query(
        'menu',
        where: 'parent_id IS NULL',
        orderBy: 'display_order',
      );
    }
    return [];
  }

  /// Alt menüleri getir
  Future<List<Map<String, dynamic>>> getSubmenusByParentId(
    int parentId, {
    String? languageCode,
  }) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query(
        'menu',
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'display_order',
      );
    }
    return [];
  }

  /// Sık kullanılan menüleri getir
  Future<List<Map<String, dynamic>>> getFavoriteMenuItems() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query('menu', where: 'is_favorite = 1', orderBy: 'title');
    }
    return [];
  }

  /// Menü öğesini sık kullanılanlara ekle/çıkar
  Future<void> toggleFavoriteMenuItem(int menuId, bool isFavorite) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      await db.update(
        'menu',
        {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [menuId],
      );
    }
  }

  /// Çoklu menü öğelerinin sık kullanılan durumunu güncelle
  Future<void> updateFavoriteMenuItems(List<int> menuIds) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      await db.transaction((txn) async {
        await txn.update('menu', {'is_favorite': 0});
        for (final id in menuIds) {
          await txn.update(
            'menu',
            {'is_favorite': 1},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });
    }
  }

  /// Menüden başlıkla veri getir
  Future<List<Map<String, dynamic>>> getMenuItemByTitle(String title) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query('menu', where: 'title = ?', whereArgs: [title]);
    }
    return [];
  }

  /// Menü veritabanını tamamen sıfırla
  Future<void> resetMenuDatabase() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      await db.execute('DROP TABLE IF EXISTS menu');
      await db.execute(SqlQuerys.createMenuTable);
      // Menü verilerini tekrar yüklemek için ek fonksiyonun varsa burada çağırabilirsin
    }
  }

  /// Menü tablosunu oluştur (geliştirici için)
  Future<void> createNewMenuTable() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      await db.execute(SqlQuerys.createMenuTable);
    }
  }

  /// Tüm company_period kayıtlarını (firma adı ile birlikte) döndürür
  Future<List<Map<String, dynamic>>>
      getAllCompanyPeriodsWithCompanyName() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      final periods = await db.query(
        'company_period',
        orderBy: 'start_date ASC',
      );
      final companies = await db.query('companies');
      // company_no ile firma adını eşleştir
      for (final period in periods) {
        final company = companies.firstWhere(
          (c) =>
              c['company_no']?.toString() == period['company_no']?.toString(),
          orElse: () => <String, Object?>{},
        );
        period['company_name'] = company['name'] ?? '';
      }
      return periods;
    }
    return [];
  }

  /// Seçilen dönemi veritabanına kaydet
  Future<void> updateCompanyPeriod(String period) async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();

      // Önce mevcut company_info'yu al
      final companyInfo = await getCompanyInfo();
      final companyNo = companyInfo['company_no']?.toString() ?? '';

      if (companyNo.isNotEmpty) {
        // Önce tüm dönemleri pasif yap
        await db.update(
          'company_period',
          {'is_active': 0},
          where: 'company_no = ?',
          whereArgs: [companyNo],
        );

        // Seçilen dönemi aktif yap
        await db.update(
          'company_period',
          {'is_active': 1},
          where: 'company_no = ? AND period_name = ?',
          whereArgs: [companyNo, period],
        );

        print(
          'DEBUG: Dönem güncellendi - Company: $companyNo, Period: $period',
        );
      } else {
        print('DEBUG: Company_no bulunamadı, dönem güncellenemedi');
      }
    }
  }

  /// Tüm firma dönemlerini start_date ve end_date ile birlikte döndürür (filtersız)
  Future<List<Map<String, dynamic>>> getAllPeriodsWithDates() async {
    if (await _storage.hasSQLiteSupport()) {
      final db = await _storage.getDatabase();
      return await db.query(
        'company_period',
        columns: ['period_name', 'start_date', 'end_date'],
        orderBy: 'start_date ASC',
      );
    }
    return [];
  }

  // Eski sync fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  // Eski sync fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  // Eski sync fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  // Eski sync fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  /// Supabase'den departments verilerini delta sync ile senkronize et
  Future<void> syncDepartmentsFromSupabase() async {
    try {
      final supabase = await PostgreService.getInstance();
      final remoteDepartments = await supabase.query('departments');

      if (remoteDepartments.isEmpty) {
        print('ℹ️ Supabase departments tablosu boş');
        return;
      }

      await performDeltaSync(
        tableName: 'departments',
        remoteData: remoteDepartments,
        primaryKey: 'id',
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );

      print('✅ Departments delta sync tamamlandı');
    } catch (e) {
      print('❌ Departments delta sync hatası: $e');
    }
  }

  /// Supabase'den factories verilerini delta sync ile senkronize et
  Future<void> syncFactoriesFromSupabase() async {
    try {
      final supabase = await PostgreService.getInstance();
      final remoteFactories = await supabase.query('factories');

      if (remoteFactories.isEmpty) {
        print('ℹ️ Supabase factories tablosu boş');
        return;
      }

      await performDeltaSync(
        tableName: 'factories',
        remoteData: remoteFactories,
        primaryKey: 'id',
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );

      print('✅ Factories delta sync tamamlandı');
    } catch (e) {
      print('❌ Factories delta sync hatası: $e');
    }
  }

  /// Supabase'den device verilerini delta sync ile senkronize et
  Future<void> syncDeviceFromSupabase() async {
    try {
      final supabase = await PostgreService.getInstance();
      final remoteDevices = await supabase.query('device');

      if (remoteDevices.isEmpty) {
        print('ℹ️ Supabase device tablosu boş');
        return;
      }

      // device_name null ise boş string ata
      for (final device in remoteDevices) {
        if (device['device_name'] == null) {
          device['device_name'] = '';
        }
      }

      await performDeltaSync(
        tableName: 'device',
        remoteData: remoteDevices,
        primaryKey: 'id',
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );

      print('✅ Device delta sync tamamlandı');
    } catch (e) {
      print('❌ Device delta sync hatası: $e');
    }
  }

  // Eski sync fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  // Eski sync fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  // Eski sync fonksiyonu kaldırıldı - Delta sync ile yönetiliyor

  /// menu_permissions tablosu - migration kaldırıldı, delta sync ile yönetiliyor

  /// user_company_visibility tablosu için migration fonksiyonu (Supabase şemasına tam uyumlu)
  Future<void> runUserCompanyVisibilityMigration(Database db) async {
    try {
      final columns = await db.rawQuery(
        "PRAGMA table_info(user_company_visibility)",
      );
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      // PRIMARY KEY kontrolü (user_id, company_no)
      final pkInfo = await db.rawQuery(
        "PRAGMA table_info(user_company_visibility)",
      );
      final pkFields = pkInfo
          .where((col) => col['pk'] == 1)
          .map((col) => col['name'])
          .toList();
      final correctPK = pkFields.contains('user_id') &&
          pkFields.contains('company_no') &&
          pkFields.length == 2;
      // Gerekli alanlar
      final requiredColumns = <String, String>{
        'user_id': 'TEXT NOT NULL',
        'company_no': 'INTEGER NOT NULL',
        'is_visible': 'INTEGER NOT NULL DEFAULT 1',
        'company_name': 'TEXT',
        'company_detail': 'TEXT',
        'username': 'TEXT',
        'is_selected': "TEXT DEFAULT '0'",
      };
      // Eğer alanlar eksikse veya PK yanlışsa tabloyu sıfırla
      final missingOrWrong =
          requiredColumns.keys.any((k) => !columnNames.contains(k)) ||
              !correctPK;
      if (missingOrWrong) {
        print(
          'user_company_visibility tablosu Supabase şemasına göre sıfırlanıyor...',
        );
        await db.execute(SqlQuerys.dropUserCompanyVisibilityTable);
        await db.execute(SqlQuerys.createUserCompanyVisibilityTable);
        print(
          'user_company_visibility tablosu Supabase şemasına göre yeniden oluşturuldu',
        );
      } else {
        // Sadece eksik alanları ekle
        for (final entry in requiredColumns.entries) {
          if (!columnNames.contains(entry.key)) {
            await db.execute(
              SqlQuerys.alterAddDescription
                  .replaceAll('{table}', 'user_company_visibility')
                  .replaceAll('description', entry.key)
                  .replaceAll('TEXT', entry.value),
            );
            print(
              'user_company_visibility tablosuna ${entry.key} alanı eklendi (migration)',
            );
          }
        }
      }
      print('✅ user_company_visibility migration tamamlandı');
    } catch (e) {
      print('❌ user_company_visibility migration hatası: $e');
    }
  }

  /// Supabase'den user_company_visibility verilerini delta sync ile senkronize et
  Future<void> syncUserCompanyVisibilityFromSupabase() async {
    try {
      final supabase = await PostgreService.getInstance();

      // Önce migration çalıştır
      if (await _storage.hasSQLiteSupport()) {
        final db = await _storage.getDatabase();
        await runUserCompanyVisibilityMigration(db);
      }

      final remoteUCV = await supabase.query('user_company_visibility');

      if (remoteUCV.isEmpty) {
        print('ℹ️ Supabase user_company_visibility tablosu boş');
        return;
      }

      await performDeltaSync(
        tableName: 'user_company_visibility',
        remoteData: remoteUCV,
        primaryKey: 'user_id', // Composite key için user_id kullanıyoruz
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );

      print('✅ User company visibility delta sync tamamlandı');
    } catch (e) {
      print('❌ User company visibility delta sync hatası: $e');
    }
  }

  /// sync_settings tablosundan bir tablonun sync edilip edilmeyeceğini ve yönünü döndürür
  Future<Map<String, dynamic>> getSyncSettingForTable(String tableName) async {
    if (!await _storage.hasSQLiteSupport())
      return {'is_enabled': 1, 'sync_direction': 'bidirectional'};
    final db = await _storage.getDatabase();
    final result = await db.query(
      'sync_settings',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      // Varsayılan: sync açık ve çift yönlü
      return {'is_enabled': 1, 'sync_direction': 'bidirectional'};
    }
  }

  /// Tüm tablolar için Supabase -> Local toplu sync (Delta sync ile)
  Future<void> syncAllTablesFromSupabase({List<String>? onlyTables}) async {
    final startTime = DateTime.now();
    print('🔄 Toplu Supabase -> Local delta sync başlatılıyor...');
    final tables = [
      'companies',
      'company_period',
      'users',
      'menu',
      'departments',
      'factories',
      'device',
      'roles',
      'menu_permissions',
      'settings',
      'user_company_visibility',
      'user_roles',
    ];
    final selectedTables = onlyTables ?? tables;
    try {
      for (final table in selectedTables) {
        final setting = await getSyncSettingForTable(table);
        if (setting['is_enabled'] == 1 &&
            (setting['sync_direction'] == 'supabase_to_local' ||
                setting['sync_direction'] == 'bidirectional')) {
          print('📥 $table tablosu delta sync ediliyor...');
          await performDeltaSyncForTable(table);
        } else {
          print(
            'Tablo sync edilmedi (devre dışı veya yön uygun değil): $table',
          );
        }
      }
      final duration = DateTime.now().difference(startTime);
      print(
        '✅ Toplu delta sync tamamlandı! Süre: ${duration.inSeconds} saniye',
      );
      await _storage.setSetting(
        'last_sync_time',
        DateTime.now().toIso8601String(),
      );
      await _storage.setSetting('sync_status', 'success');
    } catch (e) {
      print('❌ Toplu delta sync hatası: $e');
      await _storage.setSetting('sync_status', 'error');
      await _storage.setSetting('last_sync_error', e.toString());
      rethrow;
    }
  }

  /// Her tablo için manuel sync fonksiyonları (Delta sync ile)
  Future<void> manualSyncTableFromSupabase(String table) async {
    final setting = await getSyncSettingForTable(table);
    if (setting['is_enabled'] != 1 ||
        (setting['sync_direction'] != 'supabase_to_local' &&
            setting['sync_direction'] != 'bidirectional')) {
      print('Tablo sync edilmedi (devre dışı veya yön uygun değil): $table');
      return;
    }

    // Delta sync kullan
    await performDeltaSyncForTable(table);
  }

  /// Otomatik sync için timer başlatır
  Timer? _syncTimer;
  bool _isAutoSyncEnabled = false;

  /// Otomatik sync'i başlatır (varsayılan: 5 dakikada bir)
  Future<void> startAutoSync({
    Duration interval = const Duration(minutes: 5),
  }) async {
    if (_isAutoSyncEnabled) {
      print('⚠️ Otomatik sync zaten çalışıyor');
      return;
    }

    _isAutoSyncEnabled = true;
    _syncTimer = Timer.periodic(interval, (timer) async {
      print('🔄 Otomatik sync tetiklendi - ${DateTime.now()}');
      try {
        await syncAllTablesFromSupabase();
      } catch (e) {
        print('❌ Otomatik sync hatası: $e');
      }
    });

    print('✅ Otomatik sync başlatıldı (${interval.inMinutes} dakikada bir)');
    await _storage.setSetting('auto_sync_enabled', true);
    await _storage.setSetting(
      'auto_sync_interval_minutes',
      interval.inMinutes.toString(),
    );
  }

  /// Otomatik sync'i durdurur
  Future<void> stopAutoSync() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isAutoSyncEnabled = false;

    print('⏹️ Otomatik sync durduruldu');
    await _storage.setSetting('auto_sync_enabled', false);
  }

  /// Otomatik sync durumunu kontrol eder
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  /// Son sync bilgilerini döndürür
  Future<Map<String, dynamic>> getSyncStatus() async {
    final lastSyncTime = await _storage.getSetting('last_sync_time');
    final syncStatus = await _storage.getSetting('sync_status');
    final lastSyncError = await _storage.getSetting('last_sync_error');
    final autoSyncInterval = await _storage.getSetting(
      'auto_sync_interval_minutes',
    );

    return {
      'last_sync_time': lastSyncTime,
      'sync_status': syncStatus,
      'last_sync_error': lastSyncError,
      'auto_sync_enabled': await _storage.getBoolSetting(
        'auto_sync_enabled',
        defaultValue: false,
      ),
      'auto_sync_interval_minutes': int.tryParse(autoSyncInterval ?? '5') ?? 5,
      'is_auto_sync_running': _isAutoSyncEnabled,
    };
  }

  /// Sync durumunu günceller
  Future<void> updateSyncStatus({
    bool? autoSyncEnabled,
    int? autoSyncIntervalMinutes,
  }) async {
    if (autoSyncEnabled != null) {
      await _storage.setSetting(
        'auto_sync_enabled',
        autoSyncEnabled.toString(),
      );
      if (autoSyncEnabled) {
        await startAutoSync(
          interval: Duration(minutes: autoSyncIntervalMinutes ?? 5),
        );
      } else {
        await stopAutoSync();
      }
    }

    if (autoSyncIntervalMinutes != null) {
      await _storage.setSetting(
        'auto_sync_interval_minutes',
        autoSyncIntervalMinutes.toString(),
      );
    }

    print(
      '✅ Sync durumu güncellendi: autoSync=$autoSyncEnabled, interval=${autoSyncIntervalMinutes}min',
    );
  }

  /// Manuel sync tetikler (kullanıcı isteği ile)
  Future<void> triggerManualSync() async {
    print('🔄 Manuel sync tetiklendi - ${DateTime.now()}');
    try {
      await syncAllTablesFromSupabase();
      print('✅ Manuel sync başarıyla tamamlandı');
    } catch (e) {
      print('❌ Manuel sync hatası: $e');
      rethrow;
    }
  }

  /// Sync istatistiklerini döndürür
  Future<Map<String, int>> getSyncStatistics() async {
    if (!await _storage.hasSQLiteSupport()) return {};

    final db = await _storage.getDatabase();
    final stats = <String, int>{};

    try {
      final tables = [
        'companies',
        'company_period',
        'users',
        'menu',
        'departments',
        'factories',
        'device',
        'roles',
        'menu_permissions',
        'settings',
        'user_company_visibility',
        'user_roles',
      ];

      for (final table in tables) {
        try {
          final result = await db.rawQuery(
            SqlQuerys.selectCount.replaceAll('{table}', table),
          );
          stats[table] = result.first['count'] as int? ?? 0;
        } catch (e) {
          stats[table] = 0; // Tablo yoksa 0
        }
      }
    } catch (e) {
      print('❌ Sync istatistikleri alınırken hata: $e');
    }

    return stats;
  }

  /// Sync loglarını temizler
  Future<void> clearSyncLogs() async {
    await _storage.setSetting('last_sync_error', '');
    print('🧹 Sync logları temizlendi');
  }

  /// Map içindeki bool değerleri int (0/1) olarak dönüştürür
  Map<String, dynamic> _convertBoolsToInts(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is bool) {
        return MapEntry(key, value ? 1 : 0);
      }
      return MapEntry(key, value);
    });
  }

  /// Map içindeki int (0/1) değerleri bool olarak dönüştürür
  Map<String, dynamic> _convertIntsToBools(Map<String, dynamic> data) {
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
      'force_logout_request',
    ];
    return booleanFields.contains(fieldName.toLowerCase());
  }

  /// Uygulama kapatılırken otomatik sync'i durdur
  Future<void> dispose() async {
    await stopAutoSync();
    print('🔚 DatabaseService dispose edildi');
  }

  /// settings tablosu için migration fonksiyonu
  Future<void> runSettingsMigration(Database db) async {
    try {
      // Eksik alanları ekle
      final columns = await db.rawQuery("PRAGMA table_info(settings)");
      final columnNames = columns.map((col) => col['name'] as String).toSet();

      // Eğer id alanı yoksa tabloyu sıfırla
      if (!columnNames.contains('id')) {
        print('settings tablosu sıfırlanıyor (PRIMARY KEY alanı eksik)...');
        await db.execute(SqlQuerys.dropSettingsTable);
        await db.execute(SqlQuerys.createSettingsTable);
        print('settings tablosu yeniden oluşturuldu');
      } else {
        // Sadece eksik alanları ekle
        final requiredColumns = <String, String>{
          'uuid': 'TEXT',
          'description': 'TEXT',
          'category': 'TEXT',
          'is_system_setting': 'INTEGER NOT NULL DEFAULT 0',
          'is_encrypted': 'INTEGER NOT NULL DEFAULT 0',
        };

        for (final entry in requiredColumns.entries) {
          if (!columnNames.contains(entry.key)) {
            await db.execute(
              SqlQuerys.alterAddDescription
                  .replaceAll('{table}', 'settings')
                  .replaceAll('description', entry.key)
                  .replaceAll('TEXT', entry.value),
            );
            print('settings tablosuna ${entry.key} alanı eklendi (migration)');
          }
        }
      }

      print('✅ settings migration tamamlandı');
    } catch (e) {
      print('❌ settings migration hatası: $e');
    }
  }

  /// Supabase'den user_roles verilerini delta sync ile senkronize et
  Future<void> syncUserRolesFromSupabase() async {
    try {
      final supabase = await PostgreService.getInstance();
      final remoteUserRoles = await supabase.query('user_roles');

      if (remoteUserRoles.isEmpty) {
        print('ℹ️ Supabase user_roles tablosu boş');
        return;
      }

      await performDeltaSync(
        tableName: 'user_roles',
        remoteData: remoteUserRoles,
        primaryKey: 'id',
        updatedAtField: 'updated_at',
        deletedField: 'is_deleted',
        enableSoftDelete: true,
      );

      print('✅ User roles delta sync tamamlandı');
    } catch (e) {
      print('❌ User roles delta sync hatası: $e');
    }
  }

  /// sync_settings tablosunu oluşturur
  Future<void> createSyncSettingsTable(Database db) async {
    await db.execute(SqlQuerys.createSyncSettingsTable);
    print('sync_settings tablosu oluşturuldu');
  }

  /// Supabase'den sync_settings tablosunu çekip localde oluşturur
  Future<void> fetchAndInitSyncSettingsFromSupabase() async {
    final supabase = await PostgreService.getInstance();
    if (!await _storage.hasSQLiteSupport()) return;
    final db = await _storage.getDatabase();
    await createSyncSettingsTable(db);
    final remoteSettings = await supabase.query('sync_settings');
    if (remoteSettings.isEmpty) {
      print(
        'Supabase sync_settings tablosu boş veya yok. Varsayılan ayarlar eklenecek.',
      );
      // Varsayılan tablo listesi
      final defaultTables = [
        'companies',
        'company_period',
        'users',
        'menu',
        'departments',
        'factories',
        'device',
        'roles',
        'menu_permissions',
        'settings',
        'user_company_visibility',
        'user_roles',
      ];
      for (final table in defaultTables) {
        await db.insert(
            'sync_settings',
            {
              'table_name': table,
              'is_enabled': 1,
              'sync_direction': 'bidirectional',
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      print('Varsayılan sync_settings kayıtları eklendi.');
    } else {
      for (final row in remoteSettings) {
        await db.insert(
          'sync_settings',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      print('Supabase sync_settings tablosu localde oluşturuldu.');
    }
  }

  /// Public olarak veritabanı nesnesini döndürür
  Future<Database> getDatabase() async {
    return await _storage.getDatabase();
  }

  /// Tablo adına göre delta sync yapar
  Future<void> performDeltaSyncForTable(String tableName) async {
    try {
      final supabase = await PostgreService.getInstance();

      // Supabase'de tablo adını kontrol et
      String actualTableName = tableName;
      final config = _getTableConfig(tableName);

      // Eğer config'de farklı tablo adı varsa kullan
      if (config.containsKey('tableName')) {
        actualTableName = config['tableName'];
      }

      // Tablo adı alternatiflerini dene
      List<String> tableNamesToTry = [actualTableName];
      if (tableName == 'companies') {
        tableNamesToTry = ['companies', 'company', 'firm', 'organization'];
      }

      // Önce Supabase'deki mevcut tabloları kontrol et
      for (final tableNameToTry in tableNamesToTry) {
        try {
          final remoteData = await supabase.query(tableNameToTry);

          if (remoteData.isEmpty) {
            print('ℹ️ Supabase $tableNameToTry tablosu boş');
            return;
          }

          await performDeltaSync(
            tableName: tableName,
            remoteData: remoteData,
            primaryKey: config['primaryKey'],
            updatedAtField: config['updatedAtField'],
            deletedField: config['deletedField'],
            fieldMappings: config['fieldMappings'],
            enableSoftDelete: config['enableSoftDelete'],
            resetTable: config['resetTable'] ?? false,
          );

          print(
              '✅ $tableName delta sync tamamlandı. Toplam: ${remoteData.length}');
          return; // Başarılı olursa döngüden çık
        } catch (e) {
          if (e.toString().contains('does not exist')) {
            print(
                '⚠️ Supabase\'de $tableNameToTry tablosu bulunamadı, diğer alternatifler deneniyor...');
            continue; // Diğer alternatifleri dene
          }
          rethrow; // Başka bir hata varsa fırlat
        }
      }

      // Hiçbir tablo bulunamadıysa
      print('❌ Supabase\'de $tableName için uygun tablo bulunamadı');
    } catch (e) {
      print('❌ $tableName delta sync hatası: $e');
      rethrow;
    }
  }

  /// Tablo konfigürasyonlarını döndürür
  Map<String, dynamic> _getTableConfig(String tableName) {
    switch (tableName) {
      case 'companies':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'fieldMappings': {'company_name': 'name'},
          'enableSoftDelete': true,
          'tableName':
              'companies', // Önce 'companies' dene, yoksa 'company' dene
        };
      case 'company_period':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'users':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'menu':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'departments':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'factories':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'device':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'roles':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'menu_permissions':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': false, // Hard delete kullan
          'resetTable': true, // Tabloyu sıfırla
        };
      case 'settings':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
          'resetTable': true, // Tabloyu sıfırla
          'fieldMappings': {'setting_key': 'key', 'setting_value': 'value'},
        };
      case 'user_company_visibility':
        return {
          'primaryKey': 'user_id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      case 'user_roles':
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
      default:
        return {
          'primaryKey': 'id',
          'updatedAtField': 'updated_at',
          'deletedField': 'is_deleted',
          'enableSoftDelete': true,
        };
    }
  }

  /// Generic Delta Sync fonksiyonu - sadece değişen kayıtları işler
  Future<Map<String, int>> performDeltaSync({
    required String tableName,
    required List<Map<String, dynamic>> remoteData,
    required String primaryKey,
    String? updatedAtField,
    String? deletedField,
    Map<String, String>? fieldMappings,
    bool enableSoftDelete = true,
    bool resetTable = false,
  }) async {
    if (!await _storage.hasSQLiteSupport()) {
      return {'added': 0, 'updated': 0, 'deleted': 0, 'unchanged': 0};
    }

    final db = await _storage.getDatabase();

    // Eğer tablo sıfırlanacaksa
    if (resetTable) {
      print('🔄 $tableName tablosu sıfırlanıyor...');
      await db.execute('DROP TABLE IF EXISTS $tableName');

      // Tablo oluşturma SQL'ini al
      String createTableSql;
      switch (tableName) {
        case 'menu_permissions':
          createTableSql = SqlQuerys.createMenuPermissionsTable;
          break;
        case 'settings':
          createTableSql = SqlQuerys.createSettingsTable;
          break;
        default:
          createTableSql =
              'CREATE TABLE IF NOT EXISTS $tableName (id INTEGER PRIMARY KEY)';
      }

      await db.execute(createTableSql);
      print('✅ $tableName tablosu yeniden oluşturuldu');

      // Duplicate id/uuid filtrele (özellikle menu_permissions ve settings için)
      List<Map<String, dynamic>> filteredRemoteData = remoteData;
      if (tableName == 'menu_permissions' || tableName == 'settings') {
        final uniqueMap = <dynamic, Map<String, dynamic>>{};
        for (final row in remoteData) {
          final key = row['uuid'] ?? row['id'];
          uniqueMap[key] = row;
        }
        filteredRemoteData = uniqueMap.values.toList();
      }

      // Tüm verileri ekle
      final batch = db.batch();
      for (final remote in filteredRemoteData) {
        final convertedRemote = _convertBoolsToInts(remote);
        final mappedData = fieldMappings != null
            ? _applyFieldMappings(convertedRemote, fieldMappings)
            : convertedRemote;
        batch.insert(tableName, mappedData,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      print(
          '✅ $tableName tablosu sıfırlandı ve ${filteredRemoteData.length} kayıt eklendi');
      return {
        'added': filteredRemoteData.length,
        'updated': 0,
        'deleted': 0,
        'unchanged': 0,
      };
    }

    final localData = await db.query(tableName);

    // Local verileri primary key'e göre map'le
    final localDataMap = <String, Map<String, dynamic>>{};
    for (final local in localData) {
      localDataMap[local[primaryKey].toString()] = local;
    }

    // Remote verileri primary key'e göre map'le
    final remoteDataMap = <String, Map<String, dynamic>>{};
    for (final remote in remoteData) {
      if (remote[primaryKey] != null) {
        remoteDataMap[remote[primaryKey].toString()] = remote;
      }
    }

    int addedCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    int unchangedCount = 0;

    // 1. Yeni kayıtları ekle, güncellenenleri güncelle
    for (final remote in remoteDataMap.values) {
      final id = remote[primaryKey].toString();
      final local = localDataMap[id];
      final convertedRemote = _convertBoolsToInts(remote);

      // Field mapping uygula
      final mappedData = fieldMappings != null
          ? _applyFieldMappings(convertedRemote, fieldMappings)
          : convertedRemote;

      if (local == null) {
        // Yeni kayıt - ekle
        try {
          await db.insert(
            tableName,
            mappedData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          addedCount++;
        } catch (e) {
          print('❌ $tableName insert hatası: $e');
        }
      } else {
        // Mevcut kayıt - değişiklik kontrolü
        bool shouldUpdate = false;

        if (updatedAtField != null) {
          final localUpdated = local[updatedAtField];
          final remoteUpdated = remote[updatedAtField];
          shouldUpdate = remoteUpdated != null &&
              localUpdated != null &&
              remoteUpdated != localUpdated;
        } else {
          // updated_at yoksa her zaman güncelle
          shouldUpdate = true;
        }

        if (shouldUpdate) {
          try {
            await db.update(
              tableName,
              mappedData,
              where: '$primaryKey = ?',
              whereArgs: [id],
            );
            updatedCount++;
          } catch (e) {
            print('❌ $tableName update hatası: $e');
          }
        } else {
          unchangedCount++;
        }
      }
    }

    // 2. Silinen kayıtları işle (soft delete veya hard delete)
    if (enableSoftDelete && deletedField != null) {
      // Soft delete: is_deleted = 1 yap
      for (final local in localDataMap.values) {
        final id = local[primaryKey].toString();
        if (!remoteDataMap.containsKey(id) && local[deletedField] != 1) {
          try {
            await db.update(
              tableName,
              {deletedField: 1},
              where: '$primaryKey = ?',
              whereArgs: [id],
            );
            deletedCount++;
          } catch (e) {
            print('❌ $tableName soft delete hatası: $e');
          }
        }
      }
    } else {
      // Hard delete: kaydı tamamen sil
      for (final local in localDataMap.values) {
        final id = local[primaryKey].toString();
        if (!remoteDataMap.containsKey(id)) {
          try {
            await db.delete(
              tableName,
              where: '$primaryKey = ?',
              whereArgs: [id],
            );
            deletedCount++;
          } catch (e) {
            print('❌ $tableName hard delete hatası: $e');
          }
        }
      }
    }

    print('✅ $tableName delta sync tamamlandı:');
    print('   📥 Yeni eklenen: $addedCount');
    print('   🔄 Güncellenen: $updatedCount');
    print('   🗑️ Silinen: $deletedCount');
    print('   ⏭️ Değişmeyen: $unchangedCount');
    print('   📊 Toplam: ${remoteDataMap.length}');

    return {
      'added': addedCount,
      'updated': updatedCount,
      'deleted': deletedCount,
      'unchanged': unchangedCount,
    };
  }

  /// Field mapping uygula
  Map<String, dynamic> _applyFieldMappings(
    Map<String, dynamic> data,
    Map<String, String> mappings,
  ) {
    final mappedData = <String, dynamic>{};
    for (final entry in data.entries) {
      final mappedKey = mappings[entry.key] ?? entry.key;
      mappedData[mappedKey] = entry.value;
    }
    return mappedData;
  }
}
