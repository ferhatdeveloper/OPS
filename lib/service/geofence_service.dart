// Dosya Adı: geofence_service.dart
// Açıklama: Mesai açıkken yakın müşteri proximity bildirim / diyalog
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/localization/app_localization.dart';
import '../core/navigation/app_navigator.dart';
import '../modules/field_sales/gps/model/proximity_customer_pin.dart';
import '../modules/field_sales/gps/view/customer_proximity_dialog.dart';
import '../modules/field_sales/gps/viewmodel/customer_proximity_engine.dart';
import '../modules/field_sales/gps/viewmodel/geofence_settings_store.dart';
import '../modules/field_sales/other/viewmodel/day_status_store.dart';
import '../modules/field_sales/routes/view/visit_form_screen.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// {@template geofence_service}
/// Konum akışında SQLite müşteri lat/long ile proximity kontrolü.
/// Mesai kapalıysa veya geofence ayarı kapalıysa sessizce çıkar.
/// {@endtemplate}
class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();

  factory GeofenceService() => _instance;

  GeofenceService._internal();

  /// [_settingsStore]: Yarıçap / enabled prefs
  final GeofenceSettingsStore _settingsStore = const GeofenceSettingsStore();

  /// [_dayStatusStore]: Mesai açık kapısı
  final DayStatusStore _dayStatusStore = const DayStatusStore();

  /// [_engine]: Mesafe + debounce motoru
  final CustomerProximityEngine _engine = CustomerProximityEngine();

  /// [_dialogOpen]: Aynı anda tek diyalog
  bool _dialogOpen = false;

  /// {@template geofence_service_check_proximity}
  /// Konum güncellemesinde en yakın müşteriye proximity uygular.
  ///
  /// Parametreler:
  /// - [position]: Plasiyer GPS konumu
  /// - [userId]: Kullanıcı id (ileriye dönük filtre; şimdilik kullanılmıyor)
  /// {@endtemplate}
  Future<void> checkProximity(Position position, String userId) async {
    try {
      final dayOpen = await _dayStatusStore.isDayOpen();
      if (!dayOpen) return;

      final settings = await _settingsStore.load();
      if (!settings.proximityAlertsEnabled) return;

      final threshold = settings.radiusMeters.toDouble();
      final customers = await _loadCustomerPins();
      if (customers.isEmpty) return;

      final hit = _engine.evaluate(
        userLat: position.latitude,
        userLng: position.longitude,
        radiusMeters: threshold,
        customers: customers,
      );
      if (hit == null) return;

      await _triggerProximityAlert(hit);
    } catch (e) {
      debugPrint('Geofence Error: $e');
    }
  }

  /// {@template geofence_service_load_pins}
  /// Offline SQLite'tan koordinatlı aktif carileri okur.
  /// {@endtemplate}
  Future<List<ProximityCustomerPin>> _loadCustomerPins() async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    final rows = await db.query(
      'customers',
      columns: ['id', 'name', 'latitude', 'longitude'],
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL '
          'AND (is_active IS NULL OR is_active = 1)',
    );

    final pins = <ProximityCustomerPin>[];
    for (final row in rows) {
      final id = (row['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) continue;
      final lat = (row['latitude'] as num?)?.toDouble();
      final lng = (row['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      pins.add(
        ProximityCustomerPin(
          id: id,
          name: (row['name'] as String?)?.trim() ?? id,
          latitude: lat,
          longitude: lng,
        ),
      );
    }
    return pins;
  }

  /// {@template geofence_service_trigger}
  /// Bildirim + ön planda dens diyalog; Evet → ziyaret formu.
  /// {@endtemplate}
  Future<void> _triggerProximityAlert(ProximityHit hit) async {
    final l10n = await AppLocalization.resolve();
    final body = l10n.translate(
      'field_sales.proximity_visit_prompt',
      args: {'name': hit.customerName},
    );
    final title = l10n.translate('field_sales.proximity_visit_title');

    await NotificationService().showNotification(
      id: hit.customerId.hashCode & 0x7fffffff,
      title: title,
      body: body,
      payload: NotificationService.visitPayload(hit.customerId),
    );

    await _showInAppPrompt(hit);
  }

  /// {@template geofence_service_in_app}
  /// Uygulama açıkken dens diyalog gösterir.
  /// {@endtemplate}
  Future<void> _showInAppPrompt(ProximityHit hit) async {
    if (_dialogOpen) return;
    final ctx = AppNavigator.context;
    if (ctx == null || !ctx.mounted) return;

    _dialogOpen = true;
    try {
      final accepted = await showCustomerProximityDialog(
        ctx,
        customerName: hit.customerName,
      );
      if (accepted == true) {
        await openVisitForCustomer(hit.customerId);
      }
    } finally {
      _dialogOpen = false;
    }
  }

  /// {@template geofence_service_open_visit}
  /// Ziyaret / check-in formuna named route ile gider.
  ///
  /// Parametreler:
  /// - [customerId]: Cari kimliği
  /// {@endtemplate}
  Future<void> openVisitForCustomer(String customerId) async {
    final id = customerId.trim();
    if (id.isEmpty) return;
    final nav = AppNavigator.state;
    if (nav == null) return;
    await nav.pushNamed(
      VisitFormScreen.routeName,
      arguments: id,
    );
  }

  /// {@template geofence_service_clear_cache}
  /// Debounce bellek temizliği (gün kapanışı).
  /// {@endtemplate}
  void clearCache() {
    _engine.clear();
  }
}
