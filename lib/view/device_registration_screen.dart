// Dosya Adı: device_registration_screen.dart
// Açıklama: Cihaz kayıt işlemlerinin yapıldığı ekran
// Oluşturulma Tarihi: 2024-04-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-04-21

import 'package:flutter/material.dart';
import '../core/services/device_service.dart';
import '../core/services/device_registration_service.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/localization/app_localization.dart';

/// {@template DeviceRegistrationScreen}
/// Cihaz kayıt işlemlerinin yapıldığı ekran
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceRegistrationScreen()));
/// ```
/// {@endtemplate}
class DeviceRegistrationScreen extends StatefulWidget {
  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _adSoyadController = TextEditingController();
  final TextEditingController _markaController = TextEditingController();
  final TextEditingController _isletimSistemiController =
      TextEditingController();
  String? _cihazHash;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceHash();
    _fillDeviceInfo();
  }

  Future<void> _loadDeviceHash() async {
    final hash = await DeviceService.getHashedDeviceSerial();
    setState(() {
      _cihazHash = hash;
    });
  }

  Future<void> _fillDeviceInfo() async {
    // İşletim sistemi otomatik
    _isletimSistemiController.text =
        kIsWeb ? 'WEB' : Platform.operatingSystem.toUpperCase();
    String? marka;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        marka = androidInfo.brand;
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        marka = iosInfo.name;
      } else if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        marka = Platform.localHostname;
      } else if (kIsWeb) {
        marka = 'Web Tarayıcı';
      }
    } catch (e) {
      marka = null;
    }
    if (marka != null && marka.isNotEmpty) {
      _markaController.text = marka;
    }
  }

  @override
  void dispose() {
    _adSoyadController.dispose();
    _markaController.dispose();
    _isletimSistemiController.dispose();
    super.dispose();
  }

  Future<void> _registerDevice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cihazHash == null || _cihazHash == '00:00:00:00:00:00') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.of(context).translate('auth.device_code_error'))),
      );
      return;
    }
    // Kayıt öncesi Supabase'de kontrol
    final exists = await MockSupabase.instance.client
        .from('device')
        .select()
        .eq('device_serial_number', _cihazHash!)
        .maybeSingle();
    if (exists != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.of(context).translate('auth.device_already_registered'))),
      );
      return;
    }
    setState(() => _loading = true);
    final success = await DeviceRegistrationService.registerDevice(
      userFullName: _adSoyadController.text,
      deviceSerialNumber: _cihazHash!,
      brand: _markaController.text,
      operatingSystem: _isletimSistemiController.text,
    );
    setState(() => _loading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalization.of(context).translate('auth.registration_sent'))),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.of(context).translate('auth.registration_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalization.of(context).translate('auth.device_registration_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _adSoyadController,
                decoration: InputDecoration(
                  labelText: AppLocalization.of(context).translate('auth.full_name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? AppLocalization.of(context).translate('common.required_field') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _markaController,
                decoration: InputDecoration(
                  labelText: AppLocalization.of(context).translate('auth.device_brand'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? AppLocalization.of(context).translate('common.required_field') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isletimSistemiController,
                decoration: InputDecoration(
                  labelText: AppLocalization.of(context).translate('auth.operating_system'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? AppLocalization.of(context).translate('common.required_field') : null,
              ),
              const SizedBox(height: 16),
              Text('${AppLocalization.of(context).translate('auth.unique_device_code')}: ${_cihazHash ?? AppLocalization.of(context).translate('common.loading')}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _registerDevice,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppLocalization.of(context).translate('auth.register_device')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Supabase { static dynamic instance; }
class MockSupabase { static dynamic instance; }
