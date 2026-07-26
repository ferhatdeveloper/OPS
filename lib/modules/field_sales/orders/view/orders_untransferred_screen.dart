// Dosya Adı: orders_untransferred_screen.dart
// Açıklama: Transfer edilmeyen sipariş dens — SQLite + sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/job_queue_service.dart';
import '../model/order_dens_row.dart';
import '../model/order_dens_scope.dart';
import '../viewmodel/order_dens_store.dart';
import 'order_dens_queue_body.dart';

/// {@template orders_untransferred_screen}
/// MBT SİPARİŞ → Transfer Edilmeyen dens · SQLite (is_synced=0) + sync_queue.
/// Route: `/field-sales/orders-untransferred`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, OrdersUntransferredScreen.routeName);
/// ```
/// {@endtemplate}
class OrdersUntransferredScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/orders-untransferred`
  static const String routeName = '/field-sales/orders-untransferred';

  /// [store]: Test enjeksiyonu (null → OrderDensStore)
  final OrderDensStore? store;

  /// [preloadRows]: Test dens satırları (SQLite atlanır)
  final List<OrderDensRow>? preloadRows;

  /// [onRetryQueue]: Logo kuyruk yeniden işlem (null → JobQueueService)
  final Future<void> Function()? onRetryQueue;

  const OrdersUntransferredScreen({
    Key? key,
    this.store,
    this.preloadRows,
    this.onRetryQueue,
  }) : super(key: key);

  @override
  State<OrdersUntransferredScreen> createState() =>
      _OrdersUntransferredScreenState();
}

class _OrdersUntransferredScreenState extends State<OrdersUntransferredScreen> {
  /// [_processing]: Yeniden gönderim sürüyor
  bool _processing = false;

  /// [_bodyKey]: Yenilemede dens gövdeyi yeniden oluşturur
  Key _bodyKey = UniqueKey();

  /// {@template orders_untransferred_retry}
  /// sync_queue'yu işler ve dens listeyi yeniler.
  /// {@endtemplate}
  Future<void> _retry() async {
    setState(() => _processing = true);
    try {
      final retry =
          widget.onRetryQueue ?? () => JobQueueService().processQueue();
      await retry();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _bodyKey = UniqueKey();
      _processing = false;
    });
  }

  /// {@template orders_untransferred_reload}
  /// Dens gövdeyi yeniden yükler.
  /// {@endtemplate}
  void _reload() {
    setState(() => _bodyKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.orders_untransferred');

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
            icon: _processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _processing ? null : _retry,
            tooltip: l10n.translate('field_sales.resend_to_logo_tooltip'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: l10n.translate('common.reload'),
          ),
        ],
      ),
      body: OrderDensQueueBody(
        key: _bodyKey,
        scope: OrderDensScope.untransferred,
        emptyMessageKey: 'field_sales.orders_untransferred_empty',
        store: widget.store,
        preloadRows: widget.preloadRows,
      ),
    );
  }
}
