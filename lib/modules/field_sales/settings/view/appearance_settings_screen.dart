// Dosya Adı: appearance_settings_screen.dart
// Açıklama: Font büyüklüğü + tema rengi dens ayar ekranı
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/language_service.dart';
import '../../reports/view/report_logo_settings_screen.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../reports/model/report_locale_resolver.dart';
import '../../reports/viewmodel/report_language_preference_store.dart';
import '../model/appearance_settings_record.dart';
import '../viewmodel/appearance_settings_provider.dart';

/// {@template appearance_settings_screen}
/// Font büyüklüğü slider + tema rengi seçici dens ekranı.
/// Onayla kaydeder; Kapat / geri kaydetmeden kapatır.
/// Route: `/field-sales/appearance-settings`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, AppearanceSettingsScreen.routeName);
/// ```
/// {@endtemplate}
class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route
  static const String routeName = '/field-sales/appearance-settings';

  /// {@macro appearance_settings_screen}
  const AppearanceSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  /// [_draftFontSize]: Onaylanmamış font değeri
  double _draftFontSize = AppearanceSettingsRecord.defaultFontSize;

  /// [_draftColorValue]: Onaylanmamış primary ARGB
  int _draftColorValue =
      AppearanceSettingsRecord.defaultPrimaryColorValue;

  /// [_draftReportLocale]: Varsayılan rapor dili (null → uygulama dili)
  String? _draftReportLocale;

  /// [_reportLangStore]: Rapor dili tercihi
  final ReportLanguagePreferenceStore _reportLangStore =
      const ReportLanguagePreferenceStore();

  /// [_loaded]: İlk yükleme tamamlandı mı
  bool _loaded = false;

  /// [_saving]: Kayıt sırasında true
  bool _saving = false;

  /// Preset primary renkler (dens Material paleti)
  static const List<Color> _presetColors = [
    FieldSalesDensAppBar.primaryColor,
    FieldSalesDensAppBar.accentColor,
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
    Color(0xFF37474F),
    Color(0xFF5D4037),
  ];

  @override
  void initState() {
    super.initState();
    _hydrateDraft();
  }

  /// {@template _hydrateDraft}
  /// Kayıtlı görünüm ayarlarını taslağa yükler.
  /// {@endtemplate}
  Future<void> _hydrateDraft() async {
    final record =
        await ref.read(appearanceSettingsStoreProvider).load();
    final reportLocale = await _reportLangStore.load();
    if (!mounted) return;
    setState(() {
      _draftFontSize = record.fontSize;
      _draftColorValue = record.primaryColorValue;
      _draftReportLocale = reportLocale;
      _loaded = true;
    });
  }

  /// {@template _colorArgb}
  /// [Color] → ARGB int.
  /// {@endtemplate}
  int _colorArgb(Color c) {
    // ignore: deprecated_member_use
    return c.value;
  }

  /// {@template _confirm}
  /// Taslağı kaydeder ve ekranı kapatır.
  /// {@endtemplate}
  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(appearanceSettingsProvider.notifier).apply(
            AppearanceSettingsRecord(
              fontSize: _draftFontSize,
              primaryColorValue: _draftColorValue,
            ),
          );
      await _reportLangStore.save(_draftReportLocale);
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template _dismiss}
  /// Kaydetmeden kapatır.
  /// {@endtemplate}
  void _dismiss() {
    Navigator.pop(context);
  }

  /// {@template _pickColor}
  /// Dens renk seçici diyalog açar.
  /// {@endtemplate}
  Future<void> _pickColor() async {
    final l10n = AppLocalization.of(context);
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.translate('settings.theme_color'),
            style: const TextStyle(fontSize: 16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors.map((c) {
              final argb = _colorArgb(c);
              final selected = argb == _draftColorValue;
              return InkWell(
                onTap: () => Navigator.pop(ctx, argb),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? Theme.of(ctx).colorScheme.onSurface
                          : Colors.black26,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.translate('common.close')),
            ),
          ],
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _draftColorValue = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final draftColor = Color(_draftColorValue);
    final valueLabel = _draftFontSize.toStringAsFixed(2).replaceAll('.', ',');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('settings.appearance'),
        useGradient: true,
        showCalculatorHome: false,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.translate('settings.font_size'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: AppearanceSettingsRecord.clampFontSize(
                        _draftFontSize,
                      ),
                      min: AppearanceSettingsRecord.minFontSize,
                      max: AppearanceSettingsRecord.maxFontSize,
                      divisions: 24,
                      activeColor: draftColor,
                      onChanged: (v) {
                        setState(() => _draftFontSize = v);
                      },
                    ),
                  ),
                  Text(
                    valueLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('settings.font_sample'),
                    style: TextStyle(fontSize: _draftFontSize),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.translate('settings.theme_color'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _pickColor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: draftColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.translate('settings.theme_color_pick'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('settings.default_report_language'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('settings.default_report_language_hint'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<String?>(
                    value: _draftReportLocale,
                    isDense: true,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          l10n.translate(
                            'settings.default_report_language_app',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      ...LanguageService.supportedLanguages
                          .where(
                            (lang) => ReportLocaleResolver.supportedCodes
                                .contains(lang.code),
                          )
                          .map(
                            (lang) => DropdownMenuItem<String?>(
                              value: lang.code,
                              child: Text(
                                lang.localName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                    ],
                    onChanged: (v) {
                      setState(() => _draftReportLocale = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.image_outlined, size: 20),
              title: Text(
                l10n.translate('settings.report_logo'),
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                l10n.translate('settings.report_logo_desc'),
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  ReportLogoSettingsScreen.routeName,
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _saving ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FieldSalesDensAppBar.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.translate('common.confirm'),
                        style: const TextStyle(fontSize: 14),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: _saving ? null : _dismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FieldSalesDensAppBar.primaryColor,
                  side: const BorderSide(
                    color: FieldSalesDensAppBar.primaryColor,
                  ),
                ),
                child: Text(
                  l10n.translate('common.close'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
