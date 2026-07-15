---
name: gps-konum-takibi
description: Use when implementing GPS location tracking, route management, map views, or visit check-in/check-out features for the field sales application
---

# GPS Konum Takibi Skill

## Flutter Paketleri

```yaml
# pubspec.yaml'a eklenecekler
geolocator: ^13.0.0
google_maps_flutter: ^2.9.0   # veya flutter_map (OpenStreetMap - ücretsiz)
flutter_background_service: ^5.0.0
permission_handler: ^11.3.0
```

## İzin Yönetimi

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Saha satış ziyaretleri için konumunuz kullanılmaktadır.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Arka planda konum takibi için izin gereklidir.</string>
```

### İzin İsteme
```dart
Future<bool> requestLocationPermission() async {
  final permission = await Permission.location.request();
  if (permission.isDenied) {
    // Kullanıcıya açıklama göster
    return false;
  }
  return permission.isGranted;
}
```

## Konum Servisi

```dart
class LocationService {
  // Tek seferlik konum al
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  // Sürekli konum takibi (plasiyer takibi için)
  Stream<Position> trackLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // 50 metre hareket ettikçe güncelle (pil tasarrufu)
      ),
    );
  }

  // İki konum arasındaki mesafe (metre)
  double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
```

## Ziyaret Check-in / Check-out

```dart
class VisitService {
  // Müşteri konumunda mı kontrol
  Future<bool> isAtCustomerLocation(Customer customer) async {
    final position = await LocationService().getCurrentPosition();
    if (position == null) return false;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      customer.latitude,
      customer.longitude,
    );

    // 200 metre tolerans (parametrik yapılabilir)
    return distance <= 200;
  }

  // Ziyaret başlatma
  Future<Visit> checkIn(Customer customer) async {
    final position = await LocationService().getCurrentPosition();
    final isAtLocation = await isAtCustomerLocation(customer);

    if (!isAtLocation) {
      // Uyarı: Müşteri konumunda değilsiniz
      // Parametrik: Zorunlu mu değil mi?
    }

    return Visit(
      id: const Uuid().v4(),
      customerId: customer.id,
      checkInTime: DateTime.now(),
      checkInLat: position?.latitude,
      checkInLon: position?.longitude,
      isAtLocation: isAtLocation,
    );
  }

  // Ziyaret bitirme
  Future<Visit> checkOut(Visit visit) async {
    final position = await LocationService().getCurrentPosition();
    return visit.copyWith(
      checkOutTime: DateTime.now(),
      checkOutLat: position?.latitude,
      checkOutLon: position?.longitude,
    );
  }
}
```

## Arka Plan Konum Takibi

```dart
// Plasiyer gün boyunca arka planda takip edilir
class BackgroundLocationService {
  static Future<void> startTracking() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Konum Takibi',
        initialNotificationContent: 'Saha satış takibi aktif',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    // 30 saniyede bir konum gönder
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final position = await Geolocator.getCurrentPosition();
      // Yerel DB'ye kaydet
      await LocationRepository().save(LocationPoint(
        userId: currentUserId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        isSynced: false,
      ));
    });
  }
}
```

## Harita Görünümü (Google Maps)

```dart
class ManagerMapScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesReps = ref.watch(activeSalesRepsProvider);

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(39.9334, 32.8597), // Ankara merkez
        zoom: 10,
      ),
      markers: salesReps.asData?.value.map((rep) => Marker(
        markerId: MarkerId(rep.id),
        position: LatLng(rep.lastLat, rep.lastLon),
        infoWindow: InfoWindow(
          title: rep.name,
          snippet: '${rep.todayVisits} ziyaret | ${rep.todaySales} TL',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          rep.isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      )).toSet() ?? {},
      onMapCreated: (controller) { mapController = controller; },
    );
  }
}
```

## Offline Konum Senkronizasyonu

```dart
// Çevrimdışıyken konum geçmişini yerel DB'ye kaydet
// Bağlantı gelince toplu sync yap
class LocationSyncService {
  Future<void> syncPendingLocations() async {
    final pending = await locationRepo.getPending();

    for (final batch in pending.chunked(100)) {
      try {
        await supabaseClient.from('location_history').insert(batch.toList());
        await locationRepo.markAsSynced(batch.map((l) => l.id).toList());
      } catch (e) {
        // Başarısız olursa bir sonraki sync'te dene
        break;
      }
    }
  }
}
```

## KVKK Uyumluluğu

```dart
// Konum izni aydınlatma metni göster
void showLocationConsentDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Konum Verisi Kullanımı'),
      content: const Text(
        'Saha satış faaliyetlerinizin yönetimi amacıyla '
        'konumunuz takip edilecektir. Bu veriler KVKK kapsamında '
        'işlenecek ve 1 yıl süreyle saklanacaktır.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Reddet')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            requestLocationPermission();
          },
          child: const Text('Kabul Et'),
        ),
      ],
    ),
  );
}
```

## Rut Navigasyon Entegrasyonu

```dart
// Müşteri adresine navigasyon başlat
Future<void> openNavigation(Customer customer) async {
  final lat = customer.latitude;
  final lon = customer.longitude;

  // Google Maps
  final googleMapsUrl = 'google.navigation:q=$lat,$lon&mode=d';
  // Yandex Maps
  final yandexUrl = 'yandexmaps://maps.yandex.ru/?rtext=~$lat,$lon&rtt=auto';

  if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
    await launchUrl(Uri.parse(googleMapsUrl));
  } else if (await canLaunchUrl(Uri.parse(yandexUrl))) {
    await launchUrl(Uri.parse(yandexUrl));
  }
}
```
