// Dosya Adı: whms_device_list_screen.dart
// Açıklama: WHMS /whms/devices dens cihaz listesi (SQLite store)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../contract/whms_route_map.dart';
import '../model/whms_device.dart';
import '../viewmodel/whms_device_store.dart';

/// {@template whms_device_list_screen}
/// Cihaz dens listesi — offline store, ERP zorunlu değil.
/// Route: `/whms/devices`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsDeviceListScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsDeviceListScreen extends StatefulWidget {
  /// Named route — `/whms/devices`
  static const String routeName = WhmsRouteMap.whmsDevices;

  /// Store enjeksiyonu (test)
  final WhmsDeviceStore? store;

  /// Test satırları
  final List<WhmsDevice>? rows;

  /// {@macro whms_device_list_screen}
  const WhmsDeviceListScreen({
    super.key,
    this.store,
    this.rows,
  });

  @override
  State<WhmsDeviceListScreen> createState() => _WhmsDeviceListScreenState();
}

class _WhmsDeviceListScreenState extends State<WhmsDeviceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WhmsDevice> _all = const [];
  List<WhmsDevice> _filtered = const [];
  bool _loading = true;

  WhmsDeviceStore get _store => widget.store ?? const WhmsDeviceStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<WhmsDevice>.from(widget.rows!);
      _filtered = List<WhmsDevice>.from(_all);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template whms_device_list_screen_load}
  /// Store’dan cihaz listesini yükler.
  /// {@endtemplate}
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _store.list();
      if (!mounted) return;
      setState(() {
        _all = rows;
        _applyFilter(_searchController.text);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = const [];
        _filtered = const [];
        _loading = false;
      });
    }
  }

  /// {@template whms_device_list_screen_apply_filter}
  /// Arama metnine göre filtreler.
  ///
  /// Parametreler:
  /// - [q]: Arama metni
  /// {@endtemplate}
  void _applyFilter(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) {
      _filtered = List<WhmsDevice>.from(_all);
      return;
    }
    _filtered = _all.where((d) {
      final hay = [
        d.name,
        d.mac ?? '',
        d.model ?? '',
        d.osName ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(needle);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.menu.sub_whms_devices'),
        showCalculatorHome: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _applyFilter(v)),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('whms.devices.search_hint'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                        child: Text(
                          l10n.translate('whms.devices.empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color: FieldSalesDensTheme.muted(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final d = _filtered[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: FieldSalesDensTheme.surface(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: FieldSalesDensTheme.title(context),
                                  ),
                                ),
                                if ((d.mac ?? '').isNotEmpty ||
                                    (d.model ?? '').isNotEmpty)
                                  Text(
                                    [
                                      if ((d.mac ?? '').isNotEmpty) d.mac,
                                      if ((d.model ?? '').isNotEmpty)
                                        d.model,
                                    ].join(' · '),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: FieldSalesDensTheme.muted(context),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
