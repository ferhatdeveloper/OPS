// Dosya Adı: offline_aware_tile_provider.dart
// Açıklama: Önce yerel karo, yoksa ağ — flutter_map TileProvider
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as p;

/// {@template offline_aware_tile_provider}
/// İndirilmiş Carto karolarını dosyadan okur; yoksa NetworkTileProvider.
///
/// Web’de yalnızca ağ.
///
/// Kullanım örneği:
/// ```dart
/// TileLayer(
///   urlTemplate: OfflineMapTileStore.tileUrlTemplate,
///   subdomains: OfflineMapTileStore.tileSubdomains,
///   tileProvider: OfflineAwareTileProvider(cacheRootPath: root.path),
/// )
/// ```
/// {@endtemplate}
class OfflineAwareTileProvider extends TileProvider {
  /// [cacheRootPath]: `offline_map_tiles` kökü (null → yalnızca ağ)
  final String? cacheRootPath;

  /// [_network]: Ağ yedek sağlayıcı
  final NetworkTileProvider _network;

  /// {@macro offline_aware_tile_provider}
  OfflineAwareTileProvider({
    this.cacheRootPath,
    Map<String, String>? headers,
  }) : _network = NetworkTileProvider(
          headers: headers,
          silenceExceptions: true,
        );

  /// Yerel dosya yolu varsa döner
  String? _localPath(TileCoordinates c) {
    final root = cacheRootPath;
    if (root == null || kIsWeb) return null;
    return p.join(root, '${c.z}', '${c.x}', '${c.y}.png');
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final local = _localPath(coordinates);
    if (local != null) {
      final file = File(local);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return _network.getImage(coordinates, options);
  }

  @override
  Future<void> dispose() async {
    await _network.dispose();
    super.dispose();
  }
}
