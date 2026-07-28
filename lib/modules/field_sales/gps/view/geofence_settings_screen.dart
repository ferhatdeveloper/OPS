// Dosya Adı: geofence_settings_screen.dart
// Açıklama: Geofence ayarları dens form (yarıçap / aktif / fail-closed)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
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
  final _proximityRadiusController = TextEditingController();

  /// [_enabled]: Geofence kontrolü açık mı
  bool _enabled = true;

  /// [_proximityAlertsEnabled]: Yakın müşteri uyarıları
  bool _proximityAlertsEnabled = true;

  /// [_failClosed]: GPS yoksa engelle
  bool _failClosed = true;

  /// [_orderRequireGeofence]: Siparişte GPS yarıçap zorunlu
  bool _orderRequireGeofence = false;

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
    _proximityRadiusController.dispose();
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
      _orderRequireGeofence = record.orderRequireGeofence;
      _proximityAlertsEnabled = record.proximityAlertsEnabled;
      _radiusController.text = '${record.radiusMeters}';
      final prox = record.proximityRadiusMeters;
      _proximityRadiusController.text =
          prox > 0 ? '$prox' : '${record.radiusMeters}';
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
      final proxRaw = _parseRadius(_proximityRadiusController.text);
      final baseRadius =
          radius ?? GeofenceSettingsRecord.defaultRadiusMeters;
      int proximityRadius = 0;
      if (proxRaw != null && proxRaw != baseRadius) {
        proximityRadius = proxRaw;
      }
      await _store.save(
        GeofenceSettingsRecord(
          enabled: _enabled,
          radiusMeters: baseRadius,
          failClosed: _failClosed,
          orderRequireGeofence: _orderRequireGeofence,
          proximityAlertsEnabled: _proximityAlertsEnabled,
          proximityRadiusMeters: proximityRadius,
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
      appBar: FieldSalesDensAppBar(title: title),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.translate(
                        'field_sales.geofence_settings_summary',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate(
                        'field_sales.geofence_proximity_section',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate(
                          'field_sales.geofence_proximity_alerts_enabled',
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.translate(
                          'field_sales.geofence_proximity_alerts_hint',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      value: _proximityAlertsEnabled,
                      activeColor: FieldSalesDensAppBar.primaryColor,
                      onChanged: (v) =>
                          setState(() => _proximityAlertsEnabled = v),
                    ),
                    TextFormField(
                      controller: _proximityRadiusController,
                      enabled: _proximityAlertsEnabled,
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDecoration(
                        l10n.translate(
                          'field_sales.geofence_proximity_radius_m',
                        ),
                      ),
                      validator: (value) {
                        if (!_proximityAlertsEnabled) return null;
                        final key = GeofenceSettingsRecord.validateRadius(
                          _parseRadius(value ?? ''),
                        );
                        if (key == null) return null;
                        return l10n.translate(key);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.translate(
                          'field_sales.geofence_proximity_radius_hint',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.translate(
                        'field_sales.geofence_checkin_section',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate('field_sales.geofence_enabled'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _enabled,
                      activeColor: FieldSalesDensAppBar.primaryColor,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
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
                      activeColor: FieldSalesDensAppBar.primaryColor,
                      onChanged: _enabled
                          ? (v) => setState(() => _failClosed = v)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.translate(
                          'field_sales.order_geofence_enabled',
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.translate(
                          'field_sales.order_geofence_enabled_hint',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      value: _orderRequireGeofence,
                      activeColor: FieldSalesDensAppBar.primaryColor,
                      onChanged: (v) =>
                          setState(() => _orderRequireGeofence = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: FieldSalesDensAppBar.primaryColor,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n
                                    .translate('common.save')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
