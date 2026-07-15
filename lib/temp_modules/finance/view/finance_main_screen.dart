import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodel/finance/finance_provider.dart';
import '../../../view/widgets/data_table_widget.dart';
import '../../../view/widgets/navigation_tree.dart';
import '../../../core/base/module_screen_layout.dart';
import 'finance_invoice_screen.dart';
import '../../../core/utils/color_utils.dart';

class FinanceMainScreen extends ConsumerStatefulWidget {
  const FinanceMainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends ConsumerState<FinanceMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Logo Muhasebe tarzı mavi başlık çubuğu
          Container(
            height: 40,
            color: const Color(0xFF054F99),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Finans Yönetimi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // Toolbar butonları - Logo stilinde
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  tooltip: 'Yeni İşlem',
                  onPressed: () {
                    _showCreateMenu(context);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Yenile',
                  onPressed: () {
                    ref.read(financeProvider.notifier).fetchFinanceData();
                  },
                ),
                const SizedBox(width: 8),
                VerticalDivider(color: ColorUtils.withAlpha(Colors.white, 0.3), width: 1),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.white, size: 20),
                  tooltip: 'Yazdır',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Yardım',
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Tab bar - Logo stiline benzer
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF054F99),
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: const Color(0xFF054F99),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Genel Bakış'),
                Tab(text: 'Faturalar'),
                Tab(text: 'Ödemeler'),
                Tab(text: 'Kasa İşlemleri'),
              ],
            ),
          ),

          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Genel Bakış Sekmesi - Logo Muhasebe dashboard tarzı
                _buildDashboardTab(),

                // Faturalar Sekmesi
                const FinanceInvoiceScreen(),

                // Ödemeler Sekmesi - Kullanım için basit ekran
                _buildPaymentsTab(),

                // Kasa İşlemleri Sekmesi
                _buildCashTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Logo Muhasebe tarzı dashboard ekranı
  Widget _buildDashboardTab() {
    final financeState = ref.watch(financeProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet Kartları
            const Text(
              'Finansal Özet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryCard(
                  'Açık Faturalar',
                  '42.750,00',
                  const Color(0xFF4A6583),
                  Icons.receipt_long,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Bekleyen Ödemeler',
                  '15.280,00',
                  const Color(0xFF8E44AD),
                  Icons.account_balance_wallet,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Kasa Bakiyesi',
                  '${financeState.cashBalances['anaKasa'] ?? 0}',
                  const Color(0xFF27AE60),
                  Icons.attach_money,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: ColorUtils.withAlpha(Colors.black, 0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorUtils.withAlpha(color, 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yeni işlem menüsü
  void _showCreateMenu(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      <String, dynamic>{
        'title': 'Yeni Satış Faturası',
        'icon': Icons.receipt_long,
        'action': () {},
      },
      <String, dynamic>{
        'title': 'Yeni Alış Faturası',
        'icon': Icons.shopping_cart,
        'action': () {},
      },
      <String, dynamic>{
        'title': 'Yeni Tahsilat Kaydı',
        'icon': Icons.arrow_downward,
        'action': () {},
      },
      <String, dynamic>{
        'title': 'Yeni Ödeme Kaydı',
        'icon': Icons.arrow_upward,
        'action': () {},
      },
      <String, dynamic>{
        'title': 'Kasa İşlemi',
        'icon': Icons.point_of_sale,
        'action': () {},
      },
      <String, dynamic>{
        'title': 'Banka İşlemi',
        'icon': Icons.account_balance,
        'action': () {},
      },
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Yeni İşlem Oluştur'),
            content: SizedBox(
              width: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: const Color(0xFF054F99),
                    ),
                    title: Text(item['title'] as String),
                    onTap: () {
                      Navigator.pop(context);
                      final Function action = item['action'] as Function;
                      action();
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ],
          ),
    );
  }

  // Logo Muhasebe tarzı ödemeler sekmesi
  Widget _buildPaymentsTab() {
    final financeState = ref.watch(financeProvider);
    // Ödeme verilerini Map türünde dönüştür
    final List<Map<String, dynamic>> rows =
        financeState.isLoading
            ? []
            : List<Map<String, dynamic>>.from(
              financeState.payments
                  .map(
                    (item) => Map<String, dynamic>.from(
                      item as Map<dynamic, dynamic>,
                    ),
                  )
                  .toList(),
            );

    // Ödeme listesi için tablo sütunları
    final columns = ['date', 'type', 'reference', 'description', 'amount'];

    final paymentNavigationItems = [
      NavigationTreeItem(
        title: 'Ödeme Kayıtları',
        icon: Icons.list,
        children: [
          NavigationTreeItem(
            title: 'Tahsilatlar',
            icon: Icons.arrow_downward,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Ödemeler',
            icon: Icons.arrow_upward,
            onTap: () {},
          ),
        ],
      ),
      NavigationTreeItem(
        title: 'Ödeme Türleri',
        icon: Icons.category,
        children: [
          NavigationTreeItem(
            title: 'Nakit Ödemeler',
            icon: Icons.money,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Çek/Senet',
            icon: Icons.content_paste,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Havale/EFT',
            icon: Icons.account_balance,
            onTap: () {},
          ),
        ],
      ),
    ];

    final Widget filterBarWidget = Row(
      children: [
        const Text('Tarih:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextFormField(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              hintText: 'Başlangıç',
              isDense: true,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextFormField(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              hintText: 'Bitiş',
              isDense: true,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 16),
        const Text('İşlem Türü:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: '',
                child: Text('Tümü', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'Tahsilat',
                child: Text('Tahsilat', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'Ödeme',
                child: Text('Ödeme', style: TextStyle(fontSize: 12)),
              ),
            ],
            onChanged: (value) {},
            value: '',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 16),
          label: const Text('Filtrele', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF054F99),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );

    final Widget contentHeaderWidget = Row(
      children: [
        const Text(
          'Ödeme İşlemleri',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Spacer(),
        Text(
          'Toplam ${rows.length} işlem',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );

    return ModuleScreenLayout(
      moduleTitle: 'Finans - Ödemeler',
      navigationItems: paymentNavigationItems,
      filterBar: filterBarWidget,
      contentHeader: contentHeaderWidget,
      mainContent:
          financeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : DataTableWidget(
                columns: columns,
                rows: rows,
                showRowNumbers: true,
                onRowDoubleTap: (row) {
                  // Ödeme detayını göster
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Ödeme Detayı: ${row['reference']}'),
                          content: SizedBox(
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: const Text('İşlem Türü'),
                                  subtitle: Text('${row['type']}'),
                                  dense: true,
                                ),
                                ListTile(
                                  title: const Text('Tarih'),
                                  subtitle: Text('${row['date']}'),
                                  dense: true,
                                ),
                                ListTile(
                                  title: const Text('Tutar'),
                                  subtitle: Text('${row['amount']}'),
                                  dense: true,
                                ),
                                ListTile(
                                  title: const Text('Açıklama'),
                                  subtitle: Text('${row['description']}'),
                                  dense: true,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Kapat'),
                            ),
                          ],
                        ),
                  );
                },
              ),
    );
  }

  // Logo Muhasebe tarzı kasa işlemleri sekmesi
  Widget _buildCashTransactionsTab() {
    final financeState = ref.watch(financeProvider);

    final cashNavigationItems = [
      NavigationTreeItem(
        title: 'Kasa',
        icon: Icons.account_balance_wallet,
        children: [
          NavigationTreeItem(
            title: 'Ana Kasa',
            icon: Icons.point_of_sale,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Dolar Kasası',
            icon: Icons.attach_money,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Euro Kasası',
            icon: Icons.euro,
            onTap: () {},
          ),
        ],
      ),
      NavigationTreeItem(
        title: 'İşlem Türleri',
        icon: Icons.category,
        children: [
          NavigationTreeItem(
            title: 'Tahsilat',
            icon: Icons.arrow_downward,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Ödeme',
            icon: Icons.arrow_upward,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Devir İşlemleri',
            icon: Icons.sync,
            onTap: () {},
          ),
          NavigationTreeItem(
            title: 'Virman İşlemleri',
            icon: Icons.swap_horiz,
            onTap: () {},
          ),
        ],
      ),
    ];

    // Logo style filter bar for cash transactions
    final filterBar = Row(
      children: [
        const Text('Kasa:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: '',
                child: Text('Tümü', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'Ana Kasa',
                child: Text('Ana Kasa', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'Dolar Kasası',
                child: Text('Dolar Kasası', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'Euro Kasası',
                child: Text('Euro Kasası', style: TextStyle(fontSize: 12)),
              ),
            ],
            onChanged: (value) {},
            value: '',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 16),
        const Text('Tarih:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextFormField(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              hintText: 'Başlangıç',
              isDense: true,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextFormField(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              hintText: 'Bitiş',
              isDense: true,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 16),
          label: const Text('Filtrele', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF054F99),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );

    // Logo style header for content
    final contentHeader = Row(
      children: [
        const Text(
          'Kasa İşlemleri',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Spacer(),
        Text(
          'Toplam ${financeState.cashTransactions.length} işlem',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );

    // Prepare cash transactions data for the table
    final List<Map<String, dynamic>> cashTransactionRows =
        financeState.isLoading
            ? []
            : List<Map<String, dynamic>>.from(
              financeState.cashTransactions
                  .map(
                    (item) => Map<String, dynamic>.from(
                      item as Map<dynamic, dynamic>,
                    ),
                  )
                  .toList(),
            );

    // Cash transactions content widget
    final Widget cashTransactionsContent =
        financeState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                // Kasa özeti kartları
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kasa Bakiyeleri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCashBalanceItem(
                              'Ana Kasa',
                              '${financeState.cashBalances['anaKasa'] ?? 0}',
                              Icons.point_of_sale,
                              const Color(0xFF27AE60),
                            ),
                          ),
                          Expanded(
                            child: _buildCashBalanceItem(
                              'Dolar Kasası',
                              '\$${financeState.cashBalances['dolarKasa'] ?? 0}',
                              Icons.attach_money,
                              const Color(0xFF3498DB),
                            ),
                          ),
                          Expanded(
                            child: _buildCashBalanceItem(
                              'Euro Kasası',
                              '€${financeState.cashBalances['euroKasa'] ?? 0}',
                              Icons.euro,
                              const Color(0xFF8E44AD),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Show dialog to create a new cash transaction
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Yeni Kasa İşlemi'),
                                  content: SizedBox(
                                    width: 400,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                            labelText: 'İşlem Türü',
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Tahsilat',
                                              child: Text('Tahsilat'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Ödeme',
                                              child: Text('Ödeme'),
                                            ),
                                          ],
                                          onChanged: (value) {},
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                            labelText: 'Kasa',
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Ana Kasa',
                                              child: Text('Ana Kasa'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Dolar Kasası',
                                              child: Text('Dolar Kasası'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Euro Kasası',
                                              child: Text('Euro Kasası'),
                                            ),
                                          ],
                                          onChanged: (value) {},
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Tutar',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Açıklama',
                                          ),
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('İptal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // In a real app, save the transaction
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kasa işlemi kaydedildi',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Kaydet'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Yeni Kasa İşlemi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF054F99),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // İşlem tablosu
                Expanded(
                  child: DataTableWidget(
                    columns: [
                      'date',
                      'reference',
                      'type',
                      'description',
                      'amount',
                      'cashAccount',
                    ],
                    rows: cashTransactionRows,
                    showRowNumbers: true,
                    onRowDoubleTap: (row) {
                      // Kasa işlemi detayını göster
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text('İşlem Detayı: ${row['reference']}'),
                              content: SizedBox(
                                width: 400,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      title: const Text('İşlem Türü'),
                                      subtitle: Text('${row['type']}'),
                                      dense: true,
                                    ),
                                    ListTile(
                                      title: const Text('Tarih'),
                                      subtitle: Text('${row['date']}'),
                                      dense: true,
                                    ),
                                    ListTile(
                                      title: const Text('Tutar'),
                                      subtitle: Text('${row['amount']}'),
                                      dense: true,
                                    ),
                                    ListTile(
                                      title: const Text('Kasa'),
                                      subtitle: Text('${row['cashAccount']}'),
                                      dense: true,
                                    ),
                                    ListTile(
                                      title: const Text('Açıklama'),
                                      subtitle: Text('${row['description']}'),
                                      dense: true,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Kapat'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
              ],
            );
    return ModuleScreenLayout(
      moduleTitle: 'Finans - Kasa İşlemleri',
      navigationItems: cashNavigationItems,
      filterBar: filterBar,
      contentHeader: contentHeader,
      mainContent: cashTransactionsContent,
    );
  }

  Widget _buildCashBalanceItem(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorUtils.withAlpha(color, 0.1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
