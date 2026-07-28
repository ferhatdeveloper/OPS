// Dosya Adı: ai_settings_screen.dart
// Açıklama: Çoklu AI sağlayıcı dens ayar — key / model / use-case override
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/ai_api_key_editor.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/ai/ai_provider_config.dart';
import '../../../../core/ai/ai_settings_store.dart';
import '../../../../core/ai/ai_use_case.dart';
import '../../../../core/ai/openrouter_model_catalog.dart';
import '../../../../core/ai/openrouter_model_list_service.dart';
import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../widgets/ai_openrouter_model_picker.dart';
import '../widgets/ai_speech_language_picker.dart';
import '../widgets/ai_tts_engine_picker.dart';
import '../widgets/ai_tts_voice_picker.dart';

/// {@template ai_settings_screen}
/// AI sağlayıcı dens ayar ekranı.
/// Route: `/field-sales/ai-settings`
/// {@endtemplate}
class AiSettingsScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/ai-settings';

  /// [store]: Test inject
  final AiSettingsStore? store;

  /// {@macro ai_settings_screen}
  const AiSettingsScreen({Key? key, this.store}) : super(key: key);

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final AiSettingsStore _store =
      widget.store ?? AiGateway().settingsStore;

  AiSettingsSnapshot _snap = AiSettingsSnapshot.empty();
  bool _loading = true;
  bool _saving = false;

  AiProvider _editProvider = AiProvider.openRouter;
  final _keyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final Map<AiUseCase, TextEditingController> _useCaseCtrls = {
    for (final u in AiUseCase.values) u: TextEditingController(),
  };

  /// Kullanıcı API key alanını düzenledi mi (maske overwrite engeli)
  bool _keyDirty = false;

  /// OpenRouter model listesi
  List<OpenRouterModelInfo> _orModels =
      OpenRouterModelCatalog.fallbackAllowlist;
  bool _orModelsLoading = false;
  bool _orModelsFromApi = false;
  final OpenRouterModelListService _orModelService =
      OpenRouterModelListService();

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    for (final c in _useCaseCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _t(String key) => AppLocalization.of(context).translate(key);

  Future<void> _hydrate() async {
    final snap = await _store.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _editProvider = snap.activeProvider;
      _loading = false;
    });
    _syncEditors();
    if (_editProvider == AiProvider.openRouter) {
      await _loadOpenRouterModels();
    }
  }

  /// OpenRouter model listesini API veya allowlist’ten yükler.
  Future<void> _loadOpenRouterModels() async {
    if (_orModelsLoading) return;
    setState(() => _orModelsLoading = true);
    try {
      final key = await _store.readApiKey(AiProvider.openRouter);
      final result = await _orModelService.loadModels(apiKey: key);
      if (!mounted) return;
      setState(() {
        _orModels = result.models;
        _orModelsFromApi = result.fromApi;
      });
    } finally {
      if (mounted) setState(() => _orModelsLoading = false);
    }
  }

  /// Listeden model seç — alan güncelle + kaydet.
  Future<void> _onOpenRouterModelSelected(String modelId) async {
    final id = modelId.trim();
    if (id.isEmpty) return;
    _modelCtrl.text = id;
    await _store.saveModel(AiProvider.openRouter, id);
    if (!mounted) return;
    final cfg = _snap.configs[AiProvider.openRouter] ??
        AiProviderConfig.defaults(AiProvider.openRouter);
    setState(() {
      _snap = AiSettingsSnapshot(
        activeProvider: _snap.activeProvider,
        configs: {
          ..._snap.configs,
          AiProvider.openRouter: cfg.copyWith(model: id),
        },
        insightsOptIn: _snap.insightsOptIn,
        ttsEnabled: _snap.ttsEnabled,
        speechLanguage: _snap.speechLanguage,
        ttsVoicePersona: _snap.ttsVoicePersona,
        cloudTtsEnabled: _snap.cloudTtsEnabled,
        useCaseModels: _snap.useCaseModels,
      );
    });
    await _snack('ai.model_selected');
  }

  void _syncEditors() {
    final cfg =
        _snap.configs[_editProvider] ?? AiProviderConfig.defaults(_editProvider);
    _modelCtrl.text = cfg.model;
    // Kayıtlı key → maskeli dolu alan; düz key asla controller’a yazılmaz
    _keyDirty = false;
    _keyCtrl.text = AiApiKeyEditor.displayText(hasApiKey: cfg.hasApiKey);
    for (final u in AiUseCase.values) {
      _useCaseCtrls[u]!.text = _snap.useCaseModels[u] ?? '';
    }
  }

  Future<void> _snack(String key) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t(key)), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _saveProvider() async {
    if (_saving) return;
    // obscureText + setState(_saving) rebuild öncesi yakala (Android paste kaybı)
    final provider = _editProvider;
    final modelText = _modelCtrl.text;
    final plainKey = _keyCtrl.text;
    final useCaseTexts = <AiUseCase, String>{
      for (final u in AiUseCase.values) u: _useCaseCtrls[u]!.text,
    };
    final shouldSaveKey = AiApiKeyEditor.shouldPersist(text: plainKey);

    setState(() => _saving = true);
    try {
      await _store.setActiveProvider(provider);
      await _store.saveModel(provider, modelText);
      if (shouldSaveKey) {
        await _store.saveApiKey(provider, plainKey.trim());
      }
      for (final e in useCaseTexts.entries) {
        await _store.saveUseCaseModel(e.key, e.value);
      }
      await _hydrate();
      await _snack('ai.settings_saved');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearKey() async {
    await _store.clearApiKey(_editProvider);
    _keyDirty = false;
    await _hydrate();
    await _snack('ai.key_cleared');
  }

  void _onKeyFieldTap() {
    final cfg = _snap.configs[_editProvider] ??
        AiProviderConfig.defaults(_editProvider);
    if (cfg.hasApiKey && !_keyDirty) {
      setState(() {
        _keyDirty = true;
        _keyCtrl.clear();
      });
    }
  }

  Future<void> _toggleInsights(bool v) async {
    await _store.setInsightsOptIn(v);
    await _hydrate();
  }

  Future<void> _toggleTts(bool v) async {
    await _store.setTtsEnabled(v);
    await _hydrate();
  }

  Future<void> _toggleCloudTts(bool v) async {
    await _store.setCloudTtsEnabled(v);
    await _hydrate();
  }

  Future<void> _setSpeechLanguage(String code) async {
    await _store.setSpeechLanguage(code);
    await _hydrate();
  }

  Future<void> _setTtsVoice(String persona) async {
    await _store.setTtsVoicePersona(persona);
    await _hydrate();
  }

  bool get _hasOpenAiKey {
    final cfg = _snap.configs[AiProvider.openAi];
    return cfg?.hasApiKey == true;
  }

  InputDecoration _denseDeco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final cfg = _snap.configs[_editProvider] ??
        AiProviderConfig.defaults(_editProvider);

    final onMuted = FieldSalesDensTheme.muted(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('ai.settings_title'),
        backgroundColor: FieldSalesDensAppBar.primaryColor,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.save_outlined,
            onPressed: _saving ? null : _saveProvider,
            tooltip: l10n.translate('common.save'),
          ),
        ],
        bottom: FieldSalesDensFilterBar(
          backgroundColor: FieldSalesDensTheme.surface(context),
          children: [
            FieldSalesDensChipRow(
              fontSize: 10,
              items: AiProvider.values
                  .map(
                    (p) => FieldSalesDensChipItem(
                      label: l10n.translate(p.labelKey),
                      selected: _editProvider == p,
                      onTap: () {
                        setState(() => _editProvider = p);
                        _syncEditors();
                        if (p == AiProvider.openRouter) {
                          _loadOpenRouterModels();
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
              children: [
                SwitchListTile.adaptive(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _t('ai.insights_opt_in'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    _t('ai.insights_opt_in_hint'),
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _snap.insightsOptIn,
                  onChanged: _toggleInsights,
                ),
                SwitchListTile.adaptive(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _t('ai.tts_enabled'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    _t('ai.tts_enabled_hint'),
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _snap.ttsEnabled,
                  onChanged: _toggleTts,
                ),
                const SizedBox(height: 8),
                Text(
                  _t('ai.tts_engine'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t('ai.tts_engine_hint'),
                  style: TextStyle(fontSize: 11, color: onMuted),
                ),
                const SizedBox(height: 6),
                AiTtsEnginePicker(
                  cloudEnabled: _snap.cloudTtsEnabled,
                  enabled: _snap.ttsEnabled,
                  onChanged: _toggleCloudTts,
                ),
                if (_snap.cloudTtsEnabled && !_hasOpenAiKey) ...[
                  const SizedBox(height: 4),
                  Text(
                    _t('ai.tts_engine_openai_key_hint'),
                    style: TextStyle(fontSize: 11, color: onMuted),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _t('ai.speech_language'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t('ai.speech_language_hint'),
                  style: TextStyle(fontSize: 11, color: onMuted),
                ),
                const SizedBox(height: 6),
                AiSpeechLanguagePicker(
                  value: _snap.speechLanguage,
                  onChanged: _setSpeechLanguage,
                ),
                const SizedBox(height: 10),
                Text(
                  _t('ai.tts_voice'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t('ai.tts_voice_hint'),
                  style: TextStyle(fontSize: 11, color: onMuted),
                ),
                const SizedBox(height: 6),
                AiTtsVoicePicker(
                  value: _snap.ttsVoicePersona,
                  onChanged: _setTtsVoice,
                ),
                const SizedBox(height: 6),
                Text(
                  _t('ai.active_provider') +
                      ': ' +
                      _t(_snap.activeProvider.labelKey),
                  style: TextStyle(fontSize: 12, color: onMuted),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keyCtrl,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13),
                  onTap: _onKeyFieldTap,
                  onChanged: (_) {
                    if (!_keyDirty) {
                      setState(() => _keyDirty = true);
                    }
                  },
                  decoration: _denseDeco(
                    _t('ai.api_key'),
                    hint: cfg.hasApiKey && !_keyDirty
                        ? _t('ai.api_key_set_hint')
                        : _t('ai.api_key_placeholder'),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: cfg.hasApiKey ? _clearKey : null,
                    child: Text(
                      _t('ai.clear_key'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (_editProvider == AiProvider.openRouter) ...[
                  AiOpenRouterModelPicker(
                    models: _orModels,
                    selectedId: _modelCtrl.text,
                    loading: _orModelsLoading,
                    fromApi: _orModelsFromApi,
                    onSelected: _onOpenRouterModelSelected,
                    onRefresh: _loadOpenRouterModels,
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _modelCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: _denseDeco(
                    _t('ai.model'),
                    hint: _editProvider.defaultModel,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _t('ai.usecase_models_section'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t('ai.usecase_models_hint'),
                  style: TextStyle(fontSize: 11, color: onMuted),
                ),
                const SizedBox(height: 8),
                for (final u in AiUseCase.values) ...[
                  TextField(
                    controller: _useCaseCtrls[u],
                    style: const TextStyle(fontSize: 13),
                    decoration: _denseDeco(
                      _t(u.labelKey),
                      hint: _t('ai.usecase_model_default'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProvider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FieldSalesDensAppBar.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_t('common.save')),
                  ),
                ),
              ],
            ),
    );
  }
}
