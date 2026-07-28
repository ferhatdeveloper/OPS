// Dosya Adı: competitor_shelf_vision_screen.dart
// Açıklama: Raf/rakip fiyat vision dens — kamera/galeri → analiz → karşılaştırma
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../../merchandising/engine/competitor_analysis_service.dart';
import '../../merchandising/model/competitor_model.dart';
import '../../products/model/product_catalog_row.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../engine/price_text_parser.dart';
import '../engine/shelf_vision_analyzer.dart';
import '../model/shelf_price_line.dart';

/// {@template competitor_shelf_vision_screen}
/// Tek fotoğraftan ürün+fiyat; yerel katalog fuzzy karşılaştırma.
/// Route: `/field-sales/competitor-shelf-vision`
/// Görüntü loglanmaz.
/// {@endtemplate}
class CompetitorShelfVisionScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/competitor-shelf-vision';

  /// Test inject
  final ShelfVisionAnalyzer? analyzer;

  /// Test inject katalog
  final List<ProductCatalogRow>? catalog;

  /// {@macro competitor_shelf_vision_screen}
  const CompetitorShelfVisionScreen({
    Key? key,
    this.analyzer,
    this.catalog,
  }) : super(key: key);

  @override
  State<CompetitorShelfVisionScreen> createState() =>
      _CompetitorShelfVisionScreenState();
}

class _CompetitorShelfVisionScreenState
    extends State<CompetitorShelfVisionScreen> {
  late final ShelfVisionAnalyzer _analyzer =
      widget.analyzer ?? ShelfVisionAnalyzer();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  List<ProductCatalogRow> _catalog = const [];
  List<ShelfPriceComparison> _rows = const [];
  bool _busy = false;
  String? _statusKey;
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  String _t(String key) => AppLocalization.of(context).translate(key);

  Future<void> _loadCatalog() async {
    if (widget.catalog != null) {
      setState(() => _catalog = widget.catalog!);
      return;
    }
    try {
      final svc = await DatabaseService.getInstance();
      final db = await svc.getDatabase();
      final maps = await db.query('products', limit: 2000);
      final rows = maps.map(ProductCatalogRow.fromMap).toList();
      if (!mounted) return;
      setState(() => _catalog = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusKey = 'field_sales.ai_vision.catalog_empty');
    }
  }

  /// Yüksek çözünürlük sınırı (max kenar)
  static const int maxSide = 1600;

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
    setState(() {
      _busy = true;
      _statusKey = null;
      _rows = const [];
    });
    try {
      final raw = await file.readAsBytes();
      // Görüntü içeriği loglanmaz
      final resized = await _resize(raw);
      final b64 = base64Encode(resized);
      final result = await _analyzer.analyzeImage(
        imageBase64: b64,
        imageMimeType: 'image/jpeg',
      );
      if (!mounted) return;
      if (!result.isOk) {
        setState(() {
          _busy = false;
          _statusKey = result.l10nKey ?? 'ai.request_failed';
          _thumb = resized;
        });
        return;
      }
      final compared = _analyzer.compareToCatalog(
        lines: result.lines,
        catalog: _catalog,
      );
      setState(() {
        _busy = false;
        _rows = compared;
        _thumb = resized;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusKey = 'field_sales.ai_vision.err_image';
      });
    }
  }

  Future<void> _editLine(int index) async {
    final row = _rows[index];
    final nameCtrl = TextEditingController(text: row.line.name);
    final skuCtrl = TextEditingController(text: row.line.sku);
    final priceCtrl = TextEditingController(
      text: row.line.price?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('field_sales.ai_vision.manual_edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: _t('field_sales.ai_vision.col_name'),
              ),
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: skuCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: _t('field_sales.ai_vision.col_sku'),
              ),
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: priceCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: _t('field_sales.ai_vision.col_price'),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('field_sales.ai_reports.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('field_sales.ai_vision.apply_edit')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final edited = row.line.copyWith(
      name: nameCtrl.text.trim(),
      sku: skuCtrl.text.trim(),
      price: PriceTextParser.parse(priceCtrl.text) ?? row.line.price,
      confidence: 1,
      manualOverride: true,
    );
    final compared = _analyzer.compareToCatalog(
      lines: [edited],
      catalog: _catalog,
    );
    setState(() {
      final next = List<ShelfPriceComparison>.from(_rows);
      next[index] = compared.first;
      _rows = next;
    });
  }

  Future<void> _saveOptional() async {
    if (_rows.isEmpty || _busy) return;
    final uncertainIdx = <int>[];
    for (var i = 0; i < _rows.length; i++) {
      if (_rows[i].line.isUncertain) uncertainIdx.add(i);
    }
    if (uncertainIdx.isNotEmpty) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_t('field_sales.ai_vision.confirm_uncertain_title')),
          content: Text(
            _t('field_sales.ai_vision.confirm_uncertain_body')
                .replaceAll('{count}', '${uncertainIdx.length}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(_t('field_sales.ai_reports.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'approve'),
              child: Text(_t('field_sales.ai_vision.confirm_uncertain_ok')),
            ),
          ],
        ),
      );
      if (action != 'approve' || !mounted) {
        setState(() {
          _statusKey = 'field_sales.ai_vision.need_manual_review';
        });
        return;
      }
      setState(() {
        final next = List<ShelfPriceComparison>.from(_rows);
        for (final i in uncertainIdx) {
          final r = next[i];
          next[i] = ShelfPriceComparison(
            line: r.line.copyWith(manualOverride: true, confidence: 1),
            matchedProductId: r.matchedProductId,
            matchedProductCode: r.matchedProductCode,
            matchedProductName: r.matchedProductName,
            ourPrice: r.ourPrice,
            matchScore: r.matchScore,
          );
        }
        _rows = next;
      });
    }
    setState(() => _busy = true);
    try {
      final svc = CompetitorAnalysisService();
      for (final row in _rows) {
        final id = _uuid.v4();
        final dbSvc = await DatabaseService.getInstance();
        final db = await dbSvc.getDatabase();
        await db.insert('competitor_products', {
          'id': id,
          'name': row.line.name,
          'brand': row.matchedProductName ?? '',
          'category': row.line.sku,
          'price_reference': row.line.price ?? 0,
        });
        await svc.saveObservation(
          CompetitorObservationModel(
            id: _uuid.v4(),
            visitId: 'shelf_vision',
            competitorProductId: id,
            observedPrice: row.line.price,
            hasStock: true,
            onPromotion: false,
            notes: row.matchedProductCode == null
                ? 'vision'
                : 'match:${row.matchedProductCode}',
            createdAt: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusKey = 'field_sales.ai_vision.saved';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusKey = 'field_sales.ai_vision.err_save';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _t('field_sales.stubs.competitor_shelf_vision');
    return Scaffold(
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.photo_library_outlined,
            tooltip: _t('field_sales.ai_vision.gallery'),
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.photo_camera_outlined,
            tooltip: _t('field_sales.ai_vision.camera'),
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_thumb != null)
            SizedBox(
              height: 72,
              width: double.infinity,
              child: Image.memory(_thumb!, fit: BoxFit.cover),
            ),
          if (_statusKey != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(_t(_statusKey!), style: const TextStyle(fontSize: 12)),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _t('field_sales.ai_vision.results'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_rows.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _saveOptional,
                      child: Text(
                        _t('field_sales.ai_vision.save'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _t('field_sales.ai_vision.empty_hint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      final diff = r.priceDiffPercent;
                      final uncertain = r.line.isUncertain;
                      return InkWell(
                        onTap: () => _editLine(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: FieldSalesDensAppBar.primaryColor
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.line.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (uncertain)
                                    Text(
                                      _t('field_sales.ai_vision.uncertain'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                ],
                              ),
                              if (r.line.sku.isNotEmpty)
                                Text(
                                  '${_t('field_sales.ai_vision.col_sku')}: '
                                  '${r.line.sku}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              Text(
                                '${_t('field_sales.ai_vision.col_price')}: '
                                '${r.line.price?.toStringAsFixed(2) ?? '-'} '
                                '${r.line.currency}'
                                ' · conf ${(r.line.confidence * 100).round()}%',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (r.matchedProductName != null)
                                Text(
                                  '${_t('field_sales.ai_vision.our_match')}: '
                                  '${r.matchedProductCode} ${r.matchedProductName}'
                                  ' · ${r.ourPrice?.toStringAsFixed(2) ?? '-'}'
                                  '${diff == null ? '' : ' · ${diff.toStringAsFixed(1)}%'}',
                                  style: const TextStyle(fontSize: 11),
                                )
                              else
                                Text(
                                  _t('field_sales.ai_vision.no_match'),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              Text(
                                _t('field_sales.ai_vision.tap_edit'),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
