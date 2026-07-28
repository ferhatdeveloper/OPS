// Dosya Adı: orders_untransferred_screen.dart
// Açıklama: Transfer edilmeyen sipariş dens — SQLite + sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/init/navigation/routes.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/job_queue_service.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/order_dens_row.dart';
import '../model/order_dens_scope.dart';
import '../model/order_model.dart';
import '../viewmodel/order_dens_store.dart';
import '../viewmodel/order_provider.dart';
import 'order_dens_queue_body.dart';

/// {@template orders_untransferred_screen}
/// MBT SİPARİŞ → Transfer Edilmeyen dens · SQLite (is_synced=0) + sync_queue.
/// Route: `/field-sales/orders-untransferred`
/// {@endtemplate}
class OrdersUntransferredScreen extends ConsumerStatefulWidget {
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
  ConsumerState<OrdersUntransferredScreen> createState() =>
      _OrdersUntransferredScreenState();
}

class _OrdersUntransferredScreenState
    extends ConsumerState<OrdersUntransferredScreen> {
  bool _processing = false;
  Key _bodyKey = UniqueKey();

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

  void _reload() {
    setState(() => _bodyKey = UniqueKey());
  }

  Future<void> _onRowTap(MbtQueueRow row) async {
    final l10n = AppLocalization.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, size: 20),
                title: Text(
                  l10n.translate('field_sales.order_local_edit'),
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, size: 20),
                title: Text(
                  l10n.translate('field_sales.order_local_cancel'),
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () => Navigator.pop(ctx, 'cancel'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, size: 20),
                title: Text(
                  l10n.translate('field_sales.order_local_delete'),
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;

    if (action == 'cancel') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.translate('field_sales.order_local_cancel')),
          content: Text(
            l10n.translate(
              'field_sales.order_local_cancel_confirm',
              args: {'id': row.id},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.translate('field_sales.order_local_cancel')),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      final ok =
          await ref.read(orderProvider.notifier).cancelLocalOrder(row.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate(
              ok
                  ? 'field_sales.order_local_cancel_done'
                  : 'field_sales.order_local_cancel_failed',
            ),
          ),
        ),
      );
      if (ok) _reload();
      return;
    }

    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.translate('field_sales.order_local_delete')),
          content: Text(
            l10n.translate(
              'field_sales.order_local_delete_confirm',
              args: {'id': row.id},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.translate('common.delete')),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      final ok =
          await ref.read(orderProvider.notifier).softDeleteLocalOrder(row.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate(
              ok
                  ? 'field_sales.order_local_delete_done'
                  : 'field_sales.order_local_delete_failed',
            ),
          ),
        ),
      );
      if (ok) _reload();
      return;
    }

    if (action == 'edit') {
      final ok =
          await ref.read(orderProvider.notifier).loadDraftFromOrderId(row.id);
      if (!mounted) return;
      if (!ok) {
        final err = ref.read(orderProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err != null && err.startsWith('field_sales.')
                  ? l10n.translate(err)
                  : (err ?? l10n.translate('field_sales.order_edit_not_found')),
            ),
          ),
        );
        return;
      }
      final draft = ref.read(orderProvider).draftOrder;
      if (draft == null) return;
      final route = draft.orderType == OrderType.purchase
          ? AppRoutes.fieldSalesOrdersPurchase
          : AppRoutes.fieldSalesOrdersSales;
      await Navigator.pushNamed(
        context,
        route,
        arguments: {
          'customerId': draft.customerId,
          'orderType': draft.orderType.storageValue,
          'orderId': draft.id,
        },
      );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.orders_untransferred');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.sync,
            onPressed: _processing ? null : _retry,
            tooltip: l10n.translate('field_sales.resend_to_logo_tooltip'),
          ),
          if (_processing)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 4),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
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
        onRowTap: widget.preloadRows == null ? _onRowTap : null,
      ),
    );
  }
}
