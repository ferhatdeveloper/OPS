// Dosya Adı: report_logo_store.dart
// Açıklama: Rapor PDF firma logosu yerel önbellek (cihazda bir kez)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template report_logo_source}
/// Logo kaynağı (meta).
/// {@endtemplate}
enum ReportLogoSource {
  /// Henüz yok
  none,

  /// PostgREST / merkez branding
  center,

  /// Yetkili kullanıcı yüklemesi
  upload,
}

/// {@template report_logo_meta}
/// Yerel logo meta bilgisi.
///
/// Kullanım örneği:
/// ```dart
/// const ReportLogoMeta(source: ReportLogoSource.center, fileName: 'logo.png');
/// ```
/// {@endtemplate}
class ReportLogoMeta {
  /// [source]: Kaynak
  final ReportLogoSource source;

  /// [fileName]: Dosya adı (logo.png vb.)
  final String fileName;

  /// [remoteUrl]: İndirilen URL (opsiyonel)
  final String remoteUrl;

  /// [updatedAtIso]: Son yazım
  final String updatedAtIso;

  /// {@macro report_logo_meta}
  const ReportLogoMeta({
    required this.source,
    required this.fileName,
    this.remoteUrl = '',
    this.updatedAtIso = '',
  });

  /// Boş meta
  static const ReportLogoMeta empty = ReportLogoMeta(
    source: ReportLogoSource.none,
    fileName: '',
  );

  /// [hasFile]: Dosya adı dolu mu
  bool get hasFile => fileName.trim().isNotEmpty;
}

/// {@template report_logo_store}
/// Firma logosunu `Documents/report_branding/` altında saklar.
///
/// PDF üretimi bu önbelleği kullanır; merkezden bir kez indirilir veya
/// ayarlardan yetkili kullanıcı yükler.
///
/// Kullanım örneği:
/// ```dart
/// final store = ReportLogoStore();
/// final bytes = await store.loadBytes();
/// await store.saveBytes(png, source: ReportLogoSource.upload);
/// ```
/// {@endtemplate}
class ReportLogoStore {
  /// [prefsSource]: Kaynak anahtarı
  static const String prefsSource = 'report_logo_source';

  /// [prefsFileName]: Dosya adı anahtarı
  static const String prefsFileName = 'report_logo_file_name';

  /// [prefsRemoteUrl]: Uzak URL anahtarı
  static const String prefsRemoteUrl = 'report_logo_remote_url';

  /// [prefsUpdatedAt]: Güncelleme zamanı
  static const String prefsUpdatedAt = 'report_logo_updated_at';

  /// [prefsSyncedOnce]: Merkez sync en az bir kez denendi
  static const String prefsSyncedOnce = 'report_logo_synced_once';

  /// [brandingFolder]: Alt klasör adı
  static const String brandingFolder = 'report_branding';

  /// [defaultFileName]: Varsayılan dosya
  static const String defaultFileName = 'company_logo.png';

  /// [prefsFactory]: Test SharedPreferences
  final Future<SharedPreferences> Function()? prefsFactory;

  /// [resolveDirectory]: Test dizin fabrikası
  final Future<Directory> Function()? resolveDirectory;

  /// Bellek bayt önbelleği (PDF tekrarlarında I/O azaltır)
  Uint8List? _memoryBytes;

  /// {@macro report_logo_store}
  ReportLogoStore({
    this.prefsFactory,
    this.resolveDirectory,
  });

  Future<SharedPreferences> _prefs() async {
    if (prefsFactory != null) return prefsFactory!();
    return SharedPreferences.getInstance();
  }

  /// {@template report_logo_store_branding_dir}
  /// Logo klasörünü oluşturur / döner.
  ///
  /// Dönüş değeri:
  /// - [Directory]: `…/report_branding`
  /// {@endtemplate}
  Future<Directory> brandingDir() async {
    final root = resolveDirectory != null
        ? await resolveDirectory!()
        : await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, brandingFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// {@template report_logo_store_file_path}
  /// Önbellek dosyasının mutlak yolu (yoksa varsayılan ad).
  /// {@endtemplate}
  Future<String> filePath({String? fileName}) async {
    final meta = await loadMeta();
    final name = (fileName ?? meta.fileName).trim().isEmpty
        ? defaultFileName
        : (fileName ?? meta.fileName).trim();
    final dir = await brandingDir();
    return p.join(dir.path, name);
  }

  /// {@template report_logo_store_load_meta}
  /// Prefs meta yükler.
  /// {@endtemplate}
  Future<ReportLogoMeta> loadMeta() async {
    final prefs = await _prefs();
    final sourceRaw = prefs.getString(prefsSource) ?? 'none';
    final source = ReportLogoSource.values.firstWhere(
      (e) => e.name == sourceRaw,
      orElse: () => ReportLogoSource.none,
    );
    return ReportLogoMeta(
      source: source,
      fileName: prefs.getString(prefsFileName) ?? '',
      remoteUrl: prefs.getString(prefsRemoteUrl) ?? '',
      updatedAtIso: prefs.getString(prefsUpdatedAt) ?? '',
    );
  }

  /// {@template report_logo_store_has_logo}
  /// Yerelde kullanılabilir logo var mı.
  /// {@endtemplate}
  Future<bool> hasLogo() async {
    final bytes = await loadBytes();
    return bytes != null && bytes.isNotEmpty;
  }

  /// {@template report_logo_store_load_bytes}
  /// Logo baytlarını yükler; yoksa null.
  ///
  /// Dönüş değeri:
  /// - [Uint8List?]: PNG/JPEG baytları
  /// {@endtemplate}
  Future<Uint8List?> loadBytes() async {
    if (_memoryBytes != null && _memoryBytes!.isNotEmpty) {
      return _memoryBytes;
    }
    final meta = await loadMeta();
    if (!meta.hasFile) return null;
    final path = await filePath(fileName: meta.fileName);
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    _memoryBytes = Uint8List.fromList(bytes);
    return _memoryBytes;
  }

  /// {@template report_logo_store_save_bytes}
  /// Logoyu diske yazar ve meta günceller.
  ///
  /// Parametreler:
  /// - [bytes]: Görüntü baytları
  /// - [source]: Kaynak
  /// - [fileName]: Dosya adı (uzantı önerilir)
  /// - [remoteUrl]: İndirme URL’si
  /// {@endtemplate}
  Future<ReportLogoMeta> saveBytes(
    Uint8List bytes, {
    required ReportLogoSource source,
    String fileName = defaultFileName,
    String remoteUrl = '',
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Logo baytları boş olamaz');
    }
    final name = fileName.trim().isEmpty ? defaultFileName : fileName.trim();
    final path = await filePath(fileName: name);
    // Eski dosyayı temizle (farklı uzantı)
    final dir = await brandingDir();
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
    await File(path).writeAsBytes(bytes, flush: true);
    final now = DateTime.now().toUtc().toIso8601String();
    final prefs = await _prefs();
    await prefs.setString(prefsSource, source.name);
    await prefs.setString(prefsFileName, name);
    await prefs.setString(prefsRemoteUrl, remoteUrl);
    await prefs.setString(prefsUpdatedAt, now);
    _memoryBytes = Uint8List.fromList(bytes);
    return ReportLogoMeta(
      source: source,
      fileName: name,
      remoteUrl: remoteUrl,
      updatedAtIso: now,
    );
  }

  /// {@template report_logo_store_clear}
  /// Yerel logo + meta temizler.
  /// {@endtemplate}
  Future<void> clear() async {
    final dir = await brandingDir();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
    final prefs = await _prefs();
    await prefs.remove(prefsSource);
    await prefs.remove(prefsFileName);
    await prefs.remove(prefsRemoteUrl);
    await prefs.remove(prefsUpdatedAt);
    _memoryBytes = null;
  }

  /// {@template report_logo_store_synced_once}
  /// Merkez sync en az bir kez denendi mi.
  /// {@endtemplate}
  Future<bool> wasSyncedOnce() async {
    final prefs = await _prefs();
    return prefs.getBool(prefsSyncedOnce) ?? false;
  }

  /// {@template report_logo_store_mark_synced_once}
  /// Merkez sync denemesini işaretler (başarı/başarısız fark etmez).
  /// {@endtemplate}
  Future<void> markSyncedOnce() async {
    final prefs = await _prefs();
    await prefs.setBool(prefsSyncedOnce, true);
  }

  /// {@template report_logo_store_reset_memory}
  /// Test için bellek bayt önbelleğini temizler.
  /// {@endtemplate}
  void resetMemoryCacheForTest() {
    _memoryBytes = null;
  }

  /// Uzantıya göre dosya adı önerir (png/jpg).
  static String fileNameForMime(String? contentType) {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('jpeg') || ct.contains('jpg')) {
      return 'company_logo.jpg';
    }
    if (ct.contains('webp')) return 'company_logo.webp';
    return defaultFileName;
  }

  /// Magic byte ile uzantı tahmini.
  static String fileNameForBytes(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'company_logo.jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return defaultFileName;
    }
    return defaultFileName;
  }
}
