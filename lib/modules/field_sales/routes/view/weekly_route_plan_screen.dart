// Dosya Adı: weekly_route_plan_screen.dart
// Açıklama: Haftalık rota planı dens editör — personel + mesafe sıralama
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/weekly_route_distance.dart';
import '../model/weekly_route_stop.dart';
import '../model/weekly_route_weekday.dart';
import '../viewmodel/weekly_route_plan_store.dart';

/// {@template weekly_route_plan_screen}
/// Mobil haftalık rota planı — gün sekmeleri + personel + mesafe sıralama.
/// Route: `/field-sales/weekly-route-plan`
///
/// Mesafe varsayımı: sıralama başlangıcı = cihaz GPS (ambar lat/long yok).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WeeklyRoutePlanScreen.routeName);
/// ```
/// {@endtemplate}
class WeeklyRoutePlanScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/weekly-route-plan';

  /// Test enjeksiyonu (null → DatabaseService)
  final WeeklyRoutePlanStore? store;

  /// Başlangıç günü (null → bugün)
  final WeeklyRouteWeekday? initialWeekday;

  /// Başlangıç personeli (test)
  final WeeklyRouteSalesperson? initialSalesperson;

  /// GPS yerine origin (test / enjeksiyon)
  final Future<WeeklyRouteGeoPoint?> Function()? resolveOrigin;

  /// {@macro weekly_route_plan_screen}
  const WeeklyRoutePlanScreen({
    super.key,
    this.store,
    this.initialWeekday,
    this.initialSalesperson,
    this.resolveOrigin,
  });

  @override
  State<WeeklyRoutePlanScreen> createState() => _WeeklyRoutePlanScreenState();
}

class _WeeklyRoutePlanScreenState extends State<WeeklyRoutePlanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final WeeklyRoutePlanStore _store;
  late WeeklyRouteWeekday _weekday;

  WeeklyRouteSalesperson? _salesperson;
  List<WeeklyRouteStop> _stops = const [];
  bool _loading = true;
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
    _weekday = widget.initialWeekday ??
        WeeklyRouteWeekday.fromDateTime(DateTime.now());
    _salesperson = widget.initialSalesperson;
    _tabController = TabController(
      length: WeeklyRouteWeekday.allDays.length,
      vsync: this,
      initialIndex: _weekday.tabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _reload();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String? get _salespersonId => _salesperson?.id;

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final next = WeeklyRouteWeekday.fromTabIndex(_tabController.index);
    if (next == _weekday) return;
    setState(() => _weekday = next);
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stops = await _store.loadStopsForDay(
        _weekday,
        salespersonId: _salespersonId,
      );
      if (!mounted) return;
      setState(() {
        _stops = stops;
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

  Future<void> _openSalespersonPicker() async {
    final l10n = AppLocalization.of(context);
    final staff = await _store.listSalespersons();
    if (!mounted) return;
    final picked = await showModalBottomSheet<WeeklyRouteSalesperson>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FieldSalesDensTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (ctx) => _SalespersonPickerSheet(
        staff: staff,
        selectedId: _salespersonId,
        title: l10n.translate('field_sales.weekly_route_select_staff'),
        sharedLabel: l10n.translate('field_sales.weekly_route_shared_plan'),
        emptyLabel: l10n.translate('field_sales.weekly_route_no_staff'),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _salesperson = picked.id.isEmpty ? null : picked;
    });
    await _reload();
  }

  Future<void> _openAddCustomer() async {
    final l10n = AppLocalization.of(context);
    final exclude = _stops.map((s) => s.customerId).toSet();
    final picked = await showModalBottomSheet<WeeklyRouteCustomerPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FieldSalesDensTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (ctx) => _CustomerPickerSheet(
        store: _store,
        excludeCustomerIds: exclude,
        title: l10n.translate('field_sales.weekly_route_add_customer'),
        searchHint: l10n.translate('field_sales.weekly_route_search_customer'),
        emptyLabel: l10n.translate('field_sales.weekly_route_no_customers'),
      ),
    );
    if (picked == null || !mounted) return;
    await _store.addStop(
      weekday: _weekday,
      customerId: picked.id,
      salespersonId: _salespersonId,
    );
    await _reload();
  }

  Future<void> _remove(WeeklyRouteStop stop) async {
    await _store.removeStop(
      weekday: _weekday,
      stopId: stop.id,
      salespersonId: _salespersonId,
    );
    await _reload();
  }

  Future<void> _move(WeeklyRouteStop stop, int delta) async {
    await _store.moveStop(
      weekday: _weekday,
      stopId: stop.id,
      delta: delta,
      salespersonId: _salespersonId,
    );
    await _reload();
  }

  Future<WeeklyRouteGeoPoint?> _defaultResolveOrigin() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    return WeeklyRouteGeoPoint(lat: pos.latitude, lng: pos.longitude);
  }

  Future<void> _sortByDistance() async {
    final l10n = AppLocalization.of(context);
    if (_stops.isEmpty) return;

    setState(() => _loading = true);
    try {
      final resolve = widget.resolveOrigin ?? _defaultResolveOrigin;
      final origin = await resolve();
      if (!mounted) return;
      if (origin == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate('field_sales.weekly_route_origin_unavailable'),
            ),
          ),
        );
        return;
      }

      final result = await _store.reorderStopsByDistance(
        weekday: _weekday,
        origin: origin,
        salespersonId: _salespersonId,
      );
      if (!mounted) return;
      setState(() {
        _stops = result.ordered;
        _loading = false;
      });
      final msg = result.missingCoordsCount > 0
          ? l10n
              .translate('field_sales.weekly_route_sorted_missing_coords')
              .replaceAll(
                '{count}',
                '${result.missingCoordsCount}',
              )
          : l10n.translate('field_sales.weekly_route_sorted_by_distance');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color appBarBlue = FieldSalesDensAppBar.primaryColor;
    final staffLabel = _salesperson == null
        ? l10n.translate('field_sales.weekly_route_shared_plan')
        : _salesperson!.label;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.weekly_route_plan'),
        backgroundColor: appBarBlue,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.straighten,
            tooltip: l10n.translate(
              'field_sales.weekly_route_sort_by_distance',
            ),
            onPressed: _loading || _stops.isEmpty ? null : _sortByDistance,
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.person_add_alt_1,
            tooltip: l10n.translate('field_sales.weekly_route_add_customer'),
            onPressed: _loading ? null : _openAddCustomer,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: InkWell(
                  onTap: _loading ? null : _openSalespersonPicker,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${l10n.translate('field_sales.weekly_route_staff')}: '
                            '$staffLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.white,
                indicatorWeight: 2,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 11,
                ),
                tabs: [
                  for (final day in WeeklyRouteWeekday.allDays)
                    Tab(
                      height: 32,
                      text: l10n.translate(WeeklyRouteWeekday(day).l10nKey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(l10n),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _loading ? null : _openAddCustomer,
        backgroundColor: FieldSalesDensAppBar.accentColor,
        child: const Icon(Icons.add, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(AppLocalization l10n) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ),
      );
    }
    if (_stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Text(
            l10n.translate('field_sales.weekly_route_empty_day'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 72),
      itemCount: _stops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final stop = _stops[index];
        return _StopTile(
          index: index + 1,
          stop: stop,
          onRemove: () => _remove(stop),
          onMoveUp: index > 0 ? () => _move(stop, -1) : null,
          onMoveDown:
              index < _stops.length - 1 ? () => _move(stop, 1) : null,
          removeTooltip:
              l10n.translate('field_sales.weekly_route_remove_stop'),
          noCoordsLabel:
              l10n.translate('field_sales.weekly_route_no_coords'),
        );
      },
    );
  }
}

class _StopTile extends StatelessWidget {
  final int index;
  final WeeklyRouteStop stop;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final String removeTooltip;
  final String noCoordsLabel;

  const _StopTile({
    required this.index,
    required this.stop,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.removeTooltip,
    required this.noCoordsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FieldSalesDensTheme.bodyBackground(context),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.customerName.isEmpty
                      ? stop.customerId
                      : stop.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                if (stop.customerCode.isNotEmpty ||
                    stop.customerAddress.isNotEmpty ||
                    !stop.hasCoords)
                  Text(
                    [
                      if (stop.customerCode.isNotEmpty) stop.customerCode,
                      if (stop.customerAddress.isNotEmpty)
                        stop.customerAddress,
                      if (!stop.hasCoords) noCoordsLabel,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                width: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  onPressed: onMoveUp,
                  icon: Icon(
                    Icons.keyboard_arrow_up,
                    color: onMoveUp == null
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                width: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  onPressed: onMoveDown,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: onMoveDown == null
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: removeTooltip,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SalespersonPickerSheet extends StatelessWidget {
  final List<WeeklyRouteSalesperson> staff;
  final String? selectedId;
  final String title;
  final String sharedLabel;
  final String emptyLabel;

  const _SalespersonPickerSheet({
    required this.staff,
    required this.selectedId,
    required this.title,
    required this.sharedLabel,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                children: [
                  _StaffRow(
                    label: sharedLabel,
                    selected: selectedId == null || selectedId!.isEmpty,
                    onTap: () => Navigator.pop(
                      context,
                      const WeeklyRouteSalesperson(id: '', name: ''),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (staff.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        emptyLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    for (final s in staff) ...[
                      _StaffRow(
                        label: s.label,
                        selected: selectedId == s.id,
                        onTap: () => Navigator.pop(context, s),
                      ),
                      const SizedBox(height: 4),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StaffRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F1FB)
              : FieldSalesDensTheme.bodyBackground(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? FieldSalesDensAppBar.primaryColor
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check,
                size: 16,
                color: FieldSalesDensAppBar.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final WeeklyRoutePlanStore store;
  final Set<String> excludeCustomerIds;
  final String title;
  final String searchHint;
  final String emptyLabel;

  const _CustomerPickerSheet({
    required this.store,
    required this.excludeCustomerIds,
    required this.title,
    required this.searchHint,
    required this.emptyLabel,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<WeeklyRouteCustomerPick> _picks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final picks = await widget.store.searchCustomers(
      query: _search.text,
      excludeCustomerIds: widget.excludeCustomerIds,
    );
    if (!mounted) return;
    setState(() {
      _picks = picks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.62,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
              child: TextField(
                controller: _search,
                style: const TextStyle(fontSize: 13),
                textInputAction: TextInputAction.search,
                onChanged: (_) => _load(),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _picks.isEmpty
                      ? Center(
                          child: Text(
                            widget.emptyLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                          itemCount: _picks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, i) {
                            final c = _picks[i];
                            return InkWell(
                              onTap: () => Navigator.pop(context, c),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: FieldSalesDensTheme.bodyBackground(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (c.code.isNotEmpty)
                                      Text(
                                        c.code,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
