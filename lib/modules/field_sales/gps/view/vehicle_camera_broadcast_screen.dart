// Dosya Adı: vehicle_camera_broadcast_screen.dart
// Açıklama: Plasiyer araç kamera yayını (WebRTC dual/sırayla + JPEG)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:async';
import 'dart:convert';
import '../../shared/view/field_sales_dens_theme.dart';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/auth_service.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/vehicle_camera_frame.dart';
import '../model/vehicle_camera_ice_config.dart';
import '../model/vehicle_camera_lens.dart';
import '../model/vehicle_camera_settings_record.dart';
import '../model/vehicle_camera_transport.dart';
import '../viewmodel/vehicle_camera_frame_store.dart';
import '../viewmodel/vehicle_camera_settings_store.dart';
import '../viewmodel/vehicle_camera_signaling_store.dart';
import '../viewmodel/vehicle_camera_webrtc_session.dart';

/// {@template vehicle_camera_broadcast_screen}
/// Plasiyer: WebRTC tercih edilirse P2P yayın; çift lens mümkünse eşzamanlı,
/// değilse time-slice. Başarısız/web → JPEG snapshot.
/// Route: `/field-sales/vehicle-camera-broadcast`
/// {@endtemplate}
class VehicleCameraBroadcastScreen extends StatefulWidget {
  static const String routeName = '/field-sales/vehicle-camera-broadcast';

  final VehicleCameraSettingsStore settingsStore;
  final VehicleCameraFrameStore frameStore;
  final VehicleCameraSignalingStore signalingStore;

  const VehicleCameraBroadcastScreen({
    Key? key,
    this.settingsStore = const VehicleCameraSettingsStore(),
    this.frameStore = const VehicleCameraFrameStore(),
    this.signalingStore = const VehicleCameraSignalingStore(),
  }) : super(key: key);

  @override
  State<VehicleCameraBroadcastScreen> createState() =>
      _VehicleCameraBroadcastScreenState();
}

class _VehicleCameraBroadcastScreenState
    extends State<VehicleCameraBroadcastScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  VehicleCameraLens _lens = VehicleCameraLens.front;
  /// true = ön+arka (eşzamanlı veya sırayla)
  bool _bothMode = false;
  bool _enabled = false;
  bool _busy = true;
  String? _errorKey;
  Timer? _snapTimer;
  Timer? _alternateTimer;
  int _intervalSec = 8;
  bool _webrtcPref = false;
  bool _audioPref = false;
  bool _webrtcFailed = false;
  bool _concurrentBoth = false;
  bool _alternating = false;
  VehicleCameraActiveTransport _transport =
      VehicleCameraActiveTransport.jpegPoll;
  VehicleCameraWebrtcSession? _webrtcFront;
  VehicleCameraWebrtcSession? _webrtcRear;
  VehicleCameraIceConfig _ice = const VehicleCameraIceConfig();
  String _webrtcState = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    _alternateTimer?.cancel();
    unawaited(_disposeWebrtc());
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _disposeWebrtc() async {
    await _webrtcFront?.dispose();
    await _webrtcRear?.dispose();
    _webrtcFront = null;
    _webrtcRear = null;
  }

  Future<void> _bootstrap() async {
    final settings = await widget.settingsStore.load();
    if (!settings.enabled) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _busy = false;
        _errorKey = 'field_sales.vehicle_camera_disabled';
      });
      return;
    }
    _enabled = true;
    _lens = settings.defaultLens;
    _bothMode = settings.broadcastBothLenses;
    _intervalSec = settings.intervalSeconds;
    _webrtcPref = settings.webrtcEnabled;
    _audioPref = settings.audioEnabled;
    _ice = VehicleCameraIceConfig.fromSettings(settings);

    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'field_sales.vehicle_camera_web_unsupported';
      });
      return;
    }

    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'field_sales.vehicle_camera_permission_denied';
      });
      return;
    }
    if (_audioPref) {
      await Permission.microphone.request();
    }

    await _applyTransportAndOpen();
  }

  Future<void> _applyTransportAndOpen() async {
    final wantWebrtc = VehicleCameraTransportSelector.resolve(
      webrtcEnabled: _webrtcPref,
      platformSupportsWebrtc:
          VehicleCameraTransportSelector.supportsBroadcastWebrtc(
        isWeb: kIsWeb,
      ),
      webrtcFailed: _webrtcFailed,
    );
    _transport = wantWebrtc;

    if (wantWebrtc == VehicleCameraActiveTransport.webrtc) {
      final ok = await _startWebrtc();
      if (ok) return;
      _webrtcFailed = true;
      _transport = VehicleCameraActiveTransport.jpegPoll;
    }
    await _startJpegPath();
  }

  Future<VehicleCameraWebrtcSession?> _openWebrtcLens(
    VehicleCameraLens lens,
  ) async {
    final user = AuthService.getCurrentUser() ?? 'unknown';
    final session = VehicleCameraWebrtcSession(
      role: VehicleCameraWebrtcRole.broadcaster,
      userId: user,
      lens: lens,
      peerId: 'bc-$user-${lens.storageKey}',
      signaling: widget.signalingStore,
      ice: _ice,
      audioEnabled: _audioPref && lens == VehicleCameraLens.front,
      onState: (s) {
        if (!mounted) return;
        setState(() => _webrtcState = s);
      },
      onFailed: (_) {
        if (!mounted) return;
        unawaited(_fallbackToJpeg());
      },
    );
    try {
      await session.start();
      return session;
    } catch (e) {
      debugPrint('webrtc lens ${lens.storageKey}: $e');
      await session.dispose();
      return null;
    }
  }

  Future<bool> _startWebrtc() async {
    setState(() {
      _busy = true;
      _errorKey = null;
      _concurrentBoth = false;
      _alternating = false;
    });
    _snapTimer?.cancel();
    _snapTimer = null;
    _alternateTimer?.cancel();
    _alternateTimer = null;
    await _controller?.dispose();
    _controller = null;
    await _disposeWebrtc();

    if (_bothMode) {
      // Önce eşzamanlı dene (çoğu telefonda 2. lens başarısız olur)
      final front = await _openWebrtcLens(VehicleCameraLens.front);
      if (front == null) return false;
      _webrtcFront = front;
      final rear = await _openWebrtcLens(VehicleCameraLens.rear);
      if (rear != null) {
        _webrtcRear = rear;
        _concurrentBoth = true;
        if (!mounted) {
          await _disposeWebrtc();
          return false;
        }
        setState(() {
          _busy = false;
          _transport = VehicleCameraActiveTransport.webrtc;
          _lens = VehicleCameraLens.front;
        });
        return true;
      }
      // Eşzamanlı yok → sırayla (time-slice)
      _alternating = true;
      _lens = VehicleCameraLens.front;
      _startAlternateTimer();
      if (!mounted) {
        await _disposeWebrtc();
        return false;
      }
      setState(() {
        _busy = false;
        _transport = VehicleCameraActiveTransport.webrtc;
      });
      return true;
    }

    final single = await _openWebrtcLens(_lens);
    if (single == null) return false;
    if (_lens == VehicleCameraLens.front) {
      _webrtcFront = single;
    } else {
      _webrtcRear = single;
    }
    if (!mounted) {
      await single.dispose();
      return false;
    }
    setState(() {
      _busy = false;
      _transport = VehicleCameraActiveTransport.webrtc;
    });
    return true;
  }

  void _startAlternateTimer() {
    _alternateTimer?.cancel();
    _alternateTimer = Timer.periodic(
      const Duration(
        seconds: VehicleCameraSettingsRecord.defaultAlternateSeconds,
      ),
      (_) => unawaited(_switchAlternateLens()),
    );
  }

  Future<void> _switchAlternateLens() async {
    if (!_alternating ||
        _transport != VehicleCameraActiveTransport.webrtc) {
      return;
    }
    final next = _lens == VehicleCameraLens.front
        ? VehicleCameraLens.rear
        : VehicleCameraLens.front;
    // Aktif oturumu kapat, diğerini aç
    if (_lens == VehicleCameraLens.front) {
      await _webrtcFront?.dispose();
      _webrtcFront = null;
    } else {
      await _webrtcRear?.dispose();
      _webrtcRear = null;
    }
    final s = await _openWebrtcLens(next);
    if (s == null) {
      // Geri eski lense dönmeyi dene
      final back = await _openWebrtcLens(_lens);
      if (back == null) {
        await _fallbackToJpeg();
        return;
      }
      if (_lens == VehicleCameraLens.front) {
        _webrtcFront = back;
      } else {
        _webrtcRear = back;
      }
      return;
    }
    _lens = next;
    if (next == VehicleCameraLens.front) {
      _webrtcFront = s;
    } else {
      _webrtcRear = s;
    }
    if (mounted) setState(() {});
  }

  Future<void> _fallbackToJpeg() async {
    _webrtcFailed = true;
    _alternateTimer?.cancel();
    await _disposeWebrtc();
    _transport = VehicleCameraActiveTransport.jpegPoll;
    await _startJpegPath();
  }

  Future<void> _startJpegPath() async {
    setState(() {
      _busy = true;
      _errorKey = null;
      _transport = VehicleCameraActiveTransport.jpegPoll;
    });
    try {
      _cameras = await availableCameras();
      await _openLens(_lens);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'field_sales.vehicle_camera_init_failed';
      });
    }
  }

  CameraDescription? _pickCamera(VehicleCameraLens lens) {
    if (_cameras.isEmpty) return null;
    final want = lens == VehicleCameraLens.front
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    for (final c in _cameras) {
      if (c.lensDirection == want) return c;
    }
    return _cameras.first;
  }

  Future<void> _setMode({
    required bool both,
    VehicleCameraLens? lens,
  }) async {
    setState(() {
      _bothMode = both;
      if (lens != null) _lens = lens;
    });
    _alternateTimer?.cancel();
    if (_transport == VehicleCameraActiveTransport.webrtc) {
      await _disposeWebrtc();
      final ok = await _startWebrtc();
      if (!ok) {
        _webrtcFailed = true;
        await _startJpegPath();
      }
      return;
    }
    await _openLens(_lens);
  }

  Future<void> _openLens(VehicleCameraLens lens) async {
    if (_transport == VehicleCameraActiveTransport.webrtc) {
      setState(() {
        _lens = lens;
        _bothMode = false;
      });
      _alternateTimer?.cancel();
      await _disposeWebrtc();
      final ok = await _startWebrtc();
      if (!ok) {
        _webrtcFailed = true;
        await _startJpegPath();
      }
      return;
    }

    setState(() {
      _busy = true;
      _errorKey = null;
      _lens = lens;
    });
    await _controller?.dispose();
    _controller = null;
    final desc = _pickCamera(lens);
    if (desc == null) {
      setState(() {
        _busy = false;
        _errorKey = 'field_sales.vehicle_camera_init_failed';
      });
      return;
    }
    final ctrl = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await ctrl.initialize();
    if (!mounted) {
      await ctrl.dispose();
      return;
    }
    _controller = ctrl;
    _restartSnapTimer();
    setState(() => _busy = false);
  }

  void _restartSnapTimer() {
    _snapTimer?.cancel();
    _snapTimer = Timer.periodic(
      Duration(seconds: _intervalSec),
      (_) => unawaited(_captureAndUpload()),
    );
    unawaited(_captureAndUpload());
  }

  Future<void> _captureAndUpload() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.isTakingPicture) return;
    try {
      final file = await ctrl.takePicture();
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final user = AuthService.getCurrentUser() ?? 'unknown';
      final frame = VehicleCameraFrame(
        id: const Uuid().v4(),
        userId: user,
        salespersonCode: user,
        lens: _lens,
        capturedAt: DateTime.now(),
        imageBase64: b64,
      );
      await widget.frameStore.insertFrame(frame);
    } catch (e) {
      debugPrint('vehicle camera snap: $e');
    }
  }

  String _hintKey() {
    if (_transport == VehicleCameraActiveTransport.webrtc) {
      if (_concurrentBoth) {
        return 'field_sales.vehicle_camera_broadcast_dual_concurrent';
      }
      if (_alternating) {
        return 'field_sales.vehicle_camera_broadcast_dual_alternate';
      }
      return 'field_sales.vehicle_camera_broadcast_webrtc_hint';
    }
    return 'field_sales.vehicle_camera_broadcast_hint';
  }

  VehicleCameraWebrtcSession? get _activeWebrtc {
    if (_concurrentBoth) {
      return _webrtcFront ?? _webrtcRear;
    }
    return _lens == VehicleCameraLens.rear ? _webrtcRear : _webrtcFront;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title =
        l10n.translate('field_sales.vehicle_camera_broadcast');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(title: title),
      body: !_enabled || _errorKey != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.translate(
                    _errorKey ?? 'field_sales.vehicle_camera_disabled',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                  child: FieldSalesDensChipRow(
                    items: [
                      FieldSalesDensChipItem(
                        label: l10n.translate(
                          'field_sales.vehicle_camera_both',
                        ),
                        selected: _bothMode,
                        onTap: () => _setMode(both: true),
                      ),
                      FieldSalesDensChipItem(
                        label: l10n.translate(
                          'field_sales.vehicle_camera_front',
                        ),
                        selected:
                            !_bothMode && _lens == VehicleCameraLens.front,
                        onTap: () => _setMode(
                          both: false,
                          lens: VehicleCameraLens.front,
                        ),
                      ),
                      FieldSalesDensChipItem(
                        label: l10n.translate(
                          'field_sales.vehicle_camera_rear',
                        ),
                        selected:
                            !_bothMode && _lens == VehicleCameraLens.rear,
                        onTap: () => _setMode(
                          both: false,
                          lens: VehicleCameraLens.rear,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_webrtcPref && !_ice.hasTurn)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                    child: Text(
                      l10n.translate(
                        'field_sales.vehicle_camera_turn_missing_banner',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                Expanded(
                  child: _busy
                      ? const Center(child: CircularProgressIndicator())
                      : _transport == VehicleCameraActiveTransport.webrtc
                          ? _buildWebrtcPreview()
                          : _controller == null
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : ClipRect(
                                  child: CameraPreview(_controller!),
                                ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: Text(
                    l10n.translate(
                      _hintKey(),
                      args: {
                        'sec': '$_intervalSec',
                        'state': _webrtcState,
                        'lens': l10n.translate(
                          _lens == VehicleCameraLens.rear
                              ? 'field_sales.vehicle_camera_rear'
                              : 'field_sales.vehicle_camera_front',
                        ),
                      },
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWebrtcPreview() {
    if (_concurrentBoth &&
        _webrtcFront != null &&
        _webrtcRear != null) {
      return Column(
        children: [
          Expanded(
            child: RTCVideoView(
              _webrtcFront!.localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RTCVideoView(
              _webrtcRear!.localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ],
      );
    }
    final s = _activeWebrtc;
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RTCVideoView(
      s.localRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}
