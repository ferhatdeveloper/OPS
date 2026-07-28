// Dosya Adı: customer_visit_weekdays_tab.dart
// Açıklama: Cari detay — haftalık rota ziyaret günleri dens chip seçici
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../routes/model/weekly_route_weekday.dart';
import '../../routes/viewmodel/weekly_route_plan_store.dart';

/// {@template customer_visit_weekdays_tab}
/// Cari detay "Ziyaret günleri" sekmesi — Pzt–Paz dens chip toggle.
/// Kaynak: [WeeklyRoutePlanStore] (haftalık rota planı ile aynı).
///
/// Kullanım örneği:
/// ```dart
/// CustomerVisitWeekdaysTab(customerId: customer.id)
/// ```
/// {@endtemplate}
class CustomerVisitWeekdaysTab extends StatefulWidget {
  /// [customerId]: Cari id
  final String customerId;

  /// [store]: Test enjeksiyonu (null → DatabaseService)
  final WeeklyRoutePlanStore? store;

  /// {@macro customer_visit_weekdays_tab}
  const CustomerVisitWeekdaysTab({
    Key? key,
    required this.customerId,
    this.store,
  }) : super(key: key);

  @override
  State<CustomerVisitWeekdaysTab> createState() =>
      _CustomerVisitWeekdaysTabState();
}

class _CustomerVisitWeekdaysTabState extends State<CustomerVisitWeekdaysTab> {
  late final WeeklyRoutePlanStore _store;
  Set<int> _selected = const {};
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store = widget.store ??
        WeeklyRoutePlanStore(
          openDb: () async {
            final svc = await DatabaseService.getInstance();
            return svc.getDatabase();
          },
        );
    _reload();
  }

  @override
  void didUpdateWidget(covariant CustomerVisitWeekdaysTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId) {
      _reload();
    }
  }

  /// {@template customer_visit_weekdays_tab_reload}
  /// Carinin atanmış günlerini yükler.
  /// {@endtemplate}
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final days = await _store.loadWeekdaysForCustomer(widget.customerId);
      if (!mounted) return;
      setState(() {
        _selected = days.map((d) => d.dayOfWeek).toSet();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// {@template customer_visit_weekdays_tab_toggle}
  /// Gün chip’ini aç/kapa ve rota planına yazar.
  /// {@endtemplate}
  Future<void> _toggle(WeeklyRouteWeekday weekday) async {
    if (_busy) return;
    final next = !_selected.contains(weekday.dayOfWeek);
    setState(() {
      _busy = true;
      final copy = Set<int>.from(_selected);
      if (next) {
        copy.add(weekday.dayOfWeek);
      } else {
        copy.remove(weekday.dayOfWeek);
      }
      _selected = copy;
    });
    try {
      await _store.toggleCustomerWeekday(
        customerId: widget.customerId,
        weekday: weekday,
        selected: next,
      );
    } catch (e) {
      if (!mounted) return;
      // Geri al
      setState(() {
        final copy = Set<int>.from(_selected);
        if (next) {
          copy.remove(weekday.dayOfWeek);
        } else {
          copy.add(weekday.dayOfWeek);
        }
        _selected = copy;
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primaryBlue = Color(0xFF2691E5);

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.translate('field_sales.customer_visit_days_hint'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in WeeklyRouteWeekday.allDays)
                _VisitDayChip(
                  label: l10n.translate(WeeklyRouteWeekday(day).l10nKey),
                  selected: _selected.contains(day),
                  primaryBlue: primaryBlue,
                  onTap: _busy
                      ? null
                      : () => _toggle(WeeklyRouteWeekday(day)),
                ),
            ],
          ),
          if (_selected.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.translate('field_sales.customer_visit_days_none'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(fontSize: 11, color: Colors.red.shade400),
            ),
          ],
        ],
      ),
    );
  }
}

/// {@template visit_day_chip}
/// Dens gün chip (seçili / seçili değil).
/// {@endtemplate}
class _VisitDayChip extends StatelessWidget {
  /// [label]: Kısa gün adı
  final String label;

  /// [selected]: Seçili mi
  final bool selected;

  /// [primaryBlue]: Mevcut cari mavi
  final Color primaryBlue;

  /// [onTap]: Toggle
  final VoidCallback? onTap;

  /// {@macro visit_day_chip}
  const _VisitDayChip({
    required this.label,
    required this.selected,
    required this.primaryBlue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? primaryBlue : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? primaryBlue : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
