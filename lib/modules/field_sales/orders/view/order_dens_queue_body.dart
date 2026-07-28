// Dosya Adı: order_dens_queue_body.dart
// Açıklama: Sipariş dens kuyruk gövdesi — SQLite satır → MBT filtre UI
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/order_dens_row.dart';
import '../model/order_dens_scope.dart';
import '../model/order_model.dart';
import '../viewmodel/order_dens_store.dart';

/// {@template order_dens_queue_body}
/// Sipariş dens listesi gövdesi: SQLite yükler, MBT kuyruk UI bağlar.
///
/// Kullanım örneği:
/// ```dart
/// const OrderDensQueueBody(
///   scope: OrderDensScope.tracking,
///   emptyMessageKey: 'field_sales.order_tracking_empty',
/// )
/// ```
/// {@endtemplate}
class OrderDensQueueBody extends StatefulWidget {
  /// [scope]: Dens SQLite süzgeç kapsamı
  final OrderDensScope scope;

  /// [emptyMessageKey]: Boş liste çeviri anahtarı
  final String emptyMessageKey;

  /// [store]: Opsiyonel store (test enjeksiyonu)
  final OrderDensStore? store;

  /// [preloadRows]: Test için SQLite atla (null → store.query)
  final List<OrderDensRow>? preloadRows;

  /// [onRowTap]: Satır aksiyonu (düzenle / sil)
  final ValueChanged<MbtQueueRow>? onRowTap;

  /// {@macro order_dens_queue_body}
  const OrderDensQueueBody({
    Key? key,
    required this.scope,
    required this.emptyMessageKey,
    this.store,
    this.preloadRows,
    this.onRowTap,
  }) : super(key: key);

  @override
  State<OrderDensQueueBody> createState() => _OrderDensQueueBodyState();
}

class _OrderDensQueueBodyState extends State<OrderDensQueueBody> {
  /// [_store]: SQLite erişim
  late final OrderDensStore _store =
      widget.store ?? const OrderDensStore();

  /// [_rows]: Yüklü dens satırlar
  List<OrderDensRow> _rows = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_amountFmt]: TR tutar
  final NumberFormat _amountFmt = NumberFormat('#,##0.00', 'tr_TR');

  /// [_dateFmt]: dens tarih
  final DateFormat _dateFmt = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.preloadRows != null) {
      _rows = widget.preloadRows!;
      _loading = false;
    } else {
      _reload();
    }
  }

  /// {@template order_dens_queue_body_reload}
  /// SQLite dens satırlarını yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    try {
      final list = await _store.query(widget.scope);
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

  /// {@template order_dens_queue_body_to_queue_rows}
  /// OrderDensRow → MbtQueueRow.
  /// {@endtemplate}
  List<MbtQueueRow> _toQueueRows(AppLocalization l10n) {
    return _rows.map((r) {
      final side = r.orderType == OrderType.purchase
          ? MbtQueueDocSide.purchase
          : MbtQueueDocSide.sales;
      final statusLabel = _statusLabel(l10n, r.status);
      final amount = _amountFmt.format(r.totalAmount);
      final syncLabel = r.isSynced
          ? l10n.translate('field_sales.order_dens_synced')
          : l10n.translate('field_sales.order_dens_unsynced');
      final queueLabel = _queueLabel(l10n, r);
      final subtitle =
          '${_dateFmt.format(r.orderDate)} · $statusLabel · '
          '$amount · $syncLabel'
          '${queueLabel.isEmpty ? '' : ' · $queueLabel'}';
      return MbtQueueRow(
        id: r.id,
        side: side,
        date: r.orderDate,
        title: r.displayTitle,
        subtitle: subtitle,
        searchBlob: '${r.customerCode ?? ''} ${r.customerName ?? ''} '
            '${r.status} ${r.id} ${r.queueJobId ?? ''} '
            '${r.lastError ?? ''}',
      );
    }).toList();
  }

  /// {@template order_dens_queue_body_queue_label}
  /// sync_queue durum etiketi (yoksa boş).
  /// {@endtemplate}
  String _queueLabel(AppLocalization l10n, OrderDensRow r) {
    final err = (r.lastError ?? '').trim();
    if (err.isNotEmpty) {
      return l10n.translate(
        'field_sales.orders_untransferred_queue_error',
        args: {'error': err, 'retry': '${r.retryCount}'},
      );
    }
    final jobId = (r.queueJobId ?? '').trim();
    if (jobId.isNotEmpty) {
      return l10n.translate('field_sales.orders_untransferred_queue_pending');
    }
    return '';
  }

  /// {@template order_dens_queue_body_status_label}
  /// Durum kodunu l10n etikete çevirir (bilinmeyen → ham).
  /// {@endtemplate}
  String _statusLabel(AppLocalization l10n, String status) {
    final key = status.trim().toLowerCase();
    switch (key) {
      case 'pending':
        return l10n.translate('field_sales.order_status_pending');
      case 'proposal':
        return l10n.translate('field_sales.order_status_proposal');
      case 'approved':
        return l10n.translate('field_sales.order_status_approved');
      case 'cancelled':
        return l10n.translate('field_sales.order_status_cancelled');
      case 'shippable':
        return l10n.translate('field_sales.order_status_shippable');
      case 'notshippable':
        return l10n.translate('field_sales.order_status_not_shippable');
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return MbtSalesPurchaseQueueBody(
      emptyMessageKey: widget.emptyMessageKey,
      rows: _toQueueRows(l10n),
      onRowTap: widget.onRowTap,
    );
  }
}
