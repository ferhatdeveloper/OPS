// Dosya Adı: visit_detail_screen.dart
// Açıklama: Geçmiş ziyaret detay dens (salt okunur; açık → form)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/visit_detail_record.dart';
import '../viewmodel/visit_history_store.dart';

/// VisitFormScreen.routeName — form import zinciri (order) testte kırılmasın.
const String _kVisitFormRoute = '/field-sales/visit-form';

/// {@template visit_detail_screen}
/// Tamamlanmış ziyaret detayı (check-in/out, not, STT, GPS, süre, sipariş).
/// Açık ziyarette «Devam et» → VisitFormScreen (`/field-sales/visit-form`).
///
/// Rota: `/field-sales/visit-detail` — arguments: visitId (String)
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   VisitDetailScreen.routeName,
///   arguments: 'v1',
/// );
/// ```
/// {@endtemplate}
class VisitDetailScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/visit-detail';

  /// MapScreen / menü alias
  static const String routeNameAlias = '/field-sales/visit-details';

  /// [visitId]: visits.id
  final String visitId;

  /// [detail]: Opsiyonel enjekte detay (test)
  final VisitDetailRecord? detail;

  /// [store]: Opsiyonel store
  final VisitHistoryStore? store;

  /// {@macro visit_detail_screen}
  const VisitDetailScreen({
    Key? key,
    required this.visitId,
    this.detail,
    this.store,
  }) : super(key: key);

  /// {@template visit_detail_screen_parse_visit_id}
  /// Route args’tan visitId.
  /// {@endtemplate}
  static String? parseVisitId(Object? args) {
    if (args is String) {
      final t = args.trim();
      return t.isEmpty ? null : t;
    }
    if (args is Map) {
      final raw = args['visitId'] ?? args['id'];
      final t = raw?.toString().trim() ?? '';
      return t.isEmpty ? null : t;
    }
    return null;
  }

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  VisitDetailRecord? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.detail != null) {
      setState(() {
        _detail = widget.detail;
        _loading = false;
      });
      return;
    }
    try {
      final store = widget.store ??
          VisitHistoryStore(
            openDb: () async {
              final svc = await DatabaseService.getInstance();
              return svc.getDatabase();
            },
          );
      final row = await store.loadDetail(widget.visitId);
      if (!mounted) return;
      setState(() {
        _detail = row;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _loading = false;
      });
    }
  }

  void _reopenOpenVisit(VisitDetailRecord d) {
    Navigator.pushNamed(
      context,
      _kVisitFormRoute,
      arguments: d.customerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const primary = FieldSalesDensAppBar.primaryColor;
    final d = _detail;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.visit_detail_title'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.visit_detail_not_found'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                        children: [
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _StatusChip(
                                  label: l10n.translate(d.statusL10nKey),
                                  completed: d.isCompleted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _SectionCard(
                            child: Column(
                              children: [
                                _KvRow(
                                  label: l10n.translate(
                                    'field_sales.visit_detail_check_in',
                                  ),
                                  value: VisitHistoryStore.formatDateTime(
                                    d.checkInAt,
                                    translate: l10n.translate,
                                  ),
                                ),
                                _KvRow(
                                  label: l10n.translate(
                                    'field_sales.visit_detail_check_out',
                                  ),
                                  value: VisitHistoryStore.formatDateTime(
                                    d.checkOutAt,
                                    translate: l10n.translate,
                                  ),
                                ),
                                _KvRow(
                                  label: l10n.translate(
                                    'field_sales.visit_detail_duration',
                                  ),
                                  value: VisitHistoryStore.formatDuration(
                                    d.durationMinutes,
                                    translate: l10n.translate,
                                  ),
                                ),
                                if ((d.reasonCode ?? '').trim().isNotEmpty)
                                  _KvRow(
                                    label: l10n.translate(
                                      'field_sales.visit_detail_reason',
                                    ),
                                    value: d.reasonCode!.trim(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate(
                                    'field_sales.visit_detail_gps',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _KvRow(
                                  label: l10n.translate(
                                    'field_sales.visit_detail_gps_in',
                                  ),
                                  value: VisitHistoryStore.formatGps(
                                    d.checkInLat,
                                    d.checkInLong,
                                    translate: l10n.translate,
                                  ),
                                ),
                                _KvRow(
                                  label: l10n.translate(
                                    'field_sales.visit_detail_gps_out',
                                  ),
                                  value: VisitHistoryStore.formatGps(
                                    d.checkOutLat,
                                    d.checkOutLong,
                                    translate: l10n.translate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate('field_sales.visit_notes'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (d.notes ?? '').trim().isEmpty
                                      ? l10n.translate(
                                          'field_sales.visit_notes_empty',
                                        )
                                      : d.notes!.trim(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                if ((d.audioRecordingPath ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.translate(
                                      'field_sales.visit_detail_stt_audio',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.audioRecordingPath!.trim(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate(
                                    'field_sales.visit_detail_related_orders',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (d.relatedOrders.isEmpty)
                                  Text(
                                    l10n.translate(
                                      'field_sales.visit_detail_no_orders',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                else
                                  ...d.relatedOrders.map((o) {
                                    final amount =
                                        NumberFormat('#,##0.00', 'tr_TR')
                                            .format(o.totalAmount);
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${o.formattedDate} · ${o.status}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            amount,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!d.isCompleted)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => _reopenOpenVisit(d),
                              child: Text(
                                l10n.translate(
                                  'field_sales.visit_detail_continue',
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _KvRow extends StatelessWidget {
  final String label;
  final String value;

  const _KvRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool completed;

  const _StatusChip({required this.label, required this.completed});

  @override
  Widget build(BuildContext context) {
    final color = completed ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
