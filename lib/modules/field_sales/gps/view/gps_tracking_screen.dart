// Dosya Adı: gps_tracking_screen.dart
// Açıklama: GPS Takip dens — son konum listesi (SQLite gps_logs / seed)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/gps_last_location_record.dart';
import '../model/gps_last_location_seed.dart';
import '../viewmodel/gps_last_location_store.dart';

/// {@template gps_tracking_screen}
/// GPS konum takibi dens — plasiyer son konum listesi.
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

  /// [store]: SQLite erişim (test enjeksiyonu)
  final GpsLastLocationStore store;

  /// [records]: Verilirse DB atlanır (widget smoke)
  final List<GpsLastLocationRecord>? records;

  const GpsTrackingScreen({
    Key? key,
    this.store = const GpsLastLocationStore(),
    this.records,
  }) : super(key: key);

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  /// [_rows]: Son konum dens satırları
  List<GpsLastLocationRecord> _rows = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_dateFmt]: Dens zaman biçimi
  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    if (widget.records != null) {
      _rows = List<GpsLastLocationRecord>.from(widget.records!);
      _loading = false;
    } else {
      _load();
    }
  }

  /// {@template gps_tracking_load}
  /// SQLite son konumları yükler; hata / boşta seed fallback.
  /// {@endtemplate}
  Future<void> _load() async {
    setState(() => _loading = true);
    List<GpsLastLocationRecord> rows;
    try {
      rows = await widget.store.loadLastLocations();
      if (rows.isEmpty) {
        rows = GpsLastLocationSeed.defaultRows;
      }
    } catch (_) {
      rows = GpsLastLocationSeed.defaultRows;
    }
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.gps_tracking');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: l10n.translate('common.reload'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.gps_last_location_empty'),
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    final code = row.salespersonCode.trim().isEmpty
                        ? l10n.translate('field_sales.gps_salesperson_unknown')
                        : row.salespersonCode.trim();
                    final titleText = row.label.trim().isEmpty
                        ? code
                        : row.label.trim();
                    final synced = row.isSynced == 1;
                    final statusColor =
                        synced ? Colors.green : Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xFF375A7F),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          titleText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.translate('field_sales.gps_salesperson')}: $code',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                row.coordinateText,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dateFmt.format(row.recordedAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.translate(
                              synced
                                  ? 'field_sales.gps_synced'
                                  : 'field_sales.gps_pending_sync',
                            ),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
