// Dosya Adı: map_screen.dart
// Açıklama: Müşteri haritası — OfflineAware karo + dens + offline indirme girişi
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../viewmodel/map_provider.dart';
import '../viewmodel/offline_aware_tile_provider.dart';
import '../viewmodel/offline_map_tile_store.dart';
import 'offline_map_download_screen.dart';

/// {@template map_screen}
/// Müşteri haritası dens — OfflineAware Carto karoları.
/// Offline indirme AppBar’dan isteğe bağlı.
/// {@endtemplate}
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final OfflineMapTileStore _tileStore = const OfflineMapTileStore();
  OfflineAwareTileProvider? _tileProvider;
  bool _hasOffline = false;
  bool _tilesReady = false;

  @override
  void initState() {
    super.initState();
    _bootstrapTiles();
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    super.dispose();
  }

  /// Offline Carto cache varsa OfflineAware; yoksa ağ (yine OfflineAware).
  Future<void> _bootstrapTiles() async {
    String? cacheRoot;
    var hasOffline = false;
    if (!kIsWeb) {
      try {
        hasOffline = await _tileStore.hasAnyOfflineTiles();
        if (hasOffline) {
          cacheRoot = (await _tileStore.cacheRoot()).path;
        }
      } catch (_) {
        hasOffline = false;
        cacheRoot = null;
      }
    }
    final provider = OfflineAwareTileProvider(
      cacheRootPath: cacheRoot,
      headers: OfflineMapTileStore.tileRequestHeaders,
    );
    if (!mounted) {
      await provider.dispose();
      return;
    }
    setState(() {
      _tileProvider = provider;
      _hasOffline = hasOffline;
      _tilesReady = true;
    });
  }

  Future<void> _openOfflineDownload() async {
    await Navigator.pushNamed(
      context,
      OfflineMapDownloadScreen.routeName,
    );
    if (!mounted) return;
    await _tileProvider?.dispose();
    _tileProvider = null;
    await _bootstrapTiles();
  }

  Future<void> _launchNavigation(LatLng destination) async {
    final url =
        'google.navigation:q=${destination.latitude},${destination.longitude}';
    final fallbackUrl =
        'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      await launchUrl(Uri.parse(fallbackUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final l10n = AppLocalization.of(context);
    const primary = FieldSalesDensAppBar.primaryColor;
    final tileProvider = _tileProvider ??
        OfflineAwareTileProvider(
          headers: OfflineMapTileStore.tileRequestHeaders,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.customer_map'),
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.download_for_offline_outlined,
            tooltip: l10n.translate(
              'field_sales.stubs.offline_map_download',
            ),
            onPressed: _openOfflineDownload,
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            tooltip: l10n.translate('common.reload'),
            onPressed: () =>
                ref.read(mapProvider.notifier).loadCustomerMarkers(),
          ),
        ],
      ),
      body: !_tilesReady
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                  child: Row(
                    children: [
                      Icon(
                        _hasOffline
                            ? Icons.offline_pin
                            : Icons.cloud_outlined,
                        size: 16,
                        color: primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.translate(
                            _hasOffline
                                ? 'field_sales.offline_maps.mode_offline'
                                : 'field_sales.offline_maps.mode_online',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (!_hasOffline && !kIsWeb)
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _openOfflineDownload,
                          child: Text(
                            l10n.translate(
                              'field_sales.offline_maps.download_entry',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: mapState.currentLocation ??
                              const LatLng(41.0082, 28.9784),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                OfflineMapTileStore.tileUrlTemplate,
                            subdomains:
                                OfflineMapTileStore.tileSubdomains,
                            userAgentPackageName: 'com.exfin.ops',
                            tileProvider: tileProvider,
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    l10n.translate(
                                      'field_sales.offline_maps.attribution',
                                    ),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (mapState.routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: mapState.routePoints,
                                  color: const Color(0xFF00A8E8)
                                      .withValues(alpha: 0.5),
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (mapState.currentLocation != null)
                                Marker(
                                  point: mapState.currentLocation!,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.navigation,
                                        color: Colors.blue.shade800,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ...mapState.customerMarkers.map(
                                (customer) => Marker(
                                  point: customer.position,
                                  width: 60,
                                  height: 60,
                                  child: GestureDetector(
                                    onTap: () => _showCustomerDetails(
                                      context,
                                      customer,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: customer.isVisited
                                              ? Colors.green
                                              : Colors.red,
                                          size: 36,
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            customer.name,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (mapState.isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'center_map',
        onPressed: () {
          if (mapState.currentLocation != null) {
            _mapController.move(mapState.currentLocation!, 15);
          }
        },
        backgroundColor: primary,
        mini: true,
        child: const Icon(Icons.my_location, size: 20),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, CustomerMarker customer) {
    final l10n = AppLocalization.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: customer.isVisited ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.translate(
                'field_sales.map_customer_code',
                args: {'code': customer.id},
              ),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _launchNavigation(customer.position);
                      },
                      icon: const Icon(Icons.navigation, size: 18),
                      label: Text(
                        l10n.translate('field_sales.map_start_navigation'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FieldSalesDensAppBar.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/field-sales/visit-details',
                          arguments: customer.id,
                        );
                      },
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: Text(
                        l10n.translate('field_sales.map_do_action'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
