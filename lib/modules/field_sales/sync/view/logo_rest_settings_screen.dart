// Dosya Adı: logo_rest_settings_screen.dart
// Açıklama: Logo REST API bağlantı ayarları ve test ekranı
// Oluşturulma Tarihi: 2026-07-15
// Geliştirici: EXFINOPS Team
// Son Güncelleme: 2026-07-15

import 'package:flutter/material.dart';

import '../../../../core/services/logo_api_service.dart';
import '../../../../core/services/logo_rest_settings_service.dart';

/// Logo REST (ExfinApi) bağlantı ayarları
class LogoRestSettingsScreen extends StatefulWidget {
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

  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _obscurePassword = true;
  String? _testMessage;
  bool? _testOk;

  final _settingsService = LogoRestSettingsService();
  final _api = LogoApiService();

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
    } catch (e) {
      debugPrint('Logo REST ayarları yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo REST ayarları kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _testing = true;
      _testMessage = null;
      _testOk = null;
    });
    try {
      await _save();
      final result = await _api.testConnection();
      setState(() {
        _testOk = result.success;
        _testMessage = result.success
            ? 'Bağlantı başarılı (HTTP ${result.statusCode ?? 200})'
            : 'Bağlantı başarısız: ${result.error ?? 'bilinmeyen hata'}'
                '${result.statusCode != null ? ' (${result.statusCode})' : ''}';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Logo REST Ayarları',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_saving || _testing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Kaydet',
              onPressed: _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                cacheExtent: 500,
                children: [
                  _sectionCard(
                    isDark: isDark,
                    title: 'Bağlantı',
                    children: [
                      TextFormField(
                        controller: _baseUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Base URL',
                          hintText: 'http://10.0.2.2:8000',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Base URL gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apiKeyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'API Key (opsiyonel)',
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    isDark: isDark,
                    title: 'Kimlik Doğrulama',
                    children: [
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı adı',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Şifre gerekli';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    isDark: isDark,
                    title: 'Firma / Dönem',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firmaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'X-Firma',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _periodCtrl,
                              decoration: const InputDecoration(
                                labelText: 'X-Period',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _companyIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'company_id (sync)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _periodIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'period_id (opsiyonel)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_testMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_testOk == true)
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_testOk == true)
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          color: _testOk == true
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _testing || _saving ? null : _testConnection,
                    icon: const Icon(Icons.wifi_tethering),
                    label: Text(
                      _testing ? 'Test ediliyor...' : 'Bağlantıyı Test Et',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF375A7F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _saving || _testing ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Kaydet'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
      elevation: 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
