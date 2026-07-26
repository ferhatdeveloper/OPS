// Dosya Adı: geofence_settings_screen.dart
// Açıklama: Geofence ayarları dens form (yarıçap / aktif / fail-closed)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/geofence_settings_record.dart';
import '../viewmodel/geofence_settings_store.dart';

/// {@template geofence_settings_screen}
/// Geofence ayarları ekranı — SharedPreferences kalıcılık.
/// Route: `/field-sales/geofence-settings`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, GeofenceSettingsScreen.routeName);
/// ```
/// {@endtemplate}
class GeofenceSettingsScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/geofence-settings`
  static const String routeName = '/field-sales/geofence-settings';

  const GeofenceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GeofenceSettingsScreen> createState() =>
      _GeofenceSettingsScreenState();
}

class _GeofenceSettingsScreenState extends State<GeofenceSettingsScreen> {
  /// [_store]: SharedPreferences load/save
  final GeofenceSettingsStore _store = const GeofenceSettingsStore();

  final _formKey = GlobalKey<FormState>();
  final _radiusController = TextEditingController();

  /// [_enabled]: Geofence kontrolü açık mı
  bool _enabled = true;

  /// [_failClosed]: GPS yoksa engelle
  bool _failClosed = true;

  /// [_loading]: Ayarlar yüklenirken true
  bool _loading = true;

  /// [_saving]: Kayıt sırasında true
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  /// {@template _loadSettings}
  /// Yerel kayıtlı geofence ayarlarını yükler.
  /// {@endtemplate}
  Future<void> _loadSettings() async {
    final record = await _store.load();
    if (!mounted) return;
    setState(() {
      _enabled = record.enabled;
      _failClosed = record.failClosed;
      _radiusController.text = '${record.radiusMeters}';
      _loading = false;
    });
  }

  /// {@template _parseRadius}
  /// Metin yarıçapı int? olarak okur.
  /// {@endtemplate}
  int? _parseRadius(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  /// {@template _saveSettings}
  /// Form değerlerini SharedPreferences'a yazar.
  /// {@endtemplate}
  Future<void> _saveSettings() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final radius = _parseRadius(_radiusController.text);
      await _store.save(
        GeofenceSettingsRecord(
          enabled: _enabled,
          radiusMeters:
              radius ?? GeofenceSettingsRecord.defaultRadiusMeters,
          failClosed: _failClosed,
        ),
      );
      if (!mounted) return;
      final l10n = AppLocalization.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('common.success')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// {@template _inputDecoration}
  /// Dense flat InputDecoration (voucher_defaults token'ları).
  /// {@endtemplate}
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.geofence_settings');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate('field_sales.geofence_enabled'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _enabled,
                      activeColor: const Color(0xFF375A7F),
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _radiusController,
                      enabled: _enabled,
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDecoration(
                        l10n.translate('field_sales.geofence_radius_m'),
                      ),
                      validator: (value) {
                        final key = GeofenceSettingsRecord.validateRadius(
                          _parseRadius(value ?? ''),
                        );
                        if (key == null) return null;
                        return l10n.translate(key);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate('field_sales.geofence_fail_closed'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.translate(
                          'field_sales.geofence_fail_closed_hint',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      value: _failClosed,
                      activeColor: const Color(0xFF375A7F),
                      onChanged: _enabled
                          ? (v) => setState(() => _failClosed = v)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveSettings,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          l10n.translate('common.save').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF375A7F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
