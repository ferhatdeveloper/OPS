// Dosya Adı: route_map_screen.dart
// Açıklama: Rota haritası dens — SQLite ziyaret noktaları listesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/route_visit_point.dart';
import '../viewmodel/route_map_store.dart';

/// {@template route_map_screen}
/// Rota haritası dens ekranı — aktif rota ziyaret noktaları (SQLite).
/// Route: `/field-sales/route-map`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, RouteMapScreen.routeName);
/// ```
/// {@endtemplate}
class RouteMapScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/route-map`
  static const String routeName = '/field-sales/route-map';

  /// [store]: Test / override için store
  final RouteMapStore? store;

  /// [points]: Verilirse SQLite atlanır (smoke / widget test)
  final List<RouteVisitPoint>? points;

  const RouteMapScreen({
    Key? key,
    this.store,
    this.points,
  }) : super(key: key);

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  /// [_loading]: Yükleniyor
  bool _loading = true;

  /// [_points]: Dens ziyaret noktaları
  List<RouteVisitPoint> _points = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// {@template route_map_screen_load}
  /// SQLite'tan ziyaret noktalarını yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    if (widget.points != null) {
      setState(() {
        _points = widget.points!;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final store = widget.store ?? const RouteMapStore();
      final rows = await store.loadVisitPoints();
      if (!mounted) return;
      setState(() {
        _points = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _points = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.route_map');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _points.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.translate('field_sales.route_map_empty'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Text(
                        l10n.translate(
                          'field_sales.route_map_stops_count',
                          args: {'count': '${_points.length}'},
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _points.length,
                        itemBuilder: (context, index) {
                          return _RouteVisitPointTile(point: _points[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// {@template route_visit_point_tile}
/// Dens ziyaret noktası satırı (sıra · cari · koordinat · durum).
/// {@endtemplate}
class _RouteVisitPointTile extends StatelessWidget {
  /// [point]: Ziyaret noktası
  final RouteVisitPoint point;

  const _RouteVisitPointTile({required this.point});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final codeName = [
      if (point.customerCode.trim().isNotEmpty) point.customerCode.trim(),
      if (point.customerName.trim().isNotEmpty) point.customerName.trim(),
    ].join(' · ');
    final title = codeName.isNotEmpty ? codeName : point.customerId;
    final coords = point.hasCoords
        ? '${point.latitude!.toStringAsFixed(4)}, '
            '${point.longitude!.toStringAsFixed(4)}'
        : l10n.translate('field_sales.route_map_no_coords');
    final statusKey = point.isVisited
        ? 'field_sales.visit_completed'
        : 'field_sales.route_map_pending_stop';
    final statusColor = point.isVisited ? Colors.green : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: statusColor,
          child: Text(
            '${point.visitOrder}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          l10n.translate(
            'field_sales.route_map_point_subtitle',
            args: {
              'coords': coords,
              'status': l10n.translate(statusKey),
            },
          ),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: point.isMandatory
            ? Text(
                l10n.translate('field_sales.mandatory'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
    );
  }
}
