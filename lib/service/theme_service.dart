import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/migrations/SqlQuerys.dart';

class ThemeService {
  static const String _tableName = 'settings';
  static const String _columnThemeMode = 'theme_mode';
  static const String _prefKey = 'theme_mode';
  static Database? _database;
  static SharedPreferences? _prefs;

  // Veritabanı başlatma
  Future<Database?> get database async {
    if (kIsWeb) return null; // Web'de SQLite kullanma

    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database;
  }

  // Web için SharedPreferences, diğer platformlar için SQLite
  Future<void> ensureInitialized() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    } else {
      await database;
    }
  }

  // Veritabanı başlatma işlemi
  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'exfin_erp.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              SqlQuerys.createThemeTable(_tableName, _columnThemeMode));
          // Varsayılan değeri ekle
          await db.insert(_tableName, {_columnThemeMode: 'system'});
        },
      );
    } catch (e) {
      print('Veritabanı başlatma hatası: $e');
      // Hata durumunda MemoryDatabase kullanılabilir
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
              SqlQuerys.createThemeTable(_tableName, _columnThemeMode));
          await db.insert(_tableName, {_columnThemeMode: 'system'});
        },
      );
    }
  }

  // Tema ayarını kaydet
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    String themeModeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'system';
    }

    // Web platformu kontrol et
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_prefKey, themeModeString);
      return;
    }

    // Native platformlarda SQLite kullan
    final db = await database;
    if (db == null) return;

    // Tabloda veri var mı kontrol et
    final count = Sqflite.firstIntValue(
      await db
          .rawQuery(SqlQuerys.selectCount.replaceAll('{table}', _tableName)),
    );

    if (count != null && count > 0) {
      // Veri varsa güncelle
      await db.update(_tableName, {_columnThemeMode: themeModeString});
    } else {
      // Veri yoksa ekle
      await db.insert(_tableName, {_columnThemeMode: themeModeString});
    }
  }

  // Kayıtlı tema ayarını getir
  Future<ThemeMode> getThemeMode() async {
    // Web platformu kontrol et
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      final themeModeString = _prefs!.getString(_prefKey);

      switch (themeModeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    }

    // Native platformlarda SQLite kullan
    final db = await database;
    if (db == null) return ThemeMode.system;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        columns: [_columnThemeMode],
      );

      if (maps.isEmpty) {
        return ThemeMode.system; // Varsayılan
      }

      final String themeModeString = maps.first[_columnThemeMode];

      switch (themeModeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      print('Tema ayarı getirme hatası: $e');
      return ThemeMode.system;
    }
  }
}

// Theme Provider
final themeServiceProvider = Provider<ThemeService>((ref) => ThemeService());

// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeModeNotifier(themeService);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeModeNotifier(this._themeService) : super(ThemeMode.system) {
    _init();
  }

  // Başlangıçta kayıtlı tema modunu yükle
  Future<void> _init() async {
    try {
      await _themeService.ensureInitialized();
      state = await _themeService.getThemeMode();
    } catch (e) {
      print('Tema modu yükleme hatası: $e');
      // Hata durumunda varsayılan tema modunu kullan
      state = ThemeMode.system;
    }
  }

  // Tema modunu değiştir ve kaydet
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _themeService.saveThemeMode(mode);
  }

  // Tema modunu değiştir (açık/koyu arası geçiş)
  Future<void> toggleThemeMode() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}
