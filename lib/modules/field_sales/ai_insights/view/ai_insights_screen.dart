// Dosya Adı: ai_insights_screen.dart
// Açıklama: AI Öngörüler dens — bitiş uyarıları + kategori + AI özet
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/ai/ai_completion.dart';
import '../../../../core/auth/app_user_role.dart';
import '../../../../core/auth/session_role_resolver.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../ai_reports/view/ai_dynamic_report_screen.dart';
import '../../ai_vision_competitor/view/competitor_shelf_vision_screen.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../engine/demand_forecast_engine.dart';
import '../model/demand_forecast_models.dart';
import '../viewmodel/customer_product_consumption_store.dart';
import '../viewmodel/salesperson_customer_scope.dart';

/// {@template ai_insights_screen}
/// Plasiyer / admin AI öngörü dens listesi.
/// Route: `/field-sales/ai-insights`
/// {@endtemplate}
class AiInsightsScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/ai-insights';

  /// Test inject
  final CustomerProductConsumptionStore? store;

  /// Test inject forecast
  final List<CustomerProductForecast>? rows;

  /// {@macro ai_insights_screen}
  const AiInsightsScreen({Key? key, this.store, this.rows}) : super(key: key);

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final CustomerProductConsumptionStore _store =
      widget.store ?? const CustomerProductConsumptionStore();

  List<CustomerProductForecast> _all = const [];
  List<CustomerProductForecast> _filtered = const [];
  List<CategoryDemandSummary> _categories = const [];
  List<AiInsightAlert> _alerts = const [];
  bool _loading = true;
  String? _aiText;
  String? _aiL10nKey;
  bool _aiLoading = false;
  AppUserRole _role = AppUserRole.unknown;
  bool _routeUnassigned = false;

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _applyRows(widget.rows!);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _role = await SessionRoleResolver().resolve();
      final session =
          await (await DatabaseService.getInstance()).getUserSession();
      final userId =
          (session?['id'] ?? session?['user_id'] ?? '').toString();
      final scopeResult = await const SalespersonCustomerScope().resolve(
        role: _role,
        userId: userId,
      );
      final rows = await _store.loadForecasts(
        customerIds: scopeResult.filterIds,
      );
      if (!mounted) return;
      _routeUnassigned = scopeResult.routeUnassigned;
      _applyRows(rows);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = const [];
        _filtered = const [];
        _categories = const [];
        _alerts = const [];
        _routeUnassigned = false;
        _loading = false;
      });
    }
  }

  void _applyRows(List<CustomerProductForecast> rows) {
    final asOf = DateTime.now();
    final alerts = DemandForecastEngine.buildDepletionAlerts(
      rows,
      thresholdDays: _store.alertThresholdDays,
      asOf: asOf,
    );
    final cats = DemandForecastEngine.summarizeCategories(
      rows,
      thresholdDays: _store.alertThresholdDays,
      asOf: asOf,
    );
    setState(() {
      _all = rows;
      _alerts = alerts;
      _categories = cats;
      _loading = false;
      _applyFilter(_searchController.text);
    });
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<CustomerProductForecast>.from(_all);
      } else {
        _filtered = _all
            .where(
              (r) =>
                  r.customerCode.toLowerCase().contains(q) ||
                  r.customerName.toLowerCase().contains(q) ||
                  r.productCode.toLowerCase().contains(q) ||
                  r.productName.toLowerCase().contains(q) ||
                  r.category.toLowerCase().contains(q),
            )
            .toList(growable: false);
      }
    });
  }

  Future<void> _requestAi() async {
    setState(() {
      _aiLoading = true;
      _aiText = null;
      _aiL10nKey = null;
    });
    try {
      final alertRows = _all
          .where(
            (r) => r.isWithinAlertWindow(
              thresholdDays: _store.alertThresholdDays,
            ),
          )
          .toList(growable: false);
      final result = await _store.requestAiInsight(alertRows: alertRows);
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        if (result.isOk) {
          _aiText = result.text;
        } else if (result.status == AiCompletionStatus.noKey) {
          _aiL10nKey = result.l10nKey ?? 'ai.not_configured';
        } else {
          _aiL10nKey = result.l10nKey ?? 'ai.request_failed';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiL10nKey = 'ai.request_failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.ai_insights');
    final primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.assessment_outlined,
            tooltip: l10n.translate('field_sales.stubs.ai_dynamic_report'),
            onPressed: () {
              Navigator.of(context).pushNamed(AiDynamicReportScreen.routeName);
            },
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.price_change_outlined,
            tooltip:
                l10n.translate('field_sales.stubs.competitor_shelf_vision'),
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(CompetitorShelfVisionScreen.routeName);
            },
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.auto_awesome,
            tooltip: l10n.translate('field_sales.ai_insights.ai_summary'),
            onPressed: _aiLoading ? null : _requestAi,
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            tooltip: l10n.translate('common.reload'),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                if (_routeUnassigned) _buildRouteBanner(l10n, primary),
                if (_alerts.isNotEmpty) _buildAlertBanner(l10n, primary),
                if (_aiText != null || _aiL10nKey != null || _aiLoading)
                  _buildAiBox(l10n, primary),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    onChanged: _applyFilter,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.translate('common.search'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                    ),
                  ),
                ),
                if (_categories.isNotEmpty) _buildCategoryStrip(l10n, primary),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.translate(
                              'field_sales.ai_insights.empty',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: FieldSalesDensTheme.muted(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            return _ForecastTile(
                              row: _filtered[index],
                              l10n: l10n,
                              primary: primary,
                              threshold: _store.alertThresholdDays,
                            );
                          },
                        ),
                ),
                if (_role == AppUserRole.warehouseKeeper ||
                    _role == AppUserRole.admin)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/field-sales/supply-requests',
                            );
                          },
                          icon: const Icon(Icons.local_shipping, size: 18),
                          label: Text(
                            l10n.translate(
                              'field_sales.stubs.supply_request',
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRouteBanner(AppLocalization l10n, Color primary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        border: Border.all(color: primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.route, size: 18, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.translate('field_sales.ai_insights.route_unassigned'),
              style: TextStyle(
                fontSize: 12,
                color: FieldSalesDensTheme.title(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(AppLocalization l10n, Color primary) {
    final critical = _alerts.where((a) => (a.daysUntil ?? 99) <= 2).length;
    final bannerKey = _role == AppUserRole.salesperson
        ? 'field_sales.ai_insights.alert_banner_salesperson'
        : 'field_sales.ai_insights.alert_banner';
    final criticalLine = critical > 0
        ? '\n${l10n.translate(
            'field_sales.ai_insights.alert_banner_critical',
            args: {'count': '$critical'},
          )}'
        : '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Uyarı satırlarını üste getir — arama temizle + filtre yok
          _searchController.clear();
          _applyFilter('');
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            border: Border.all(color: primary, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.translate(
                    bannerKey,
                    args: {'count': '${_alerts.length}'},
                  )}$criticalLine',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiBox(AppLocalization l10n, Color primary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: _aiLoading
          ? const SizedBox(
              height: 24,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Text(
              _aiText ??
                  l10n.translate(_aiL10nKey ?? 'ai.not_configured'),
              style: const TextStyle(fontSize: 12),
            ),
    );
  }

  Widget _buildCategoryStrip(AppLocalization l10n, Color primary) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _categories.length.clamp(0, 12),
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final c = _categories[i];
          final label = c.category.isEmpty
              ? l10n.translate('field_sales.ai_insights.uncategorized')
              : c.category;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: primary),
              borderRadius: BorderRadius.circular(4),
              color: c.alertCount > 0 ? primary : Colors.white,
            ),
            child: Text(
              '$label (${c.alertCount})',
              style: TextStyle(
                fontSize: 11,
                color: c.alertCount > 0 ? Colors.white : primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final CustomerProductForecast row;
  final AppLocalization l10n;
  final Color primary;
  final int threshold;

  const _ForecastTile({
    required this.row,
    required this.l10n,
    required this.primary,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final days = row.stats.daysUntilDepletion();
    final alert = row.isWithinAlertWindow(thresholdDays: threshold);
    final code = row.customerCode.isNotEmpty
        ? row.customerCode
        : row.customerId;
    final pcode =
        row.productCode.isNotEmpty ? row.productCode : row.productId;
    final onBody = FieldSalesDensTheme.title(context);
    final onMuted = FieldSalesDensTheme.muted(context);
    final surface = FieldSalesDensTheme.surface(context);
    final border = FieldSalesDensTheme.border(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(
          color: alert ? primary : border,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$code · $pcode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onBody,
                  ),
                ),
              ),
              if (row.isQuantityAnomaly)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: primary),
                    borderRadius: BorderRadius.circular(4),
                    color: surface,
                  ),
                  child: Text(
                    l10n.translate(
                      'field_sales.ai_insights.anomaly_badge',
                    ),
                    style: TextStyle(fontSize: 10, color: primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            row.productName.isNotEmpty
                ? row.productName
                : row.customerName,
            style: TextStyle(fontSize: 12, color: onMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.translate(
              'field_sales.ai_insights.row_meta',
              args: {
                'interval': row.stats.avgIntervalDays.toStringAsFixed(0),
                'qty': row.stats.avgQuantity.toStringAsFixed(1),
                'days': days?.toString() ?? '-',
              },
            ),
            style: TextStyle(
              fontSize: 11,
              color: alert ? primary : onMuted,
            ),
          ),
        ],
      ),
    );
  }
}
