// Dosya Adı: whms_order_detail_screen.dart
// Açıklama: WHMS emir dens detay — satırlar + ONAY chip
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../../model/whms_order_dto.dart';
import '../../model/whms_order_line_dto.dart';
import '../../model/whms_order_type.dart';
import '../../pick/view/whms_pick_order_screen.dart';
import '../../viewmodel/whms_order_store.dart';
import 'whms_receipt_execute_screen.dart';
import 'widgets/whms_order_approval_chip.dart';
import 'widgets/whms_order_empty_state.dart';
import 'widgets/whms_order_list_tile.dart';

/// Emir detay yükleyici — A ajanı store bağlayana kadar inject.
typedef WhmsOrderDetailLoader = Future<WhmsOrderDto?> Function(String orderId);

/// {@template whms_order_detail_screen}
/// Emir detay dens — özet, ONAY chip, satır listesi.
/// Route: `/whms/orders/detail` (arguments: orderId [String])
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WhmsOrderDetailScreen.routeName,
///   arguments: orderId,
/// );
/// ```
/// {@endtemplate}
class WhmsOrderDetailScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/whms/orders/detail';

  /// [orderId]: Named route arguments veya ctor
  final String? orderId;

  /// A store / test enjeksiyonu
  final WhmsOrderDetailLoader? loadOrder;

  /// Test / önceden yüklenmiş emir
  final WhmsOrderDto? initialOrder;

  /// {@macro whms_order_detail_screen}
  const WhmsOrderDetailScreen({
    super.key,
    this.orderId,
    this.loadOrder,
    this.initialOrder,
  });

  @override
  State<WhmsOrderDetailScreen> createState() => _WhmsOrderDetailScreenState();
}

class _WhmsOrderDetailScreenState extends State<WhmsOrderDetailScreen> {
  WhmsOrderDto? _order;
  bool _loading = true;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _loading = false;
      _loadStarted = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _resolveAndLoad();
  }

  String? _resolveOrderId() {
    if (widget.orderId != null && widget.orderId!.trim().isNotEmpty) {
      return widget.orderId!.trim();
    }
    if (_order != null && _order!.id.trim().isNotEmpty) {
      return _order!.id.trim();
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WhmsOrderDto && args.id.trim().isNotEmpty) {
      return args.id.trim();
    }
    if (args is String && args.trim().isNotEmpty) return args.trim();
    return null;
  }

  /// {@template whms_order_detail_load}
  /// orderId ile emir yükler.
  /// {@endtemplate}
  Future<void> _resolveAndLoad() async {
    final id = _resolveOrderId();
    if (id == null) {
      setState(() {
        _order = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final loader = widget.loadOrder;
      final WhmsOrderDto? order;
      if (loader != null) {
        order = await loader(id);
      } else {
        order = await const WhmsOrderStore().getById(id);
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _order = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final o = _order;
    final title = o == null
        ? l10n.translate('whms.orders.detail_title')
        : WhmsOrderListTile.displayCode(o);

    final canReceipt = o != null &&
        !o.status.isTerminal &&
        (o.orderType == WhmsOrderType.malKabul ||
            o.orderType == WhmsOrderType.putaway);
    final canPick = o != null &&
        !o.status.isTerminal &&
        o.orderType == WhmsOrderType.pick;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        showCalculatorHome: false,
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : o == null
              ? const WhmsOrderEmptyState(
                  messageKey: 'whms.orders.detail_missing',
                )
              : Column(
                  children: [
                    Expanded(child: _OrderDetailBody(order: o)),
                    if (canReceipt)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: FilledButton(
                              onPressed: () => _openReceipt(o),
                              child: Text(
                                l10n.translate(
                                  'whms.orders.receipt_execute',
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (canPick)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: FilledButton(
                              onPressed: () => _openPick(o),
                              child: Text(
                                l10n.translate('whms.pick.execute'),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  /// {@template whms_order_detail_open_receipt}
  /// Mal kabul / putaway yürütme ekranına gider; dönüşte yeniler.
  /// {@endtemplate}
  Future<void> _openReceipt(WhmsOrderDto order) async {
    final result = await Navigator.pushNamed(
      context,
      WhmsReceiptExecuteScreen.routeName,
      arguments: order.id,
    );
    if (!mounted) return;
    if (result != null) {
      await _resolveAndLoad();
    }
  }

  /// {@template whms_order_detail_open_pick}
  /// Pick emir dens ekranına gider; dönüşte yeniler.
  /// {@endtemplate}
  Future<void> _openPick(WhmsOrderDto order) async {
    await Navigator.pushNamed(
      context,
      WhmsPickOrderScreen.routeName,
      arguments: order.id,
    );
    if (!mounted) return;
    await _resolveAndLoad();
  }
}

/// Detay gövde — özet + ONAY + satırlar.
class _OrderDetailBody extends StatelessWidget {
  final WhmsOrderDto order;

  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final lines = order.lines;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 140,
            child: WhmsOrderApprovalChip(approval: order.approval),
          ),
        ),
        const SizedBox(height: 10),
        _DensDetailRow(
          label: l10n.translate('whms.orders.field_code'),
          value: WhmsOrderListTile.displayCode(order),
        ),
        _DensDetailRow(
          label: l10n.translate('whms.orders.field_type'),
          value: l10n.translate(
            'whms.orders.type_${order.orderType.wireName}',
          ),
        ),
        _DensDetailRow(
          label: l10n.translate('whms.orders.field_status'),
          value: l10n.translate(
            'whms.orders.status_${order.status.storageCode}',
          ),
        ),
        _DensDetailRow(
          label: l10n.translate('whms.orders.field_date'),
          value: WhmsOrderListTile.formatOrderDate(order.orderDate),
        ),
        _DensDetailRow(
          label: l10n.translate('whms.orders.field_warehouse'),
          value: (order.warehouseCode ?? '').trim().isEmpty
              ? '—'
              : order.warehouseCode!.trim(),
        ),
        _DensDetailRow(
          label: l10n.translate('whms.orders.field_lines'),
          value: '${lines.length}',
        ),
        if ((order.notes ?? '').trim().isNotEmpty)
          _DensDetailRow(
            label: l10n.translate('whms.orders.field_note'),
            value: order.notes!.trim(),
          ),
        const SizedBox(height: 10),
        Text(
          l10n.translate('whms.orders.lines_title'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FieldSalesDensTheme.title(context),
          ),
        ),
        const SizedBox(height: 6),
        if (lines.isEmpty)
          Text(
            l10n.translate('whms.orders.lines_empty'),
            style: TextStyle(
              fontSize: 12,
              color: FieldSalesDensTheme.muted(context),
            ),
          )
        else
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _DensLineTile(line: lines[i]),
          ],
      ],
    );
  }
}

/// Dens emir satırı kartı.
class _DensLineTile extends StatelessWidget {
  final WhmsOrderLineDto line;

  const _DensLineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = (line.productCode ?? '').trim();
    final name = (line.productName ?? '').trim();
    final loc = (line.locationCode ?? '').trim();
    final unit = (line.unitName ?? '').trim();
    final qtyText = unit.isEmpty
        ? '${line.quantityDone} / ${line.quantity}'
        : '${line.quantityDone} / ${line.quantity} $unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  code.isEmpty ? '—' : code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FieldSalesDensTheme.title(context),
                  ),
                ),
              ),
              Text(
                qtyText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FieldSalesDensTheme.title(context),
                ),
              ),
            ],
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: FieldSalesDensTheme.muted(context),
              ),
            ),
          ],
          if (loc.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.translate('whms.orders.field_location')}: $loc',
              style: TextStyle(
                fontSize: 11,
                color: FieldSalesDensTheme.muted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dens etiket + değer satırı.
class _DensDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DensDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: FieldSalesDensTheme.muted(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: FieldSalesDensTheme.title(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
