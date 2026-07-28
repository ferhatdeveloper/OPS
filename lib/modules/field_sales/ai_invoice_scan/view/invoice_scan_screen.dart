// Dosya Adı: invoice_scan_screen.dart
// Açıklama: Resim→Fatura dens — kamera/galeri → OCR → onay → fatura
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../invoices/viewmodel/invoice_provider.dart';
import '../../products/model/product_catalog_row.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../model/invoice_ocr_line.dart';
import '../model/invoice_ocr_result.dart';
import '../model/invoice_scan_doc_type.dart';
import '../viewmodel/invoice_scan_store.dart';

/// {@template invoice_scan_screen}
/// Fatura fotoğrafı OCR + kullanıcı onaylı fatura oluşturma.
/// Route: `/field-sales/invoice-scan`
/// Görüntü / key loglanmaz; sessiz otomatik fatura yok.
/// {@endtemplate}
class InvoiceScanScreen extends ConsumerStatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/invoice-scan';

  /// Test inject
  final InvoiceScanStore? store;

  /// Test katalog
  final List<ProductCatalogRow>? catalog;

  /// Test cariler
  final List<Map<String, dynamic>>? customers;

  /// {@macro invoice_scan_screen}
  const InvoiceScanScreen({
    Key? key,
    this.store,
    this.catalog,
    this.customers,
  }) : super(key: key);

  @override
  ConsumerState<InvoiceScanScreen> createState() => _InvoiceScanScreenState();
}

class _InvoiceScanScreenState extends ConsumerState<InvoiceScanScreen> {
  late final InvoiceScanStore _store =
      widget.store ?? InvoiceScanStore();
  final _picker = ImagePicker();

  List<ProductCatalogRow> _catalog = const [];
  List<Map<String, dynamic>> _customers = const [];
  bool _busy = false;

  static const int maxSide = 1600;

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  String _t(String key) => AppLocalization.of(context).translate(key);

  Future<void> _loadMasters() async {
    if (widget.catalog != null && widget.customers != null) {
      setState(() {
        _catalog = widget.catalog!;
        _customers = widget.customers!;
      });
      return;
    }
    try {
      final svc = await DatabaseService.getInstance();
      final db = await svc.getDatabase();
      final products = await db.query('products', limit: 2000);
      final customers = await db.query(
        'customers',
        columns: ['id', 'code', 'name'],
        limit: 3000,
      );
      if (!mounted) return;
      setState(() {
        _catalog = widget.catalog ??
            products.map(ProductCatalogRow.fromMap).toList();
        _customers = widget.customers ?? customers;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _store.setStatusKey('field_sales.ai_invoice_scan.catalog_empty');
      });
    }
  }

  Future<Uint8List> _resize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: maxSide,
    );
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (bd == null) return bytes;
    return bd.buffer.asUint8List();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: maxSide.toDouble(),
    );
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final raw = await file.readAsBytes();
      // Görüntü içeriği loglanmaz
      final resized = await _resize(raw);
      final b64 = base64Encode(resized);
      await _store.analyzeBytes(
        bytes: resized,
        imageBase64: b64,
        catalog: _catalog,
        customers: _customers,
      );
    } catch (_) {
      _store.setStatusKey('field_sales.ai_invoice_scan.err_image');
      _store.setPhase(InvoiceScanPhase.idle);
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _pickCustomer() async {
    if (_customers.isEmpty) {
      setState(() {
        _store.setStatusKey('field_sales.ai_invoice_scan.need_customer');
      });
      return;
    }
    final qCtrl = TextEditingController();
    var filtered = List<Map<String, dynamic>>.from(_customers);
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(_t('field_sales.ai_invoice_scan.party')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: qCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _t('field_sales.ai_invoice_scan.party'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) {
                        final q = v.trim().toLowerCase();
                        setLocal(() {
                          filtered = _customers.where((c) {
                            if (q.isEmpty) return true;
                            final name =
                                (c['name'] ?? '').toString().toLowerCase();
                            final code =
                                (c['code'] ?? '').toString().toLowerCase();
                            return name.contains(q) || code.contains(q);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 240,
                      child: ListView.separated(
                        itemCount: filtered.length.clamp(0, 80),
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          final label =
                              '${c['code'] ?? ''}  ${c['name'] ?? ''}'.trim();
                          return InkWell(
                            onTap: () => Navigator.pop(ctx, c),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_t('field_sales.ai_invoice_scan.cancel')),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null) return;
    _store.setCustomerMatch(
      InvoiceOcrCustomerMatch(
        customerId: (picked['id'] ?? '').toString(),
        customerCode: (picked['code'] ?? '').toString(),
        customerName: (picked['name'] ?? '').toString(),
        score: 1,
      ),
    );
    setState(() {});
  }

  Future<void> _editLine(int index) async {
    final row = _store.state.lineMatches[index];
    final nameCtrl = TextEditingController(text: row.line.name);
    final skuCtrl = TextEditingController(text: row.line.sku);
    final qtyCtrl = TextEditingController(
      text: row.line.quantity.toString(),
    );
    final unitCtrl = TextEditingController(text: row.line.unit);
    final priceCtrl = TextEditingController(
      text: row.line.unitPrice?.toString() ??
          row.line.effectiveUnitPrice.toString(),
    );
    final vatCtrl = TextEditingController(
      text: row.line.vatRate.toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('field_sales.ai_invoice_scan.manual_edit')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _denseField(nameCtrl, _t('field_sales.ai_invoice_scan.col_name')),
              _denseField(skuCtrl, _t('field_sales.ai_invoice_scan.col_sku')),
              _denseField(
                qtyCtrl,
                _t('field_sales.ai_invoice_scan.col_qty'),
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              _denseField(unitCtrl, _t('field_sales.ai_invoice_scan.col_unit')),
              _denseField(
                priceCtrl,
                _t('field_sales.ai_invoice_scan.col_price'),
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              _denseField(
                vatCtrl,
                _t('field_sales.ai_invoice_scan.col_vat'),
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('field_sales.ai_invoice_scan.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('field_sales.ai_invoice_scan.apply_edit')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
    final price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
    final vat = double.tryParse(vatCtrl.text.replaceAll(',', '.')) ?? 20;
    _store.updateLine(
      index,
      row.line.copyWith(
        name: nameCtrl.text.trim(),
        sku: skuCtrl.text.trim(),
        quantity: qty <= 0 ? 1 : qty,
        unit: unitCtrl.text.trim().isEmpty ? 'ADET' : unitCtrl.text.trim(),
        unitPrice: price,
        vatRate: vat,
        manualOverride: true,
      ),
    );
    setState(() {});
  }

  Widget _denseField(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      textCapitalization: TextCapitalization.sentences,
      keyboardType: keyboard ?? TextInputType.text,
      textInputAction: TextInputAction.next,
    );
  }

  Future<void> _confirmCreate() async {
    final s = _store.state;
    if (s.phase != InvoiceScanPhase.review) return;
    if (_busy) return;

    final uncertain = s.lineMatches.where((e) => e.line.isUncertain).length;
    if (uncertain > 0 && !s.userConfirmed) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_t('field_sales.ai_invoice_scan.confirm_title')),
          content: Text(
            _t('field_sales.ai_invoice_scan.confirm_body')
                .replaceAll('{count}', '$uncertain'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('field_sales.ai_invoice_scan.fix')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('field_sales.ai_invoice_scan.confirm_ok')),
            ),
          ],
        ),
      );
      if (ok != true) return;
      _store.markConfirmed();
    } else {
      _store.markConfirmed();
    }

    final customerId = s.customerMatch.customerId?.trim() ?? '';
    if (customerId.isEmpty) {
      setState(() {
        _store.setStatusKey('field_sales.ai_invoice_scan.need_customer');
      });
      return;
    }

    final matched = s.lineMatches.where((e) => e.hasProductMatch).toList();
    if (matched.isEmpty) {
      setState(() {
        _store.setStatusKey('field_sales.ai_invoice_scan.need_products');
      });
      return;
    }

    setState(() {
      _busy = true;
      _store.setPhase(InvoiceScanPhase.saving);
    });

    try {
      final notifier = ref.read(invoiceProvider.notifier);
      notifier.discardDraft();
      notifier.startNewInvoice(
        customerId,
        invoiceType: s.docType.invoiceTypeKey,
      );
      for (final row in matched) {
        await notifier.addItem(
          row.matchedProductId!,
          row.matchedProductName ?? row.line.name,
          row.line.effectiveUnitPrice,
          row.line.quantity,
          vatRate: row.line.vatRate,
          unitName: row.line.unit,
        );
      }
      final notes = [
        if (s.draft?.documentNo.isNotEmpty == true)
          'OCR:${s.draft!.documentNo}',
        if (s.draft?.documentDate.isNotEmpty == true)
          s.draft!.documentDate,
        'ai_invoice_scan',
      ].join(' ');
      final success = await notifier.saveInvoice(notes);
      if (!mounted) return;
      if (!success) {
        final err = ref.read(invoiceProvider).error;
        setState(() {
          _busy = false;
          _store.setPhase(InvoiceScanPhase.review);
          _store.setStatusKey(err ?? 'field_sales.ai_invoice_scan.err_save');
        });
        return;
      }
      setState(() {
        _busy = false;
        _store.resetReview();
        _store.setStatusKey('field_sales.ai_invoice_scan.saved');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _store.setPhase(InvoiceScanPhase.review);
        _store.setStatusKey('field_sales.ai_invoice_scan.err_save');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _t('field_sales.stubs.invoice_scan');
    final s = _store.state;
    final primary = FieldSalesDensAppBar.primaryColor;
    final onMuted = FieldSalesDensTheme.muted(context);
    final onBody = FieldSalesDensTheme.title(context);

    final chipItems = InvoiceScanDocType.values
        .map(
          (t) => FieldSalesDensChipItem(
            label: _t(t.labelKey),
            selected: s.docType == t,
            onTap: () {
              if (_busy) return;
              setState(() => _store.setDocType(t));
            },
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.photo_library_outlined,
            tooltip: _t('field_sales.ai_invoice_scan.gallery'),
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.photo_camera_outlined,
            tooltip: _t('field_sales.ai_invoice_scan.camera'),
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: FieldSalesDensChipRow(items: chipItems),
          ),
        ),
      ),
      body: Column(
        children: [
          if (s.thumb != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: SizedBox(
                height: 72,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    s.thumb!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          if (s.statusKey != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
              child: Text(
                _t(s.statusKey!),
                style: TextStyle(fontSize: 12, color: onMuted),
              ),
            ),
          if (s.pendingQueued)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Text(
                _t('field_sales.ai_invoice_scan.queued'),
                style: TextStyle(fontSize: 12, color: primary),
              ),
            ),
          if (_busy || s.phase == InvoiceScanPhase.analyzing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (s.phase == InvoiceScanPhase.review && s.draft != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
              child: InkWell(
                onTap: _busy ? null : _pickCustomer,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _partySummary(s),
                    style: TextStyle(fontSize: 12, color: onBody),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
              child: Text(
                _t('field_sales.ai_invoice_scan.correct_question'),
                style: TextStyle(fontSize: 13, color: onBody),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                itemCount: s.lineMatches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (ctx, i) => _lineTile(s.lineMatches[i], i, primary),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() => _store.resetReview());
                              },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          foregroundColor: primary,
                          side: BorderSide(color: primary),
                        ),
                        child: Text(
                          _t('field_sales.ai_invoice_scan.fix'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _confirmCreate,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          backgroundColor: primary,
                        ),
                        child: Text(
                          _t('field_sales.ai_invoice_scan.confirm'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (!_busy && s.phase == InvoiceScanPhase.idle)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _t('field_sales.ai_invoice_scan.empty_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: onMuted),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  String _partySummary(InvoiceScanState s) {
    final d = s.draft!;
    final parts = <String>[];
    final match = s.customerMatch;
    if (match.hasMatch) {
      parts.add(
        '${_t('field_sales.ai_invoice_scan.party')}: '
        '${match.customerName ?? d.partyName}'
        '${match.customerCode != null && match.customerCode!.isNotEmpty ? ' (${match.customerCode})' : ''}',
      );
    } else if (d.partyName.isNotEmpty) {
      parts.add(
        '${_t('field_sales.ai_invoice_scan.party')}: ${d.partyName} '
        '(${_t('field_sales.ai_invoice_scan.no_customer')})',
      );
    }
    if (d.documentNo.isNotEmpty) {
      parts.add('${_t('field_sales.ai_invoice_scan.doc_no')}: ${d.documentNo}');
    }
    if (d.documentDate.isNotEmpty) {
      parts.add('${_t('field_sales.ai_invoice_scan.doc_date')}: ${d.documentDate}');
    }
    return parts.join(' · ');
  }

  Widget _lineTile(InvoiceOcrLineMatch row, int index, Color primary) {
    final uncertain = row.line.isUncertain;
    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => _editLine(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: uncertain
                  ? Colors.orange.withValues(alpha: 0.7)
                  : primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.line.name,
                style: TextStyle(
                  fontSize: 13,
                  color: FieldSalesDensTheme.title(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${row.line.quantity} ${row.line.unit} × '
                '${row.line.effectiveUnitPrice.toStringAsFixed(2)}'
                '  KDV %${row.line.vatRate.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  color: FieldSalesDensTheme.muted(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.hasProductMatch
                    ? '${_t('field_sales.ai_invoice_scan.matched')}: '
                        '${row.matchedProductCode} ${row.matchedProductName}'
                    : _t('field_sales.ai_invoice_scan.no_product'),
                style: TextStyle(
                  fontSize: 11,
                  color: row.hasProductMatch
                      ? primary
                      : FieldSalesDensTheme.muted(context),
                ),
              ),
              if (uncertain)
                Text(
                  _t('field_sales.ai_invoice_scan.uncertain'),
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
