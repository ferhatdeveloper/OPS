// Dosya Adı: company_list_screen.dart
// Açıklama: MBT dens birleşik bağlam — firma / dönem / depo seçim
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/tenant/postgrest_master_sync.dart';
import '../../../../core/tenant/postgrest_table_names.dart';
import '../../../../service/database_service.dart';
import '../../../../service/postgres_service.dart';
import '../../stock/model/active_warehouse_session.dart';
import '../../stock/model/warehouse_list_row.dart';
import '../../stock/model/warehouse_master_seed.dart';
import '../../stock/view/multi_warehouse_screen.dart';
import '../../stock/viewmodel/active_warehouse_store.dart';
import '../../stock/viewmodel/warehouse_master_store.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/active_company_session.dart';
import '../viewmodel/active_company_store.dart';
import '../viewmodel/active_context_switcher.dart';
import '../viewmodel/company_context_loader.dart';

/// {@template company_context_tab}
/// Şirketler ekranı dens sekmeleri.
/// {@endtemplate}
enum CompanyContextTab {
  /// Firmalar
  firms,

  /// Dönemler (seçili firmaya göre)
  periods,

  /// Depo / mağaza (seçili firmaya göre)
  warehouses,
}

/// {@template company_firm_row}
/// Dens firma satırı (ad · Firma No).
/// {@endtemplate}
class CompanyFirmRow {
  /// [companyId]: companies.id
  final String companyId;

  /// [name]: Firma adı
  final String name;

  /// [companyNo]: Firma No
  final String companyNo;

  /// {@macro company_firm_row}
  const CompanyFirmRow({
    required this.companyId,
    required this.name,
    required this.companyNo,
  });
}

/// {@template company_period_row}
/// Firma + dönem satırı (MBT: ad · Firma No · Dönem · tarih aralığı).
/// {@endtemplate}
class CompanyPeriodRow {
  /// [companyId]: companies.id
  final String companyId;

  /// [name]: Firma adı (ör. MBT)
  final String name;

  /// [companyNo]: Firma No (ör. 001)
  final String companyNo;

  /// [periodNo]: Dönem No / period_name (ör. 01)
  final String periodNo;

  /// [startDate]: Başlangıç (DD-MM-YYYY veya ISO)
  final String startDate;

  /// [endDate]: Bitiş (DD-MM-YYYY veya ISO)
  final String endDate;

  /// {@macro company_period_row}
  const CompanyPeriodRow({
    required this.companyId,
    required this.name,
    required this.companyNo,
    required this.periodNo,
    required this.startDate,
    required this.endDate,
  });
}

/// {@template company_list_screen}
/// Dens birleşik bağlam: Firmalar | Dönemler | Depo/Mağaza.
/// Route: `/field-sales/companies`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   CompanyListScreen.routeName,
///   arguments: CompanyContextTab.warehouses,
/// );
/// ```
/// {@endtemplate}
class CompanyListScreen extends StatefulWidget {
  /// [routeName]: Named route — menü seed ile aynı
  static const String routeName = '/field-sales/companies';

  /// [initialTab]: Açılış sekmesi (chip / route arg)
  final CompanyContextTab initialTab;

  /// {@macro company_list_screen}
  const CompanyListScreen({
    Key? key,
    this.initialTab = CompanyContextTab.firms,
  }) : super(key: key);

  /// Route / push argümanından sekme çözümler.
  static CompanyContextTab resolveTab(Object? arguments) {
    if (arguments is CompanyContextTab) return arguments;
    if (arguments is int) {
      final i = arguments.clamp(0, CompanyContextTab.values.length - 1);
      return CompanyContextTab.values[i];
    }
    if (arguments is String) {
      switch (arguments.toLowerCase()) {
        case 'periods':
        case 'period':
        case 'donem':
          return CompanyContextTab.periods;
        case 'warehouses':
        case 'warehouse':
        case 'depo':
        case 'magaza':
          return CompanyContextTab.warehouses;
        default:
          return CompanyContextTab.firms;
      }
    }
    return CompanyContextTab.firms;
  }

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<CompanyFirmRow> _firms = const [];
  List<CompanyPeriodRow> _allPeriods = const [];
  List<CompanyPeriodRow> _periods = const [];
  List<WarehouseListRow> _warehouses = const [];

  List<CompanyFirmRow> _filteredFirms = const [];
  List<CompanyPeriodRow> _filteredPeriods = const [];
  List<WarehouseListRow> _filteredWarehouses = const [];

  int? _selectedFirmIndex;
  int? _selectedPeriodIndex;
  int? _selectedWarehouseIndex;

  bool _loading = true;
  bool _warehousesLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CompanyContextTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _tabController.addListener(_onTabChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _applyFilter(_searchController.text);
  }

  /// ISO veya ham tarihi MBT DD-MM-YYYY gösterimine çevirir.
  String _formatDisplayDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(t)) return t;
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (iso != null) {
      return '${iso.group(3)}-${iso.group(2)}-${iso.group(1)}';
    }
    return t;
  }

  CompanyFirmRow? get _selectedFirm {
    final i = _selectedFirmIndex;
    if (i == null || i < 0 || i >= _firms.length) return null;
    return _firms[i];
  }

  CompanyPeriodRow? get _selectedPeriod {
    final i = _selectedPeriodIndex;
    if (i == null || i < 0 || i >= _periods.length) return null;
    return _periods[i];
  }

  WarehouseListRow? get _selectedWarehouse {
    final i = _selectedWarehouseIndex;
    if (i == null || i < 0 || i >= _warehouses.length) return null;
    return _warehouses[i];
  }

  /// Firma + dönem + ambar listelerini yükler (REST → SQLite, stub yok).
  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final data = await const CompanyContextLoader().loadFirmsAndPeriods();
      final firms = data.firms
          .map(
            (f) => CompanyFirmRow(
              companyId: f.companyId,
              name: f.name,
              companyNo: f.companyNo,
            ),
          )
          .toList();
      final periods = data.periods
          .map(
            (p) => CompanyPeriodRow(
              companyId: p.companyId,
              name: p.name,
              companyNo: p.companyNo,
              periodNo: p.periodNo,
              startDate: _formatDisplayDate(p.startDate),
              endDate: _formatDisplayDate(p.endDate),
            ),
          )
          .toList();

      final session = await const ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      ).load();

      int? firmIdx = _indexForFirm(firms, session);
      if (firmIdx == null && firms.isNotEmpty) firmIdx = 0;
      final firm =
          firmIdx != null && firmIdx < firms.length ? firms[firmIdx] : null;
      final firmPeriods =
          firm == null ? <CompanyPeriodRow>[] : _periodsForFirm(periods, firm);
      final periodIdx = firm == null
          ? null
          : (_indexForPeriod(firmPeriods, session) ??
              (firmPeriods.isEmpty ? null : 0));

      if (!mounted) return;
      setState(() {
        _firms = firms;
        _allPeriods = periods;
        _periods = firmPeriods;
        _selectedFirmIndex = firmIdx;
        _selectedPeriodIndex = periodIdx;
        _filteredFirms = firms;
        _filteredPeriods = firmPeriods;
        _loading = false;
      });

      if (firm != null) {
        await _loadWarehousesForFirm(firm);
      } else {
        setState(() {
          _warehouses = const [];
          _filteredWarehouses = const [];
          _selectedWarehouseIndex = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _firms = const [];
        _allPeriods = const [];
        _periods = const [];
        _filteredFirms = const [];
        _filteredPeriods = const [];
        _warehouses = const [];
        _filteredWarehouses = const [];
        _selectedFirmIndex = null;
        _selectedPeriodIndex = null;
        _selectedWarehouseIndex = null;
        _loading = false;
      });
    }
  }

  List<CompanyPeriodRow> _periodsForFirm(
    List<CompanyPeriodRow> all,
    CompanyFirmRow firm,
  ) {
    return all
        .where(
          (p) =>
              p.companyNo == firm.companyNo ||
              (firm.companyId.isNotEmpty && p.companyId == firm.companyId),
        )
        .toList();
  }

  int? _indexForFirm(List<CompanyFirmRow> firms, ActiveCompanySession session) {
    if (session.isEmpty || firms.isEmpty) return null;
    for (var i = 0; i < firms.length; i++) {
      final f = firms[i];
      if (session.companyId.isNotEmpty && f.companyId == session.companyId) {
        return i;
      }
      if (f.companyNo == session.companyNo) return i;
    }
    return null;
  }

  int? _indexForPeriod(
    List<CompanyPeriodRow> periods,
    ActiveCompanySession session,
  ) {
    if (session.isEmpty || periods.isEmpty) return null;
    for (var i = 0; i < periods.length; i++) {
      if (periods[i].periodNo == session.periodNo) return i;
    }
    return null;
  }

  int? _indexForWarehouse(
    List<WarehouseListRow> rows,
    ActiveWarehouseSession session,
  ) {
    if (session.isEmpty || rows.isEmpty) return null;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].code == session.code) return i;
    }
    return null;
  }

  /// Seçili firmaya göre ambarları yükler (REST → SQLite; seed yok).
  Future<void> _loadWarehousesForFirm(CompanyFirmRow firm) async {
    if (!mounted) return;
    setState(() => _warehousesLoading = true);
    try {
      final firmNr = PostgrestTableNames.padFirm(firm.companyNo);
      var rows = <WarehouseListRow>[];
      final restReady =
          PostgresService.instance.activeRemoteRestUrl.trim().isNotEmpty;

      if (restReady) {
        try {
          final sync = PostgrestMasterSync();
          var stores = await sync.fetchStores(firmNr: firmNr);
          stores = stores.where((s) => s.firmNr == firmNr).toList();
          if (stores.isNotEmpty) {
            await sync.syncStoresToSqlite(stores);
            rows = stores
                .map(
                  (s) => WarehouseListRow(
                    code: s.code,
                    name: s.name,
                    type: s.type,
                  ),
                )
                .toList();
          }
        } catch (_) {}
      }

      if (rows.isEmpty) {
        final store = const WarehouseMasterStore();
        await store.ensureReady();
        final records = await store.listActive();
        for (final r in records) {
          rows.add(
            WarehouseListRow(
              code: r.code,
              name: r.name,
              type: r.type,
            ),
          );
        }
      }

      // Kiracı REST kullanıldıysa seed (MRK/ARC/IAD) uydurma.
      if (rows.isEmpty && !restReady) {
        rows = WarehouseMasterSeed.defaultRows
            .map(
              (s) => WarehouseListRow(
                code: s.code,
                name: s.seedName,
                type: s.type,
              ),
            )
            .toList();
      }

      final whSession = await const ActiveWarehouseStore().load();
      final selected = rows.isEmpty
          ? null
          : (_indexForWarehouse(rows, whSession) ?? 0);

      if (!mounted) return;
      setState(() {
        _warehouses = rows;
        _filteredWarehouses = _filterWarehouses(rows, _searchController.text);
        _selectedWarehouseIndex = selected;
        _warehousesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _warehouses = const [];
        _filteredWarehouses = const [];
        _selectedWarehouseIndex = null;
        _warehousesLoading = false;
      });
    }
  }

  List<WarehouseListRow> _filterWarehouses(
    List<WarehouseListRow> rows,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (r) =>
              r.code.toLowerCase().contains(q) ||
              r.name.toLowerCase().contains(q) ||
              r.type.toLowerCase().contains(q),
        )
        .toList();
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredFirms = _firms;
        _filteredPeriods = _periods;
        _filteredWarehouses = _warehouses;
      } else {
        _filteredFirms = _firms
            .where(
              (r) =>
                  r.name.toLowerCase().contains(q) ||
                  r.companyNo.toLowerCase().contains(q),
            )
            .toList();
        _filteredPeriods = _periods
            .where(
              (r) =>
                  r.name.toLowerCase().contains(q) ||
                  r.companyNo.toLowerCase().contains(q) ||
                  r.periodNo.toLowerCase().contains(q),
            )
            .toList();
        _filteredWarehouses = _filterWarehouses(_warehouses, q);
      }
    });
  }

  Future<void> _onFirmTap(int filteredIndex) async {
    if (filteredIndex < 0 || filteredIndex >= _filteredFirms.length) return;
    final firm = _filteredFirms[filteredIndex];
    final firmIdx = _firms.indexWhere(
      (f) =>
          f.companyId == firm.companyId && f.companyNo == firm.companyNo,
    );
    if (firmIdx < 0) return;

    final firmPeriods = _periodsForFirm(_allPeriods, firm);
    setState(() {
      _selectedFirmIndex = firmIdx;
      _periods = firmPeriods;
      _filteredPeriods = _filterPeriods(firmPeriods, _searchController.text);
      _selectedPeriodIndex = firmPeriods.isEmpty ? null : 0;
    });
    await _loadWarehousesForFirm(firm);
  }

  List<CompanyPeriodRow> _filterPeriods(
    List<CompanyPeriodRow> rows,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.companyNo.toLowerCase().contains(q) ||
              r.periodNo.toLowerCase().contains(q),
        )
        .toList();
  }

  void _onPeriodTap(int filteredIndex) {
    if (filteredIndex < 0 || filteredIndex >= _filteredPeriods.length) return;
    final row = _filteredPeriods[filteredIndex];
    final idx = _periods.indexWhere(
      (p) => p.periodNo == row.periodNo && p.companyNo == row.companyNo,
    );
    if (idx < 0) return;
    setState(() => _selectedPeriodIndex = idx);
  }

  void _onWarehouseTap(int filteredIndex) {
    if (filteredIndex < 0 || filteredIndex >= _filteredWarehouses.length) {
      return;
    }
    final row = _filteredWarehouses[filteredIndex];
    final idx = _warehouses.indexWhere((w) => w.code == row.code);
    if (idx < 0) return;
    setState(() => _selectedWarehouseIndex = idx);
  }

  /// Seçili firma + dönem + ambarı kalıcılaştırır.
  Future<void> _onSelect() async {
    final l10n = AppLocalization.of(context);
    final firm = _selectedFirm;
    final period = _selectedPeriod;
    final warehouse = _selectedWarehouse;

    if (firm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.company_select_required'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(CompanyContextTab.firms.index);
      return;
    }
    if (period == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.period_select_required'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(CompanyContextTab.periods.index);
      return;
    }
    if (warehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.warehouse_select_required'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(CompanyContextTab.warehouses.index);
      return;
    }

    final session = ActiveCompanySession(
      companyId: firm.companyId,
      companyName: firm.name,
      companyNo: firm.companyNo,
      periodNo: period.periodNo,
      startDate: period.startDate,
      endDate: period.endDate,
    );
    final whSession = ActiveWarehouseSession(
      code: warehouse.code,
      name: warehouse.name,
      type: warehouse.type,
    );

    try {
      await const ActiveContextSwitcher().applyCompany(session);
      await const ActiveContextSwitcher().applyWarehouse(whSession);
    } catch (_) {
      try {
        await const ActiveCompanyStore().save(session);
        await const ActiveWarehouseStore().save(whSession);
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('field_sales.context_switched')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).maybePop();
  }

  String _summaryText(AppLocalization l10n) {
    final firm = _selectedFirm;
    final period = _selectedPeriod;
    final wh = _selectedWarehouse;
    final firmLabel = firm == null
        ? '—'
        : '${firm.name} (${firm.companyNo})';
    final periodLabel = period?.periodNo ?? '—';
    final whLabel = wh?.label ?? '—';
    return l10n.translate(
      'field_sales.context_summary',
      args: {
        'firm': firmLabel,
        'period': periodLabel,
        'warehouse': whLabel,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.company_list');
    final titleFallback = l10n.translate('submodules.mobil_sirket_listesi');
    final appTitle =
        title == 'field_sales.stubs.company_list' ? titleFallback : title;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: appTitle,
        backgroundColor: FieldSalesDensAppBar.primaryColor,
        showCalculatorHome: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            tabs: [
              Tab(
                height: 32,
                text: l10n.translate('field_sales.context_tab_firms'),
              ),
              Tab(
                height: 32,
                text: l10n.translate('field_sales.context_tab_periods'),
              ),
              Tab(
                height: 32,
                text: l10n.translate('field_sales.context_tab_warehouses'),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _summaryText(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.translate('common.search'),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: _applyFilter,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFirmList(l10n),
                      _buildPeriodList(l10n),
                      _buildWarehouseList(l10n),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _onSelect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF375A7F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.translate('common.select'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFirmList(AppLocalization l10n) {
    if (_filteredFirms.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('field_sales.no_companies'),
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filteredFirms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = _filteredFirms[index];
        final selected = _selectedFirm?.companyNo == row.companyNo &&
            _selectedFirm?.companyId == row.companyId;
        return _FirmDensTile(
          row: row,
          selected: selected,
          onTap: () => _onFirmTap(index),
        );
      },
    );
  }

  Widget _buildPeriodList(AppLocalization l10n) {
    if (_filteredPeriods.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('field_sales.no_periods'),
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filteredPeriods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = _filteredPeriods[index];
        final selected = _selectedPeriod?.periodNo == row.periodNo &&
            _selectedPeriod?.companyNo == row.companyNo;
        return _PeriodDensTile(
          row: row,
          selected: selected,
          onTap: () => _onPeriodTap(index),
        );
      },
    );
  }

  Widget _buildWarehouseList(AppLocalization l10n) {
    if (_warehousesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredWarehouses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('field_sales.no_warehouses'),
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, MultiWarehouseScreen.routeName)
                    .then((_) {
                  final firm = _selectedFirm;
                  if (firm != null) _loadWarehousesForFirm(firm);
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                l10n.translate('field_sales.warehouse_create'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, MultiWarehouseScreen.routeName)
                    .then((_) {
                  final firm = _selectedFirm;
                  if (firm != null) _loadWarehousesForFirm(firm);
                });
              },
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                l10n.translate('field_sales.warehouse_manage'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _filteredWarehouses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = _filteredWarehouses[index];
              final selected = _selectedWarehouse?.code == row.code;
              return _WarehouseDensTile(
                row: row,
                selected: selected,
                onTap: () => _onWarehouseTap(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Dens firma satırı.
class _FirmDensTile extends StatelessWidget {
  final CompanyFirmRow row;
  final bool selected;
  final VoidCallback onTap;

  const _FirmDensTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final firmaNo = l10n.translate('field_sales.firma_no_label');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF375A7F)
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$firmaNo : ${row.companyNo}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dens dönem satırı.
class _PeriodDensTile extends StatelessWidget {
  final CompanyPeriodRow row;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodDensTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final donemNo = l10n.translate('field_sales.donem_no_label');
    final baslangic = l10n.translate('field_sales.baslangic_label');
    final bitis = l10n.translate('field_sales.bitis_label');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF375A7F)
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$donemNo : ${row.periodNo}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$baslangic : ${row.startDate}  -  $bitis : ${row.endDate}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dens ambar satırı (Şirketler sekmesi içinde).
class _WarehouseDensTile extends StatelessWidget {
  final WarehouseListRow row;
  final bool selected;
  final VoidCallback onTap;

  const _WarehouseDensTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF375A7F)
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (row.type.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  row.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
