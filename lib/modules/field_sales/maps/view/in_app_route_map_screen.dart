// Dosya Adı: in_app_route_map_screen.dart
// Açıklama: Uygulama içi yol tarifi dens — polyline + offline/online karo
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/geo/haversine.dart';
import '../../../../core/localization/app_localization.dart';
import '../../gps/model/route_visit_point.dart';
import '../../gps/viewmodel/route_map_store.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../viewmodel/offline_aware_tile_provider.dart';
import '../viewmodel/offline_map_tile_store.dart';

/// {@template in_app_route_map_screen}
/// Uygulama içi rota haritası — A→B polyline (müşteri lat/long).
/// Offline karo varsa yerel; yoksa Carto Voyager online.
/// Sesli turn-by-turn yok — harici navigasyon opsiyonel.
/// Route: `/field-sales/in-app-route-map`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, InAppRouteMapScreen.routeName);
/// ```
/// {@endtemplate}
class InAppRouteMapScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/in-app-route-map';

  /// [store]: Ziyaret noktaları (test)
  final RouteMapStore? routeStore;

  /// [points]: Verilirse SQLite atlanır
  final List<RouteVisitPoint>? points;

  /// [tileStore]: Offline karo kökü
  final OfflineMapTileStore? tileStore;

  /// [cacheRootPath]: Test için sabit kök
  final String? cacheRootPath;

  /// {@macro in_app_route_map_screen}
  const InAppRouteMapScreen({
    Key? key,
    this.routeStore,
    this.points,
    this.tileStore,
    this.cacheRootPath,
  }) : super(key: key);

  @override
  State<InAppRouteMapScreen> createState() => _InAppRouteMapScreenState();
}

class _InAppRouteMapScreenState extends State<InAppRouteMapScreen> {
  final MapController _mapController = MapController();
  late final OfflineMapTileStore _tileStore;

  bool _loading = true;
  List<RouteVisitPoint> _points = const [];
  bool _hasOffline = false;
  OfflineAwareTileProvider? _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileStore = widget.tileStore ?? const OfflineMapTileStore();
    _bootstrap();
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    List<RouteVisitPoint> rows;
    if (widget.points != null) {
      rows = widget.points!;
    } else {
      try {
        final store = widget.routeStore ?? const RouteMapStore();
        rows = await store.loadVisitPoints();
      } catch (_) {
        rows = const [];
      }
    }

    String? cacheRoot = widget.cacheRootPath;
    var hasOffline = false;
    if (!kIsWeb && cacheRoot == null) {
      try {
        hasOffline = await _tileStore.hasAnyOfflineTiles();
        if (hasOffline) {
          cacheRoot = (await _tileStore.cacheRoot()).path;
        }
      } catch (_) {
        hasOffline = false;
        cacheRoot = null;
      }
    } else if (cacheRoot != null) {
      hasOffline = true;
    }

    _tileProvider = OfflineAwareTileProvider(
      cacheRootPath: cacheRoot,
      headers: OfflineMapTileStore.tileRequestHeaders,
    );

    if (!mounted) return;
    setState(() {
      _points = rows;
      _hasOffline = hasOffline;
      _loading = false;
    });
  }

  List<RouteVisitPoint> get _withCoords =>
      _points.where((p) => p.hasCoords).toList(growable: false);

  List<LatLng> get _polylinePoints => _withCoords
      .map((p) => LatLng(p.latitude!, p.longitude!))
      .toList(growable: false);

  double? get _totalKm {
    final pts = _withCoords;
    if (pts.length < 2) return null;
    var m = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      m += haversineMeters(
        pts[i].latitude!,
        pts[i].longitude!,
        pts[i + 1].latitude!,
        pts[i + 1].longitude!,
      );
    }
    return m / 1000.0;
  }

  Future<void> _openExternalNav(LatLng dest) async {
    final url =
        'google.navigation:q=${dest.latitude},${dest.longitude}&mode=d';
    final fallback =
        'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(
        Uri.parse(fallback),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = FieldSalesDensAppBar.primaryColor;
    final coords = _withCoords;
    final center = coords.isNotEmpty
        ? LatLng(coords.first.latitude!, coords.first.longitude!)
        : const LatLng(36.2, 44.0);
    final km = _totalKm;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.in_app_route_map'),
        backgroundColor: primary,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.download_for_offline_outlined,
            tooltip: l10n.translate('field_sales.stubs.offline_map_download'),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/field-sales/offline-map-download',
              );
            },
          ),
        ],
      ),
      body: _loading
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
                        _hasOffline ? Icons.offline_pin : Icons.cloud_outlined,
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
                      if (km != null)
                        Text(
                          l10n.translate(
                            'field_sales.offline_maps.route_km',
                            args: {'km': km.toStringAsFixed(1)},
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                  child: Text(
                    l10n.translate('field_sales.offline_maps.tbt_note'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: coords.isEmpty
                      ? Center(
                          child: Text(
                            l10n.translate('field_sales.route_map_empty'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  OfflineMapTileStore.tileUrlTemplate,
                              subdomains:
                                  OfflineMapTileStore.tileSubdomains,
                              userAgentPackageName: 'com.exfin.ops',
                              tileProvider: _tileProvider ??
                                  NetworkTileProvider(
                                    headers: OfflineMapTileStore
                                        .tileRequestHeaders,
                                    silenceExceptions: true,
                                  ),
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
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _polylinePoints,
                                  color: const Color(0xFF00A8E8)
                                      .withValues(alpha: 0.7),
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                for (var i = 0; i < coords.length; i++)
                                  Marker(
                                    point: LatLng(
                                      coords[i].latitude!,
                                      coords[i].longitude!,
                                    ),
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: i == 0
                                            ? Colors.green
                                            : primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
                if (coords.isNotEmpty)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                      child: SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final last = coords.last;
                            _openExternalNav(
                              LatLng(last.latitude!, last.longitude!),
                            );
                          },
                          icon: const Icon(Icons.navigation, size: 18),
                          label: Text(
                            l10n.translate(
                              'field_sales.offline_maps.external_nav',
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
