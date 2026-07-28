// Dosya Adı: logo_rest_settings_screen.dart
// Açıklama: Logo REST (ExfinApi + Tiger Objects) bağlantı ayarları dens ekranı
// Oluşturulma Tarihi: 2026-07-15
// Geliştirici: EXFINOPS Team
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/logo/logo_tiger.dart';
import '../../../../core/services/logo_api_service.dart';
import '../../../../core/services/logo_rest_settings_service.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';

/// {@template logo_rest_settings_screen}
/// Logo REST ayarları — ExfinApi middleware + opsiyonel Tiger Objects REST.
/// {@endtemplate}
class LogoRestSettingsScreen extends StatefulWidget {
  /// {@macro logo_rest_settings_screen}
  const LogoRestSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LogoRestSettingsScreen> createState() => _LogoRestSettingsScreenState();
}

class _LogoRestSettingsScreenState extends State<LogoRestSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firmaCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  final _companyIdCtrl = TextEditingController();
  final _periodIdCtrl = TextEditingController();
  final _tigerBaseCtrl = TextEditingController();
  final _tigerApiKeyCtrl = TextEditingController();
  final _tigerClientIdCtrl = TextEditingController();
  final _tigerClientSecretCtrl = TextEditingController();
  final _tigerUserCtrl = TextEditingController();
  final _tigerPassCtrl = TextEditingController();
  final _tigerFirmCtrl = TextEditingController();
  final _tigerPeriodCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _syncing = false;
  bool _obscurePassword = true;
  bool _obscureTigerPass = true;
  bool _tigerEnabled = false;
  String? _testMessage;
  bool? _testOk;

  final _settingsService = LogoRestSettingsService();
  final _api = LogoApiService();
  final _tigerStore = LogoTigerSettingsStore();
  final _tigerClient = LogoTigerRestClient();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _firmaCtrl.dispose();
    _periodCtrl.dispose();
    _companyIdCtrl.dispose();
    _periodIdCtrl.dispose();
    _tigerBaseCtrl.dispose();
    _tigerApiKeyCtrl.dispose();
    _tigerClientIdCtrl.dispose();
    _tigerClientSecretCtrl.dispose();
    _tigerUserCtrl.dispose();
    _tigerPassCtrl.dispose();
    _tigerFirmCtrl.dispose();
    _tigerPeriodCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _api.ensureReady();
      final s = await _settingsService.getSettings();
      _baseUrlCtrl.text = s.baseUrl;
      _apiKeyCtrl.text = s.apiKey ?? '';
      _usernameCtrl.text = s.username;
      _passwordCtrl.text = s.password;
      _firmaCtrl.text = s.firma;
      _periodCtrl.text = s.period;
      _companyIdCtrl.text = s.companyId?.toString() ?? '1';
      _periodIdCtrl.text = s.periodId?.toString() ?? '';

      _tigerEnabled = await _tigerStore.isEnabled();
      final t = await _tigerStore.load();
      _tigerBaseCtrl.text = t.baseUrl.isNotEmpty
          ? LogoTigerUrls.hostPortOnly(t.baseUrl)
          : LogoTigerSettingsStore.devExampleHostPort;
      _tigerApiKeyCtrl.text = t.apiKey;
      _tigerClientIdCtrl.text = t.clientId;
      _tigerClientSecretCtrl.text = t.clientSecret;
      _tigerUserCtrl.text = t.username;
      _tigerPassCtrl.text = t.password;
      _tigerFirmCtrl.text = '${t.firmNr}';
      _tigerPeriodCtrl.text = '${t.periodNr}';
    } catch (e) {
      debugPrint('Logo REST ayarları yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalization.of(context);
    setState(() => _saving = true);
    try {
      final settings = LogoRestSettings(
        baseUrl: _baseUrlCtrl.text.trim(),
        apiKey: _apiKeyCtrl.text.trim().isEmpty
            ? null
            : _apiKeyCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        firma: _firmaCtrl.text.trim().isEmpty ? '1' : _firmaCtrl.text.trim(),
        period:
            _periodCtrl.text.trim().isEmpty ? '1' : _periodCtrl.text.trim(),
        companyId: int.tryParse(_companyIdCtrl.text.trim()),
        periodId: int.tryParse(_periodIdCtrl.text.trim()),
      );
      await _api.applySettings(settings);

      final tiger = LogoTigerConfig(
        baseUrl: _tigerBaseCtrl.text.trim(),
        apiKey: _tigerApiKeyCtrl.text.trim(),
        clientId: _tigerClientIdCtrl.text.trim(),
        clientSecret: _tigerClientSecretCtrl.text,
        username: _tigerUserCtrl.text.trim(),
        password: _tigerPassCtrl.text,
        firmNr: int.tryParse(_tigerFirmCtrl.text.trim()) ?? 1,
        periodNr: int.tryParse(_tigerPeriodCtrl.text.trim()) ?? 1,
      );
      await _tigerStore.save(tiger);
      await _tigerStore.setEnabled(_tigerEnabled);
      _tigerClient.applyConfig(tiger);

      // Sunucu ayarları ile tek URL kaynağı
      final logoUrl = tiger.baseUrl.trim().isNotEmpty
          ? tiger.baseUrl.trim()
          : settings.baseUrl.trim();
      if (logoUrl.isNotEmpty) {
        await LogoServerUrlBridge.syncServerFromLogoRest(
          baseUrl: logoUrl,
          apiKey: tiger.apiKey.isNotEmpty ? tiger.apiKey : settings.apiKey,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('field_sales.logo_rest_saved')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate(
              'field_sales.logo_rest_save_error',
              args: {'error': '$e'},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalization.of(context);
    setState(() {
      _testing = true;
      _testMessage = null;
      _testOk = null;
    });
    try {
      await _save();
      if (_tigerEnabled) {
        final result = await _tigerClient.testConnection();
        setState(() {
          _testOk = result.success;
          _testMessage = result.success
              ? l10n.translate(
                  'field_sales.logo_tiger_test_ok',
                  args: {
                    'code': '${result.statusCode ?? 200}',
                  },
                )
              : l10n.translate(
                  'field_sales.logo_tiger_test_fail',
                  args: {'error': result.error ?? ''},
                );
        });
      } else {
        final result = await _api.testConnection();
        setState(() {
          _testOk = result.success;
          _testMessage = result.success
              ? l10n.translate(
                  'field_sales.logo_rest_test_ok',
                  args: {'code': '${result.statusCode ?? 200}'},
                )
              : l10n.translate(
                  'field_sales.logo_rest_test_fail',
                  args: {'error': result.error ?? ''},
                );
        });
      }
    } catch (e) {
      setState(() {
        _testOk = false;
        _testMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _pingHelp() async {
    final l10n = AppLocalization.of(context);
    setState(() {
      _testing = true;
      _testMessage = null;
      _testOk = null;
    });
    try {
      await _save();
      final result = await _tigerClient.pingHelp();
      setState(() {
        _testOk = result.success;
        _testMessage = result.success
            ? l10n.translate(
                'field_sales.logo_tiger_help_ok',
                args: {'code': '${result.statusCode ?? 200}'},
              )
            : l10n.translate(
                'field_sales.logo_tiger_help_fail',
                args: {'error': result.error ?? ''},
              );
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _pullTigerSync() async {
    final l10n = AppLocalization.of(context);
    setState(() => _syncing = true);
    try {
      await _save();
      final sync = LogoTigerPullSync(client: _tigerClient);
      final result = await sync.pullAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.ok
                ? l10n.translate(
                    'field_sales.logo_tiger_sync_ok',
                    args: {'detail': result.messages.join(' · ')},
                  )
                : l10n.translate(
                    'field_sales.logo_tiger_sync_fail',
                    args: {'error': result.error ?? ''},
                  ),
          ),
          backgroundColor: result.ok ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.logo_rest_settings_title'),
        useGradient: false,
        actions: [
          if (_saving || _testing || _syncing)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.save,
              tooltip: l10n.translate('common.save'),
              onPressed: _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                cacheExtent: 500,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      l10n.translate('field_sales.logo_tiger_enabled'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      l10n.translate('field_sales.logo_tiger_enabled_hint'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _tigerEnabled,
                    onChanged: (v) => setState(() => _tigerEnabled = v),
                  ),
                  const SizedBox(height: 8),
                  _sectionCard(
                    isDark: isDark,
                    title: l10n.translate('field_sales.logo_tiger_section'),
                    children: [
                      TextFormField(
                        controller: _tigerBaseCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.translate(
                            'field_sales.logo_tiger_base_url',
                          ),
                          hintText: LogoTigerSettingsStore.devExampleHostPort,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tigerApiKeyCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.translate(
                            'field_sales.logo_tiger_api_key',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tigerClientIdCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.translate(
                            'field_sales.logo_tiger_client_id',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tigerClientSecretCtrl,
                        obscureText: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.translate(
                            'field_sales.logo_tiger_client_secret',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tigerUserCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.translate(
                            'field_sales.logo_tiger_username',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tigerPassCtrl,
                        obscureText: _obscureTigerPass,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.translate(
                            'field_sales.logo_tiger_password',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureTigerPass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscureTigerPass = !_obscureTigerPass,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tigerFirmCtrl,
                              style: const TextStyle(fontSize: 13),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: l10n.translate(
                                  'field_sales.logo_tiger_firm_nr',
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _tigerPeriodCtrl,
                              style: const TextStyle(fontSize: 13),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: l10n.translate(
                                  'field_sales.logo_tiger_period_nr',
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _sectionCard(
                    isDark: isDark,
                    title: l10n.translate('field_sales.logo_exfin_section'),
                    children: [
                      TextFormField(
                        controller: _baseUrlCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText:
                              l10n.translate('field_sales.logo_rest_base_url'),
                          hintText: 'http://10.0.2.2:8000',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (_tigerEnabled) return null;
                          if (v == null || v.trim().isEmpty) {
                            return l10n.translate(
                              'field_sales.logo_rest_base_url_required',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _apiKeyCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText:
                              l10n.translate('field_sales.logo_rest_api_key'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText:
                              l10n.translate('field_sales.logo_rest_username'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (_tigerEnabled) return null;
                          if (v == null || v.trim().isEmpty) {
                            return l10n.translate(
                              'field_sales.logo_rest_username_required',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText:
                              l10n.translate('field_sales.logo_rest_password'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (_tigerEnabled) return null;
                          if (v == null || v.isEmpty) {
                            return l10n.translate(
                              'field_sales.logo_rest_password_required',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firmaCtrl,
                              style: const TextStyle(fontSize: 13),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: l10n
                                    .translate('field_sales.logo_rest_firma'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _periodCtrl,
                              style: const TextStyle(fontSize: 13),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: l10n
                                    .translate('field_sales.logo_rest_period'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _companyIdCtrl,
                              style: const TextStyle(fontSize: 13),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: l10n.translate(
                                  'field_sales.logo_rest_company_id',
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _periodIdCtrl,
                              style: const TextStyle(fontSize: 13),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: l10n.translate(
                                  'field_sales.logo_rest_period_id',
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_testMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_testOk == true)
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              (_testOk == true) ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testOk == true
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: _testing || _saving ? null : _testConnection,
                      icon: const Icon(Icons.wifi_tethering, size: 18),
                      label: Text(
                        _testing
                            ? l10n.translate('field_sales.logo_rest_testing')
                            : l10n.translate('field_sales.logo_rest_test'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FieldSalesDensAppBar.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _testing || _saving ? null : _pingHelp,
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: Text(
                        l10n.translate('field_sales.logo_tiger_ping_help'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: !_tigerEnabled || _syncing || _saving
                          ? null
                          : _pullTigerSync,
                      icon: const Icon(Icons.cloud_download, size: 18),
                      label: Text(
                        _syncing
                            ? l10n.translate('field_sales.logo_tiger_syncing')
                            : l10n.translate('field_sales.logo_tiger_pull_sync'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _saving || _testing ? null : _save,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        l10n.translate('common.save'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard({
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
