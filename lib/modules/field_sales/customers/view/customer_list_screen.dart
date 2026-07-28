// Dosya Adı: customer_list_screen.dart
// Açıklama: Cari liste — gün sekmeleri haftalık rota planına göre filtreler
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../routes/model/weekly_route_weekday.dart';
import '../../routes/viewmodel/weekly_route_plan_store.dart';
import '../viewmodel/customer_provider.dart';
import '../model/customer_model.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

/// {@template customer_list_screen}
/// Cari master listesi. Tab 0 = tüm günler; 1–7 = Pzt–Paz rota planı.
/// {@endtemplate}
class CustomerListScreen extends ConsumerStatefulWidget {
  /// [routeStore]: Test enjeksiyonu
  final WeeklyRoutePlanStore? routeStore;

  /// {@macro customer_list_screen}
  const CustomerListScreen({Key? key, this.routeStore}) : super(key: key);

  /// Tab sayısı: Tüm günler + 7 hafta günü
  static int get dayTabCount => 1 + WeeklyRouteWeekday.allDays.length;

  /// {@template customer_list_tab_to_weekday}
  /// Tab indeksi → gün (0 = tüm günler → null).
  ///
  /// Parametreler:
  /// - [tabIndex]: TabBar indeksi
  ///
  /// Dönüş değeri:
  /// - [WeeklyRouteWeekday?]: null = filtre yok
  /// {@endtemplate}
  static WeeklyRouteWeekday? weekdayForTab(int tabIndex) {
    if (tabIndex <= 0) return null;
    return WeeklyRouteWeekday.fromTabIndex(tabIndex - 1);
  }

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late final WeeklyRoutePlanStore _routeStore;

  /// Gün sekmesi → rota cari id seti (null = henüz yüklenmedi)
  final Map<int, Set<String>> _idsByDay = {};
  bool _routeIdsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CustomerListScreen.dayTabCount,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _routeStore = widget.routeStore ??
        WeeklyRoutePlanStore(
          openDb: () async {
            final svc = await DatabaseService.getInstance();
            return svc.getDatabase();
          },
        );
    _ensureRouteIdsForTab(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _ensureRouteIdsForTab(_tabController.index);
    setState(() {});
  }

  /// {@template _ensureRouteIdsForTab}
  /// Seçili gün sekmesi için rota cari id’lerini yükler.
  /// {@endtemplate}
  Future<void> _ensureRouteIdsForTab(int tabIndex) async {
    final weekday = CustomerListScreen.weekdayForTab(tabIndex);
    if (weekday == null) return;
    if (_idsByDay.containsKey(weekday.dayOfWeek)) return;

    setState(() => _routeIdsLoading = true);
    try {
      final ids = await _routeStore.loadCustomerIdsForDay(weekday);
      if (!mounted) return;
      setState(() {
        _idsByDay[weekday.dayOfWeek] = ids;
        _routeIdsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _idsByDay[weekday.dayOfWeek] = {};
        _routeIdsLoading = false;
      });
    }
  }

  /// {@template _customersForTab}
  /// Tab’a göre filtrelenmiş cari listesi.
  /// {@endtemplate}
  List<CustomerModel> _customersForTab(CustomerState state, int tabIndex) {
    final weekday = CustomerListScreen.weekdayForTab(tabIndex);
    if (weekday == null) return state.customers;
    final ids = _idsByDay[weekday.dayOfWeek];
    if (ids == null) return const [];
    return WeeklyRoutePlanStore.filterCustomersByRouteDay(
      customers: state.customers,
      idOf: (c) => c.id,
      routeCustomerIds: ids,
    );
  }

  Future<void> _refreshAll() async {
    _idsByDay.clear();
    await ref.read(customerProvider.notifier).fetchCustomers();
    await _ensureRouteIdsForTab(_tabController.index);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final l10n = AppLocalization.of(context);

    const Color primaryBlue = Color(0xFF2691E5);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                      child: Row(
                        children: [
                          const Text(
                            "MÜŞTERİLER",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFF1E2022),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.grey.shade600,
                              size: 26,
                            ),
                            onPressed: _refreshAll,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.list,
                              color: Colors.grey.shade600,
                              size: 28,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => ref
                                    .read(customerProvider.notifier)
                                    .searchCustomers(value),
                                decoration: InputDecoration(
                                  hintText: "Arama",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(customerProvider.notifier)
                                      .fetchCustomers();
                                },
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: primaryBlue,
                      unselectedLabelColor: Colors.grey.shade500,
                      indicatorColor: primaryBlue,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      dividerColor: Colors.grey.shade200,
                      padding: const EdgeInsets.only(left: 8),
                      tabs: [
                        Tab(
                          text: l10n.translate(
                            'field_sales.customer_list_all_days',
                          ),
                        ),
                        for (final day in WeeklyRouteWeekday.allDays)
                          Tab(
                            text: l10n.translate(
                              WeeklyRouteWeekday(day).l10nKey,
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          CustomerListScreen.dayTabCount,
                          (index) => _buildList(
                            state,
                            l10n,
                            index,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerFormScreen(),
            ),
          );
          if (result == true || result is CustomerModel) {
            await _refreshAll();
          }
        },
      ),
    );
  }

  Widget _buildList(
    CustomerState state,
    AppLocalization l10n,
    int tabIndex,
  ) {
    if (state.isLoading ||
        (_routeIdsLoading &&
            CustomerListScreen.weekdayForTab(tabIndex) != null &&
            !_idsByDay.containsKey(
              CustomerListScreen.weekdayForTab(tabIndex)!.dayOfWeek,
            ))) {
      return const Center(child: CircularProgressIndicator());
    }

    final customers = _customersForTab(state, tabIndex);
    if (customers.isEmpty) {
      final weekday = CustomerListScreen.weekdayForTab(tabIndex);
      final emptyKey = weekday == null
          ? 'field_sales.no_customers'
          : 'field_sales.customer_list_empty_day';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.translate(emptyKey),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: customers.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
        indent: 64,
      ),
      itemBuilder: (context, index) {
        return _buildListItem(context, customers[index], index);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    CustomerModel customer,
    int index,
  ) {
    final bool isGreen = index % 2 == 0;
    final Color avatarColor =
        isGreen ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    final String initial = customer.name.isNotEmpty
        ? customer.name.substring(0, 1).toUpperCase()
        : "M";

    return InkWell(
      onTap: () async {
        final result = await Navigator.push<Object?>(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(
              customer: customer,
              routeStore: widget.routeStore ?? _routeStore,
            ),
          ),
        );
        if (!mounted) return;
        if (result == true || result is CustomerModel) {
          await ref.read(customerProvider.notifier).fetchCustomers();
        }
        // Detayda gün değişmiş olabilir → cache temizle
        _idsByDay.clear();
        await _ensureRouteIdsForTab(_tabController.index);
        if (mounted) setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: avatarColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${customer.taxNo ?? 'CARI1000$index'} •\n${customer.address?.toUpperCase() ?? 'ADRES BILGISI YOK'}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}
