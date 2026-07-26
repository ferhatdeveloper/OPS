// Dosya Adı: order_list_screen.dart
// Açıklama: Sipariş listesi dens (transfer edilen · SQLite orders)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/order_dens_scope.dart';
import '../viewmodel/order_dens_store.dart';
import 'order_dens_queue_body.dart';

/// {@template order_list_screen}
/// MBT SİPARİŞ → Sipariş Listesi (transfer edilen) dens · SQLite.
/// Route: `/field-sales/orders-list`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, OrderListScreen.routeName);
/// ```
/// {@endtemplate}
class OrderListScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/orders-list`
  static const String routeName = '/field-sales/orders-list';

  /// [store]: Test enjeksiyonu (null → [OrderDensStore])
  final OrderDensStore? store;

  const OrderListScreen({
    Key? key,
    this.store,
  }) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  /// [_bodyKey]: Yenilemede dens gövdeyi yeniden oluşturur
  Key _bodyKey = UniqueKey();

  /// {@template order_list_screen_reload}
  /// Dens gövdeyi SQLite’tan yeniden yükler.
  /// {@endtemplate}
  void _reload() {
    setState(() => _bodyKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.order_list');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: l10n.translate('common.reload'),
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: OrderDensQueueBody(
        key: _bodyKey,
        scope: OrderDensScope.transferred,
        emptyMessageKey: 'field_sales.order_list_empty',
        store: widget.store,
      ),
    );
  }
}
