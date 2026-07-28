// Dosya Adı: active_warehouse_dens_chip.dart
// Açıklama: Dashboard aktif ambar dens chip (ActiveWarehouseStore)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/color_utils.dart';
import '../../companies/view/company_list_screen.dart';
import '../model/active_warehouse_session.dart';
import '../viewmodel/active_warehouse_store.dart';

/// {@template active_warehouse_dens_chip}
/// Dashboard’da aktif ambar/mağaza dens chip.
/// Tıklanınca [CompanyListScreen] Depo sekmesi açılır;
/// [ActiveWarehouseStore.revision] ile etiket yenilenir.
///
/// Kullanım örneği:
/// ```dart
/// const ActiveWarehouseDensChip()
/// ```
/// {@endtemplate}
class ActiveWarehouseDensChip extends StatefulWidget {
  /// [store]: Test/enjeksiyon için isteğe bağlı store
  final ActiveWarehouseStore store;

  /// {@macro active_warehouse_dens_chip}
  const ActiveWarehouseDensChip({
    Key? key,
    this.store = const ActiveWarehouseStore(),
  }) : super(key: key);

  /// [labelKey]: Chip l10n anahtarı (`{label}` yer tutucusu)
  static const String labelKey = 'field_sales.warehouse_chip';

  /// Widget test / semantik anahtarı
  static const Key tapKey = Key('active_warehouse_dens_chip');

  /// {@template active_warehouse_dens_chip_resolve_label}
  /// Oturumdan chip etiketi; boşsa null.
  /// {@endtemplate}
  static String? resolveLabel(ActiveWarehouseSession? session) {
    if (session == null || session.isEmpty) return null;
    final label = session.label.trim();
    return label.isEmpty ? null : label;
  }

  @override
  State<ActiveWarehouseDensChip> createState() =>
      _ActiveWarehouseDensChipState();
}

class _ActiveWarehouseDensChipState extends State<ActiveWarehouseDensChip> {
  String? _label;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    ActiveWarehouseStore.revision.addListener(_onStoreRevision);
    _reload();
  }

  @override
  void dispose() {
    ActiveWarehouseStore.revision.removeListener(_onStoreRevision);
    super.dispose();
  }

  void _onStoreRevision() {
    if (!mounted) return;
    final memory = ActiveWarehouseDensChip.resolveLabel(
      ActiveWarehouseStore.current,
    );
    setState(() {
      _label = memory;
      _ready = true;
    });
    _reload();
  }

  Future<void> _reload() async {
    final memory = ActiveWarehouseDensChip.resolveLabel(
      ActiveWarehouseStore.current,
    );
    if (memory != null && mounted) {
      setState(() {
        _label = memory;
        _ready = true;
      });
    }

    final session = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _label = ActiveWarehouseDensChip.resolveLabel(
        session.isEmpty ? null : session,
      );
      _ready = true;
    });
  }

  /// Birleşik bağlam (Depo) ekranına gider; dönüşte etiket yenilenir.
  Future<void> _openWarehouseList() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: CompanyListScreen.routeName,
          arguments: CompanyContextTab.warehouses,
        ),
        builder: (_) => const CompanyListScreen(
          initialTab: CompanyContextTab.warehouses,
        ),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _label == null) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalization.of(context);
    final text = l10n.translate(
      ActiveWarehouseDensChip.labelKey,
      args: {'label': _label!},
    );
    final fg = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return Semantics(
      button: true,
      label: text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ActiveWarehouseDensChip.tapKey,
          onTap: _openWarehouseList,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 140, minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorUtils.withAlpha(colorScheme.surface, 0.5)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: fg),
                  ),
                ),
                Icon(Icons.expand_more, size: 12, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
