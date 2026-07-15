import 'package:flutter/material.dart';
import 'package:exfin_ops/service/notification_service.dart';

class MDMService {
  static final MDMService _instance = MDMService._internal();
  factory MDMService() => _instance;
  MDMService._internal();

  bool _isKioskModeEnabled = false;
  List<String> _blockedSites = [];
  
  bool get isKioskModeEnabled => _isKioskModeEnabled;

  void setKioskMode(bool enabled, {String? message}) {
    _isKioskModeEnabled = enabled;
    if (enabled) {
      NotificationService().showNotification(
        id: 500,
        title: '🛡️ MDM: Kiosk Modu Aktif',
        body: message ?? 'Cihaz sadece bu uygulama için kilitlenmiştir.',
      );
    } else {
      NotificationService().showNotification(
        id: 501,
        title: '🔓 MDM: Kiosk Modu Devre Dışı',
        body: 'Cihaz kısıtlamaları kaldırıldı.',
      );
    }
  }

  void updateContentFilter(List<String> blockedUrls) {
    _blockedSites = blockedUrls;
    debugPrint('MDM: Blocked Sites Updated: \$_blockedSites');
  }

  bool isUrlBlocked(String url) {
    return _blockedSites.any((blocked) => url.contains(blocked));
  }

  /// Simulates a remote wipe command from the server
  Future<void> remoteWipe() async {
    debugPrint('🚨 MDM ALERT: Remote Wipe Command Received!');
    
    NotificationService().showNotification(
      id: 666,
      title: '⚠️ GÜVENLİK UYARISI',
      body: 'Cihaz verileri güvenlik nedeniyle uzaktan siliniyor...',
    );

    // Simulate clearing local storage
    await Future.delayed(const Duration(seconds: 3));
    debugPrint('MDM: Local SQLite database cleared.');
    debugPrint('MDM: Logged out and session invalidated.');
    
    // In a real app, we would call:
    // await DatabaseService.getInstance().clearAllData();
    // await AuthService.instance.logout();
  }

  /// Checks device security posture (Mock)
  Future<Map<String, dynamic>> checkDeviceHealth() async {
    return {
      'security_patch_date': '2024-02-01',
      'is_compliant': true,
      'is_time_automatic': true, // New: Checks if network time is used
    };
  }

  /// Verifies if the device time has been manually tampered with.
  /// In a real app, this uses 'safe_device' or 'trust_fall' plugins.
  Future<bool> verifyTimeIntegrity() async {
    // 1. Check if "Automatic Date & Time" is enabled in OS
    bool isAutoTime = true; // Mock: In real Android, check Settings.Global.AUTO_TIME

    // 2. Fetch NTP time and compare with device time
    // If delta > 5 minutes, we flag it as tampered.
    DateTime deviceTime = DateTime.now();
    DateTime serverTime = deviceTime; // Mock: In real app, fetch from NTP or your API

    final offset = deviceTime.difference(serverTime).inMinutes.abs();
    
    if (!isAutoTime || offset > 5) {
      debugPrint('🚨 SECURITY ALERT: Device time is not trusted! Offset: \$offset min');
      return false;
    }
    return true;
  }

  /// In a real Android implementation, we would use a MethodChannel
  /// to call DevicePolicyManager.setLockTaskPackages()
  Future<void> requestDeviceAdmin() async {
    debugPrint('MDM: Requesting Device Administrator privileges...');
    // Mocking the native call
  }
}
