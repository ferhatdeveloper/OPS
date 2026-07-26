// Dosya Adı: stock_count_screen.dart
// Açıklama: Stok sayım fişleri ekranı (işyeri/fabrika/ambar + placeholder liste)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localization.dart';

/// {@template stock_count_screen}
/// Sayım fişleri için placeholder liste + MBT İşyeri/Fabrika/Ambar alanları.
/// Route: `/field-sales/stock-count` (dashboard envanter yolu)
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, StockCountScreen.routeName);
/// ```
/// {@endtemplate}
class StockCountScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/stock-count`
  static const String routeName = '/field-sales/stock-count';

  const StockCountScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends ConsumerState<StockCountScreen> {
  /// [_workplace]: Seçili işyeri
  String? _workplace;

  /// [_factory]: Seçili fabrika
  String? _factory;

  /// [_warehouse]: Seçili ambar
  String? _warehouse;

  /// [_seeded]: İlk l10n seçenekleri uygulandı mı
  bool _seeded = false;

  /// [_placeholderSlips]: Yer tutucu sayım fişi satırları
  static const List<Map<String, String>> _placeholderSlips = [
    {
      'id': 'SAY-2026-001',
      'warehouseKey': 'inventory.count_warehouse_center',
      'date': '2026-07-20',
      'statusKey': 'inventory.count_status_draft',
      'lines': '12',
    },
    {
      'id': 'SAY-2026-002',
      'warehouseKey': 'inventory.count_warehouse_vehicle',
      'date': '2026-07-22',
      'statusKey': 'inventory.count_status_pending',
      'lines': '8',
    },
    {
      'id': 'SAY-2026-003',
      'warehouseKey': 'inventory.count_warehouse_center',
      'date': '2026-07-24',
      'statusKey': 'inventory.count_status_approved',
      'lines': '24',
    },
  ];

  List<String> _workplaces(AppLocalization l10n) => [
        l10n.translate('inventory.count_workplace_sample'),
        l10n.translate('inventory.count_workplace_sample_2'),
      ];

  List<String> _factories(AppLocalization l10n) => [
        l10n.translate('inventory.count_factory_sample'),
        l10n.translate('inventory.count_factory_sample_2'),
      ];

  List<String> _warehouses(AppLocalization l10n) => [
        l10n.translate('inventory.count_warehouse_center'),
        l10n.translate('inventory.count_warehouse_vehicle'),
      ];

  void _seed(AppLocalization l10n) {
    if (_seeded) return;
    _seeded = true;
    _workplace = _workplaces(l10n).first;
    _factory = _factories(l10n).first;
    _warehouse = _warehouses(l10n).first;
  }

  InputDecoration _denseDecoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    _seed(l10n);
    final workplaces = _workplaces(l10n);
    final factories = _factories(l10n);
    final warehouses = _warehouses(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('inventory.stock_count')),
        backgroundColor: const Color(0xFF8B7CC7),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _workplace,
                  isDense: true,
                  decoration: _denseDecoration(
                    l10n.translate('inventory.count_workplace'),
                  ),
                  items: workplaces
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text(w, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _workplace = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _factory,
                  isDense: true,
                  decoration: _denseDecoration(
                    l10n.translate('inventory.count_factory'),
                  ),
                  items: factories
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _factory = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _warehouse,
                  isDense: true,
                  decoration: _denseDecoration(
                    l10n.translate('inventory.count_ambar'),
                  ),
                  items: warehouses
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text(w, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _warehouse = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.translate('inventory.count_module_desc'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _placeholderSlips.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final slip = _placeholderSlips[index];
                final warehouse = l10n.translate(slip['warehouseKey']!);
                final status = l10n.translate(slip['statusKey']!);
                final linesLabel = l10n
                    .translate('inventory.count_line_count')
                    .replaceAll('{count}', slip['lines']!);

                return ListTile(
                  leading: const Icon(Icons.checklist, color: Colors.grey),
                  title: Text(slip['id']!),
                  subtitle: Text(
                    '$warehouse · ${slip['date']} · $linesLabel',
                  ),
                  trailing: Text(
                    status,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
