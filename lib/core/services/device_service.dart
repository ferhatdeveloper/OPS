// Dosya Adı: device_service.dart
// Açıklama: Cihazın benzersiz kimliğini platforma göre döndüren servis
// Oluşturulma Tarihi: 2024-04-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-04-21

import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// {@template DeviceService}
/// Cihazın benzersiz kimliğini platforma göre (Android/iOS) döndüren servis sınıfı
///
/// Kullanım örneği:
/// ```dart
/// final id = await DeviceService.getDeviceId();
/// ```
/// {@endtemplate}
class DeviceService {
  /// [getDeviceId]: Cihazın benzersiz kimliğini döndürür
  ///
  /// Parametreler:
  /// - Yok
  ///
  /// Dönüş değeri:
  /// - [Future<String?>]: Cihaz kimliği
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Platform desteklenmiyor veya kimlik alınamıyor
  static Future<String?> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        // Web: localStorage UUID
        final prefs = await SharedPreferences.getInstance();
        String? uuid = prefs.getString('device_uuid');
        if (uuid == null) {
          uuid = const Uuid().v4();
          await prefs.setString('device_uuid', uuid);
        }
        return uuid;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // MAC adresi alınabiliyorsa onu döndür
        final info = NetworkInfo();
        final mac = await info.getWifiBSSID();
        if (mac != null && mac.isNotEmpty) {
          return mac;
        }
        // MAC adresi alınamazsa local UUID kullan
        final prefs = await SharedPreferences.getInstance();
        String? uuid = prefs.getString('device_uuid');
        if (uuid == null) {
          uuid = const Uuid().v4();
          await prefs.setString('device_uuid', uuid);
        }
        return uuid;
      } else {
        // TODO(Ferhat NAS): Diğer platformlar için destek eklenebilir
        return null;
      }
    } catch (e) {
      // TODO(Ferhat NAS): Hata yönetimi geliştirilecek
      return null;
    }
  }

  /// [getHashedDeviceSerial]: Cihaz serial kombinasyonunu hash'leyip döndürür ve saklar
  ///
  /// - MAC adresi + local UUID birleştirilir
  /// - SHA-256 ile hash'lenir
  /// - shared_preferences ile saklanır
  /// - Her açılışta aynı hash döner
  static Future<String?> getHashedDeviceSerial() async {
    try {
      String? mac;
      String? uuid;
      if (!kIsWeb &&
          (Platform.isAndroid ||
              Platform.isWindows ||
              Platform.isMacOS ||
              Platform.isLinux)) {
        try {
          final info = NetworkInfo();
          mac = await info.getWifiBSSID();
          if (mac == null ||
              mac == '00:00:00:00:00:00' ||
              mac == '000000' ||
              mac == '02:00:00:00:00:00') {
            mac = null;
          }
        } catch (e) {
          mac = null; // Prevent hangs if network_info_plus fails
        }
      }
      final prefs = await SharedPreferences.getInstance();
      uuid = prefs.getString('device_uuid');
      if (uuid == null) {
        uuid = const Uuid().v4();
        await prefs.setString('device_uuid', uuid);
      }
      // Platform ve cihaz adı ekle
      final platform = kIsWeb ? 'web' : Platform.operatingSystem;
      final hostname = kIsWeb ? 'browser' : Platform.localHostname;
      final rawSerial = '${mac ?? ''}|$uuid|$platform|$hostname';
      final bytes = utf8.encode(rawSerial);
      final hash = sha256.convert(bytes).toString();
      await prefs.setString('device_serial_hash', hash);
      return hash;
    } catch (e) {
      // TODO(Ferhat NAS): Hata yönetimi geliştirilecek
      return null;
    }
  }

  /// [resetDeviceSerial]: Admin panelinden cihaz serial hash'ini sıfırlamak için fonksiyon
  static Future<void> resetDeviceSerial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_serial_hash');
    await prefs.remove('device_uuid');
  }

  /// [validateDeviceSerial]: Donanım hash'i ile saklanan hash'i karşılaştırır. Uyuşmazsa null döner.
  static Future<String?> validateDeviceSerial() async {
    try {
      String? mac;
      String? uuid;
      if (!kIsWeb &&
          (Platform.isAndroid ||
              Platform.isWindows ||
              Platform.isMacOS ||
              Platform.isLinux)) {
        try {
          final info = NetworkInfo();
          mac = await info.getWifiBSSID();
          if (mac == null ||
              mac == '00:00:00:00:00:00' ||
              mac == '000000' ||
              mac == '02:00:00:00:00:00') {
            mac = null;
          }
        } catch (e) {
          mac = null; // Prevent hangs if network_info_plus fails
        }
      }
      final prefs = await SharedPreferences.getInstance();
      uuid = prefs.getString('device_uuid');
      if (uuid == null) {
        uuid = const Uuid().v4();
        await prefs.setString('device_uuid', uuid);
      }
      final platform = kIsWeb ? 'web' : Platform.operatingSystem;
      final hostname = kIsWeb ? 'browser' : Platform.localHostname;
      final rawSerial = '${mac ?? ''}|$uuid|$platform|$hostname';
      final bytes = utf8.encode(rawSerial);
      final currentHash = sha256.convert(bytes).toString();
      final storedHash = prefs.getString('device_serial_hash');
      if (storedHash == null) {
        await prefs.setString('device_serial_hash', currentHash);
        return currentHash;
      }
      if (storedHash == currentHash) {
        return currentHash;
      } else {
        return null;
      }
    } catch (e) {
      // TODO(Ferhat NAS): Hata yönetimi geliştirilecek
      return null;
    }
  }
}
