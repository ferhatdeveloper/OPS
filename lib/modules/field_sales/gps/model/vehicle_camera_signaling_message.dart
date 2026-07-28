// Dosya Adı: vehicle_camera_signaling_message.dart
// Açıklama: Araç kamera WebRTC sinyal mesajı (SDP / ICE)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'vehicle_camera_lens.dart';

/// {@template vehicle_camera_signaling_kind}
/// Sinyal mesaj tipi.
/// {@endtemplate}
enum VehicleCameraSignalingKind {
  /// SDP offer
  offer,

  /// SDP answer
  answer,

  /// ICE candidate
  ice,

  /// Oturumu kapat
  hangup,

  /// Yayıncı çevrimiçi (JPEG yokken keşif)
  presence;

  /// Saklama anahtarı
  String get storageKey {
    switch (this) {
      case VehicleCameraSignalingKind.offer:
        return 'offer';
      case VehicleCameraSignalingKind.answer:
        return 'answer';
      case VehicleCameraSignalingKind.ice:
        return 'ice';
      case VehicleCameraSignalingKind.hangup:
        return 'hangup';
      case VehicleCameraSignalingKind.presence:
        return 'presence';
    }
  }

  /// Anahtardan parse
  static VehicleCameraSignalingKind parse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'answer':
        return VehicleCameraSignalingKind.answer;
      case 'ice':
        return VehicleCameraSignalingKind.ice;
      case 'hangup':
        return VehicleCameraSignalingKind.hangup;
      case 'presence':
        return VehicleCameraSignalingKind.presence;
      case 'offer':
      default:
        return VehicleCameraSignalingKind.offer;
    }
  }
}

/// {@template vehicle_camera_signaling_message}
/// PostgREST / lokal poll ile taşınan WebRTC sinyal kaydı.
///
/// Kullanım örneği:
/// ```dart
/// final m = VehicleCameraSignalingMessage(
///   id: '1',
///   sessionId: 'u1|front',
///   fromPeerId: 'viewer-1',
///   toPeerId: 'broadcaster',
///   kind: VehicleCameraSignalingKind.offer,
///   payload: sdp,
///   createdAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class VehicleCameraSignalingMessage {
  /// [id]: Mesaj kimliği
  final String id;

  /// [sessionId]: `userId|lens` oturum anahtarı
  final String sessionId;

  /// [fromPeerId]: Gönderen peer
  final String fromPeerId;

  /// [toPeerId]: Hedef peer (`*` = oturumdaki herkes)
  final String toPeerId;

  /// [kind]: offer / answer / ice / hangup
  final VehicleCameraSignalingKind kind;

  /// [payload]: SDP metni veya ICE JSON
  final String payload;

  /// [createdAt]: Oluşturma zamanı
  final DateTime createdAt;

  /// {@macro vehicle_camera_signaling_message}
  const VehicleCameraSignalingMessage({
    required this.id,
    required this.sessionId,
    required this.fromPeerId,
    required this.toPeerId,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  /// Oturum anahtarı üretir.
  static String buildSessionId({
    required String userId,
    required VehicleCameraLens lens,
  }) {
    return '${userId.trim()}|${lens.storageKey}';
  }

  /// `userId|lens` → kullanıcı id (yoksa null).
  static String? userIdFromSessionId(String sessionId) {
    final i = sessionId.indexOf('|');
    if (i <= 0) return null;
    final u = sessionId.substring(0, i).trim();
    return u.isEmpty ? null : u;
  }

  /// `userId|lens` → lens (parse edilemezse front).
  static VehicleCameraLens lensFromSessionId(String sessionId) {
    final i = sessionId.indexOf('|');
    if (i < 0 || i >= sessionId.length - 1) {
      return VehicleCameraLens.front;
    }
    return VehicleCameraLens.parse(sessionId.substring(i + 1));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'from_peer_id': fromPeerId,
      'to_peer_id': toPeerId,
      'kind': kind.storageKey,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'is_synced': 0,
      'is_deleted': 0,
      'updated_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toRemoteMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'from_peer_id': fromPeerId,
      'to_peer_id': toPeerId,
      'kind': kind.storageKey,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VehicleCameraSignalingMessage.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.tryParse(v?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return VehicleCameraSignalingMessage(
      id: map['id']?.toString() ?? '',
      sessionId: map['session_id']?.toString() ?? '',
      fromPeerId: map['from_peer_id']?.toString() ?? '',
      toPeerId: map['to_peer_id']?.toString() ?? '',
      kind: VehicleCameraSignalingKind.parse(map['kind']?.toString()),
      payload: map['payload']?.toString() ?? '',
      createdAt: parseDate(map['created_at']),
    );
  }

  /// Bu peer için mi (hedef `*` veya eşleşme).
  bool isAddressedTo(String peerId) {
    final to = toPeerId.trim();
    if (to.isEmpty || to == '*') return true;
    return to == peerId;
  }
}
