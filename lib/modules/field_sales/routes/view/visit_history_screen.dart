// Dosya Adı: visit_history_screen.dart
// Açıklama: Geçmiş ziyaret dens listesi (filtre + detay / açık form)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/visit_history_record.dart';
import '../viewmodel/visit_history_store.dart';
import 'visit_detail_screen.dart';

/// VisitFormScreen.routeName — form import zinciri (order) testte kırılmasın.
const String _kVisitFormRoute = '/field-sales/visit-form';

/// {@template visit_history_screen}
/// Plasiyer geçmiş ziyaret kayıtlarını SQLite `visits` üzerinden görür.
///
/// Rota: `/field-sales/visit-history`
/// Arguments: `String` cariId veya `Map` `{customerId}`.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   VisitHistoryScreen.routeName,
///   arguments: {'customerId': 'c1'},
/// );
/// ```
/// {@endtemplate}
class VisitHistoryScreen extends StatefulWidget {
  /// [routeName]: GoRouter / named route yolu
  static const String routeName = '/field-sales/visit-history';

  /// [customerId]: Opsiyonel cari filtresi (route args)
  final String? customerId;

  /// [records]: Opsiyonel kayıtlar (null → SQLite `visits`)
  final List<VisitHistoryRecord>? records;

  /// [store]: Opsiyonel store (null → varsayılan [VisitHistoryStore])
  final VisitHistoryStore? store;

  /// {@macro visit_history_screen}
  const VisitHistoryScreen({
    Key? key,
    this.customerId,
    this.records,
    this.store,
  }) : super(key: key);

  /// {@template visit_history_screen_parse_customer_id}
  /// Named route arguments’tan cariId çıkarır.
  /// {@endtemplate}
  static String? parseCustomerId(Object? args) {
    if (args is String) {
      final t = args.trim();
      return t.isEmpty ? null : t;
    }
    if (args is Map) {
      final raw = args['customerId'] ?? args['cariId'];
      final t = raw?.toString().trim() ?? '';
      return t.isEmpty ? null : t;
    }
    return null;
  }

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  /// [_visits]: Yüklenen dens kayıtları
  List<VisitHistoryRecord> _visits = const [];

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  /// [_period]: Dönem preset
  VisitHistoryPeriod _period = VisitHistoryPeriod.thisMonth;

  /// [_start]: Başlangıç günü
  late DateTime _start;

  /// [_end]: Bitiş günü
  late DateTime _end;

  /// [_searchController]: Cari adı ara
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final range = VisitHistoryStore.rangeForPeriod(_period);
    _start = range.$1;
    _end = range.$2;
    _loadVisits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  VisitHistoryStore _resolveStore() {
    return widget.store ??
        VisitHistoryStore(
          openDb: () async {
            final svc = await DatabaseService.getInstance();
            return svc.getDatabase();
          },
        );
  }

  /// {@template _loadVisits}
  /// Enjekte kayıt varsa kullanır; yoksa SQLite filtreli okur.
  /// {@endtemplate}
  Future<void> _loadVisits() async {
    final injected = widget.records;
    if (injected != null) {
      setState(() {
        _visits = injected;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final rows = await _resolveStore().loadFiltered(
        customerId: widget.customerId,
        start: _start,
        end: _end,
      );
      if (!mounted) return;
      setState(() {
        _visits = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _visits = const [];
        _loading = false;
      });
    }
  }

  void _applyPeriod(VisitHistoryPeriod period) {
    final range = VisitHistoryStore.rangeForPeriod(period);
    setState(() {
      _period = period;
      _start = range.$1;
      _end = range.$2;
    });
    // ignore: discarded_futures
    _loadVisits();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = DateTime(picked.year, picked.month, picked.day);
        if (_start.isAfter(_end)) _start = _end;
      }
    });
    await _loadVisits();
  }

  List<VisitHistoryRecord> get _visible {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _visits;
    return _visits
        .where((v) => v.customerName.toLowerCase().contains(q))
        .toList(growable: false);
  }

  /// {@template _openVisit}
  /// Tamamlanan → detay; açık → VisitFormScreen.
  /// {@endtemplate}
  void _openVisit(VisitHistoryRecord visit) {
    if (visit.statusKind == VisitHistoryStatusKind.open) {
      Navigator.pushNamed(
        context,
        _kVisitFormRoute,
        arguments: visit.customerId,
      );
      return;
    }
    Navigator.pushNamed(
      context,
      VisitDetailScreen.routeName,
      arguments: visit.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const primary = FieldSalesDensAppBar.primaryColor;
    final dateFmt = DateFormat('dd-MM-yyyy');
    final periodEntries = <(VisitHistoryPeriod, String)>[
      (VisitHistoryPeriod.today, 'field_sales.period_today'),
      (VisitHistoryPeriod.thisWeek, 'field_sales.period_this_week'),
      (VisitHistoryPeriod.thisMonth, 'field_sales.period_this_month'),
      (VisitHistoryPeriod.thisYear, 'field_sales.period_this_year'),
    ];
    final visible = _visible;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.visit_history'),
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(
              primary: primary,
              fontSize: 11,
              items: [
                for (final entry in periodEntries)
                  FieldSalesDensChipItem(
                    label: l10n.translate(entry.$2),
                    selected: _period == entry.$1,
                    onTap: () => _applyPeriod(entry.$1),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 0),
            child: Row(
              children: [
                Expanded(
                  child: _DateCell(
                    primary: primary,
                    label: l10n.translate('field_sales.date_start_label'),
                    value: dateFmt.format(_start),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateCell(
                    primary: primary,
                    label: l10n.translate('field_sales.date_end_label'),
                    value: dateFmt.format(_end),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
          ),
          if (widget.customerId == null ||
              widget.customerId!.trim().isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 4),
              child: TextField(
                controller: _searchController,
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.translate('field_sales.visit_history_search'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('field_sales.visit_history_empty'),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final visit = visible[index];
                          final statusColor = visit.statusKind ==
                                  VisitHistoryStatusKind.completed
                              ? Colors.green
                              : Colors.orange;
                          final durationLabel =
                              VisitHistoryStore.formatDuration(
                            visit.durationMinutes,
                            translate: l10n.translate,
                          );

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _openVisit(visit),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.history,
                                      color: primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            visit.customerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${visit.formattedDate} · $durationLabel',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.translate(visit.statusL10nKey),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Dens tarih hücre (başlangıç / bitiş).
class _DateCell extends StatelessWidget {
  final Color primary;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateCell({
    required this.primary,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: primary.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
