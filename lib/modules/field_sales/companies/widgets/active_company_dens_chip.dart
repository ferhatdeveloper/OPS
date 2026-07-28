// Dosya Adı: active_company_dens_chip.dart
// Açıklama: Dashboard aktif firma/dönem dens chip (ActiveCompanyStore)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/color_utils.dart';
import '../model/active_company_session.dart';
import '../view/company_list_screen.dart';
import '../viewmodel/active_company_store.dart';

/// {@template active_company_dens_chip}
/// Dashboard’da aktif firma/dönem dens chip.
/// Tıklanınca [CompanyListScreen] (Firmalar sekmesi) açılır;
/// [ActiveCompanyStore.revision] ile etiket yenilenir.
///
/// Kullanım örneği:
/// ```dart
/// const ActiveCompanyDensChip()
/// ```
/// {@endtemplate}
class ActiveCompanyDensChip extends StatefulWidget {
  /// [store]: Test/enjeksiyon için isteğe bağlı store
  final ActiveCompanyStore store;

  /// {@macro active_company_dens_chip}
  const ActiveCompanyDensChip({
    Key? key,
    this.store = const ActiveCompanyStore(
      syncLogoPrefs: false,
      syncPostgresContext: false,
    ),
  }) : super(key: key);

  /// [labelKey]: Chip l10n anahtarı (`{label}` yer tutucusu)
  static const String labelKey = 'field_sales.company_chip';

  /// Widget test / semantik anahtarı
  static const Key tapKey = Key('active_company_dens_chip');

  /// {@template active_company_dens_chip_resolve_label}
  /// Oturumdan dens chip etiketi (`001_01`); boşsa null.
  /// {@endtemplate}
  static String? resolveLabel(ActiveCompanySession? session) {
    if (session == null || session.isEmpty) return null;
    final label = session.densChipLabel.trim();
    return label.isEmpty ? null : label;
  }

  @override
  State<ActiveCompanyDensChip> createState() => _ActiveCompanyDensChipState();
}

class _ActiveCompanyDensChipState extends State<ActiveCompanyDensChip> {
  String? _label;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    ActiveCompanyStore.revision.addListener(_onStoreRevision);
    _reload();
  }

  @override
  void dispose() {
    ActiveCompanyStore.revision.removeListener(_onStoreRevision);
    super.dispose();
  }

  void _onStoreRevision() {
    if (!mounted) return;
    final memory = ActiveCompanyDensChip.resolveLabel(
      ActiveCompanyStore.current,
    );
    setState(() {
      _label = memory;
      _ready = true;
    });
    _reload();
  }

  Future<void> _reload() async {
    final memory = ActiveCompanyDensChip.resolveLabel(
      ActiveCompanyStore.current,
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
      _label = ActiveCompanyDensChip.resolveLabel(
        session.isEmpty ? null : session,
      );
      _ready = true;
    });
  }

  /// Birleşik bağlam ekranına (Firmalar) gider; dönüşte etiket yenilenir.
  Future<void> _openCompanyList() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: CompanyListScreen.routeName,
          arguments: CompanyContextTab.firms,
        ),
        builder: (_) => const CompanyListScreen(
          initialTab: CompanyContextTab.firms,
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
      ActiveCompanyDensChip.labelKey,
      args: {'label': _label!},
    );
    final fg = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return Semantics(
      button: true,
      label: text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ActiveCompanyDensChip.tapKey,
          onTap: _openCompanyList,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 110, minHeight: 24),
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
