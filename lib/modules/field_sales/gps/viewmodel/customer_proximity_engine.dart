// Dosya Adı: customer_proximity_engine.dart
// Açıklama: En yakın müşteri proximity + debounce (spam önleme)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../../../../core/geo/haversine.dart';
import '../model/proximity_customer_pin.dart';

/// {@template customer_proximity_engine}
/// Konum güncellemesinde yarıçap içindeki **en yakın** müşteriyi bulur;
/// aynı müşteri için çıkış + cooldown olmadan tekrar uyarı vermez.
///
/// Kullanım örneği:
/// ```dart
/// final engine = CustomerProximityEngine();
/// final hit = engine.evaluate(
///   userLat: 41.0,
///   userLng: 29.0,
///   radiusMeters: 150,
///   customers: pins,
/// );
/// ```
/// {@endtemplate}
class CustomerProximityEngine {
  /// [defaultCooldown]: Aynı müşteri için varsayılan yeniden uyarı süresi
  static const Duration defaultCooldown = Duration(minutes: 30);

  /// [defaultRadiusMeters]: Dens varsayılan proximity yarıçapı
  static const double defaultRadiusMeters = 150;

  /// [cooldown]: Bildirim sonrası bekleme
  final Duration cooldown;

  /// [_lastNotifiedAt]: Müşteri başına son bildirim zamanı
  final Map<String, DateTime> _lastNotifiedAt = {};

  /// [_currentlyInside]: Bu oturumda yarıçap içinde kalan müşteriler
  final Set<String> _currentlyInside = {};

  /// {@macro customer_proximity_engine}
  CustomerProximityEngine({
    this.cooldown = defaultCooldown,
  });

  /// {@template customer_proximity_engine_evaluate}
  /// Yarıçap içindeki en yakın müşteri için tek seferlik hit döner.
  ///
  /// Parametreler:
  /// - [userLat] / [userLng]: Plasiyer konumu
  /// - [radiusMeters]: Proximity yarıçapı
  /// - [customers]: Koordinatlı cari pinleri
  /// - [now]: Test için sabit zaman (opsiyonel)
  ///
  /// Dönüş değeri:
  /// - [ProximityHit?]: Bildirim tetiklenecekse hit; aksi halde null
  /// {@endtemplate}
  ProximityHit? evaluate({
    required double userLat,
    required double userLng,
    required double radiusMeters,
    required List<ProximityCustomerPin> customers,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final radius = radiusMeters > 0 ? radiusMeters : defaultRadiusMeters;

    ProximityHit? nearest;
    final insideNow = <String>{};

    for (final pin in customers) {
      final id = pin.id.trim();
      if (id.isEmpty) continue;

      final distance = haversineMeters(
        userLat,
        userLng,
        pin.latitude,
        pin.longitude,
      );

      if (distance > radius) continue;

      insideNow.add(id);
      if (nearest == null || distance < nearest.distanceMeters) {
        nearest = ProximityHit(
          customerId: id,
          customerName: pin.name.trim().isEmpty ? id : pin.name.trim(),
          distanceMeters: distance,
        );
      }
    }

    // Yarıçap dışına çıkanları (veya bu turda gelmeyenleri) temizle
    _currentlyInside.removeWhere((id) => !insideNow.contains(id));

    if (nearest == null) return null;

    final id = nearest.customerId;
    if (_currentlyInside.contains(id)) {
      return null;
    }

    final last = _lastNotifiedAt[id];
    if (last != null && clock.difference(last) < cooldown) {
      // Cooldown sürerken "içeride" işaretleme — süre bitince aynı kalışta uyarı çıkar
      return null;
    }

    _currentlyInside.add(id);
    _lastNotifiedAt[id] = clock;
    return nearest;
  }

  /// {@template customer_proximity_engine_clear}
  /// Bellek durumunu sıfırlar (gün kapanışı / test).
  /// {@endtemplate}
  void clear() {
    _lastNotifiedAt.clear();
    _currentlyInside.clear();
  }

  /// {@template customer_proximity_engine_is_inside}
  /// Test / debug: müşteri şu an "içeride" işaretli mi.
  /// {@endtemplate}
  bool isInside(String customerId) =>
      _currentlyInside.contains(customerId.trim());
}
