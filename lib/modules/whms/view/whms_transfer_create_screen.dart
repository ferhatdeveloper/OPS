// Dosya Adı: whms_transfer_create_screen.dart
// Açıklama: WHMS transfer draft dens — kaynak/hedef + ürün satırları / barkod
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/app_localization.dart';
import '../../field_sales/shared/view/catalog_barcode_actions.dart';
import '../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../field_sales/stock/model/warehouse_master_seed.dart';
import '../model/whms_order_line_dto.dart';
import '../model/whms_order_type.dart';
import '../viewmodel/whms_order_store.dart';

/// {@template whms_transfer_draft_line}
/// Transfer oluşturma dens satırı (kod · miktar · lot opsiyonel).
/// {@endtemplate}
class WhmsTransferDraftLine {
  /// [productId]: Ürün id
  final String productId;

  /// [productCode]: Ürün kodu
  final String productCode;

  /// [productName]: Ürün adı
  final String productName;

  /// [unitName]: Birim
  final String unitName;

  /// [quantity]: Miktar
  double quantity;

  /// [lotNo]: Lot (opsiyonel)
  String lotNo;

  /// {@macro whms_transfer_draft_line}
  WhmsTransferDraftLine({
    required this.productId,
    required this.productCode,
    required this.productName,
    this.unitName = 'ADET',
    this.quantity = 1,
    this.lotNo = '',
  });
}

/// {@template whms_transfer_create_screen}
/// Transfer emri dens oluşturma — ambar + çoklu ürün (liste / kamera barkod).
/// Kaydet → [WhmsOrderStore.createDraft] `type=transfer` + satırlar.
///
/// Kullanım örneği:
/// ```dart
/// final order = await Navigator.push<WhmsOrderDto>(
///   context,
///   MaterialPageRoute(builder: (_) => const WhmsTransferCreateScreen()),
/// );
/// ```
/// {@endtemplate}
class WhmsTransferCreateScreen extends StatefulWidget {
  /// [store]: Test inject
  final WhmsOrderStore? store;

  /// {@macro whms_transfer_create_screen}
  const WhmsTransferCreateScreen({
    super.key,
    this.store,
  });

  @override
  State<WhmsTransferCreateScreen> createState() =>
      _WhmsTransferCreateScreenState();
}

class _WhmsTransferCreateScreenState extends State<WhmsTransferCreateScreen> {
  late String _from;
  late String _to;
  final List<WhmsTransferDraftLine> _lines = [];
  final Map<int, TextEditingController> _qtyCtrls = {};
  final Map<int, TextEditingController> _lotCtrls = {};
  bool _saving = false;

  WhmsOrderStore get _store => widget.store ?? const WhmsOrderStore();

  List<WarehouseMasterSeedRow> get _seeds => WarehouseMasterSeed.defaultRows;

  @override
  void initState() {
    super.initState();
    final seeds = _seeds;
    _from = seeds.first.code;
    _to = seeds.length > 1 ? seeds[1].code : seeds.first.code;
  }

  @override
  void dispose() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    for (final c in _lotCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _qtyCtrl(int index) {
    return _qtyCtrls.putIfAbsent(index, () {
      final q = _lines[index].quantity;
      final text = q == q.roundToDouble()
          ? q.toInt().toString()
          : q.toString();
      return TextEditingController(text: text);
    });
  }

  TextEditingController _lotCtrl(int index) {
    return _lotCtrls.putIfAbsent(
      index,
      () => TextEditingController(text: _lines[index].lotNo),
    );
  }

  void _syncLineFromCtrls(int index) {
    if (index < 0 || index >= _lines.length) return;
    final qty = double.tryParse(
          _qtyCtrls[index]?.text.trim().replaceAll(',', '.') ?? '',
        ) ??
        0;
    _lines[index].quantity = qty;
    _lines[index].lotNo = _lotCtrls[index]?.text.trim() ?? '';
  }

  void _rebuildControllers() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    for (final c in _lotCtrls.values) {
      c.dispose();
    }
    _qtyCtrls.clear();
    _lotCtrls.clear();
  }

  Future<void> _addProduct({required bool camera}) async {
    final map = await openFieldSalesBarcodeScan(
      context,
      autoScan: camera,
      selectionMode: true,
    );
    if (map == null || !mounted) return;
    final id = (map['id'] ?? '').toString().trim();
    final code = (map['code'] ?? map['barcode'] ?? '').toString().trim();
    if (id.isEmpty && code.isEmpty) return;
    final name = (map['name'] ?? '').toString().trim();
    final unit = (map['unit'] ?? map['main_unit'] ?? 'ADET').toString();

    setState(() {
      final existing = _lines.indexWhere(
        (l) =>
            (id.isNotEmpty && l.productId == id) ||
            (code.isNotEmpty &&
                l.productCode.toLowerCase() == code.toLowerCase() &&
                l.lotNo.trim().isEmpty),
      );
      if (existing >= 0) {
        _syncLineFromCtrls(existing);
        _lines[existing].quantity += 1;
        _qtyCtrls[existing]?.text = _formatQty(_lines[existing].quantity);
      } else {
        _lines.add(
          WhmsTransferDraftLine(
            productId: id.isEmpty ? code : id,
            productCode: code.isEmpty ? id : code,
            productName: name,
            unitName: unit,
            quantity: 1,
          ),
        );
      }
    });
  }

  String _formatQty(double q) {
    return q == q.roundToDouble() ? q.toInt().toString() : q.toString();
  }

  void _removeLine(int index) {
    setState(() {
      _syncLineFromCtrls(index);
      _lines.removeAt(index);
      _rebuildControllers();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalization.of(context);
    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('whms.transfer.same_warehouse')),
        ),
      );
      return;
    }
    for (var i = 0; i < _lines.length; i++) {
      _syncLineFromCtrls(i);
    }
    final valid = _lines
        .where((l) => l.productCode.trim().isNotEmpty && l.quantity > 0)
        .toList(growable: false);
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('whms.transfer.lines_required')),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final draftLines = <WhmsOrderLineDto>[];
      for (var i = 0; i < valid.length; i++) {
        final l = valid[i];
        draftLines.add(
          WhmsOrderLineDto(
            id: const Uuid().v4(),
            orderId: '',
            lineNo: i + 1,
            productId: l.productId,
            productCode: l.productCode,
            productName: l.productName.isEmpty ? null : l.productName,
            quantity: l.quantity,
            unitName: l.unitName,
            lotNo: l.lotNo.trim().isEmpty ? null : l.lotNo.trim(),
          ),
        );
      }
      final order = await _store.createDraft(
        orderType: WhmsOrderType.transfer,
        fromWarehouseCode: _from,
        toWarehouseCode: _to,
        warehouseCode: _from,
        lines: draftLines,
      );
      if (!mounted) return;
      Navigator.pop(context, order);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('whms.transfer.save_failed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.transfer.create'),
        showCalculatorHome: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _from,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: l10n.translate('whms.transfer.from'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      for (final s in _seeds)
                        DropdownMenuItem(
                          value: s.code,
                          child: Text(
                            s.code,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _from = v);
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _to,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: l10n.translate('whms.transfer.to'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      for (final s in _seeds)
                        DropdownMenuItem(
                          value: s.code,
                          child: Text(
                            s.code,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _to = v);
                          },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _addProduct(camera: false),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: Text(
                      l10n.translate('whms.transfer.add_from_list'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _addProduct(camera: true),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text(
                      l10n.translate('whms.transfer.add_from_camera'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _lines.isEmpty
                ? Center(
                    child: Text(
                      l10n.translate('whms.transfer.lines_hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    itemCount: _lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    line.productCode,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: l10n.translate(
                                    'whms.transfer.remove_line',
                                  ),
                                  onPressed: _saving
                                      ? null
                                      : () => _removeLine(index),
                                ),
                              ],
                            ),
                            if (line.productName.isNotEmpty)
                              Text(
                                line.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _qtyCtrl(index),
                                    enabled: !_saving,
                                    style: const TextStyle(fontSize: 13),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,]'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: l10n.translate(
                                        'whms.transfer.quantity',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _lotCtrl(index),
                                    enabled: !_saving,
                                    style: const TextStyle(fontSize: 13),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: l10n.translate(
                                        'whms.transfer.lot_optional',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.translate('whms.transfer.save'),
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
