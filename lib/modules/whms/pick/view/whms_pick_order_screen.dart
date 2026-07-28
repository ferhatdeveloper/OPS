// Dosya Adı: whms_pick_order_screen.dart
// Açıklama: Pick emir dens — route_seq sırası + barkod/seri zorunlu okutma
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';

import '../../../../core/init/navigation/routes.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../../contract/whms_route_map.dart';
import '../../model/whms_order_dto.dart';
import '../../model/whms_order_line_dto.dart';
import '../../model/whms_order_type.dart';
import '../../orders/view/widgets/whms_order_empty_state.dart';
import '../../orders/view/widgets/whms_order_list_tile.dart';
import '../../viewmodel/whms_order_store.dart';
import '../engine/whms_pick_serial_rule.dart';
import '../viewmodel/whms_product_serial_rule_store.dart';

/// Emir yükleyici (test inject).
typedef WhmsPickOrderLoader = Future<WhmsOrderDto?> Function(String orderId);

/// {@template whms_pick_order_screen}
/// Toplama emri dens ekranı — satırlar `route_seq` sırası.
/// Barkod: field_sales [BarcodeScanScreen] reuse.
/// Seri zorunlu (emir flag ∪ ürün kuralı) → `serial_no` boşsa tamamlanamaz.
///
/// Route: `/whms/pick` (arguments: orderId [String])
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WhmsPickOrderScreen.routeName,
///   arguments: orderId,
/// );
/// ```
/// {@endtemplate}
class WhmsPickOrderScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsPick;

  /// [orderId]: Named route arguments veya ctor
  final String? orderId;

  /// Store inject
  final WhmsOrderStore? store;

  /// Ürün seri kuralı inject
  final WhmsProductSerialRuleStore? productSerialStore;

  /// Test loader
  final WhmsPickOrderLoader? loadOrder;

  /// Önceden yüklenmiş emir
  final WhmsOrderDto? initialOrder;

  /// {@macro whms_pick_order_screen}
  const WhmsPickOrderScreen({
    super.key,
    this.orderId,
    this.store,
    this.productSerialStore,
    this.loadOrder,
    this.initialOrder,
  });

  @override
  State<WhmsPickOrderScreen> createState() => _WhmsPickOrderScreenState();
}

class _WhmsPickOrderScreenState extends State<WhmsPickOrderScreen> {
  WhmsOrderDto? _order;
  Set<String> _serialProductIds = const {};
  bool _loading = true;
  bool _busy = false;
  bool _loadStarted = false;

  WhmsOrderStore get _store => widget.store ?? const WhmsOrderStore();

  WhmsProductSerialRuleStore get _productSerial =>
      widget.productSerialStore ??
      widget.store?.productSerialStore ??
      const WhmsProductSerialRuleStore();

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _loading = false;
      _loadStarted = true;
      _refreshProductRules();
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
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is WhmsOrderDto) return args.id;
    return null;
  }

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
        order = await _store.getById(id);
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
      await _refreshProductRules();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _order = null;
        _loading = false;
      });
    }
  }

  Future<void> _refreshProductRules() async {
    final o = _order;
    if (o == null) return;
    final ids = await _productSerial.productIdsRequiringSerial(
      o.lines.map((l) => l.productId),
    );
    if (!mounted) return;
    setState(() => _serialProductIds = ids);
  }

  List<WhmsOrderLineDto> get _sortedLines {
    final o = _order;
    if (o == null) return const [];
    return WhmsPickSerialRule.sortByRouteSeq(o.lines);
  }

  bool _lineNeedsSerial(WhmsOrderLineDto line) {
    final o = _order;
    if (o == null) return false;
    return WhmsPickSerialRule.lineRequiresSerial(
      o,
      line,
      productIdsRequiringSerial: _serialProductIds,
    );
  }

  bool get _canComplete {
    final o = _order;
    if (o == null) return false;
    if (o.status.isTerminal) return false;
    return WhmsPickSerialRule.canCompleteOrder(
      o,
      productIdsRequiringSerial: _serialProductIds,
    );
  }

  void _snack(String key) {
    if (!mounted) return;
    final l10n = AppLocalization.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate(key)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// field_sales barkod ekranı → ürün map.
  Future<Map<String, dynamic>?> _openProductBarcodeScan() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.fieldSalesBarcodeScan,
      arguments: <String, dynamic>{
        'selectionMode': true,
        'autoScan': true,
      },
    );
    if (result is Map<String, dynamic>) return result;
    return null;
  }

  /// Ham seri / barkod (barcode_scan2 — field_sales ile aynı paket).
  Future<String?> _scanRawBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type != ResultType.Barcode) return null;
      final raw = result.rawContent.trim();
      return raw.isEmpty ? null : raw;
    } catch (_) {
      _snack('field_sales.barcode_camera_failed');
      return null;
    }
  }

  Future<void> _onScanProduct() async {
    final o = _order;
    if (o == null || o.status.isTerminal || _busy) return;
    final map = await _openProductBarcodeScan();
    if (map == null || !mounted) return;
    final code = (map['code'] ?? map['barcode'] ?? '').toString().trim();
    if (code.isEmpty) {
      _snack(WhmsPickSerialRule.errorBarcodeMismatch);
      return;
    }
    final sorted = _sortedLines;
    final line = WhmsPickSerialRule.matchLineByProductCode(sorted, code) ??
        WhmsPickSerialRule.matchLineByProductCode(
          sorted,
          (map['id'] ?? '').toString(),
        );
    if (line == null) {
      _snack(WhmsPickSerialRule.errorBarcodeMismatch);
      return;
    }
    await _applyPickForLine(line);
  }

  Future<void> _applyPickForLine(WhmsOrderLineDto line) async {
    final o = _order;
    if (o == null || _busy) return;
    setState(() => _busy = true);
    try {
      String? serial = line.serialNo;
      if (_lineNeedsSerial(line) && !WhmsPickSerialRule.hasSerial(line)) {
        final scanned = await _scanRawBarcode();
        if (scanned == null || scanned.isEmpty) {
          _snack(WhmsPickSerialRule.errorSerialRequired);
          return;
        }
        serial = scanned;
      }
      final nextQty = (line.quantityDone + 1).clamp(0, line.quantity);
      final updated = await _store.updateLinePickScan(
        orderId: o.id,
        lineId: line.id,
        serialNo: serial,
        quantityDone: nextQty.toDouble(),
      );
      if (!mounted) return;
      if (updated == null) {
        _snack('whms.pick.load_failed');
        return;
      }
      setState(() => _order = updated);
      await _refreshProductRules();
    } on StateError catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('whms.pick.load_failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onScanSerialForLine(WhmsOrderLineDto line) async {
    final o = _order;
    if (o == null || o.status.isTerminal || _busy) return;
    if (!_lineNeedsSerial(line)) return;
    setState(() => _busy = true);
    try {
      final scanned = await _scanRawBarcode();
      if (scanned == null || scanned.isEmpty) {
        _snack(WhmsPickSerialRule.errorSerialRequired);
        return;
      }
      final nextQty = line.quantityDone > 0
          ? line.quantityDone
          : (line.quantityDone + 1).clamp(0, line.quantity).toDouble();
      final updated = await _store.updateLinePickScan(
        orderId: o.id,
        lineId: line.id,
        serialNo: scanned,
        quantityDone: nextQty,
      );
      if (!mounted) return;
      if (updated == null) {
        _snack('whms.pick.load_failed');
        return;
      }
      setState(() => _order = updated);
      await _refreshProductRules();
    } catch (_) {
      _snack('whms.pick.load_failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onComplete() async {
    final o = _order;
    if (o == null || _busy) return;
    if (!_canComplete) {
      _snack(WhmsPickSerialRule.errorSerialRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await _store.completePick(o.id);
      if (!mounted) return;
      if (updated == null) {
        _snack('whms.pick.load_failed');
        return;
      }
      setState(() => _order = updated);
      _snack('whms.pick.complete_ok');
    } on StateError catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(WhmsPickSerialRule.errorSerialRequired);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final o = _order;
    final title = o == null
        ? l10n.translate('whms.pick.title')
        : WhmsOrderListTile.displayCode(o);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        showCalculatorHome: false,
        actions: [
          if (o != null && !o.status.isTerminal)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.qr_code_scanner,
              tooltip: l10n.translate('whms.pick.scan_product'),
              onPressed: _busy ? null : _onScanProduct,
            ),
        ],
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
                  messageKey: 'whms.pick.missing',
                )
              : o.orderType != WhmsOrderType.pick
                  ? const WhmsOrderEmptyState(
                      messageKey: 'whms.pick.not_pick_type',
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildBody(context, o)),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: FilledButton(
                                onPressed: (!_canComplete || _busy)
                                    ? null
                                    : _onComplete,
                                child: Text(
                                  l10n.translate('whms.pick.complete'),
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

  Widget _buildBody(BuildContext context, WhmsOrderDto order) {
    final l10n = AppLocalization.of(context);
    final lines = _sortedLines;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      children: [
        Text(
          l10n.translate('whms.pick.route_hint'),
          style: TextStyle(
            fontSize: 12,
            color: FieldSalesDensTheme.muted(context),
          ),
        ),
        if (order.requireSerial) ...[
          const SizedBox(height: 4),
          Text(
            l10n.translate('whms.pick.order_serial_flag'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FieldSalesDensTheme.title(context),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (lines.isEmpty)
          Text(
            l10n.translate('whms.pick.lines_empty'),
            style: TextStyle(
              fontSize: 12,
              color: FieldSalesDensTheme.muted(context),
            ),
          )
        else
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _PickLineTile(
              line: lines[i],
              needsSerial: _lineNeedsSerial(lines[i]),
              onScanSerial: order.status.isTerminal || _busy
                  ? null
                  : () => _onScanSerialForLine(lines[i]),
              onTapPick: order.status.isTerminal || _busy
                  ? null
                  : () => _applyPickForLine(lines[i]),
            ),
          ],
      ],
    );
  }
}

/// Dens pick satırı — rota + seri durumu.
class _PickLineTile extends StatelessWidget {
  final WhmsOrderLineDto line;
  final bool needsSerial;
  final VoidCallback? onScanSerial;
  final VoidCallback? onTapPick;

  const _PickLineTile({
    required this.line,
    required this.needsSerial,
    this.onScanSerial,
    this.onTapPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = (line.productCode ?? '').trim();
    final name = (line.productName ?? '').trim();
    final loc = (line.locationCode ?? '').trim();
    final serial = (line.serialNo ?? '').trim();
    final route = line.routeSeq;
    final unit = (line.unitName ?? '').trim();
    final qtyText = unit.isEmpty
        ? '${line.quantityDone} / ${line.quantity}'
        : '${line.quantityDone} / ${line.quantity} $unit';
    final serialOk = !needsSerial || serial.isNotEmpty;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTapPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: serialOk
                  ? (isDark ? Colors.white24 : Colors.grey.shade300)
                  : const Color(0xFF375A7F),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (route != null) ...[
                    Text(
                      '#$route',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FieldSalesDensTheme.muted(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
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
                  if (needsSerial) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        serialOk
                            ? Icons.qr_code_2
                            : Icons.qr_code_scanner,
                        size: 18,
                        color: FieldSalesDensTheme.title(context),
                      ),
                      tooltip: l10n.translate('whms.pick.scan_serial'),
                      onPressed: onScanSerial,
                    ),
                  ],
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
                  '${l10n.translate('whms.pick.field_location')}: $loc',
                  style: TextStyle(
                    fontSize: 11,
                    color: FieldSalesDensTheme.muted(context),
                  ),
                ),
              ],
              if (needsSerial) ...[
                const SizedBox(height: 2),
                Text(
                  serial.isEmpty
                      ? l10n.translate('whms.pick.serial_missing')
                      : '${l10n.translate('whms.pick.field_serial')}: $serial',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: serial.isEmpty
                        ? const Color(0xFF375A7F)
                        : FieldSalesDensTheme.muted(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
