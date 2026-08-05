// Dosya Adı: vehicle_vision_screen.dart
// Açıklama: Araç fotoğrafı dens — kamera/galeri → AI → form → kaydet
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../model/vehicle_vision_result.dart';
import '../viewmodel/vehicle_vision_store.dart';

/// {@template vehicle_vision_screen}
/// Araç fotoğrafından plaka/marka/tür/renk çıkarımı.
/// Route: `/field-sales/vehicle-vision`
/// Görüntü loglanmaz.
/// {@endtemplate}
class VehicleVisionScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/vehicle-vision';

  /// Test inject
  final VehicleVisionStore? store;

  /// Kaydet sonrası plakayı `Navigator.pop` ile döndür (güne başlama)
  final bool returnPlateOnSave;

  /// {@macro vehicle_vision_screen}
  const VehicleVisionScreen({
    Key? key,
    this.store,
    this.returnPlateOnSave = false,
  }) : super(key: key);

  @override
  State<VehicleVisionScreen> createState() => _VehicleVisionScreenState();
}

class _VehicleVisionScreenState extends State<VehicleVisionScreen> {
  late final VehicleVisionStore _store =
      widget.store ?? VehicleVisionStore();
  final _picker = ImagePicker();

  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _busy = false;

  static const int maxSide = 1600;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _typeCtrl.dispose();
    _colorCtrl.dispose();
    _yearCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _t(String key) => AppLocalization.of(context).translate(key);

  void _syncControllers(VehicleVisionResult v) {
    _plateCtrl.text = v.plate;
    _brandCtrl.text = v.brand;
    _modelCtrl.text = v.model;
    _typeCtrl.text = v.type;
    _colorCtrl.text = v.color;
    _yearCtrl.text = v.year;
    _notesCtrl.text = v.notes;
  }

  VehicleVisionResult _fromControllers(VehicleVisionResult? base) {
    return (base ?? const VehicleVisionResult()).copyWith(
      plate: _plateCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
      color: _colorCtrl.text.trim(),
      year: _yearCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      manualOverride: true,
      confidence: 1,
    );
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
      await _store.analyzeBytes(bytes: resized, imageBase64: b64);
      final v = _store.state.vehicle;
      if (v != null) _syncControllers(v);
    } catch (_) {
      _store.setStatusKey('field_sales.ai_vehicle_vision.err_image');
      _store.setPhase(VehicleVisionPhase.idle);
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _save() async {
    if (_busy) return;
    final base = _store.state.vehicle;
    final edited = _fromControllers(base);
    if (edited.isUncertain &&
        (base?.isUncertain ?? false) &&
        !edited.manualOverride) {
      // controllers zaten override
    }
    setState(() => _busy = true);
    final ok = await _store.save(edited: edited);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      if (widget.returnPlateOnSave) {
        Navigator.of(context).pop(edited.plate.trim().toUpperCase());
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('field_sales.ai_vehicle_vision.saved'))),
      );
    }
  }

  Widget _denseField(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    TextCapitalization caps = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: ctrl,
        style: TextStyle(
          fontSize: 13,
          color: FieldSalesDensTheme.title(context),
        ),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
        textCapitalization: caps,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: TextInputAction.next,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _t('field_sales.stubs.vehicle_vision');
    final st = _store.state;
    final analyzing = st.phase == VehicleVisionPhase.analyzing || _busy;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.photo_library_outlined,
            tooltip: _t('field_sales.ai_vehicle_vision.gallery'),
            onPressed: analyzing
                ? null
                : () => _pick(ImageSource.gallery),
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.photo_camera_outlined,
            tooltip: _t('field_sales.ai_vehicle_vision.camera'),
            onPressed: analyzing
                ? null
                : () => _pick(ImageSource.camera),
          ),
        ],
      ),
      body: Column(
        children: [
          if (st.thumb != null)
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.memory(st.thumb!, fit: BoxFit.cover),
            ),
          if (analyzing)
            const LinearProgressIndicator(minHeight: 2),
          if (st.statusKey != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _t(st.statusKey!),
                  style: TextStyle(
                    fontSize: 12,
                    color: FieldSalesDensTheme.muted(context),
                  ),
                ),
              ),
            ),
          Expanded(
            child: st.vehicle == null && st.phase != VehicleVisionPhase.review
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _t('field_sales.ai_vehicle_vision.empty_hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: FieldSalesDensTheme.muted(context),
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                    children: [
                      if (st.vehicle?.isUncertain == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _t('field_sales.ai_vehicle_vision.uncertain'),
                            style: TextStyle(
                              fontSize: 12,
                              color: FieldSalesDensTheme.muted(context),
                            ),
                          ),
                        ),
                      _denseField(
                        _plateCtrl,
                        _t('field_sales.ai_vehicle_vision.plate'),
                        caps: TextCapitalization.characters,
                      ),
                      _denseField(
                        _brandCtrl,
                        _t('field_sales.ai_vehicle_vision.brand'),
                      ),
                      _denseField(
                        _modelCtrl,
                        _t('field_sales.ai_vehicle_vision.model'),
                      ),
                      _denseField(
                        _typeCtrl,
                        _t('field_sales.ai_vehicle_vision.type'),
                      ),
                      _denseField(
                        _colorCtrl,
                        _t('field_sales.ai_vehicle_vision.color'),
                      ),
                      _denseField(
                        _yearCtrl,
                        _t('field_sales.ai_vehicle_vision.year'),
                        keyboardType: TextInputType.number,
                        caps: TextCapitalization.none,
                      ),
                      _denseField(
                        _notesCtrl,
                        _t('field_sales.ai_vehicle_vision.notes'),
                        caps: TextCapitalization.sentences,
                      ),
                    ],
                  ),
          ),
          if (st.vehicle != null || st.phase == VehicleVisionPhase.review)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton(
                    onPressed: analyzing ? null : _save,
                    child: Text(
                      _t('field_sales.ai_vehicle_vision.save'),
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
