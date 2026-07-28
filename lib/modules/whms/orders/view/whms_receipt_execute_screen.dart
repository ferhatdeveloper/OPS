// Dosya Adı: whms_receipt_execute_screen.dart
// Açıklama: Mal kabul / putaway yürütme dens — lokasyon zorunlu + onay
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../../contract/whms_route_map.dart';
import '../../locations/model/whms_location.dart';
import '../../locations/viewmodel/whms_location_store.dart';
import '../../model/whms_order_dto.dart';
import '../../model/whms_order_line_dto.dart';
import '../../model/whms_order_type.dart';
import '../../viewmodel/whms_order_store.dart';
import 'widgets/whms_order_empty_state.dart';
import 'widgets/whms_order_list_tile.dart';

/// Emir yükleyici — test enjeksiyonu.
typedef WhmsReceiptOrderLoader = Future<WhmsOrderDto?> Function(String orderId);

/// {@template whms_receipt_execute_screen}
/// Mal kabul / yerleştirme yürütme dens.
/// Route: `/whms/orders/receipt` (arguments: orderId [String] | WhmsOrderDto)
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WhmsReceiptExecuteScreen.routeName,
///   arguments: orderId,
/// );
/// ```
/// {@endtemplate}
class WhmsReceiptExecuteScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsOrderReceipt;

  /// [orderId]: Named route / ctor
  final String? orderId;

  /// Önceden yüklenmiş emir (test / detaydan)
  final WhmsOrderDto? initialOrder;

  /// Store enjeksiyonu
  final WhmsOrderStore? store;

  /// Lokasyon store (öneri listesi)
  final WhmsLocationStore? locationStore;

  /// Emir yükleyici
  final WhmsReceiptOrderLoader? loadOrder;

  /// {@macro whms_receipt_execute_screen}
  const WhmsReceiptExecuteScreen({
    super.key,
    this.orderId,
    this.initialOrder,
    this.store,
    this.locationStore,
    this.loadOrder,
  });

  @override
  State<WhmsReceiptExecuteScreen> createState() =>
      _WhmsReceiptExecuteScreenState();
}

class _WhmsReceiptExecuteScreenState extends State<WhmsReceiptExecuteScreen> {
  WhmsOrderDto? _order;
  bool _loading = true;
  bool _saving = false;
  bool _loadStarted = false;
  String? _errorKey;

  final Map<String, TextEditingController> _locCtrls = {};
  final Map<String, TextEditingController> _qtyCtrls = {};
  List<WhmsLocation> _locations = const [];

  WhmsOrderStore get _store => widget.store ?? const WhmsOrderStore();

  WhmsLocationStore get _locStore =>
      widget.locationStore ?? const WhmsLocationStore();

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _bindOrder(widget.initialOrder!);
      _loading = false;
      _loadStarted = true;
      _loadLocations(widget.initialOrder!.warehouseCode);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _resolveAndLoad();
  }

  @override
  void dispose() {
    for (final c in _locCtrls.values) {
      c.removeListener(_onLineInputChanged);
      c.dispose();
    }
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _resolveOrderId() {
    if (widget.orderId != null && widget.orderId!.trim().isNotEmpty) {
      return widget.orderId!.trim();
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WhmsOrderDto) return args.id;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    return null;
  }

  Future<void> _resolveAndLoad() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WhmsOrderDto) {
      _bindOrder(args);
      setState(() => _loading = false);
      await _loadLocations(args.warehouseCode);
      return;
    }
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
      final order = loader != null
          ? await loader(id)
          : await _store.getById(id);
      if (!mounted) return;
      if (order != null) {
        _bindOrder(order);
        await _loadLocations(order.warehouseCode);
      }
      setState(() {
        _order = order;
        _loading = false;
        _errorKey = order == null
            ? 'whms.orders.detail_missing'
            : (!_isReceiptType(order)
                ? 'whms.orders.receipt_invalid_type'
                : null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _order = null;
        _loading = false;
        _errorKey = 'whms.orders.detail_missing';
      });
    }
  }

  bool _isReceiptType(WhmsOrderDto o) =>
      o.orderType == WhmsOrderType.malKabul ||
      o.orderType == WhmsOrderType.putaway;

  void _bindOrder(WhmsOrderDto order) {
    _order = order;
    for (final line in order.lines) {
      if (!_locCtrls.containsKey(line.id)) {
        final loc = TextEditingController(
          text: (line.locationCode ?? '').trim(),
        );
        loc.addListener(_onLineInputChanged);
        _locCtrls[line.id] = loc;
      }
      if (!_qtyCtrls.containsKey(line.id)) {
        final qty =
            line.quantityDone > 0 ? line.quantityDone : line.quantity;
        _qtyCtrls[line.id] = TextEditingController(
          text: qty == qty.roundToDouble()
              ? qty.toInt().toString()
              : qty.toString(),
        );
      }
    }
  }

  void _onLineInputChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLocations(String? warehouseCode) async {
    try {
      final rows = await _locStore.listActive(
        warehouseCode: warehouseCode,
      );
      if (!mounted) return;
      setState(() => _locations = rows);
    } catch (_) {
      // Öneri yok — serbest lokasyon girişi
    }
  }

  List<WhmsOrderLineDto> _buildLinesFromInputs() {
    final order = _order;
    if (order == null) return const [];
    return order.lines.map((line) {
      final loc = (_locCtrls[line.id]?.text ?? '').trim();
      final qtyRaw = (_qtyCtrls[line.id]?.text ?? '').trim().replaceAll(',', '.');
      final qtyDone = double.tryParse(qtyRaw) ?? line.quantityDone;
      return line.copyWith(
        locationCode: loc.isEmpty ? null : loc,
        quantityDone: qtyDone < 0 ? 0 : qtyDone,
      );
    }).toList(growable: false);
  }

  bool get _allLocationsFilled {
    final order = _order;
    if (order == null || order.lines.isEmpty) return false;
    return order.lines.every((l) {
      return (_locCtrls[l.id]?.text ?? '').trim().isNotEmpty;
    });
  }

  Future<void> _confirmPutaway() async {
    final order = _order;
    if (order == null || _saving) return;
    final l10n = AppLocalization.of(context);
    if (!_allLocationsFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('whms.orders.receipt_location_required'),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await _store.confirmReceiptPutaway(
        orderId: order.id,
        lines: _buildLinesFromInputs(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('whms.orders.receipt_putaway_ok'),
          ),
        ),
      );
      Navigator.pop(context, saved);
    } on StateError catch (e) {
      if (!mounted) return;
      final key = e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            key.startsWith('whms.')
                ? l10n.translate(key)
                : l10n.translate('whms.orders.receipt_location_required'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('whms.orders.receipt_save_error'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final o = _order;
    final title = o == null
        ? l10n.translate('whms.orders.receipt_title')
        : '${l10n.translate('whms.orders.receipt_title')} · '
            '${WhmsOrderListTile.displayCode(o)}';

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
          : o == null || _errorKey != null
              ? WhmsOrderEmptyState(
                  messageKey: _errorKey ?? 'whms.orders.detail_missing',
                )
                              : o.status.isTerminal
                  ? const WhmsOrderEmptyState(
                      messageKey: 'whms.orders.receipt_already_done',
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                            children: [
                              Text(
                                l10n.translate(
                                  'whms.orders.receipt_hint',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: FieldSalesDensTheme.muted(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (o.lines.isEmpty)
                                Text(
                                  l10n.translate('whms.orders.lines_empty'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: FieldSalesDensTheme.muted(context),
                                  ),
                                )
                              else
                                for (var i = 0; i < o.lines.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 4),
                                  _ReceiptLineCard(
                                    line: o.lines[i],
                                    locCtrl: _locCtrls[o.lines[i].id]!,
                                    qtyCtrl: _qtyCtrls[o.lines[i].id]!,
                                    suggestions: _locations,
                                  ),
                                ],
                            ],
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: FilledButton(
                                onPressed: _saving || !_allLocationsFilled
                                    ? null
                                    : _confirmPutaway,
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        l10n.translate(
                                          'whms.orders.receipt_putaway_confirm',
                                        ),
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
}

/// Dens satır kartı — lokasyon + tamamlanan miktar.
class _ReceiptLineCard extends StatelessWidget {
  final WhmsOrderLineDto line;
  final TextEditingController locCtrl;
  final TextEditingController qtyCtrl;
  final List<WhmsLocation> suggestions;

  const _ReceiptLineCard({
    required this.line,
    required this.locCtrl,
    required this.qtyCtrl,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final code = (line.productCode ?? '').trim();
    final name = (line.productName ?? '').trim();
    final unit = (line.unitName ?? '').trim();
    final ordered = unit.isEmpty
        ? '${line.quantity}'
        : '${line.quantity} $unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: FieldSalesDensTheme.border(context),
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
                ordered,
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: locCtrl,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.translate(
                      'whms.orders.field_location',
                    ),
                    hintText: suggestions.isEmpty
                        ? null
                        : suggestions.first.code,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.,]'),
                    ),
                  ],
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.translate(
                      'whms.orders.field_qty_done',
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
