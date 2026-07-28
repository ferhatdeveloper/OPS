// Dosya Adı: vehicle_camera_webrtc_session.dart
// Açıklama: Araç kamera WebRTC P2P oturumu (yayıncı / izleyici)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../model/vehicle_camera_ice_config.dart';
import '../model/vehicle_camera_lens.dart';
import '../model/vehicle_camera_signaling_message.dart';
import 'vehicle_camera_signaling_store.dart';

/// {@template vehicle_camera_webrtc_role}
/// Peer rolü.
/// {@endtemplate}
enum VehicleCameraWebrtcRole {
  /// Plasiyer yayıncı
  broadcaster,

  /// Yönetici izleyici
  viewer,
}

/// {@template vehicle_camera_webrtc_session}
/// Tek peer P2P: sinyal tablosu üzerinden offer/answer/ICE.
/// SFU yok. NAT arkasında TURN gerekebilir. Ses opsiyonel.
///
/// Kullanım örneği:
/// ```dart
/// final s = VehicleCameraWebrtcSession(...);
/// await s.start();
/// ```
/// {@endtemplate}
class VehicleCameraWebrtcSession {
  /// [role]: Yayıncı / izleyici
  final VehicleCameraWebrtcRole role;

  /// [userId]: Plasiyer kullanıcı (oturum anahtarı)
  final String userId;

  /// [lens]: Ön / arka
  final VehicleCameraLens lens;

  /// [peerId]: Bu cihaz peer kimliği
  final String peerId;

  /// [signaling]: Sinyal deposu
  final VehicleCameraSignalingStore signaling;

  /// [ice]: ICE sunucuları
  final VehicleCameraIceConfig ice;

  /// [audioEnabled]: Mikrofon track ekle / al
  final bool audioEnabled;

  /// [onState]: Bağlantı durumu değişince
  final void Function(String state)? onState;

  /// [onFailed]: Kurtarılamayan hata
  final void Function(Object error)? onFailed;

  /// [pollInterval]: Sinyal poll aralığı (canlı için kısa)
  final Duration pollInterval;

  /// [uuid]: Kimlik üretici
  final Uuid uuid;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  Timer? _pollTimer;
  DateTime _since = DateTime.now().toUtc().subtract(const Duration(seconds: 5));
  bool _disposed = false;
  bool _makingOffer = false;
  bool _remoteDescSet = false;
  String? _remotePeerId;

  /// {@macro vehicle_camera_webrtc_session}
  VehicleCameraWebrtcSession({
    required this.role,
    required this.userId,
    required this.lens,
    required this.peerId,
    required this.signaling,
    this.ice = const VehicleCameraIceConfig(),
    this.audioEnabled = false,
    this.onState,
    this.onFailed,
    this.pollInterval = const Duration(milliseconds: 900),
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  /// Oturum anahtarı
  String get sessionId => VehicleCameraSignalingMessage.buildSessionId(
        userId: userId,
        lens: lens,
      );

  /// Yerel önizleme (yayıncı)
  MediaStream? get localStream => _localStream;

  /// Bağlantı hazır mı (remote track geldi)
  bool get hasRemoteVideo =>
      remoteRenderer.srcObject != null &&
      (remoteRenderer.srcObject!.getVideoTracks().isNotEmpty);

  /// Uzak ses track var mı
  bool get hasRemoteAudio =>
      remoteRenderer.srcObject != null &&
      (remoteRenderer.srcObject!.getAudioTracks().isNotEmpty);

  /// Oturumu başlatır.
  Future<void> start() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _pc = await createPeerConnection({
      'iceServers': ice.toRtcIceServers(),
      'sdpSemantics': 'unified-plan',
    });
    _wirePc(_pc!);

    if (role == VehicleCameraWebrtcRole.broadcaster) {
      await _openLocalCamera();
      await _publishPresence();
      onState?.call('waiting');
    } else {
      onState?.call('joining');
      await _createAndPublishOffer();
    }

    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_pollInbox());
    });
    await _pollInbox();
  }

  Future<void> _openLocalCamera() async {
    final facing = lens == VehicleCameraLens.front ? 'user' : 'environment';
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': audioEnabled,
      'video': {
        'facingMode': facing,
        'width': 640,
        'height': 480,
      },
    });
    _localStream = stream;
    localRenderer.srcObject = stream;
    for (final track in stream.getTracks()) {
      await _pc!.addTrack(track, stream);
    }
  }

  Future<void> _publishPresence() async {
    await signaling.publish(
      VehicleCameraSignalingMessage(
        id: uuid.v4(),
        sessionId: sessionId,
        fromPeerId: peerId,
        toPeerId: '*',
        kind: VehicleCameraSignalingKind.presence,
        payload: lens.storageKey,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  void _wirePc(RTCPeerConnection pc) {
    pc.onIceCandidate = (RTCIceCandidate c) {
      if (c.candidate == null || c.candidate!.isEmpty) return;
      unawaited(_publishIce(c));
    };
    pc.onConnectionState = (RTCPeerConnectionState state) {
      onState?.call(state.toString());
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onFailed?.call(StateError('WebRTC connection failed'));
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onState?.call('streaming');
      }
    };
    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        onState?.call('streaming');
      } else if (event.track.kind == 'video' || event.track.kind == 'audio') {
        // Tek track geldiyse renderer’a bağla
        final existing = remoteRenderer.srcObject;
        if (existing != null) {
          existing.addTrack(event.track);
        }
        onState?.call('streaming');
      }
    };
  }

  Future<void> _createAndPublishOffer() async {
    if (_makingOffer || _pc == null) return;
    _makingOffer = true;
    try {
      final offer = await _pc!.createOffer({
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': audioEnabled ? 1 : 0,
      });
      await _pc!.setLocalDescription(offer);
      final sdp = offer.sdp ?? '';
      await signaling.publish(
        VehicleCameraSignalingMessage(
          id: uuid.v4(),
          sessionId: sessionId,
          fromPeerId: peerId,
          toPeerId: '*',
          kind: VehicleCameraSignalingKind.offer,
          payload: sdp,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      onState?.call('offer_sent');
    } catch (e) {
      onFailed?.call(e);
    } finally {
      _makingOffer = false;
    }
  }

  Future<void> _publishIce(RTCIceCandidate c) async {
    final payload = jsonEncode({
      'candidate': c.candidate,
      'sdpMid': c.sdpMid,
      'sdpMLineIndex': c.sdpMLineIndex,
    });
    await signaling.publish(
      VehicleCameraSignalingMessage(
        id: uuid.v4(),
        sessionId: sessionId,
        fromPeerId: peerId,
        toPeerId: _remotePeerId ?? '*',
        kind: VehicleCameraSignalingKind.ice,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _pollInbox() async {
    if (_disposed || _pc == null) return;
    try {
      final inbox = await signaling.pollSince(
        sessionId: sessionId,
        since: _since,
        excludePeerId: peerId,
      );
      for (final msg in inbox) {
        if (!msg.isAddressedTo(peerId) && msg.toPeerId != '*') continue;
        if (msg.createdAt.isAfter(_since)) {
          _since = msg.createdAt;
        }
        await _handleMessage(msg);
      }
    } catch (e) {
      debugPrint('VehicleCameraWebrtcSession poll: $e');
    }
  }

  Future<void> _handleMessage(VehicleCameraSignalingMessage msg) async {
    final pc = _pc;
    if (pc == null) return;
    switch (msg.kind) {
      case VehicleCameraSignalingKind.offer:
        if (role != VehicleCameraWebrtcRole.broadcaster) return;
        _remotePeerId = msg.fromPeerId;
        await pc.setRemoteDescription(
          RTCSessionDescription(msg.payload, 'offer'),
        );
        _remoteDescSet = true;
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        await signaling.publish(
          VehicleCameraSignalingMessage(
            id: uuid.v4(),
            sessionId: sessionId,
            fromPeerId: peerId,
            toPeerId: msg.fromPeerId,
            kind: VehicleCameraSignalingKind.answer,
            payload: answer.sdp ?? '',
            createdAt: DateTime.now().toUtc(),
          ),
        );
        onState?.call('answer_sent');
        break;
      case VehicleCameraSignalingKind.answer:
        if (role != VehicleCameraWebrtcRole.viewer) return;
        _remotePeerId = msg.fromPeerId;
        await pc.setRemoteDescription(
          RTCSessionDescription(msg.payload, 'answer'),
        );
        _remoteDescSet = true;
        onState?.call('answer_applied');
        break;
      case VehicleCameraSignalingKind.ice:
        if (!_remoteDescSet) return;
        try {
          final map = jsonDecode(msg.payload) as Map<String, dynamic>;
          await pc.addCandidate(
            RTCIceCandidate(
              map['candidate']?.toString(),
              map['sdpMid']?.toString(),
              map['sdpMLineIndex'] is int
                  ? map['sdpMLineIndex'] as int
                  : int.tryParse('${map['sdpMLineIndex']}'),
            ),
          );
        } catch (e) {
          debugPrint('ICE apply: $e');
        }
        break;
      case VehicleCameraSignalingKind.hangup:
        onFailed?.call(StateError('remote hangup'));
        break;
      case VehicleCameraSignalingKind.presence:
        // İzleyici: yayıncı çevrimiçi — henüz offer yoksa yeniden dene
        if (role == VehicleCameraWebrtcRole.viewer && !_remoteDescSet) {
          unawaited(_createAndPublishOffer());
        }
        break;
    }
  }

  /// Kaynakları serbest bırakır.
  Future<void> dispose() async {
    _disposed = true;
    _pollTimer?.cancel();
    try {
      await signaling.publish(
        VehicleCameraSignalingMessage(
          id: uuid.v4(),
          sessionId: sessionId,
          fromPeerId: peerId,
          toPeerId: _remotePeerId ?? '*',
          kind: VehicleCameraSignalingKind.hangup,
          payload: '',
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } catch (_) {}
    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    _pc = null;
    _localStream = null;
  }
}
