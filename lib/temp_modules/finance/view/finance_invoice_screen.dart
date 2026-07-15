import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../view/widgets/data_table_widget.dart';
import '../../../core/base/module_screen_layout.dart';
import '../../../viewmodel/finance/finance_provider.dart';
import '../../../view/widgets/navigation_tree.dart';

class FinanceInvoiceScreen extends ConsumerStatefulWidget {
  const FinanceInvoiceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FinanceInvoiceScreen> createState() =>
      _FinanceInvoiceScreenState();
}

class _FinanceInvoiceScreenState extends ConsumerState<FinanceInvoiceScreen> {
  int? selectedRowIndex;

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);

    // Logo Muhasebe tarzı navigasyon için sol menü öğeleri
    final navigationItems = [
      NavigationTreeItem(
        title: 'Genel',
        icon: Icons.dashboard,
        children: [
          NavigationTreeItem(
            title: 'Fatura Listesi',
            icon: Icons.receipt_long,
            onTap: () {
              // Aynı sayfada olduğumuz için bir şey yapmaya gerek yok
            },
          ),
          NavigationTreeItem(
            title: 'İşlem Bekleyenler',
            icon: Icons.pending_actions,
            onTap: () {
              // İşlem bekleyen faturaları göster
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('İşlem Bekleyen Faturalar gösteriliyor...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      NavigationTreeItem(
        title: 'Fatura Türleri',
        icon: Icons.category,
        children: [
          NavigationTreeItem(
            title: 'Satış Faturaları',
            icon: Icons.receipt,
            onTap: () {
              // Satış faturalarını göster
            },
          ),
          NavigationTreeItem(
            title: 'Satınalma Faturaları',
            icon: Icons.shopping_cart,
            onTap: () {
              // Alış faturalarını göster
            },
          ),
          NavigationTreeItem(
            title: 'İade Faturaları',
            icon: Icons.assignment_return,
            onTap: () {
              // İade faturalarını göster
            },
          ),
        ],
      ),
      NavigationTreeItem(
        title: 'Raporlar',
        icon: Icons.summarize,
        children: [
          NavigationTreeItem(
            title: 'Fatura Özeti',
            icon: Icons.bar_chart,
            onTap: () {
              // Fatura özet raporunu göster
            },
          ),
          NavigationTreeItem(
            title: 'Detaylı İstatistikler',
            icon: Icons.stacked_line_chart,
            onTap: () {
              // Detaylı istatistikleri göster
            },
          ),
        ],
      ),
    ];

    // Logo Muhasebe tarzı filtre çubuğu
    final filterBar = Row(
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
        const Text('Müşteri:', style: TextStyle(fontSize: 13)),
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
                value: 'ABC',
                child: Text('ABC Ltd.', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'XYZ',
                child: Text('XYZ A.Ş.', style: TextStyle(fontSize: 12)),
              ),
            ],
            onChanged: (value) {},
            value: '',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 16),
        const Text('Durum:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
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
                value: 'Open',
                child: Text('Açık', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'Paid',
                child: Text('Ödenmiş', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'Overdue',
                child: Text('Gecikmiş', style: TextStyle(fontSize: 12)),
              ),
            ],
            onChanged: (value) {},
            value: '',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            // Filtreleri uygula
          },
          icon: const Icon(Icons.filter_list, size: 16),
          label: const Text('Filtrele', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF054F99),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            // Filtreleri temizle
          },
          child: const Text('Temizle', style: TextStyle(fontSize: 12)),
        ),
      ],
    );

    // Fatura listesi için tablo sütunları
    final columns = ['number', 'date', 'customer', 'amount']; // Fatura verileri
    final List<Map<String, dynamic>> rows =
        financeState.isLoading
            ? []
            : List<Map<String, dynamic>>.from(
              financeState.invoices
                  .map(
                    (item) => Map<String, dynamic>.from(
                      item as Map<dynamic, dynamic>,
                    ),
                  )
                  .toList(),
            );

    // Logo Muhasebe tarzı içerik başlığı
    final contentHeader = Row(
      children: [
        const Text(
          'Fatura Listesi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Spacer(),
        Text(
          'Toplam ${rows.length} fatura',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );

    // Tablo verilerini Logo Muhasebe tarzında göster
    return ModuleScreenLayout(
      moduleTitle: 'Finans - Faturalar',
      navigationItems: navigationItems,
      filterBar: filterBar,
      contentHeader: contentHeader,
      mainContent:
          financeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : DataTableWidget(
                columns: columns,
                rows: rows,
                showRowNumbers: true,
                selectedRowIndex: selectedRowIndex,
                onRowSelected: (index) {
                  setState(() {
                    selectedRowIndex = index;
                  });
                },
                onRowDoubleTap: (row) {
                  // Fatura detayını göster
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Fatura Detayı: ${row['number']}'),
                          content: SizedBox(
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: const Text('Müşteri'),
                                  subtitle: Text('${row['customer']}'),
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
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Kapat'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Düzenleme ekranına git
                                Navigator.of(context).pop();
                              },
                              child: const Text('Düzenle'),
                            ),
                          ],
                        ),
                  );
                },
              ),
    );
  }
}
