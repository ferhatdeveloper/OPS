// Dosya Adı: live_location_poller.dart
// Açıklama: Canlı konum HTTP poll — değişimde hızlı, aynı snapshot’ta backoff
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:async';

import '../model/live_location_quality.dart';
import '../model/live_location_transport.dart';
import '../model/personnel_live_location.dart';
import 'personnel_live_location_store.dart';

/// {@template live_location_poller}
/// PostgREST Realtime yokken yönetici listesi için HTTP poll.
///
/// Kullanım örneği:
/// ```dart
/// final poller = LiveLocationPoller(store: store);
/// poller.start(onData: (rows) => ...);
/// ```
/// {@endtemplate}
class LiveLocationPoller {
  /// Backoff adımları (değişim yokken).
  static const List<Duration> managerPollBackoffSteps = [
    Duration(seconds: 5),
    Duration(seconds: 8),
    Duration(seconds: 12),
    Duration(seconds: 15),
  ];

  /// [store]: Veri kaynağı
  final PersonnelLiveLocationStore store;

  /// [limit]: Maksimum satır
  final int limit;

  Timer? _timer;
  LiveLocationSnapshotFingerprint? _lastFp;
  int _backoffIndex = 0;
  bool _busy = false;

  /// {@macro live_location_poller}
  LiveLocationPoller({
    required this.store,
    this.limit = 100,
  });

  /// Poll döngüsünü başlatır.
  void start({
    required void Function(List<PersonnelLiveLocation> rows) onData,
    void Function(Object error)? onError,
    bool immediate = true,
    Duration? initialDelay,
  }) {
    stop();
    if (immediate) {
      unawaited(_tick(onData, onError));
    } else {
      _scheduleNext(
        onData,
        onError,
        initialDelay ?? LiveLocationQuality.managerPollInterval,
      );
    }
  }

  /// Poll’u durdurur.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNext(
    void Function(List<PersonnelLiveLocation> rows) onData,
    void Function(Object error)? onError,
    Duration delay,
  ) {
    _timer?.cancel();
    _timer = Timer(delay, () => _tick(onData, onError));
  }

  Future<void> _tick(
    void Function(List<PersonnelLiveLocation> rows) onData,
    void Function(Object error)? onError,
  ) async {
    if (_busy) {
      _scheduleNext(
        onData,
        onError,
        LiveLocationQuality.managerPollInterval,
      );
      return;
    }
    _busy = true;
    try {
      final rows = await store.loadLive(limit: limit);
      onData(rows);
      final fp = LiveLocationSnapshotFingerprint.fromRows(rows);
      Duration next;
      if (_lastFp != null && _lastFp!.value == fp.value) {
        final idx = _backoffIndex.clamp(
          0,
          managerPollBackoffSteps.length - 1,
        );
        next = managerPollBackoffSteps[idx];
        if (_backoffIndex < managerPollBackoffSteps.length - 1) {
          _backoffIndex++;
        }
      } else {
        _backoffIndex = 0;
        next = LiveLocationQuality.managerPollInterval;
      }
      _lastFp = fp;
      _scheduleNext(onData, onError, next);
    } catch (e) {
      onError?.call(e);
      _scheduleNext(
        onData,
        onError,
        managerPollBackoffSteps.last,
      );
    } finally {
      _busy = false;
    }
  }
}
