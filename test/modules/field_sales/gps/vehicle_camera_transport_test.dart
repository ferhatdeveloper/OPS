// Dosya Adı: vehicle_camera_transport_test.dart
// Açıklama: WebRTC / JPEG taşıma seçici birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_ice_config.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_ice_profile.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_lens.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_settings_record.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_signaling_message.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/vehicle_camera_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleCameraTransportSelector', () {
    test('webrtc kapalı → jpeg', () {
      final t = VehicleCameraTransportSelector.resolve(
        webrtcEnabled: false,
        platformSupportsWebrtc: true,
        webrtcFailed: false,
      );
      expect(t, VehicleCameraActiveTransport.jpegPoll);
    });

    test('platform desteklemez → jpeg', () {
      final t = VehicleCameraTransportSelector.resolve(
        webrtcEnabled: true,
        platformSupportsWebrtc: false,
        webrtcFailed: false,
      );
      expect(t, VehicleCameraActiveTransport.jpegPoll);
    });

    test('webrtc hata → jpeg fallback', () {
      final t = VehicleCameraTransportSelector.resolve(
        webrtcEnabled: true,
        platformSupportsWebrtc: true,
        webrtcFailed: true,
      );
      expect(t, VehicleCameraActiveTransport.jpegPoll);
    });

    test('webrtc tercih + destek → webrtc', () {
      final t = VehicleCameraTransportSelector.resolve(
        webrtcEnabled: true,
        platformSupportsWebrtc: true,
        webrtcFailed: false,
      );
      expect(t, VehicleCameraActiveTransport.webrtc);
    });

    test('web yayın desteklenmez; izleme desteklenir', () {
      expect(
        VehicleCameraTransportSelector.supportsBroadcastWebrtc(isWeb: true),
        isFalse,
      );
      expect(
        VehicleCameraTransportSelector.supportsBroadcastWebrtc(isWeb: false),
        isTrue,
      );
      expect(
        VehicleCameraTransportSelector.supportsMonitorWebrtc(isWeb: true),
        isTrue,
      );
    });
  });

  group('VehicleCameraIceConfig', () {
    test('varsayılan STUN listesi (çoklu otomatik)', () {
      final ice = VehicleCameraIceConfig.defaults();
      final servers = ice.toRtcIceServers();
      expect(servers.length, greaterThanOrEqualTo(2));
      expect(servers.first['urls'], contains('stun:'));
      expect(ice.hasTurn, isFalse);
      expect(
        VehicleCameraIceConfig.defaultStunUrls.length,
        greaterThanOrEqualTo(2),
      );
    });

    test('TURN eklenince iceServers’a girer', () {
      final ice = VehicleCameraIceConfig.defaults(
        turnUrl: 'turn:turn.example.com:3478',
        turnUsername: 'u',
        turnCredential: 'p',
      );
      expect(ice.hasTurn, isTrue);
      final servers = ice.toRtcIceServers();
      expect(servers.length, greaterThanOrEqualTo(2));
      expect(
        servers.any((s) => s['urls']?.toString().startsWith('turn:') == true),
        isTrue,
      );
    });

    test('fromSettings autoStun TURN yok sayar', () {
      const settings = VehicleCameraSettingsRecord(
        iceProfile: VehicleCameraIceProfile.autoStun,
        turnUrl: 'turn:ignored:3478',
        turnUsername: 'u',
        turnCredential: 'p',
      );
      final ice = VehicleCameraIceConfig.fromSettings(settings);
      expect(ice.hasTurn, isFalse);
    });

    test('fromSettings customTurn TURN ekler', () {
      const settings = VehicleCameraSettingsRecord(
        iceProfile: VehicleCameraIceProfile.customTurn,
        turnUrl: 'turn:turn.example.com:3478',
        turnUsername: 'u',
        turnCredential: 'p',
      );
      final ice = VehicleCameraIceConfig.fromSettings(settings);
      expect(ice.hasTurn, isTrue);
    });
  });

  group('VehicleCameraSignalingMessage', () {
    test('sessionId ve map roundtrip', () {
      final sid = VehicleCameraSignalingMessage.buildSessionId(
        userId: 'u1',
        lens: VehicleCameraLens.rear,
      );
      expect(sid, 'u1|rear');
      expect(
        VehicleCameraSignalingMessage.userIdFromSessionId(sid),
        'u1',
      );
      expect(
        VehicleCameraSignalingMessage.lensFromSessionId(sid),
        VehicleCameraLens.rear,
      );
      final m = VehicleCameraSignalingMessage(
        id: 'm1',
        sessionId: sid,
        fromPeerId: 'viewer',
        toPeerId: '*',
        kind: VehicleCameraSignalingKind.offer,
        payload: 'v=0',
        createdAt: DateTime.utc(2026, 7, 27, 12),
      );
      final back = VehicleCameraSignalingMessage.fromMap(m.toMap());
      expect(back.id, 'm1');
      expect(back.kind, VehicleCameraSignalingKind.offer);
      expect(back.isAddressedTo('anyone'), isTrue);
      expect(
        VehicleCameraSignalingMessage.fromMap({
          ...m.toMap(),
          'to_peer_id': 'bc-1',
        }).isAddressedTo('bc-1'),
        isTrue,
      );
      expect(
        VehicleCameraSignalingMessage.fromMap({
          ...m.toMap(),
          'to_peer_id': 'bc-1',
        }).isAddressedTo('other'),
        isFalse,
      );
      expect(
        VehicleCameraSignalingKind.parse('presence'),
        VehicleCameraSignalingKind.presence,
      );
    });
  });
}
