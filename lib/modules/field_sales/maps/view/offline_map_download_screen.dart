// Dosya Adı: offline_map_download_screen.dart
// Açıklama: İsteğe bağlı offline harita bölgesi indirme dens ekranı
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/offline_map_region.dart';
import '../viewmodel/offline_map_tile_store.dart';

/// {@template offline_map_download_screen}
/// Offline harita indirme dens — kullanıcı seçer, zorunlu değil.
/// Route: `/field-sales/offline-map-download`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, OfflineMapDownloadScreen.routeName);
/// ```
/// {@endtemplate}
class OfflineMapDownloadScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/offline-map-download';

  /// [store]: Test enjeksiyonu
  final OfflineMapTileStore? store;

  /// [regions]: Test enjeksiyonu
  final List<OfflineMapRegion>? regions;

  /// {@macro offline_map_download_screen}
  const OfflineMapDownloadScreen({
    Key? key,
    this.store,
    this.regions,
  }) : super(key: key);

  @override
  State<OfflineMapDownloadScreen> createState() =>
      _OfflineMapDownloadScreenState();
}

class _OfflineMapDownloadScreenState extends State<OfflineMapDownloadScreen> {
  late final OfflineMapTileStore _store;
  late final List<OfflineMapRegion> _regions;

  Set<String> _downloaded = <String>{};
  String? _activeRegionId;
  double _progress = 0;
  bool _loadingMeta = true;
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? const OfflineMapTileStore();
    _regions = widget.regions ?? OfflineMapRegion.presets;
    _refreshMeta();
  }

  Future<void> _refreshMeta() async {
    final ids = await _store.downloadedRegionIds();
    if (!mounted) return;
    setState(() {
      _downloaded = ids;
      _loadingMeta = false;
    });
  }

  Future<void> _download(OfflineMapRegion region) async {
    if (_activeRegionId != null) return;
    if (!_store.supportsFileCache) {
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.offline_maps.web_unsupported'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _activeRegionId = region.id;
      _progress = 0;
      _cancelRequested = false;
    });

    try {
      await _store.downloadRegion(
        region,
        shouldCancel: () => _cancelRequested,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p.fraction;
            if (p.done) {
              _activeRegionId = null;
            }
          });
        },
      );
      await _refreshMeta();
    } catch (_) {
      if (!mounted) return;
      setState(() => _activeRegionId = null);
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.offline_maps.download_failed'),
          ),
        ),
      );
    }
  }

  Future<void> _delete(OfflineMapRegion region) async {
    await _store.deleteRegion(region);
    await _refreshMeta();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.offline_map_download'),
        backgroundColor: primary,
      ),
      body: _loadingMeta
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                  child: Text(
                    l10n.translate('field_sales.offline_maps.download_hint'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
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
                if (_activeRegionId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                    child: Column(
                      children: [
                        LinearProgressIndicator(value: _progress),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 32,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _cancelRequested = true),
                            child: Text(
                              l10n.translate('common.cancel'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    itemCount: _regions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final region = _regions[index];
                      final isDown = _downloaded.contains(region.id);
                      final isBusy = _activeRegionId == region.id;
                      final tiles = region.estimateTileCount();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDown
                                  ? Icons.download_done
                                  : Icons.download_for_offline_outlined,
                              size: 20,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.translate(region.nameKey),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    l10n.translate(
                                      'field_sales.offline_maps.tile_estimate',
                                      args: {'count': '$tiles'},
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isBusy)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else if (isDown)
                              FieldSalesDensAppBar.densIconButton(
                                icon: Icons.delete_outline,
                                tooltip: l10n.translate(
                                  'field_sales.offline_maps.delete',
                                ),
                                onPressed: () => _delete(region),
                              )
                            else
                              SizedBox(
                                height: 32,
                                child: TextButton(
                                  onPressed: _activeRegionId != null
                                      ? null
                                      : () => _download(region),
                                  child: Text(
                                    l10n.translate(
                                      'field_sales.offline_maps.download',
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
