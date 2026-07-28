// Dosya Adı: whms_typed_order_list_screen.dart
// Açıklama: Tip sabitli WHMS emir listesi (mal kabul / putaway / pick / sevk)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../field_sales/shared/view/field_sales_dens_theme.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../contract/whms_route_map.dart';
import '../orders/model/whms_order.dart';
import '../orders/view/whms_order_detail_screen.dart';
import '../orders/view/widgets/whms_order_empty_state.dart';
import '../orders/view/widgets/whms_order_list_tile.dart';
import '../pick/view/whms_pick_order_screen.dart';
import '../viewmodel/whms_order_store.dart';

/// {@template whms_typed_order_list_screen}
/// Tek tip emir dens listesi — boş state + satır → detay/yürütme.
/// {@endtemplate}
class WhmsTypedOrderListScreen extends StatefulWidget {
  /// Named route
  final String routeName;

  /// Başlık l10n
  final String titleKey;

  /// Sabit tip filtresi
  final WhmsOrderType orderType;

  /// Store inject
  final WhmsOrderStore? store;

  /// Test satırları
  final List<WhmsOrderDto>? initialRows;

  /// {@macro whms_typed_order_list_screen}
  const WhmsTypedOrderListScreen({
    super.key,
    required this.routeName,
    required this.titleKey,
    required this.orderType,
    this.store,
    this.initialRows,
  });

  /// Mal kabul listesi
  static WhmsTypedOrderListScreen receipt({Key? key}) =>
      WhmsTypedOrderListScreen(
        key: key,
        routeName: WhmsRouteMap.whmsReceiptList,
        titleKey: 'whms.hub.receipt',
        orderType: WhmsOrderType.malKabul,
      );

  /// Putaway listesi
  static WhmsTypedOrderListScreen putaway({Key? key}) =>
      WhmsTypedOrderListScreen(
        key: key,
        routeName: WhmsRouteMap.whmsPutaway,
        titleKey: 'whms.hub.putaway',
        orderType: WhmsOrderType.putaway,
      );

  /// Pick listesi
  static WhmsTypedOrderListScreen pick({Key? key}) => WhmsTypedOrderListScreen(
        key: key,
        routeName: WhmsRouteMap.whmsPickList,
        titleKey: 'whms.hub.pick',
        orderType: WhmsOrderType.pick,
      );

  /// Sevk listesi
  static WhmsTypedOrderListScreen shipping({Key? key}) =>
      WhmsTypedOrderListScreen(
        key: key,
        routeName: WhmsRouteMap.whmsShipping,
        titleKey: 'whms.hub.shipping',
        orderType: WhmsOrderType.sevk,
      );

  @override
  State<WhmsTypedOrderListScreen> createState() =>
      _WhmsTypedOrderListScreenState();
}

class _WhmsTypedOrderListScreenState extends State<WhmsTypedOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final WhmsOrderListSource _source = WhmsOrderListSource(
    store: widget.store ?? const WhmsOrderStore(),
  );
  List<WhmsOrderDto> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRows != null) {
      _rows = List<WhmsOrderDto>.from(widget.initialRows!);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _source.list(
        type: widget.orderType,
        query: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loading = false;
      });
    }
  }

  Future<void> _open(WhmsOrderDto order) async {
    if (widget.orderType == WhmsOrderType.malKabul ||
        widget.orderType == WhmsOrderType.putaway) {
      await Navigator.pushNamed(
        context,
        WhmsRouteMap.whmsOrderReceipt,
        arguments: order,
      );
    } else if (widget.orderType == WhmsOrderType.pick) {
      await Navigator.pushNamed(
        context,
        WhmsPickOrderScreen.routeName,
        arguments: order,
      );
    } else {
      await Navigator.pushNamed(
        context,
        WhmsOrderDetailScreen.routeName,
        arguments: order,
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate(widget.titleKey),
        showCalculatorHome: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('whms.orders.search_hint'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                    )
                  : _rows.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.4,
                              child: const WhmsOrderEmptyState(),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, i) {
                            final o = _rows[i];
                            return WhmsOrderListTile(
                              order: o,
                              onTap: () => _open(o),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
