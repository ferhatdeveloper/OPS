// Dosya Adı: gps_tracking_screen.dart
// Açıklama: Personel canlı konum dens liste + harita (pin / trail)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:async';
import '../../shared/view/field_sales_dens_theme.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/gps_last_location_seed.dart';
import '../model/live_location_quality.dart';
import '../model/live_location_transport.dart';
import '../model/personnel_live_location.dart';
import '../model/personnel_location_trail_point.dart';
import '../viewmodel/live_location_realtime_client.dart';
import '../viewmodel/personnel_live_location_store.dart';
import '../viewmodel/personnel_location_trail_store.dart';
import '../viewmodel/vehicle_camera_settings_store.dart';
import 'gps_tracking_map_pane.dart';
import 'vehicle_camera_broadcast_screen.dart';
import 'vehicle_camera_monitor_screen.dart';
import 'vehicle_camera_settings_screen.dart';

/// {@template gps_tracking_view_mode}
/// GPS takip görünüm: dens liste veya harita.
/// {@endtemplate}
enum GpsTrackingViewMode {
  /// Liste
  list,

  /// Harita (canlı pin + trail)
  map,
}

/// {@template gps_tracking_screen}
/// Personel canlı / son konum dens liste + harita.
/// Realtime/WS varsa kullanır; yoksa HTTP poll.
/// Route: `/field-sales/gps-tracking`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, GpsTrackingScreen.routeName);
/// ```
/// {@endtemplate}
class GpsTrackingScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/gps-tracking`
  static const String routeName = GpsLastLocationSeed.route;

  /// [store]: Canlı konum kaynağı
  final PersonnelLiveLocationStore store;

  /// [trailStore]: Geçmiş trail kaynağı
  final PersonnelLocationTrailStore trailStore;

  /// [cameraSettings]: Araç kamera parametresi
  final VehicleCameraSettingsStore cameraSettings;

  /// [records]: Verilirse DB atlanır (widget smoke)
  final List<PersonnelLiveLocation>? records;

  /// [injectedTrail]: Harita trail smoke (DB atlanır)
  final List<PersonnelLocationTrailPoint>? injectedTrail;

  /// [initialMode]: Başlangıç görünümü (test)
  final GpsTrackingViewMode initialMode;

  const GpsTrackingScreen({
    Key? key,
    this.store = const PersonnelLiveLocationStore(),
    this.trailStore = const PersonnelLocationTrailStore(),
    this.cameraSettings = const VehicleCameraSettingsStore(),
    this.records,
    this.injectedTrail,
    this.initialMode = GpsTrackingViewMode.list,
  }) : super(key: key);

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  List<PersonnelLiveLocation> _rows = const [];
  bool _loading = true;
  bool _cameraEnabled = false;
  LiveLocationTransportMode _transport = LiveLocationTransportMode.httpPoll;
  bool _realtimeConnected = false;
  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy HH:mm:ss');
  LiveLocationRealtimeClient? _watch;
  StreamSubscription<LiveLocationWatchEvent>? _watchSub;
  Timer? _ageTicker;

  late GpsTrackingViewMode _mode;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (widget.records != null) {
      _rows = List<PersonnelLiveLocation>.from(widget.records!);
      _loading = false;
    } else {
      _watch = widget.store.createWatchClient();
      _watchSub = _watch!.events.listen((event) {
        if (!mounted) return;
        setState(() {
          _rows = event.rows;
          _transport = event.mode;
          _realtimeConnected = event.realtimeConnected;
          _loading = false;
        });
      });
      unawaited(_watch!.start());
    }
    _ageTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _rows.isEmpty || _mode != GpsTrackingViewMode.list) {
        return;
      }
      setState(() {});
    });
    _loadCameraFlag();
  }

  @override
  void dispose() {
    _watchSub?.cancel();
    unawaited(_watch?.dispose() ?? Future<void>.value());
    _ageTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadCameraFlag() async {
    final s = await widget.cameraSettings.load();
    if (!mounted) return;
    setState(() => _cameraEnabled = s.enabled);
  }

  Future<void> _refresh() async {
    if (widget.records != null) return;
    setState(() => _loading = true);
    try {
      final rows = await widget.store.loadLive();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _personKey(PersonnelLiveLocation row) {
    final uid = row.userId.trim();
    return uid.isEmpty ? row.salespersonCode.trim() : uid;
  }

  void _selectPerson(PersonnelLiveLocation row, {bool switchToMap = true}) {
    setState(() {
      _selectedUserId = _personKey(row);
      if (switchToMap) _mode = GpsTrackingViewMode.map;
    });
  }

  void _clearSelection() {
    setState(() => _selectedUserId = null);
  }

  String _ageText(AppLocalization l10n, PersonnelLiveLocation row) {
    final bucket = LiveLocationQuality.ageBucket(row.age());
    switch (bucket.unit) {
      case 'minutes':
        return l10n.translate(
          'field_sales.gps_age_minutes',
          args: {'min': '${bucket.value}'},
        );
      case 'hours':
        return l10n.translate(
          'field_sales.gps_age_hours',
          args: {'hr': '${bucket.value}'},
        );
      default:
        return l10n.translate(
          'field_sales.gps_age_seconds',
          args: {'sec': '${bucket.value}'},
        );
    }
  }

  String _accuracyText(AppLocalization l10n, PersonnelLiveLocation row) {
    final a = row.accuracy;
    if (a == null || a <= 0) {
      return l10n.translate('field_sales.gps_accuracy_unknown');
    }
    final band = LiveLocationQuality.accuracyBand(a);
    final meters = l10n.translate(
      'field_sales.gps_accuracy_m',
      args: {'m': a.round().toString()},
    );
    final bandLabel = l10n.translate(
      LiveLocationQuality.accuracyBandKey(band),
    );
    if (band == LiveLocationAccuracyBand.unknown) return meters;
    return '$meters · $bandLabel';
  }

  Color _bandColor(LiveLocationAccuracyBand band) {
    switch (band) {
      case LiveLocationAccuracyBand.good:
        return Colors.green.shade700;
      case LiveLocationAccuracyBand.fair:
        return Colors.orange.shade800;
      case LiveLocationAccuracyBand.poor:
        return Colors.red.shade700;
      case LiveLocationAccuracyBand.unknown:
        return Colors.grey.shade600;
    }
  }

  String _transportLabel(AppLocalization l10n) {
    if (_transport == LiveLocationTransportMode.realtime &&
        _realtimeConnected) {
      return l10n.translate('field_sales.gps_transport_realtime');
    }
    if (_transport == LiveLocationTransportMode.localOnly) {
      return l10n.translate('field_sales.gps_transport_local');
    }
    return l10n.translate('field_sales.gps_transport_poll');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.gps_tracking');
    const primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(
              primary: primary,
              fontSize: 11,
              items: [
                FieldSalesDensChipItem(
                  label: l10n.translate('field_sales.gps_view_list'),
                  selected: _mode == GpsTrackingViewMode.list,
                  onTap: () => setState(
                    () => _mode = GpsTrackingViewMode.list,
                  ),
                ),
                FieldSalesDensChipItem(
                  label: l10n.translate('field_sales.gps_view_map'),
                  selected: _mode == GpsTrackingViewMode.map,
                  onTap: () => setState(
                    () => _mode = GpsTrackingViewMode.map,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.translate(
              'field_sales.stubs.vehicle_camera_settings',
            ),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                VehicleCameraSettingsScreen.routeName,
              );
              await _loadCameraFlag();
            },
          ),
          if (_cameraEnabled)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.videocam_outlined,
              tooltip: l10n.translate('field_sales.vehicle_camera_monitor'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  VehicleCameraMonitorScreen.routeName,
                );
              },
            ),
          if (_cameraEnabled)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.camera_alt_outlined,
              tooltip: l10n.translate('field_sales.vehicle_camera_broadcast'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  VehicleCameraBroadcastScreen.routeName,
                );
              },
            ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            tooltip: l10n.translate('common.reload'),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.records == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
              child: Row(
                children: [
                  Icon(
                    _realtimeConnected ? Icons.bolt : Icons.sync,
                    size: 14,
                    color: FieldSalesDensAppBar.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.translate(
                        _realtimeConnected
                            ? 'field_sales.gps_poll_fast'
                            : 'field_sales.gps_poll_backoff',
                        args: {
                          'sec': _realtimeConnected
                              ? '1'
                              : '${LiveLocationQuality.managerPollInterval.inSeconds}',
                        },
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    _transportLabel(l10n),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _mode == GpsTrackingViewMode.map
                    ? GpsTrackingMapPane(
                        rows: _rows,
                        selectedUserId: _selectedUserId,
                        onSelectPerson: (row) => _selectPerson(row),
                        onClearSelection: _clearSelection,
                        trailStore: widget.trailStore,
                        injectedTrail: widget.injectedTrail,
                      )
                    : _buildList(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalization l10n) {
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.translate('field_sales.gps_last_location_empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final code = row.salespersonCode.trim().isEmpty
            ? l10n.translate('field_sales.gps_salesperson_unknown')
            : row.salespersonCode.trim();
        final titleText = row.displayName.trim().isEmpty
            ? code
            : row.displayName.trim();
        final fresh = row.isFresh();
        final statusColor = fresh ? Colors.green : Colors.orange;
        final band = LiveLocationQuality.accuracyBand(row.accuracy);
        final meta =
            '${_accuracyText(l10n, row)} · ${_ageText(l10n, row)}';
        final selected = _selectedUserId == _personKey(row);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectPerson(row, switchToMap: true),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: FieldSalesDensTheme.surface(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? FieldSalesDensAppBar.primaryColor
                      : Colors.grey.shade200,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 20,
                    color: _bandColor(band),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${l10n.translate('field_sales.gps_salesperson')}: $code',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          row.coordinateText,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          meta,
                          style: TextStyle(
                            color: _bandColor(band),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _dateFmt.format(row.updatedAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.translate(
                      fresh
                          ? 'field_sales.gps_live_fresh'
                          : 'field_sales.gps_live_stale',
                    ),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_cameraEnabled) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.videocam,
                        size: 18,
                      ),
                      tooltip: l10n.translate(
                        'field_sales.vehicle_camera_monitor',
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          VehicleCameraMonitorScreen.routeName,
                          arguments: {
                            'userId': row.userId,
                            'salespersonCode': row.salespersonCode,
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
