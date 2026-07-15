import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localization.dart';
import '../viewmodel/customer_provider.dart';
import '../model/customer_model.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final l10n = AppLocalization.of(context);

    // Mavi arka plan rengi mockup'a göre
    const Color primaryBlue = Color(0xFF2691E5);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Üst Açıklama Metni Kaldırıldı (Kullanıcı İsteği)
            const SizedBox(height: 16),

            // Beyaz Kart Alanı
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
                    // Başlık ve İkonlar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
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
                            icon: Icon(Icons.refresh, color: Colors.grey.shade600, size: 26),
                            onPressed: () => ref.read(customerProvider.notifier).fetchCustomers(),
                          ),
                          IconButton(
                            icon: Icon(Icons.list, color: Colors.grey.shade600, size: 28),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    // Arama Çubuğu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => ref.read(customerProvider.notifier).searchCustomers(value),
                                decoration: InputDecoration(
                                  hintText: "Arama",
                                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(customerProvider.notifier).fetchCustomers();
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    // Sekmeler (TabBar)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: primaryBlue,
                      unselectedLabelColor: Colors.grey.shade500,
                      indicatorColor: primaryBlue,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      dividerColor: Colors.grey.shade200,
                      padding: const EdgeInsets.only(left: 8),
                      tabs: const [
                        Tab(text: "TÜM GÜNLER"),
                        Tab(text: "PAZARTESİ"),
                        Tab(text: "SALI"),
                        Tab(text: "ÇARŞAMBA"),
                        Tab(text: "PERŞEMBE"),
                        Tab(text: "CUMA"),
                      ],
                    ),

                    // Liste Görünümü
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(6, (index) => _buildList(state, l10n)),
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
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
          );
          if (result == true) {
            ref.read(customerProvider.notifier).fetchCustomers();
          }
        },
      ),
    );
  }

  Widget _buildList(CustomerState state, AppLocalization l10n) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.translate('field_sales.no_customers'),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80), // Fab için boşluk
      itemCount: state.customers.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
        indent: 80, // Çizgiyi avatardan sonra başlat
      ),
      itemBuilder: (context, index) {
        return _buildListItem(context, state.customers[index], index);
      },
    );
  }

  Widget _buildListItem(BuildContext context, CustomerModel customer, int index) {
    // Mockup'taki yeşil/kırmızı avatar mantığı - indexe göre değişiyor gibi
    final bool isGreen = index % 2 == 0;
    final Color avatarColor = isGreen ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    final String initial = customer.name.isNotEmpty ? customer.name.substring(0, 1).toUpperCase() : "M";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(customer: customer),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
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
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${customer.taxNo ?? 'CARI1000${index}'} •\n${customer.address?.toUpperCase() ?? 'ADRES BILGISI YOK'}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }
}
