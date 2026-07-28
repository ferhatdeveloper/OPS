// Dosya Adı: ai_insight_notifier.dart
// Açıklama: Bitiş uyarıları → in-app + opsiyonel local notification
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../../service/notification_service.dart';
import '../model/demand_forecast_models.dart';
import 'customer_product_consumption_store.dart';

/// {@template ai_insight_notifier}
/// Deterministik uyarıları yükler; isteğe bağlı yerel bildirim gösterir.
/// Otomatik sipariş kesmez.
///
/// Kullanım örneği:
/// ```dart
/// final n = AiInsightNotifier();
/// final alerts = await n.loadInAppAlerts();
/// await n.maybeNotifyLocal(alerts, enabled: false);
/// ```
/// {@endtemplate}
class AiInsightNotifier {
  /// [store]: Forecast kaynağı
  final CustomerProductConsumptionStore store;

  /// [notifications]: Yerel bildirim (opsiyonel)
  final NotificationService? notifications;

  /// {@macro ai_insight_notifier}
  const AiInsightNotifier({
    this.store = const CustomerProductConsumptionStore(),
    this.notifications,
  });

  /// In-app dens liste (zorunlu kanal)
  Future<List<AiInsightAlert>> loadInAppAlerts({
    Set<String>? customerIds,
  }) {
    return store.loadAlerts(customerIds: customerIds);
  }

  /// {@template ai_insight_notifier_maybe_notify}
  /// [enabled] true ise ilk N uyarı için local notification.
  /// {@endtemplate}
  Future<void> maybeNotifyLocal(
    List<AiInsightAlert> alerts, {
    required bool enabled,
    int maxNotifications = 5,
  }) async {
    if (!enabled || alerts.isEmpty) return;
    final svc = notifications ?? NotificationService();
    var i = 0;
    for (final a in alerts.take(maxNotifications)) {
      i++;
      final title = a.params['product'] ?? a.titleKey;
      final body = a.params['customer'] != null
          ? '${a.params['customer']} · ${a.params['days'] ?? ''}g'
          : a.bodyKey;
      await svc.showNotification(
        id: 9100 + i,
        title: title,
        body: body,
        payload: a.customerId == null
            ? null
            : NotificationService.visitPayload(a.customerId!),
      );
    }
  }
}
