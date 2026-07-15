// Dosya Adı: logo_rest_settings_service.dart
// Açıklama: Logo REST API bağlantı ayarlarını SharedPreferences üzerinden yönetir
// Oluşturulma Tarihi: 2026-07-15
// Geliştirici: EXFINOPS Team
// Son Güncelleme: 2026-07-15

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logo REST bağlantı ayarları modeli
class LogoRestSettings {
  final String baseUrl;
  final String? apiKey;
  final String firma;
  final String period;
  final String username;
  final String password;
  final int? companyId;
  final int? periodId;

  const LogoRestSettings({
    required this.baseUrl,
    this.apiKey,
    this.firma = '1',
    this.period = '1',
    this.username = '',
    this.password = '',
    this.companyId,
    this.periodId,
  });

  LogoRestSettings copyWith({
    String? baseUrl,
    String? apiKey,
    String? firma,
    String? period,
    String? username,
    String? password,
    int? companyId,
    int? periodId,
  }) {
    return LogoRestSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      firma: firma ?? this.firma,
      period: period ?? this.period,
      username: username ?? this.username,
      password: password ?? this.password,
      companyId: companyId ?? this.companyId,
      periodId: periodId ?? this.periodId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'firma': firma,
      'period': period,
      'username': username,
      'password': password,
      'companyId': companyId,
      'periodId': periodId,
    };
  }
}

/// SharedPreferences anahtarları ve varsayılan değerlerle Logo REST ayar servisi
class LogoRestSettingsService {
  static final LogoRestSettingsService _instance =
      LogoRestSettingsService._internal();
  factory LogoRestSettingsService() => _instance;
  LogoRestSettingsService._internal();

  static const String keyBaseUrl = 'logo_rest_base_url';
  static const String keyApiKey = 'logo_rest_api_key';
  static const String keyFirma = 'logo_firma';
  static const String keyPeriod = 'logo_period';
  static const String keyUsername = 'logo_username';
  static const String keyPassword = 'logo_password';
  static const String keyCompanyId = 'logo_company_id';
  static const String keyPeriodId = 'logo_period_id';
  static const String keyAccessToken = 'logo_rest_access_token';

  /// Android emülatör için 10.0.2.2, diğerleri için 127.0.0.1
  static String defaultBaseUrl() {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Platform erişilemezse (özellikle bazı web senaryoları)
    }
    return 'http://127.0.0.1:8000';
  }

  Future<LogoRestSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return LogoRestSettings(
      baseUrl: prefs.getString(keyBaseUrl)?.trim().isNotEmpty == true
          ? prefs.getString(keyBaseUrl)!.trim()
          : defaultBaseUrl(),
      apiKey: prefs.getString(keyApiKey),
      firma: prefs.getString(keyFirma) ?? '1',
      period: prefs.getString(keyPeriod) ?? '1',
      username: prefs.getString(keyUsername) ?? '',
      password: prefs.getString(keyPassword) ?? '',
      companyId: prefs.getInt(keyCompanyId),
      periodId: prefs.getInt(keyPeriodId),
    );
  }

  Future<void> saveSettings(LogoRestSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, settings.baseUrl.trim());
    if (settings.apiKey != null) {
      await prefs.setString(keyApiKey, settings.apiKey!);
    }
    await prefs.setString(keyFirma, settings.firma.trim());
    await prefs.setString(keyPeriod, settings.period.trim());
    await prefs.setString(keyUsername, settings.username.trim());
    await prefs.setString(keyPassword, settings.password);
    if (settings.companyId != null) {
      await prefs.setInt(keyCompanyId, settings.companyId!);
    }
    if (settings.periodId != null) {
      await prefs.setInt(keyPeriodId, settings.periodId!);
    }
    debugPrint('Logo REST ayarları kaydedildi: ${settings.baseUrl}');
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, url.trim());
  }

  Future<void> setCredentials({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUsername, username.trim());
    await prefs.setString(keyPassword, password);
  }

  Future<void> setFirmaPeriod({
    required String firma,
    required String period,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFirma, firma.trim());
    await prefs.setString(keyPeriod, period.trim());
  }

  Future<void> saveAccessToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(keyAccessToken);
    } else {
      await prefs.setString(keyAccessToken, token);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAccessToken);
  }

  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAccessToken);
  }
}
