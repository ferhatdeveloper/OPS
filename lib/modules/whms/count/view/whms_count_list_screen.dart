// Dosya Adı: whms_count_list_screen.dart
// Açıklama: Merkez sayım emirleri dens liste (P0 iskelet; UI no-touch)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../contract/whms_route_map.dart';
import '../model/whms_count_order.dart';
import '../viewmodel/whms_count_store.dart';

/// {@template whms_count_list_screen}
/// `/whms/count` — sayım emir dens listesi (bellek store).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsCountListScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsCountListScreen extends StatefulWidget {
  /// [routeName]: `/whms/count`
  static const String routeName = WhmsRouteMap.whmsCount;

  /// [store]: Test / DI için opsiyonel store
  final WhmsCountStore? store;

  /// {@macro whms_count_list_screen}
  const WhmsCountListScreen({super.key, this.store});

  @override
  State<WhmsCountListScreen> createState() => _WhmsCountListScreenState();
}

class _WhmsCountListScreenState extends State<WhmsCountListScreen> {
  late final WhmsCountStore _store;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? WhmsCountStore();
    _store.seedDemoIfEmpty();
    _store.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    if (widget.store == null) {
      _store.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = l10n.translate('field_sales.menu.sub_whms_count');
    final orders = _store.orders;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: title,
        showCalculatorHome: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              l10n.translate('whms.phase2_shell'),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return _CountOrderRow(
                  order: orders[index],
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountOrderRow extends StatelessWidget {
  final WhmsCountOrder order;
  final bool isDark;

  const _CountOrderRow({
    required this.order,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final loc = order.locationCode;
    final subtitle = loc == null || loc.isEmpty
        ? order.warehouseCode
        : '${order.warehouseCode} · $loc';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle · ${order.status.name}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.inventory_2_outlined,
            size: 18,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ],
      ),
    );
  }
}
