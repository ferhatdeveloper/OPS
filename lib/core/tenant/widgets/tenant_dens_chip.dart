// Dosya Adı: tenant_dens_chip.dart
// Açıklama: Dashboard aktif kiracı dens chip’i (TenantStore)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../localization/app_localization.dart';
import '../../utils/color_utils.dart';
import '../tenant_context.dart';
import '../tenant_store.dart';

/// {@template tenant_dens_chip}
/// Dashboard’da aktif PostgREST kiracı dens chip.
/// [TenantStore] okur; boş bağlamda gizlenir (DayStatusDensChip dens dili).
///
/// Kullanım örneği:
/// ```dart
/// const TenantDensChip()
/// ```
/// {@endtemplate}
class TenantDensChip extends StatefulWidget {
  /// [store]: Test/enjeksiyon için isteğe bağlı store
  final TenantStore store;

  /// {@macro tenant_dens_chip}
  const TenantDensChip({
    Key? key,
    this.store = const TenantStore(),
  }) : super(key: key);

  /// [labelKey]: Chip l10n anahtarı (`{code}` yer tutucusu)
  static const String labelKey = 'auth.tenant_chip';

  /// {@template tenant_dens_chip_resolve_label}
  /// Aktif bağlamdan chip kod/adı; yoksa null.
  ///
  /// Parametreler:
  /// - [ctx]: Kiracı bağlamı
  ///
  /// Dönüş değeri:
  /// - [String?]: `chipLabel` veya null
  /// {@endtemplate}
  static String? resolveLabel(TenantContext? ctx) {
    if (ctx == null || ctx.isEmpty) return null;
    final label = ctx.chipLabel;
    return label.isEmpty ? null : label;
  }

  @override
  State<TenantDensChip> createState() => _TenantDensChipState();
}

class _TenantDensChipState extends State<TenantDensChip> {
  /// [_label]: null = yok / yükleniyor sonrası gizli
  String? _label;

  /// [_ready]: İlk yükleme tamamlandı mı
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template tenant_dens_chip_reload}
  /// TenantStore’dan aktif kiracı etiketini yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    final memory = TenantDensChip.resolveLabel(TenantStore.current);
    if (memory != null && mounted) {
      setState(() {
        _label = memory;
        _ready = true;
      });
    }

    final ctx = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _label = TenantDensChip.resolveLabel(ctx.isEmpty ? null : ctx);
      _ready = true;
    });
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
      TenantDensChip.labelKey,
      args: {'code': _label!},
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? ColorUtils.withAlpha(colorScheme.surface, 0.5)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }
}
