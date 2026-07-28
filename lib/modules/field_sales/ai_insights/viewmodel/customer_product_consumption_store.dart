// Dosya Adı: customer_product_consumption_store.dart
// Açıklama: SQLite sipariş/fatura geçmişinden cari-ürün tüketim forecast
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../../core/ai/ai_completion.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../../../../core/ai/ai_use_case.dart';
import '../../../../service/database_service.dart';
import '../engine/demand_forecast_engine.dart';
import '../model/demand_forecast_models.dart';

/// {@template customer_product_consumption_store}
/// Yerel sipariş + fatura satırlarından deterministic forecast.
/// Opsiyonel AI yorum: [AiGateway] + [AiUseCase.demandForecastInsight].
///
/// Kullanım örneği:
/// ```dart
/// final store = CustomerProductConsumptionStore();
/// final rows = await store.loadForecasts();
/// ```
/// {@endtemplate}
class CustomerProductConsumptionStore {
  /// [gateway]: Opsiyonel AI
  final AiGateway? gateway;

  /// [alertThresholdDays]: Uyarı eşiği
  final int alertThresholdDays;

  /// {@macro customer_product_consumption_store}
  const CustomerProductConsumptionStore({
    this.gateway,
    this.alertThresholdDays =
        DemandForecastEngine.defaultAlertThresholdDays,
  });

  /// {@template customer_product_consumption_store_load}
  /// Tüm cari-ürün forecast satırları.
  ///
  /// Parametreler:
  /// - [customerIds]: Boş değilse yalnızca bu cariler (plasiyer filtresi)
  /// - [asOf]: Referans gün
  /// {@endtemplate}
  Future<List<CustomerProductForecast>> loadForecasts({
    Set<String>? customerIds,
    DateTime? asOf,
  }) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    final orderRows = await db.rawQuery('''
      SELECT
        o.customer_id AS customer_id,
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, '') AS customer_name,
        oi.product_id AS product_id,
        COALESCE(p.code, '') AS product_code,
        COALESCE(p.name, '') AS product_name,
        COALESCE(p.category, '') AS category,
        o.order_date AS event_date,
        oi.quantity AS quantity
      FROM order_items oi
      INNER JOIN orders o ON o.id = oi.order_id
      LEFT JOIN customers c ON c.id = o.customer_id
      LEFT JOIN products p ON p.id = oi.product_id
      WHERE COALESCE(o.is_deleted, 0) = 0
        AND COALESCE(o.status, '') != 'Cancelled'
        AND oi.product_id IS NOT NULL
        AND o.customer_id IS NOT NULL
        AND o.order_date IS NOT NULL
    ''');

    final invoiceRows = await db.rawQuery('''
      SELECT
        i.customer_id AS customer_id,
        COALESCE(c.code, '') AS customer_code,
        COALESCE(c.name, '') AS customer_name,
        ii.product_id AS product_id,
        COALESCE(p.code, '') AS product_code,
        COALESCE(p.name, '') AS product_name,
        COALESCE(p.category, '') AS category,
        i.invoice_date AS event_date,
        ii.quantity AS quantity
      FROM invoice_items ii
      INNER JOIN invoices i ON i.id = ii.invoice_id
      LEFT JOIN customers c ON c.id = i.customer_id
      LEFT JOIN products p ON p.id = ii.product_id
      WHERE COALESCE(i.status, '') != 'Cancelled'
        AND ii.product_id IS NOT NULL
        AND i.customer_id IS NOT NULL
        AND i.invoice_date IS NOT NULL
    ''');

    final bucket =
        <String, _Acc>{}; // key: customerId|productId

    void ingest(List<Map<String, Object?>> rows) {
      for (final row in rows) {
        final cid = (row['customer_id'] ?? '').toString();
        final pid = (row['product_id'] ?? '').toString();
        if (cid.isEmpty || pid.isEmpty) continue;
        // null = tüm cariler; boş set = hiçbiri; dolu = plasiyer kapsamı
        if (customerIds != null && !customerIds.contains(cid)) {
          continue;
        }
        final rawDate = (row['event_date'] ?? '').toString();
        final dt = DateTime.tryParse(rawDate);
        if (dt == null) continue;
        final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
        if (qty <= 0) continue;
        final key = '$cid|$pid';
        final acc = bucket.putIfAbsent(
          key,
          () => _Acc(
            customerId: cid,
            customerCode: (row['customer_code'] ?? '').toString(),
            customerName: (row['customer_name'] ?? '').toString(),
            productId: pid,
            productCode: (row['product_code'] ?? '').toString(),
            productName: (row['product_name'] ?? '').toString(),
            category: (row['category'] ?? '').toString(),
          ),
        );
        acc.events.add(OrderConsumptionEvent(date: dt, quantity: qty));
      }
    }

    ingest(orderRows);
    ingest(invoiceRows);

    final out = <CustomerProductForecast>[];
    for (final acc in bucket.values) {
      final stats = DemandForecastEngine.compute(acc.events, asOf: asOf);
      out.add(
        CustomerProductForecast(
          customerId: acc.customerId,
          customerCode: acc.customerCode,
          customerName: acc.customerName,
          productId: acc.productId,
          productCode: acc.productCode,
          productName: acc.productName,
          category: acc.category,
          stats: stats,
        ),
      );
    }

    out.sort((a, b) {
      final da = a.stats.daysUntilDepletion(asOf: asOf) ?? 9999;
      final dbDays = b.stats.daysUntilDepletion(asOf: asOf) ?? 9999;
      return da.compareTo(dbDays);
    });
    return out;
  }

  /// Eşik içi uyarılar
  Future<List<AiInsightAlert>> loadAlerts({
    Set<String>? customerIds,
    DateTime? asOf,
  }) async {
    final rows = await loadForecasts(
      customerIds: customerIds,
      asOf: asOf,
    );
    return DemandForecastEngine.buildDepletionAlerts(
      rows,
      thresholdDays: alertThresholdDays,
      asOf: asOf,
    );
  }

  /// Kategori özetleri
  Future<List<CategoryDemandSummary>> loadCategorySummaries({
    Set<String>? customerIds,
    DateTime? asOf,
  }) async {
    final rows = await loadForecasts(
      customerIds: customerIds,
      asOf: asOf,
    );
    return DemandForecastEngine.summarizeCategories(
      rows,
      thresholdDays: alertThresholdDays,
      asOf: asOf,
    );
  }

  /// {@template customer_product_consumption_store_ai}
  /// Opsiyonel AI özet; key yoksa noKey / l10n.
  /// Sipariş kesmez — yalnızca metin.
  /// {@endtemplate}
  Future<AiCompletionResult> requestAiInsight({
    required List<CustomerProductForecast> alertRows,
  }) async {
    final gw = gateway ?? AiGateway();
    final snapshot = await gw.loadSettings();
    final active = snapshot.configs[snapshot.activeProvider];
    if (active == null || !active.hasApiKey) {
      return AiCompletionResult.noKey(provider: snapshot.activeProvider);
    }

    final payload = DemandForecastEngine.buildAiPromptPayload(alertRows);
    return gw.ask(
      useCase: AiUseCase.demandForecastInsight,
      systemPrompt:
          'You are a field-sales demand assistant. '
          'Given anonymized codes only, write 2-4 short sentences: '
          'priority visit suggestions for this week, '
          'and replenishment hints. '
          'Do NOT create orders. No PII. Reply in Turkish.',
      userMessage: payload,
      temperature: 0.3,
      maxTokens: 280,
    );
  }
}

class _Acc {
  final String customerId;
  final String customerCode;
  final String customerName;
  final String productId;
  final String productCode;
  final String productName;
  final String category;
  final List<OrderConsumptionEvent> events = [];

  _Acc({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.category,
  });
}
