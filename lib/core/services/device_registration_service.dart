// Dosya Adı: device_registration_service.dart
// Açıklama: Cihaz kayıt ve onay kontrol işlemlerini yöneten servis
// Oluşturulma Tarihi: 2024-04-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-04-21

// supabase removed
import 'postgre_service.dart';
import 'package:flutter/foundation.dart';

/// {@template DeviceRegistrationService}
/// Cihazın kayıtlı ve onaylı olup olmadığını kontrol eden, kayıt işlemini yöneten servis
///
/// Kullanım örneği:
/// ```dart
/// final isRegistered = await DeviceRegistrationService.isDeviceAllowed('cihaz_seri_no');
/// ```
/// {@endtemplate}
class DeviceRegistrationService {
  /// [isDeviceAllowed]: Cihazın kayıtlı, onaylı ve geçerlilik süresi dolmamış olup olmadığını kontrol eder
  ///
  /// Parametreler:
  /// - [deviceSerialNumber]: Cihazın benzersiz seri numarası (hash değeri)
  ///
  /// Dönüş değeri:
  /// - [Future<bool>]: Cihaz girişe uygun mu?
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Sorgu hatası
  static Future<bool> isDeviceAllowed(String deviceSerialNumber) async {
    try {
      final postgre = await PostgreService.getInstance();
      final results = await postgre.query(
        'device',
        filter: 'device_serial_number = @p0 AND approval_status = 1 AND is_active = 1',
        filterArgs: [deviceSerialNumber],
      );
      return results.isNotEmpty;
    } catch (e) {
      debugPrint('DeviceRegistrationService: Error checking device: $e');
      return false; 
    }
  }

  /// [registerDevice]: Registers the device (adds as unapproved)
  ///
  /// Parametreler:
  /// - [userFullName]: User's full name
  /// - [deviceSerialNumber]: Device serial number
  /// - [brand]: Device brand
  /// - [operatingSystem]: Device operating system
  ///
  /// Dönüş değeri:
  /// - [Future<bool>]: Registration successful?
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Registration error
  static Future<bool> registerDevice({
    required String userFullName,
    required String deviceSerialNumber,
    required String brand,
    required String operatingSystem,
  }) async {
    try {
      final postgre = await PostgreService.getInstance();
      await postgre.insert('device', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_full_name': userFullName,
        'device_serial_number': deviceSerialNumber,
        'brand': brand,
        'operating_system': operatingSystem,
        'approval_status': 0, // Pending
        'is_active': 1, // Active
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('DeviceRegistrationService: Error registering device: $e');
      return false;
    }
  }
}

