// Dosya Adı: visit_history_screen.dart
// Açıklama: Geçmiş ziyaretler dens listesi (visits → SQLite)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../model/visit_history_record.dart';
import '../viewmodel/visit_history_store.dart';

/// {@template visit_history_screen}
/// Plasiyer geçmiş ziyaret kayıtlarını SQLite `visits` üzerinden görür.
///
/// Rota: `/field-sales/visit-history`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VisitHistoryScreen.routeName);
/// ```
/// {@endtemplate}
class VisitHistoryScreen extends StatefulWidget {
  /// [routeName]: GoRouter / named route yolu
  static const String routeName = '/field-sales/visit-history';

  /// [records]: Opsiyonel kayıtlar (null → SQLite `visits`)
  final List<VisitHistoryRecord>? records;

  /// [store]: Opsiyonel store (null → varsayılan [VisitHistoryStore])
  final VisitHistoryStore? store;

  const VisitHistoryScreen({
    Key? key,
    this.records,
    this.store,
  }) : super(key: key);

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  /// [_visits]: Yüklenen dens kayıtları
  List<VisitHistoryRecord> _visits = const [];

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  /// {@template _loadVisits}
  /// Enjekte kayıt varsa kullanır; yoksa SQLite `visits` okur.
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
      final store = widget.store ??
          VisitHistoryStore(
            openDb: () async {
              final svc = await DatabaseService.getInstance();
              return svc.getDatabase();
            },
          );
      final rows = await store.loadAll();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.stubs.visit_history'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _visits.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.visit_history_empty'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _visits.length,
                  itemBuilder: (context, index) {
                    final visit = _visits[index];
                    final statusColor =
                        visit.statusKind == VisitHistoryStatusKind.completed
                            ? Colors.green
                            : Colors.orange;
                    final durationLabel = VisitHistoryStore.formatDuration(
                      visit.durationMinutes,
                      translate: l10n.translate,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Color(0xFF375A7F),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          visit.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                visit.formattedDate,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                durationLabel,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.translate(visit.statusL10nKey),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                ),
    );
  }
}
