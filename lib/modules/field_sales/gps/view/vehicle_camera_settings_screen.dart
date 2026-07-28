// Dosya Adı: vehicle_camera_settings_screen.dart
// Açıklama: Araç kamera canlı izleme parametre dens formu
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/vehicle_camera_ice_profile.dart';
import '../model/vehicle_camera_lens.dart';
import '../model/vehicle_camera_settings_record.dart';
import '../viewmodel/vehicle_camera_settings_store.dart';

/// {@template vehicle_camera_settings_screen}
/// Araç ön/arka kamera parametreleri — varsayılan kapalı.
/// Kamera açılınca WebRTC + STUN otomatik; TURN opsiyonel; ses isteğe bağlı.
/// Route: `/field-sales/vehicle-camera-settings`
/// {@endtemplate}
class VehicleCameraSettingsScreen extends StatefulWidget {
  static const String routeName = '/field-sales/vehicle-camera-settings';

  const VehicleCameraSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VehicleCameraSettingsScreen> createState() =>
      _VehicleCameraSettingsScreenState();
}

class _VehicleCameraSettingsScreenState
    extends State<VehicleCameraSettingsScreen> {
  final _store = const VehicleCameraSettingsStore();
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  bool _webrtc = true;
  bool _audio = false;
  bool _bothLenses = true;
  VehicleCameraLens _lens = VehicleCameraLens.front;
  VehicleCameraIceProfile _iceProfile = VehicleCameraIceProfile.autoStun;
  double _interval = VehicleCameraSettingsRecord.defaultIntervalSeconds
      .toDouble();
  final _turnUrlCtrl = TextEditingController();
  final _turnUserCtrl = TextEditingController();
  final _turnPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _turnUrlCtrl.dispose();
    _turnUserCtrl.dispose();
    _turnPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _store.load();
    if (!mounted) return;
    setState(() {
      _enabled = r.enabled;
      _webrtc = r.webrtcEnabled;
      _audio = r.audioEnabled;
      _bothLenses = r.broadcastBothLenses;
      _lens = r.defaultLens;
      _iceProfile = r.iceProfile;
      _interval = r.intervalSeconds.toDouble();
      _turnUrlCtrl.text = r.turnUrl;
      _turnUserCtrl.text = r.turnUsername;
      _turnPassCtrl.text = r.turnCredential;
      _loading = false;
    });
  }

  void _onEnabledChanged(bool v) {
    setState(() {
      _enabled = v;
      if (v) {
        // Kamera açılınca WebRTC otomatik
        _webrtc = true;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _store.save(
        VehicleCameraSettingsRecord(
          enabled: _enabled,
          defaultLens: _lens,
          intervalSeconds: _interval.round(),
          webrtcEnabled: _enabled ? _webrtc : false,
          audioEnabled: _enabled ? _audio : false,
          broadcastBothLenses: _bothLenses,
          iceProfile: _iceProfile,
          turnUrl: _turnUrlCtrl.text,
          turnUsername: _turnUserCtrl.text,
          turnCredential: _turnPassCtrl.text,
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

  InputDecoration _denseDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title =
        l10n.translate('field_sales.stubs.vehicle_camera_settings');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(title: title),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              children: [
                Text(
                  l10n.translate('field_sales.vehicle_camera_privacy_hint'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.translate('field_sales.vehicle_camera_enabled'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: _enabled,
                  activeColor: FieldSalesDensAppBar.primaryColor,
                  onChanged: _onEnabledChanged,
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.translate('field_sales.vehicle_camera_webrtc'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.translate(
                      'field_sales.vehicle_camera_webrtc_hint',
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: _webrtc,
                  activeColor: FieldSalesDensAppBar.primaryColor,
                  onChanged: _enabled
                      ? (v) => setState(() => _webrtc = v)
                      : null,
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.translate('field_sales.vehicle_camera_audio'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.translate('field_sales.vehicle_camera_audio_hint'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: _audio,
                  activeColor: FieldSalesDensAppBar.primaryColor,
                  onChanged: _enabled && _webrtc
                      ? (v) => setState(() => _audio = v)
                      : null,
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.translate(
                      'field_sales.vehicle_camera_both_lenses',
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.translate(
                      'field_sales.vehicle_camera_both_lenses_hint',
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: _bothLenses,
                  activeColor: FieldSalesDensAppBar.primaryColor,
                  onChanged: _enabled
                      ? (v) => setState(() => _bothLenses = v)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.translate('field_sales.vehicle_camera_default_lens'),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                SegmentedButton<VehicleCameraLens>(
                  segments: [
                    ButtonSegment(
                      value: VehicleCameraLens.front,
                      label: Text(
                        l10n.translate('field_sales.vehicle_camera_front'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.camera_front, size: 16),
                    ),
                    ButtonSegment(
                      value: VehicleCameraLens.rear,
                      label: Text(
                        l10n.translate('field_sales.vehicle_camera_rear'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.camera_rear, size: 16),
                    ),
                  ],
                  selected: {_lens},
                  onSelectionChanged: _enabled
                      ? (s) => setState(() => _lens = s.first)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.translate(
                    'field_sales.vehicle_camera_interval',
                    args: {'sec': '${_interval.round()}'},
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                Slider(
                  value: _interval,
                  min: VehicleCameraSettingsRecord.minIntervalSeconds
                      .toDouble(),
                  max: VehicleCameraSettingsRecord.maxIntervalSeconds
                      .toDouble(),
                  divisions: VehicleCameraSettingsRecord.maxIntervalSeconds -
                      VehicleCameraSettingsRecord.minIntervalSeconds,
                  label: '${_interval.round()}s',
                  onChanged: _enabled
                      ? (v) => setState(() => _interval = v)
                      : null,
                ),
                if (_webrtc) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('field_sales.vehicle_camera_ice_profile'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  SegmentedButton<VehicleCameraIceProfile>(
                    segments: [
                      ButtonSegment(
                        value: VehicleCameraIceProfile.autoStun,
                        label: Text(
                          l10n.translate(
                            'field_sales.vehicle_camera_ice_profile_auto',
                          ),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      ButtonSegment(
                        value: VehicleCameraIceProfile.customTurn,
                        label: Text(
                          l10n.translate(
                            'field_sales.vehicle_camera_ice_profile_turn',
                          ),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                    selected: {_iceProfile},
                    onSelectionChanged: _enabled
                        ? (s) => setState(() => _iceProfile = s.first)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.translate(
                      _iceProfile == VehicleCameraIceProfile.autoStun
                          ? 'field_sales.vehicle_camera_ice_auto'
                          : 'field_sales.vehicle_camera_turn_optional',
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (_iceProfile == VehicleCameraIceProfile.customTurn) ...[
                    const SizedBox(height: 6),
                    if (_enabled &&
                        _webrtc &&
                        _turnUrlCtrl.text.trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          l10n.translate(
                            'field_sales.vehicle_camera_turn_nat_hint',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    TextField(
                      controller: _turnUrlCtrl,
                      enabled: _enabled,
                      style: const TextStyle(fontSize: 13),
                      decoration: _denseDeco(
                        l10n.translate(
                          'field_sales.vehicle_camera_turn_url',
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.url,
                      textCapitalization: TextCapitalization.none,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _turnUserCtrl,
                      enabled: _enabled,
                      style: const TextStyle(fontSize: 13),
                      decoration: _denseDeco(
                        l10n.translate(
                          'field_sales.vehicle_camera_turn_username',
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.none,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _turnPassCtrl,
                      enabled: _enabled,
                      obscureText: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: _denseDeco(
                        l10n.translate(
                          'field_sales.vehicle_camera_turn_credential',
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.none,
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.translate('field_sales.vehicle_camera_limitations'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FieldSalesDensAppBar.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      l10n.translate('common.save').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
