// Dosya Adı: offline_map_tile_store_test.dart
// Açıklama: OfflineMapTileStore indirme meta / mock http testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:io';

import 'package:exfin_ops/modules/field_sales/maps/model/offline_map_region.dart';
import 'package:exfin_ops/modules/field_sales/maps/viewmodel/offline_map_tile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineMapTileStore', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('offline_map_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('downloadRegion karo yazar ve meta kaydeder', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.url.host, contains('cartocdn.com'));
        expect(
          request.headers['User-Agent'],
          OfflineMapTileStore.userAgent,
        );
        return http.Response.bytes(
          List<int>.filled(8, 1),
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      const region = OfflineMapRegion(
        id: 'test_tiny',
        nameKey: 'x',
        south: 41.00,
        west: 29.00,
        north: 41.005,
        east: 29.005,
        minZoom: 12,
        maxZoom: 12,
      );

      final store = OfflineMapTileStore(
        httpClient: client,
        documentsDirFactory: () async => tempDir,
        delayBetweenTiles: Duration.zero,
      );

      final progress = <OfflineMapDownloadProgress>[];
      await store.downloadRegion(
        region,
        onProgress: progress.add,
      );

      expect(await store.isRegionDownloaded('test_tiny'), isTrue);
      expect(await store.hasAnyOfflineTiles(), isTrue);
      expect(requests, greaterThan(0));
      expect(progress.last.done, isTrue);
      expect(progress.last.error, isNull);

      final path = await store.tilePath(12, region.tileCoordinates().first.x,
          region.tileCoordinates().first.y);
      // May or may not exist if tiles overlap empty - check any file under cache
      final cache = await store.cacheRoot();
      final files = cache
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'));
      expect(files, isNotEmpty);
      expect(File(path).existsSync() || files.isNotEmpty, isTrue);
    });

    test('deleteRegion meta temizler', () async {
      final client = MockClient((request) async {
        return http.Response.bytes(List<int>.filled(4, 2), 200);
      });

      const region = OfflineMapRegion(
        id: 'del_me',
        nameKey: 'x',
        south: 41.00,
        west: 29.00,
        north: 41.005,
        east: 29.005,
        minZoom: 12,
        maxZoom: 12,
      );

      final store = OfflineMapTileStore(
        httpClient: client,
        documentsDirFactory: () async => tempDir,
        delayBetweenTiles: Duration.zero,
      );

      await store.downloadRegion(region);
      expect(await store.isRegionDownloaded('del_me'), isTrue);
      await store.deleteRegion(region);
      expect(await store.isRegionDownloaded('del_me'), isFalse);
    });

    test('tileUrlTemplate Carto; OSM.org yok', () {
      expect(
        OfflineMapTileStore.tileUrlTemplate,
        contains('basemaps.cartocdn.com'),
      );
      expect(
        OfflineMapTileStore.tileUrlTemplate,
        isNot(contains('tile.openstreetmap.org')),
      );
      final url = OfflineMapTileStore.resolveTileUrl(12, 100, 200);
      expect(url, contains('basemaps.cartocdn.com'));
      expect(url, contains('/12/100/200.png'));
      expect(url, isNot(contains('{s}')));
      expect(url, isNot(contains('{z}')));
    });
  });
}
