// Dosya Adı: gps_tracking_map_pane.dart
// Açıklama: GPS takip harita paneli — canlı pin + kişi trail polyline
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/app_localization.dart';
import '../../maps/viewmodel/offline_aware_tile_provider.dart';
import '../../maps/viewmodel/offline_map_tile_store.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/live_location_quality.dart';
import '../model/personnel_live_location.dart';
import '../model/personnel_location_trail_point.dart';
import '../viewmodel/personnel_location_trail_store.dart';

/// {@template gps_tracking_map_pane}
/// Canlı personel Marker’ları + seçili kişi polyline trail.
///
/// Kullanım örneği:
/// ```dart
/// GpsTrackingMapPane(
///   rows: liveRows,
///   selectedUserId: selectedId,
///   onSelectPerson: (row) {},
/// )
/// ```
/// {@endtemplate}
class GpsTrackingMapPane extends StatefulWidget {
  /// [rows]: Canlı konum satırları
  final List<PersonnelLiveLocation> rows;

  /// [selectedUserId]: Seçili kişi (userId / salesperson)
  final String? selectedUserId;

  /// [onSelectPerson]: Pin / chip seçimi
  final ValueChanged<PersonnelLiveLocation> onSelectPerson;

  /// [onClearSelection]: Seçimi kaldır
  final VoidCallback onClearSelection;

  /// [trailStore]: Geçmiş trail kaynağı
  final PersonnelLocationTrailStore trailStore;

  /// [injectedTrail]: Test enjekte trail (DB atlanır)
  final List<PersonnelLocationTrailPoint>? injectedTrail;

  /// {@macro gps_tracking_map_pane}
  const GpsTrackingMapPane({
    Key? key,
    required this.rows,
    required this.selectedUserId,
    required this.onSelectPerson,
    required this.onClearSelection,
    this.trailStore = const PersonnelLocationTrailStore(),
    this.injectedTrail,
  }) : super(key: key);

  @override
  State<GpsTrackingMapPane> createState() => _GpsTrackingMapPaneState();
}

class _GpsTrackingMapPaneState extends State<GpsTrackingMapPane> {
  final MapController _mapController = MapController();
  final OfflineMapTileStore _tileStore = const OfflineMapTileStore();
  OfflineAwareTileProvider? _tileProvider;
  bool _tilesReady = false;

  PersonnelTrailPeriod _period = PersonnelTrailPeriod.today;
  List<PersonnelLocationTrailPoint> _trail = const [];
  bool _trailLoading = false;
  String? _trailForKey;

  @override
  void initState() {
    super.initState();
    _bootstrapTiles();
    _reloadTrail();
  }

  @override
  void didUpdateWidget(covariant GpsTrackingMapPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selChanged =
        oldWidget.selectedUserId != widget.selectedUserId;
    final rowsChanged = !identical(oldWidget.rows, widget.rows);
    if (selChanged || rowsChanged) {
      _reloadTrail();
      if (selChanged) {
        _zoomToSelection();
      }
    }
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    super.dispose();
  }

  Future<void> _bootstrapTiles() async {
    String? cacheRoot;
    if (!kIsWeb) {
      try {
        if (await _tileStore.hasAnyOfflineTiles()) {
          cacheRoot = (await _tileStore.cacheRoot()).path;
        }
      } catch (_) {
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
      _tilesReady = true;
    });
  }

  PersonnelLiveLocation? get _selected {
    final id = widget.selectedUserId?.trim() ?? '';
    if (id.isEmpty) return null;
    for (final r in widget.rows) {
      final key = r.userId.trim().isEmpty
          ? r.salespersonCode.trim()
          : r.userId.trim();
      if (key == id || r.salespersonCode.trim() == id) return r;
    }
    return null;
  }

  String _personKey(PersonnelLiveLocation r) {
    final uid = r.userId.trim();
    return uid.isEmpty ? r.salespersonCode.trim() : uid;
  }

  Future<void> _reloadTrail() async {
    final sel = _selected;
    if (sel == null) {
      if (!mounted) return;
      setState(() {
        _trail = const [];
        _trailLoading = false;
        _trailForKey = null;
      });
      return;
    }

    final range = PersonnelLocationTrailStore.rangeForPeriod(_period);
    final key =
        '${_personKey(sel)}|${_period.name}|${range.$1}|${range.$2}';
    if (widget.injectedTrail != null) {
      setState(() {
        _trail = PersonnelLocationTrailPoint.mergeChronological(
          widget.injectedTrail!,
        );
        _trailLoading = false;
        _trailForKey = key;
      });
      return;
    }

    setState(() {
      _trailLoading = true;
      _trailForKey = key;
    });
    try {
      final pts = await widget.trailStore.loadTrail(
        salespersonCode: sel.salespersonCode,
        userId: sel.userId,
        start: range.$1,
        end: range.$2,
      );
      if (!mounted || _trailForKey != key) return;
      setState(() {
        _trail = pts;
        _trailLoading = false;
      });
      _fitTrailOrPerson(sel, pts);
    } catch (_) {
      if (!mounted || _trailForKey != key) return;
      setState(() {
        _trail = const [];
        _trailLoading = false;
      });
    }
  }

  void _applyPeriod(PersonnelTrailPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    // ignore: discarded_futures
    _reloadTrail();
  }

  void _zoomToSelection() {
    final sel = _selected;
    if (sel == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(
          LatLng(sel.latitude, sel.longitude),
          14,
        );
      } catch (_) {}
    });
  }

  void _fitTrailOrPerson(
    PersonnelLiveLocation sel,
    List<PersonnelLocationTrailPoint> pts,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (pts.length >= 2) {
          final bounds = LatLngBounds.fromPoints(
            pts
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(growable: false),
          );
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(36),
            ),
          );
        } else {
          _mapController.move(
            LatLng(sel.latitude, sel.longitude),
            14,
          );
        }
      } catch (_) {}
    });
  }

  LatLng get _initialCenter {
    final sel = _selected;
    if (sel != null) {
      return LatLng(sel.latitude, sel.longitude);
    }
    if (widget.rows.isNotEmpty) {
      final r = widget.rows.first;
      return LatLng(r.latitude, r.longitude);
    }
    return const LatLng(41.0082, 28.9784);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const primary = FieldSalesDensAppBar.primaryColor;
    final tileProvider = _tileProvider ??
        OfflineAwareTileProvider(
          headers: OfflineMapTileStore.tileRequestHeaders,
        );
    final selected = _selected;
    final selectedKey = selected == null ? null : _personKey(selected);

    final periodEntries = <(PersonnelTrailPeriod, String)>[
      (PersonnelTrailPeriod.today, 'field_sales.period_today'),
      (PersonnelTrailPeriod.thisWeek, 'field_sales.period_this_week'),
    ];

    if (!_tilesReady) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.translate('field_sales.gps_last_location_empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      );
    }

    final trailPoints = _trail
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    return Column(
      children: [
        if (widget.rows.length > 1)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 2),
              itemCount: widget.rows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final row = widget.rows[index];
                final key = _personKey(row);
                final label = row.displayName.trim().isEmpty
                    ? (row.salespersonCode.trim().isEmpty
                        ? l10n.translate(
                            'field_sales.gps_salesperson_unknown',
                          )
                        : row.salespersonCode.trim())
                    : row.displayName.trim();
                final short = label.length > 18
                    ? '${label.substring(0, 16)}…'
                    : label;
                return SizedBox(
                  width: 110,
                  child: FieldSalesDensChip(
                    label: short,
                    selected: selectedKey == key,
                    fontSize: 11,
                    onTap: () => widget.onSelectPerson(row),
                  ),
                );
              },
            ),
          ),
        if (selected != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 2),
            child: FieldSalesDensChipRow(
              primary: primary,
              fontSize: 11,
              items: [
                for (final entry in periodEntries)
                  FieldSalesDensChipItem(
                    label: l10n.translate(entry.$2),
                    selected: _period == entry.$1,
                    onTap: () => _applyPeriod(entry.$1),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 2, 10, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected == null
                      ? l10n.translate('field_sales.gps_select_person')
                      : _trailLoading
                          ? l10n.translate('field_sales.gps_trail_loading')
                          : l10n.translate(
                              'field_sales.gps_trail_points',
                              args: {'count': '${_trail.length}'},
                            ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              if (selected != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: widget.onClearSelection,
                  child: Text(
                    l10n.translate('field_sales.gps_clear_selection'),
                    style: const TextStyle(fontSize: 11),
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
                  initialCenter: _initialCenter,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: OfflineMapTileStore.tileUrlTemplate,
                    subdomains: OfflineMapTileStore.tileSubdomains,
                    userAgentPackageName: 'com.exfin.ops',
                    tileProvider: tileProvider,
                  ),
                  if (trailPoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: trailPoints,
                          color: primary.withValues(alpha: 0.75),
                          strokeWidth: 3.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      for (final row in widget.rows)
                        Marker(
                          point: LatLng(row.latitude, row.longitude),
                          width: 56,
                          height: 56,
                          child: GestureDetector(
                            onTap: () {
                              widget.onSelectPerson(row);
                              try {
                                _mapController.move(
                                  LatLng(row.latitude, row.longitude),
                                  14,
                                );
                              } catch (_) {}
                            },
                            child: _PersonnelMapPin(
                              row: row,
                              selected: selectedKey == _personKey(row),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (_trailLoading)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (selected != null &&
                  !_trailLoading &&
                  _trail.isEmpty)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.translate('field_sales.gps_trail_empty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// {@template _personnel_map_pin}
/// Canlı personel pin (doğruluk rengi + seçili vurgu).
/// {@endtemplate}
class _PersonnelMapPin extends StatelessWidget {
  /// [row]: Canlı konum
  final PersonnelLiveLocation row;

  /// [selected]: Seçili mi
  final bool selected;

  const _PersonnelMapPin({
    required this.row,
    required this.selected,
  });

  Color _bandColor(LiveLocationAccuracyBand band) {
    switch (band) {
      case LiveLocationAccuracyBand.good:
        return Colors.green.shade700;
      case LiveLocationAccuracyBand.fair:
        return Colors.orange.shade800;
      case LiveLocationAccuracyBand.poor:
        return Colors.red.shade700;
      case LiveLocationAccuracyBand.unknown:
        return FieldSalesDensAppBar.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final band = LiveLocationQuality.accuracyBand(row.accuracy);
    final color = _bandColor(band);
    final code = row.salespersonCode.trim().isEmpty
        ? row.displayName.trim()
        : row.salespersonCode.trim();
    final short = code.length > 8 ? '${code.substring(0, 7)}…' : code;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected ? Icons.location_on : Icons.person_pin_circle,
          color: color,
          size: selected ? 32 : 28,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: selected
                ? FieldSalesDensAppBar.primaryColor
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: FieldSalesDensAppBar.primaryColor,
              width: 1,
            ),
          ),
          child: Text(
            short,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : FieldSalesDensAppBar.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
