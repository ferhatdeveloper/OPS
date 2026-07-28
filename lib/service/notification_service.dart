// Dosya Adı: notification_service.dart
// Açıklama: Yerel bildirim servisi + ziyaret payload yönlendirme
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/navigation/app_navigator.dart';
import '../modules/field_sales/routes/view/visit_form_screen.dart';

/// {@template notification_service}
/// Yerel bildirim gösterimi ve proximity ziyaret payload işleme.
/// {@endtemplate}
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  /// [visitPayloadPrefix]: Ziyaret yönlendirme payload öneki
  static const String visitPayloadPrefix = 'visit:';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// {@template notification_service_visit_payload}
  /// Proximity bildirimi için `visit:{customerId}` payload üretir.
  /// {@endtemplate}
  static String visitPayload(String customerId) =>
      '$visitPayloadPrefix${customerId.trim()}';

  /// {@template notification_service_parse_visit}
  /// Payload'dan cari id çıkarır; geçersizse null.
  /// {@endtemplate}
  static String? parseVisitCustomerId(String? payload) {
    final raw = payload?.trim() ?? '';
    if (!raw.startsWith(visitPayloadPrefix)) return null;
    final id = raw.substring(visitPayloadPrefix.length).trim();
    return id.isEmpty ? null : id;
  }

  /// {@template notification_service_initialize}
  /// Plugin init + tıklamada ziyaret formuna git.
  /// {@endtemplate}
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification clicked: ${response.payload}');
    final customerId = parseVisitCustomerId(response.payload);
    if (customerId == null) return;
    final nav = AppNavigator.state;
    if (nav == null) return;
    nav.pushNamed(
      VisitFormScreen.routeName,
      arguments: customerId,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'exfin_ops_channel',
      'EXFINOPS Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Mock for receiving a push notification from the center
  Future<void> simulatePushNotification(String title, String body) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📢 MERKEZ: $title',
      body: body,
    );
  }
}
