// Dosya Adı: offline_map_tile_store.dart
// Açıklama: Carto Voyager karo indirme / silme / durum — path_provider + http
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/offline_map_region.dart';

/// {@template offline_map_download_progress}
/// Bölge indirme ilerleme durumu.
/// {@endtemplate}
class OfflineMapDownloadProgress {
  /// [regionId]: İndirilen bölge
  final String regionId;

  /// [completed]: Tamamlanan karo
  final int completed;

  /// [total]: Toplam karo
  final int total;

  /// [done]: Bitti mi
  final bool done;

  /// [error]: Hata mesajı (varsa)
  final String? error;

  /// {@macro offline_map_download_progress}
  const OfflineMapDownloadProgress({
    required this.regionId,
    required this.completed,
    required this.total,
    this.done = false,
    this.error,
  });

  /// 0–1 ilerleme
  double get fraction => total <= 0 ? 0 : completed / total;
}

/// {@template offline_map_tile_store}
/// Offline raster karo deposu (Carto Voyager — OSM tabanlı, uygulama uyumlu).
///
/// `tile.openstreetmap.org` kullanılmaz (OSM kullanım politikası / 403).
/// Web’de dosya önbelleği yok — yalnızca online TileLayer.
/// Sesli turn-by-turn bu katmanda yoktur.
///
/// Kullanım örneği:
/// ```dart
/// final store = OfflineMapTileStore();
/// await store.downloadRegion(OfflineMapRegion.presets.first);
/// ```
/// {@endtemplate}
class OfflineMapTileStore {
  /// [prefsKey]: İndirilmiş bölge meta JSON
  static const String prefsKey = 'offline_map_downloaded_regions_v1';

  /// [tileUrlTemplate]: Carto Voyager (OSM verisi + Carto stil)
  static const String tileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// [tileSubdomains]: Carto CDN alt alanları
  static const List<String> tileSubdomains = ['a', 'b', 'c', 'd'];

  /// [userAgent]: Tanımlı uygulama kimliği (CDN politika uyumu)
  static const String userAgent =
      'com.exfin.ops/1.0 (EXFINOPS; offline-map; +https://exfinops.local)';

  /// [tileRequestHeaders]: Ağ / indirme ortak başlıkları
  static const Map<String, String> tileRequestHeaders = {
    'User-Agent': userAgent,
    'Referer': 'https://exfinops.local/',
  };

  /// [z]/[x]/[y] için somut karo URL’si (`{s}` dahil)
  static String resolveTileUrl(int z, int x, int y) {
    final s = tileSubdomains[(x + y) % tileSubdomains.length];
    return tileUrlTemplate
        .replaceAll('{s}', s)
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }

  /// [httpClient]: Test enjeksiyonu
  final http.Client? httpClient;

  /// [prefsFactory]: Test SharedPreferences
  final Future<SharedPreferences> Function()? prefsFactory;

  /// [documentsDirFactory]: Test dizin
  final Future<Directory> Function()? documentsDirFactory;

  /// [delayBetweenTiles]: CDN nezaket gecikmesi
  final Duration delayBetweenTiles;

  /// {@macro offline_map_tile_store}
  const OfflineMapTileStore({
    this.httpClient,
    this.prefsFactory,
    this.documentsDirFactory,
    this.delayBetweenTiles = const Duration(milliseconds: 40),
  });

  /// Web / stub platformlarda dosya önbelleği yok
  bool get supportsFileCache => !kIsWeb;

  Future<SharedPreferences> _prefs() async {
    if (prefsFactory != null) return prefsFactory!();
    return SharedPreferences.getInstance();
  }

  Future<Directory> _docs() async {
    if (documentsDirFactory != null) return documentsDirFactory!();
    return getApplicationDocumentsDirectory();
  }

  /// Karo kök dizini
  Future<Directory> cacheRoot() async {
    final root = Directory(p.join((await _docs()).path, 'offline_map_tiles'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  /// Yerel karo dosya yolu
  Future<String> tilePath(int z, int x, int y) async {
    final root = await cacheRoot();
    return p.join(root.path, '$z', '$x', '$y.png');
  }

  /// İndirilmiş bölge id listesi
  Future<Set<String>> downloadedRegionIds() async {
    final prefs = await _prefs();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => e.toString())
          .toList(growable: false);
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _saveDownloadedIds(Set<String> ids) async {
    final prefs = await _prefs();
    await prefs.setString(prefsKey, jsonEncode(ids.toList()..sort()));
  }

  /// Herhangi bir offline karo var mı
  Future<bool> hasAnyOfflineTiles() async {
    if (!supportsFileCache) return false;
    final ids = await downloadedRegionIds();
    return ids.isNotEmpty;
  }

  /// Bölge indirilmiş mi
  Future<bool> isRegionDownloaded(String regionId) async {
    final ids = await downloadedRegionIds();
    return ids.contains(regionId);
  }

  /// Bölge karolarını indirir (iptal için [shouldCancel])
  Future<void> downloadRegion(
    OfflineMapRegion region, {
    void Function(OfflineMapDownloadProgress progress)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (!supportsFileCache) {
      onProgress?.call(
        OfflineMapDownloadProgress(
          regionId: region.id,
          completed: 0,
          total: 0,
          done: true,
          error: 'web_unsupported',
        ),
      );
      return;
    }

    final tiles = region.tileCoordinates().toList(growable: false);
    final total = tiles.length;
    final client = httpClient ?? http.Client();
    var completed = 0;

    try {
      for (final t in tiles) {
        if (shouldCancel?.call() == true) {
          onProgress?.call(
            OfflineMapDownloadProgress(
              regionId: region.id,
              completed: completed,
              total: total,
              done: true,
              error: 'cancelled',
            ),
          );
          return;
        }

        final path = await tilePath(t.z, t.x, t.y);
        final file = File(path);
        if (!await file.exists()) {
          final url = resolveTileUrl(t.z, t.x, t.y);
          final res = await client.get(
            Uri.parse(url),
            headers: tileRequestHeaders,
          );
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            await file.parent.create(recursive: true);
            await file.writeAsBytes(res.bodyBytes, flush: true);
          }
          if (delayBetweenTiles > Duration.zero) {
            await Future<void>.delayed(delayBetweenTiles);
          }
        }
        completed++;
        onProgress?.call(
          OfflineMapDownloadProgress(
            regionId: region.id,
            completed: completed,
            total: total,
          ),
        );
      }

      final ids = await downloadedRegionIds();
      ids.add(region.id);
      await _saveDownloadedIds(ids);
      onProgress?.call(
        OfflineMapDownloadProgress(
          regionId: region.id,
          completed: total,
          total: total,
          done: true,
        ),
      );
    } catch (e) {
      onProgress?.call(
        OfflineMapDownloadProgress(
          regionId: region.id,
          completed: completed,
          total: total,
          done: true,
          error: e.toString(),
        ),
      );
      rethrow;
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// Bölge meta + karo dosyalarını siler (yalnızca o bölgenin bbox karoları)
  Future<void> deleteRegion(OfflineMapRegion region) async {
    if (!supportsFileCache) return;
    for (final t in region.tileCoordinates()) {
      final path = await tilePath(t.z, t.x, t.y);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    final ids = await downloadedRegionIds();
    ids.remove(region.id);
    await _saveDownloadedIds(ids);
  }
}
