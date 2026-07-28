// Dosya Adı: whms_terminal_session.dart
// Açıklama: Terminal oturumu — MAC kayıt/aktif + rol gate
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../model/whms_order_type.dart';
import '../model/whms_device.dart';
import 'whms_device_store.dart';

/// {@template whms_terminal_session}
/// Bağlı terminal cihaz oturumu. Emir yürütmeden önce
/// [assertReady] / [assertCanExecute] çağrılır.
///
/// Kullanım örneği:
/// ```dart
/// final s = await WhmsTerminalSession.bindByMac(
///   store: store,
///   mac: 'AA:BB:CC:DD:EE:FF',
/// );
/// s.assertCanExecute(WhmsOrderType.pick);
/// ```
/// {@endtemplate}
class WhmsTerminalSession {
  /// [device]: Kayıtlı cihaz
  final WhmsDevice device;

  /// [macNormalized]: Oturum MAC’i
  final String macNormalized;

  /// {@macro whms_terminal_session}
  const WhmsTerminalSession({
    required this.device,
    required this.macNormalized,
  });

  /// Cihaz id
  String get deviceId => device.id;

  /// Varsayılan ambar
  String? get defaultWarehouseCode => device.defaultWarehouseCode;

  /// Rol wire seti
  Set<String> get roleSet =>
      device.roles.map((e) => e.trim().toLowerCase()).toSet();

  /// {@template whms_terminal_session_bind}
  /// MAC ile cihaz bulur; kayıtlı + aktif değilse StateError.
  ///
  /// Parametreler:
  /// - [store]: Cihaz store
  /// - [mac]: Ham MAC
  ///
  /// Dönüş değeri:
  /// - [WhmsTerminalSession]: Bağlı oturum
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: `whms.terminal.device_not_registered` |
  ///   `whms.terminal.device_inactive` | `whms.terminal.mac_invalid`
  /// {@endtemplate}
  static Future<WhmsTerminalSession> bindByMac({
    required WhmsDeviceStore store,
    required String mac,
  }) async {
    final norm = WhmsDeviceStore.normalizeMac(mac);
    if (norm == null) {
      throw StateError('whms.terminal.mac_invalid');
    }
    final device = await store.findByMac(norm);
    if (device == null) {
      throw StateError('whms.terminal.device_not_registered');
    }
    if (!device.isActive) {
      throw StateError('whms.terminal.device_inactive');
    }
    return WhmsTerminalSession(
      device: device,
      macNormalized: norm,
    );
  }

  /// {@template whms_terminal_session_assert_ready}
  /// Cihaz hâlâ aktif mi.
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: `whms.terminal.device_inactive`
  /// {@endtemplate}
  void assertReady() {
    if (!device.isActive) {
      throw StateError('whms.terminal.device_inactive');
    }
  }

  /// {@template whms_terminal_session_assert_can_execute}
  /// Emir tipi için rol yetkisi. Boş roller = tüm tipler (yalnızca
  /// kayıtlı+aktif kapısı).
  ///
  /// Parametreler:
  /// - [orderType]: Emir tipi
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: `whms.terminal.device_inactive` |
  ///   `whms.terminal.role_denied`
  /// {@endtemplate}
  void assertCanExecute(WhmsOrderType orderType) {
    assertReady();
    if (roleSet.isEmpty) return;
    final needed = orderType.wireName.toLowerCase();
    if (!roleSet.contains(needed)) {
      throw StateError('whms.terminal.role_denied');
    }
  }
}
