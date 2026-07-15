import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import '../core/database/migrations/SqlQuerys.dart';

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

    if (kIsWeb) {
      // Initialize SharedPreferences for web
      _preferences ??= await SharedPreferences.getInstance();
    } else {
      // Initialize SQLite for non-web platforms
      _database ??= await _initDatabase();
    }

    return _instance!;
  }

  /// Initialize the SQLite database based on platform
  static Future<Database> _initDatabase() async {
    if (!kIsWeb && Platform.isWindows) {
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      final dbPath = 'C:\\exfin_erp_data';
      await Directory(dbPath).create(recursive: true);
      final dbFilePath = path.join(dbPath, 'exfin_erp.db');
      return await databaseFactory.openDatabase(
        dbFilePath,
        options: OpenDatabaseOptions(version: 1, onCreate: _createTables),
      );
    } else if (!kIsWeb) {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDirectory.path, 'exfin_erp.db');
      return await openDatabase(
        dbPath,
        version: 1,
        onCreate: _createTables,
      );
    } else {
      throw UnsupportedError('Web platformunda SQLite desteklenmez.');
    }
  }

  /// Create database tables
  static Future<void> _createTables(Database db, int version) async {
    // Create settings table
    await db.execute(SqlQuerys.createSettingsTable);

    // Create api_config table
    await db.execute(SqlQuerys.createApiConfigTable);
  }

  // Store API configuration
  Future<void> saveApiConfig({
    required String baseUrl,
    String? apiKey,
    int timeout = 30,
    bool useHttps = true,
  }) async {
    final apiConfig = {
      'base_url': baseUrl,
      'api_key': apiKey,
      'timeout': timeout,
      'use_https': useHttps ? 1 : 0,
    };

    if (kIsWeb) {
      // Web: Use localStorage via SharedPreferences
      await _preferences!.setString('api_config', jsonEncode(apiConfig));
      print('Web: API Config saved: $apiConfig');
    } else {
      // Windows/Mobile: Use SQLite
      final results = await _database!.rawQuery(
        SqlQuerys.selectCount.replaceAll('{table}', 'api_config'),
      );
      final count = Sqflite.firstIntValue(results) ?? 0;

      if (count > 0) {
        // There's an existing record, update it
        print('SQLite: Updating existing API config');
        final result = await _database!.update(
          'api_config',
          apiConfig,
          where: '1=1', // Update all records (should be only one)
        );
        print('SQLite: Update result: $result rows affected');
      } else {
        // No existing record, insert a new one
        print('SQLite: Inserting new API config');
        final id = await _database!.insert('api_config', apiConfig);
        print('SQLite: Insert result: ID=$id');
      }

      // Debug: Print current config after save to verify it worked
      final configAfterSave = await _database!.query('api_config');
      print('SQLite: API Config after save: $configAfterSave');
    }
  }

  // Get API configuration
  Future<Map<String, dynamic>?> getApiConfig() async {
    if (kIsWeb) {
      // Web: Use localStorage via SharedPreferences
      final apiConfigJson = _preferences!.getString('api_config');
      if (apiConfigJson != null) {
        final config = jsonDecode(apiConfigJson) as Map<String, dynamic>;
        print('Web: API Config retrieved: $config');
        return config;
      }
      print('Web: No API config found');
      return null;
    } else {
      // Windows/Mobile: Use SQLite
      final result = await _database!.query('api_config', limit: 1);
      if (result.isNotEmpty) {
        print('SQLite: API Config retrieved: ${result.first}');
        return result.first;
      }
      print('SQLite: No API config found');
      return null;
    }
  }

  // Store a key-value setting
  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) {
      // Web: Use localStorage via SharedPreferences
      await _preferences!.setString(key, value);
    } else {
      // Windows/Mobile: Use SQLite
      await _database!.insert(
          'settings',
          {
            'setting_key': key,
            'setting_value': value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Get a setting by key
  Future<String?> getSetting(String key) async {
    if (kIsWeb) {
      // Web: Use localStorage via SharedPreferences
      return _preferences!.getString(key);
    } else {
      // Windows/Mobile: Use SQLite
      final result = await _database!.query(
        'settings',
        columns: ['setting_value'],
        where: 'setting_key = ?',
        whereArgs: [key],
      );

      if (result.isNotEmpty) {
        return result.first['setting_value'] as String?;
      }
      return null;
    }
  }

  // Store complex object
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);

    if (kIsWeb) {
      // Web: Use localStorage via SharedPreferences
      await _preferences!.setString(key, jsonString);
    } else {
      // Windows/Mobile: Use SQLite
      await _database!.insert(
          'settings',
          {
            'setting_key': key,
            'setting_value': jsonString,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Get complex object
  Future<Map<String, dynamic>?> getObject(String key) async {
    String? jsonString;

    if (kIsWeb) {
      // Web: Use localStorage via SharedPreferences
      jsonString = _preferences!.getString(key);
    } else {
      // Windows/Mobile: Use SQLite
      final result = await _database!.query(
        'settings',
        columns: ['setting_value'],
        where: 'setting_key = ?',
        whereArgs: [key],
      );

      if (result.isNotEmpty) {
        jsonString = result.first['setting_value'] as String?;
      }
    }

    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }

    return null;
  }

  // Clear all stored data
  Future<void> clearAll() async {
    if (kIsWeb) {
      // Web: Use localStorage via SharedPreferences
      await _preferences!.clear();
    } else {
      // Windows/Mobile: Use SQLite
      await _database!.delete('settings');
      await _database!.delete('api_config');
    }
  }
}
