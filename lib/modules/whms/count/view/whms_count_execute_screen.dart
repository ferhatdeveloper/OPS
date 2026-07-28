// Dosya Adı: whms_count_execute_screen.dart
// Açıklama: Sayım emri yürütme dens — satır fiili + kamera barkod
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../field_sales/shared/view/field_sales_dens_theme.dart';

import 'package:flutter/services.dart';

import '../../../../core/init/navigation/routes.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../contract/whms_bridge_dto.dart';
import '../../contract/whms_route_map.dart';
import '../model/whms_count_order.dart';
import '../model/whms_count_result_line.dart';
import '../queue/whms_count_queue_bridge.dart';
import '../viewmodel/whms_count_order_store.dart';
import '../viewmodel/whms_count_session.dart';

/// Emir yükleyici (test inject).
typedef WhmsCountOrderLoader = Future<WhmsCountOrder?> Function(String orderId);

/// {@template whms_count_execute_screen}
/// Sayım yürütme dens — sistem vs fiili, barkod +1 / miktar dialog.
/// Route: `/whms/count/execute` (arguments: orderId [String] | WhmsCountOrder)
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WhmsCountExecuteScreen.routeName,
///   arguments: orderId,
/// );
/// ```
/// {@endtemplate}
class WhmsCountExecuteScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsCountExecute;

  /// [orderId]: Named route / ctor
  final String? orderId;

  /// Önceden yüklenmiş emir
  final WhmsCountOrder? initialOrder;

  /// Store inject
  final WhmsCountOrderStore? orderStore;

  /// Oturum inject
  final WhmsCountSession? session;

  /// Test loader
  final WhmsCountOrderLoader? loadOrder;

  /// {@macro whms_count_execute_screen}
  const WhmsCountExecuteScreen({
    super.key,
    this.orderId,
    this.initialOrder,
    this.orderStore,
    this.session,
    this.loadOrder,
  });

  @override
  State<WhmsCountExecuteScreen> createState() =>
      _WhmsCountExecuteScreenState();
}

class _WhmsCountExecuteScreenState extends State<WhmsCountExecuteScreen> {
  WhmsCountOrder? _order;
  List<WhmsCountResultLine> _lines = const [];
  String? _resultId;
  bool _loading = true;
  bool _busy = false;
  bool _loadStarted = false;

  WhmsCountOrderStore get _orderStore =>
      widget.orderStore ?? const WhmsCountOrderStore();

  WhmsCountSession get _session =>
      widget.session ?? WhmsCountSession(orderStore: _orderStore);

  bool get _isTerminal {
    final o = _order;
    if (o == null) return true;
    return o.status == WhmsCountOrderStatus.completed ||
        o.status == WhmsCountOrderStatus.cancelled ||
        o.approval == WhmsApprovalStatus.approved ||
        o.approval == WhmsApprovalStatus.synced;
  }

  double get _totalVariance {
    var v = 0.0;
    for (final l in _lines) {
      v += l.variance;
    }
    return v;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _loading = false;
      _loadStarted = true;
      _loadDraft();
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
    if (args is WhmsCountOrder) return args.id;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final id = (args['orderId'] ?? args['id'] ?? '').toString().trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  Future<void> _resolveAndLoad() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WhmsCountOrder) {
      setState(() {
        _order = args;
        _loading = false;
      });
      await _loadDraft();
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
          : await _orderStore.getById(id);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
      if (order != null) await _loadDraft();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _order = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadDraft() async {
    final o = _order;
    if (o == null) return;
    try {
      final draft = await _session.loadDraftLines(o.id);
      if (!mounted) return;
      setState(() {
        _resultId = draft.resultId;
        _lines = List<WhmsCountResultLine>.from(draft.lines);
      });
    } catch (_) {}
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

  Future<void> _persistDraft() async {
    final o = _order;
    if (o == null || _isTerminal) return;
    try {
      final row = await _session.saveDraft(
        order: o,
        lines: _lines,
        existingResultId: _resultId,
      );
      _resultId = row.id;
      final refreshed = await _orderStore.getById(o.id);
      if (refreshed != null && mounted) {
        setState(() => _order = refreshed);
      }
    } catch (_) {}
  }

  /// field_sales BarcodeScanScreen → ürün map.
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

  Future<void> _onScanBarcode() async {
    final o = _order;
    if (o == null || _isTerminal || _busy) return;
    final map = await _openProductBarcodeScan();
    if (map == null || !mounted) return;
    final productId = (map['id'] ?? '').toString().trim();
    final code = (map['code'] ?? map['barcode'] ?? '').toString().trim();
    if (code.isEmpty && productId.isEmpty) {
      _snack('whms.count.product_not_found');
      return;
    }
    await _applyScanProduct(
      productId: productId.isEmpty ? code : productId,
      productCode: code.isEmpty ? productId : code,
      productName: (map['name'] ?? '').toString().trim(),
      unitName: (map['unit'] ?? map['main_unit'] ?? '').toString().trim(),
    );
  }

  Future<void> _applyScanProduct({
    required String productId,
    required String productCode,
    String? productName,
    String? unitName,
  }) async {
    final o = _order;
    if (o == null) return;
    setState(() => _busy = true);
    try {
      final idx = _lines.indexWhere(
        (l) =>
            l.productId == productId ||
            l.productCode.toLowerCase() == productCode.toLowerCase(),
      );
      if (idx >= 0) {
        final cur = _lines[idx];
        final next = List<WhmsCountResultLine>.from(_lines);
        next[idx] = cur.copyWith(countedQty: cur.countedQty + 1);
        setState(() => _lines = next);
      } else {
        final sys = await _session.systemQtyFor(
          productId: productId,
          warehouseCode: o.warehouseCode,
        );
        final line = WhmsCountResultLine(
          productId: productId,
          productCode: productCode,
          systemQty: sys,
          countedQty: 1,
          locationCode: o.locationCode,
          unitName: (unitName == null || unitName.isEmpty) ? null : unitName,
          productName:
              (productName == null || productName.isEmpty) ? null : productName,
        );
        setState(() => _lines = [..._lines, line]);
      }
      await _persistDraft();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editQtyDialog(int index) async {
    if (_isTerminal || index < 0 || index >= _lines.length) return;
    final l10n = AppLocalization.of(context);
    final line = _lines[index];
    final ctrl = TextEditingController(
      text: line.countedQty == line.countedQty.roundToDouble()
          ? line.countedQty.toInt().toString()
          : line.countedQty.toString(),
    );
    final saved = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.translate('whms.count.qty_dialog'),
            style: const TextStyle(fontSize: 16),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.translate('whms.count.actual_qty'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () {
                final raw = ctrl.text.trim().replaceAll(',', '.');
                final v = double.tryParse(raw);
                if (v == null || v < 0) return;
                Navigator.pop(ctx, v);
              },
              child: Text(l10n.translate('common.save')),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (saved == null || !mounted) return;
    final next = List<WhmsCountResultLine>.from(_lines);
    next[index] = line.copyWith(countedQty: saved);
    setState(() => _lines = next);
    await _persistDraft();
  }

  Future<void> _complete() async {
    final o = _order;
    if (o == null || _isTerminal || _busy) return;
    if (_lines.isEmpty) {
      _snack('whms.count.lines_required');
      return;
    }
    setState(() => _busy = true);
    try {
      final outcome = await _session.complete(
        order: o,
        lines: _lines,
        existingResultId: _resultId,
      );
      if (!mounted) return;
      _resultId = outcome.result.id;
      final refreshed = await _orderStore.getById(o.id);
      setState(() {
        if (refreshed != null) _order = refreshed;
        _busy = false;
      });
      if (outcome.enqueue.status == WhmsCountEnqueueStatus.enqueued) {
        _snack('whms.count.enqueue_ok');
      } else if (outcome.enqueue.status == WhmsCountEnqueueStatus.skipped) {
        _snack('whms.count.enqueue_skip');
      } else {
        _snack('whms.count.complete_failed');
      }
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (e) {
      if (mounted) setState(() => _busy = false);
      _snack(e.message);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _snack('whms.count.complete_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final o = _order;
    final title = l10n.translate('whms.count.execute_title');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        showCalculatorHome: false,
        actions: [
          if (!_isTerminal)
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.qr_code_scanner,
              tooltip: l10n.translate('whms.count.scan_barcode'),
              onPressed: _busy ? null : _onScanBarcode,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : o == null
              ? Center(
                  child: Text(
                    l10n.translate('whms.count.load_failed'),
                    style: TextStyle(
                      fontSize: 13,
                      color: FieldSalesDensTheme.muted(context),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                      child: Text(
                        '${o.warehouseCode}'
                        '${o.locationCode == null || o.locationCode!.isEmpty ? '' : ' · ${o.locationCode}'}'
                        ' · ${l10n.translate('whms.count.variance')}: '
                        '${_totalVariance.toStringAsFixed(_totalVariance == _totalVariance.roundToDouble() ? 0 : 2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: FieldSalesDensTheme.muted(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _lines.isEmpty
                          ? Center(
                              child: Text(
                                l10n.translate('whms.count.lines_empty'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: FieldSalesDensTheme.muted(context),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 0, 10, 12),
                              itemCount: _lines.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                return _CountLineRow(
                                  line: _lines[index],
                                  systemLabel:
                                      l10n.translate('whms.count.system_qty'),
                                  actualLabel:
                                      l10n.translate('whms.count.actual_qty'),
                                  varianceLabel:
                                      l10n.translate('whms.count.variance'),
                                  onTap: _isTerminal
                                      ? null
                                      : () => _editQtyDialog(index),
                                );
                              },
                            ),
                    ),
                    if (!_isTerminal)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _complete,
                              child: Text(
                                l10n.translate('whms.count.complete'),
                                style: const TextStyle(fontSize: 14),
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

class _CountLineRow extends StatelessWidget {
  final WhmsCountResultLine line;
  final String systemLabel;
  final String actualLabel;
  final String varianceLabel;
  final VoidCallback? onTap;

  const _CountLineRow({
    required this.line,
    required this.systemLabel,
    required this.actualLabel,
    required this.varianceLabel,
    this.onTap,
  });

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final name = line.productName;
    final title = (name == null || name.isEmpty)
        ? line.productCode
        : '${line.productCode} · $name';

    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FieldSalesDensTheme.title(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$systemLabel: ${_fmt(line.systemQty)} · '
                '$actualLabel: ${_fmt(line.countedQty)} · '
                '$varianceLabel: ${_fmt(line.variance)}',
                style: TextStyle(
                  fontSize: 11,
                  color: FieldSalesDensTheme.muted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
