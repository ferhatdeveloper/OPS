// Dosya Adı: live_location_realtime_client.dart
// Açıklama: Canlı konum WS/Realtime + HTTP poll yedek
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../service/postgres_service.dart';
import '../model/live_location_transport.dart';
import '../model/personnel_live_location.dart';
import 'live_location_poller.dart';
import 'personnel_live_location_store.dart';

/// {@template live_location_realtime_client}
/// Önce Realtime/WS dener; başarısızsa [LiveLocationPoller] ile HTTP poll.
///
/// Kullanım örneği:
/// ```dart
/// final client = LiveLocationRealtimeClient(store: store);
/// final sub = client.events.listen((e) => ...);
/// await client.start();
/// ```
/// {@endtemplate}
class LiveLocationRealtimeClient {
  /// [store]: loadLive kaynağı
  final PersonnelLiveLocationStore store;

  /// [limit]: Liste limiti
  final int limit;

  /// [postgres]: Kiracı URL / auth
  final PostgresService postgres;

  final StreamController<LiveLocationWatchEvent> _events =
      StreamController<LiveLocationWatchEvent>.broadcast();

  LiveLocationPoller? _poller;
  Timer? _safetyTimer;
  RealtimeChannel? _realtimeChannel;
  SupabaseClient? _supabaseClient;
  WebSocketChannel? _wsChannel;
  StreamSubscription<dynamic>? _wsSub;
  LiveLocationTransportMode _mode = LiveLocationTransportMode.httpPoll;
  bool _realtimeConnected = false;
  bool _started = false;
  List<PersonnelLiveLocation> _cache = const [];

  /// {@macro live_location_realtime_client}
  LiveLocationRealtimeClient({
    required this.store,
    this.limit = 100,
    PostgresService? postgres,
  }) : postgres = postgres ?? PostgresService.instance;

  /// Olay akışı
  Stream<LiveLocationWatchEvent> get events => _events.stream;

  /// Aktif mod
  LiveLocationTransportMode get mode => _mode;

  /// Realtime bağlı mı
  bool get realtimeConnected => _realtimeConnected;

  /// Dinlemeyi başlatır (idempotent).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final initial = await store.loadLive(limit: limit);
    _emit(initial, _mode, _realtimeConnected);

    final supabaseOk = await _trySupabaseRealtime();
    if (supabaseOk) {
      _mode = LiveLocationTransportMode.realtime;
      _realtimeConnected = true;
      _emit(_cache.isEmpty ? initial : _cache, _mode, true);
      _startSafetyPoll();
      return;
    }

    final wsOk = await _tryCustomWebSocket();
    if (wsOk) {
      _mode = LiveLocationTransportMode.realtime;
      _realtimeConnected = true;
      _emit(_cache.isEmpty ? initial : _cache, _mode, true);
      _startSafetyPoll();
      return;
    }

    _mode = LiveLocationTransportMode.httpPoll;
    _realtimeConnected = false;
    _startHttpPoll();
  }

  /// Dinlemeyi durdurur.
  Future<void> dispose() async {
    _started = false;
    _safetyTimer?.cancel();
    _safetyTimer = null;
    _poller?.stop();
    _poller = null;
    await _wsSub?.cancel();
    _wsSub = null;
    await _wsChannel?.sink.close();
    _wsChannel = null;
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _supabaseClient = null;
    await _events.close();
  }

  void _startHttpPoll() {
    _poller?.stop();
    _poller = LiveLocationPoller(store: store, limit: limit)
      ..start(
        onData: (rows) {
          _mode = _remoteConfigured
              ? LiveLocationTransportMode.httpPoll
              : LiveLocationTransportMode.localOnly;
          _emit(rows, _mode, false);
        },
      );
  }

  /// Realtime varken seyrek HTTP doğrulama.
  void _startSafetyPoll() {
    _safetyTimer?.cancel();
    _safetyTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      if (!_started || !_realtimeConnected) return;
      try {
        final rows = await store.loadLive(limit: limit);
        _mergeAndEmit(rows);
      } catch (e) {
        debugPrint('LiveLocationRealtimeClient safety poll: $e');
      }
    });
  }

  bool get _remoteConfigured =>
      postgres.activeRemoteRestUrl.trim().isNotEmpty;

  void _emit(
    List<PersonnelLiveLocation> rows,
    LiveLocationTransportMode mode,
    bool connected,
  ) {
    _cache = rows;
    if (_events.isClosed) return;
    _events.add(
      LiveLocationWatchEvent(
        rows: rows,
        mode: mode,
        realtimeConnected: connected,
      ),
    );
  }

  void _mergeAndEmit(List<PersonnelLiveLocation> incoming) {
    final merged = PersonnelLiveLocation.mergeLatestByUserId([
      ..._cache,
      ...incoming,
    ]).take(limit).toList(growable: false);
    _emit(merged, _mode, _realtimeConnected);
  }

  Future<bool> _trySupabaseRealtime() async {
    final rest = postgres.activeRemoteRestUrl.trim();
    if (rest.isEmpty) return false;

    final match = RegExp(
      r'^https://([a-z0-9-]+)\.supabase\.co/rest/v1/?$',
      caseSensitive: false,
    ).firstMatch(rest);
    if (match == null) return false;

    final host = match.group(1)!;
    final projectUrl = 'https://$host.supabase.co';
    final key = postgres.activeTenantApiKey ?? postgres.activeTenantJwt;
    if (key == null || key.trim().isEmpty) return false;

    try {
      _supabaseClient = SupabaseClient(projectUrl, key.trim());
      _realtimeChannel = _supabaseClient!.channel('live_location_snapshots');
      _realtimeChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: postgres.activePostgrestSchema.trim().isEmpty
                ? 'public'
                : postgres.activePostgrestSchema.trim(),
            table: 'live_location_snapshots',
            callback: (payload) {
              final record = payload.newRecord;
              if (record.isEmpty) return;
              try {
                final row = PersonnelLiveLocation.fromMap(record);
                _mergeAndEmit([row]);
              } catch (e) {
                debugPrint('LiveLocationRealtimeClient record: $e');
              }
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              _realtimeConnected = true;
            } else if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('LiveLocationRealtimeClient channel: $status $error');
              _fallbackToPoll('supabase');
            }
          });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return _realtimeConnected;
    } catch (e) {
      debugPrint('LiveLocationRealtimeClient supabase: $e');
      return false;
    }
  }

  Future<bool> _tryCustomWebSocket() async {
    final wsUrl = _resolveCustomWsUrl();
    if (wsUrl == null) return false;

    try {
      final headers = postgres.postgrestHeaders();
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsSub = _wsChannel!.stream.listen(
        _onWsMessage,
        onError: (Object e) {
          debugPrint('LiveLocationRealtimeClient ws error: $e');
          _fallbackToPoll('ws');
        },
        onDone: () => _fallbackToPoll('ws_done'),
      );
      if (headers.isNotEmpty) {
        _wsChannel!.sink.add(
          jsonEncode({'type': 'auth', 'headers': headers}),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return _realtimeConnected;
    } catch (e) {
      debugPrint('LiveLocationRealtimeClient ws connect: $e');
      return false;
    }
  }

  String? _resolveCustomWsUrl() {
    final rest = postgres.activeRemoteRestUrl.trim();
    if (rest.isEmpty) return null;
    final uri = Uri.tryParse(rest);
    if (uri == null || !uri.hasScheme) return null;
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final base = '$wsScheme://${uri.host}';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$base$port/ws/live-locations';
  }

  void _onWsMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String);
      if (decoded is List) {
        final rows = decoded
            .whereType<Map>()
            .map(
              (e) => PersonnelLiveLocation.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList(growable: false);
        if (rows.isNotEmpty) {
          _realtimeConnected = true;
          _mergeAndEmit(rows);
        }
        return;
      }
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type']?.toString();
        if (type == 'ping') {
          _realtimeConnected = true;
          return;
        }
        final record = decoded['record'] ?? decoded['payload'];
        if (record is Map) {
          _realtimeConnected = true;
          _mergeAndEmit([
            PersonnelLiveLocation.fromMap(
              Map<String, dynamic>.from(record),
            ),
          ]);
        }
      }
    } catch (e) {
      debugPrint('LiveLocationRealtimeClient ws parse: $e');
    }
  }

  void _fallbackToPoll(String reason) {
    if (!_started) return;
    if (_mode == LiveLocationTransportMode.httpPoll &&
        !_realtimeConnected) {
      return;
    }
    debugPrint('LiveLocationRealtimeClient fallback ($reason) → HTTP poll');
    _realtimeConnected = false;
    _mode = LiveLocationTransportMode.httpPoll;
    unawaited(_wsSub?.cancel());
    _wsSub = null;
    unawaited(_wsChannel?.sink.close());
    _wsChannel = null;
    unawaited(_realtimeChannel?.unsubscribe());
    _realtimeChannel = null;
    _startHttpPoll();
  }
}
