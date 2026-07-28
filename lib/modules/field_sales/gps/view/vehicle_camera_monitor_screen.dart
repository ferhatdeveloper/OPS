// Dosya Adı: vehicle_camera_monitor_screen.dart
// Açıklama: Yönetici araç kamera izleme (WebRTC dual + JPEG fallback)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'dart:async';
import 'dart:convert';
import '../../shared/view/field_sales_dens_theme.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/vehicle_camera_frame.dart';
import '../model/vehicle_camera_ice_config.dart';
import '../model/vehicle_camera_lens.dart';
import '../model/vehicle_camera_signaling_message.dart';
import '../model/vehicle_camera_transport.dart';
import '../viewmodel/vehicle_camera_frame_store.dart';
import '../viewmodel/vehicle_camera_settings_store.dart';
import '../viewmodel/vehicle_camera_signaling_store.dart';
import '../viewmodel/vehicle_camera_webrtc_session.dart';

/// {@template vehicle_camera_monitor_screen}
/// Yönetici: WebRTC canlı (ön+arka split); başarısız/timeout → JPEG poll.
/// Route: `/field-sales/vehicle-camera-monitor`
/// {@endtemplate}
class VehicleCameraMonitorScreen extends StatefulWidget {
  static const String routeName = '/field-sales/vehicle-camera-monitor';

  final VehicleCameraFrameStore frameStore;
  final VehicleCameraSettingsStore settingsStore;
  final VehicleCameraSignalingStore signalingStore;
  final String? filterUserId;

  /// [webrtcConnectTimeout]: Canlı bağlanamazsa JPEG'e düş
  final Duration webrtcConnectTimeout;

  const VehicleCameraMonitorScreen({
    Key? key,
    this.frameStore = const VehicleCameraFrameStore(),
    this.settingsStore = const VehicleCameraSettingsStore(),
    this.signalingStore = const VehicleCameraSignalingStore(),
    this.filterUserId,
    this.webrtcConnectTimeout = const Duration(seconds: 28),
  }) : super(key: key);

  @override
  State<VehicleCameraMonitorScreen> createState() =>
      _VehicleCameraMonitorScreenState();
}

class _VehicleCameraMonitorScreenState
    extends State<VehicleCameraMonitorScreen> {
  List<VehicleCameraFrame> _frames = const [];
  bool _loading = true;
  bool _enabled = false;
  bool _webrtcPref = false;
  bool _audioPref = false;
  bool _webrtcFailed = false;
  VehicleCameraActiveTransport _transport =
      VehicleCameraActiveTransport.jpegPoll;
  /// null = her iki lens (çift izleme)
  VehicleCameraLens? _lensFilter;
  Timer? _poll;
  Timer? _webrtcTimeout;
  VehicleCameraWebrtcSession? _webrtcFront;
  VehicleCameraWebrtcSession? _webrtcRear;
  VehicleCameraIceConfig _ice = const VehicleCameraIceConfig();
  String? _webrtcTargetUser;
  String _webrtcState = '';
  final _fmt = DateFormat('dd.MM.yyyy HH:mm:ss');
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _webrtcTimeout?.cancel();
    unawaited(_disposeWebrtc());
    super.dispose();
  }

  Future<void> _disposeWebrtc() async {
    await _webrtcFront?.dispose();
    await _webrtcRear?.dispose();
    _webrtcFront = null;
    _webrtcRear = null;
  }

  Future<void> _bootstrap() async {
    final s = await widget.settingsStore.load();
    _enabled = s.enabled;
    _webrtcPref = s.webrtcEnabled;
    _audioPref = s.audioEnabled;
    _ice = VehicleCameraIceConfig.fromSettings(s);
    if (!_enabled) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    await _load();
    _poll = Timer.periodic(
      Duration(seconds: s.intervalSeconds),
      (_) => _load(),
    );
    await _maybeStartWebrtc();
  }

  bool get _wantDual => _lensFilter == null;

  Future<void> _maybeStartWebrtc() async {
    final want = VehicleCameraTransportSelector.resolve(
      webrtcEnabled: _webrtcPref,
      platformSupportsWebrtc:
          VehicleCameraTransportSelector.supportsMonitorWebrtc(
        isWeb: kIsWeb,
      ),
      webrtcFailed: _webrtcFailed,
    );
    if (want != VehicleCameraActiveTransport.webrtc) {
      setState(() => _transport = VehicleCameraActiveTransport.jpegPoll);
      return;
    }

    String? target = widget.filterUserId?.trim().isNotEmpty == true
        ? widget.filterUserId!.trim()
        : (_frames.isNotEmpty ? _frames.first.userId : null);

    if (target == null || target.isEmpty) {
      try {
        final sessions = await widget.signalingStore.loadRecentSessionIds();
        for (final sid in sessions) {
          final uid =
              VehicleCameraSignalingMessage.userIdFromSessionId(sid);
          if (uid == null) continue;
          final sl =
              VehicleCameraSignalingMessage.lensFromSessionId(sid);
          if (_lensFilter != null && sl != _lensFilter) continue;
          target = uid;
          break;
        }
      } catch (_) {}
    }
    if (target == null || target.isEmpty) {
      setState(() => _transport = VehicleCameraActiveTransport.jpegPoll);
      return;
    }

    await _disposeWebrtc();
    _webrtcTargetUser = target;

    final lenses = _wantDual
        ? <VehicleCameraLens>[
            VehicleCameraLens.front,
            VehicleCameraLens.rear,
          ]
        : <VehicleCameraLens>[_lensFilter!];

    try {
      for (final lens in lenses) {
        final session = VehicleCameraWebrtcSession(
          role: VehicleCameraWebrtcRole.viewer,
          userId: target,
          lens: lens,
          peerId: 'vw-${lens.storageKey}-${_uuid.v4()}',
          signaling: widget.signalingStore,
          ice: _ice,
          audioEnabled: _audioPref,
          onState: (st) {
            if (!mounted) return;
            setState(() {
              _webrtcState = st;
              if (st == 'streaming' || st.contains('Connected')) {
                _transport = VehicleCameraActiveTransport.webrtc;
                _webrtcTimeout?.cancel();
              }
            });
          },
          onFailed: (_) {
            // Tek lens düşerse diğer canlı kalabilir
            if (!mounted) return;
            if (!_anyRemoteLive) {
              unawaited(_fallbackJpeg());
            }
          },
        );
        await session.start();
        if (!mounted) {
          await session.dispose();
          return;
        }
        if (lens == VehicleCameraLens.front) {
          _webrtcFront = session;
        } else {
          _webrtcRear = session;
        }
      }
      setState(() {
        _transport = VehicleCameraActiveTransport.webrtc;
        _webrtcState = 'joining';
      });
      _webrtcTimeout?.cancel();
      _webrtcTimeout = Timer(widget.webrtcConnectTimeout, () {
        if (!mounted) return;
        if (!_anyRemoteLive) {
          unawaited(_fallbackJpeg());
        }
      });
    } catch (e) {
      debugPrint('monitor webrtc: $e');
      await _disposeWebrtc();
      await _fallbackJpeg();
    }
  }

  bool get _anyRemoteLive =>
      (_webrtcFront?.hasRemoteVideo ?? false) ||
      (_webrtcRear?.hasRemoteVideo ?? false);

  bool get _showLive =>
      _transport == VehicleCameraActiveTransport.webrtc &&
      (_webrtcFront != null || _webrtcRear != null);

  Future<void> _fallbackJpeg() async {
    _webrtcFailed = true;
    _webrtcTimeout?.cancel();
    await _disposeWebrtc();
    if (!mounted) return;
    setState(() => _transport = VehicleCameraActiveTransport.jpegPoll);
  }

  Future<void> _load() async {
    List<VehicleCameraFrame> rows;
    try {
      rows = await widget.frameStore.loadLatest();
    } catch (_) {
      rows = const [];
    }
    final filterUser = widget.filterUserId;
    if (filterUser != null && filterUser.isNotEmpty) {
      rows = rows.where((f) => f.userId == filterUser).toList();
    }
    if (_lensFilter != null) {
      rows = rows.where((f) => f.lens == _lensFilter).toList();
    }
    if (!mounted) return;
    final hadNoTarget = _webrtcTargetUser == null;
    setState(() {
      _frames = rows;
      _loading = false;
    });
    if (_webrtcPref &&
        !_webrtcFailed &&
        _webrtcFront == null &&
        _webrtcRear == null &&
        hadNoTarget &&
        rows.isNotEmpty) {
      await _maybeStartWebrtc();
    }
  }

  Future<void> _onLensChip(VehicleCameraLens? lens) async {
    setState(() => _lensFilter = lens);
    await _load();
    if (_webrtcPref) {
      _webrtcFailed = false;
      await _maybeStartWebrtc();
    }
  }

  Widget _livePane({
    required String label,
    required VehicleCameraWebrtcSession? session,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: session == null
                ? ColoredBox(
                    color: Colors.black12,
                    child: Center(
                      child: Text(
                        AppLocalization.of(context).translate(
                          'field_sales.vehicle_camera_waiting_lens',
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                : RTCVideoView(
                    session.remoteRenderer,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title =
        l10n.translate('field_sales.vehicle_camera_monitor');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            tooltip: l10n.translate('common.reload'),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: !_enabled
          ? Center(
              child: Text(
                l10n.translate('field_sales.vehicle_camera_disabled'),
                style: const TextStyle(fontSize: 14),
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
                        selected: _lensFilter == null,
                        onTap: () => _onLensChip(null),
                      ),
                      FieldSalesDensChipItem(
                        label: l10n.translate(
                          'field_sales.vehicle_camera_front',
                        ),
                        selected: _lensFilter == VehicleCameraLens.front,
                        onTap: () => _onLensChip(VehicleCameraLens.front),
                      ),
                      FieldSalesDensChipItem(
                        label: l10n.translate(
                          'field_sales.vehicle_camera_rear',
                        ),
                        selected: _lensFilter == VehicleCameraLens.rear,
                        onTap: () => _onLensChip(VehicleCameraLens.rear),
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
                if (_webrtcPref)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                    child: Text(
                      l10n.translate(
                        _showLive && _anyRemoteLive
                            ? 'field_sales.vehicle_camera_monitor_webrtc_live'
                            : 'field_sales.vehicle_camera_monitor_fallback',
                        args: {'state': _webrtcState},
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                if (_showLive)
                  SizedBox(
                    height: _wantDual ? 280 : 180,
                    child: _wantDual
                        ? Column(
                            children: [
                              _livePane(
                                label: l10n.translate(
                                  'field_sales.vehicle_camera_front',
                                ),
                                session: _webrtcFront,
                              ),
                              const SizedBox(height: 4),
                              _livePane(
                                label: l10n.translate(
                                  'field_sales.vehicle_camera_rear',
                                ),
                                session: _webrtcRear,
                              ),
                            ],
                          )
                        : Builder(
                            builder: (_) {
                              final s = _lensFilter == VehicleCameraLens.rear
                                  ? _webrtcRear
                                  : _webrtcFront;
                              if (s == null) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return RTCVideoView(
                                s.remoteRenderer,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              );
                            },
                          ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _frames.isEmpty && !_anyRemoteLive
                          ? Center(
                              child: Text(
                                l10n.translate(
                                  'field_sales.vehicle_camera_no_frames',
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                10,
                                4,
                                10,
                                12,
                              ),
                              itemCount: _frames.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, i) {
                                final f = _frames[i];
                                final lensLabel = l10n.translate(
                                  f.lens == VehicleCameraLens.rear
                                      ? 'field_sales.vehicle_camera_rear'
                                      : 'field_sales.vehicle_camera_front',
                                );
                                Widget image;
                                try {
                                  final bytes =
                                      base64Decode(f.imageBase64);
                                  image = Image.memory(
                                    bytes,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                      height: 80,
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                } catch (_) {
                                  image = const SizedBox(
                                    height: 80,
                                    child: Icon(Icons.broken_image),
                                  );
                                }
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      image,
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          '${f.salespersonCode} · $lensLabel · ${_fmt.format(f.capturedAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
