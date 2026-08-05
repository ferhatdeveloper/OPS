// Dosya Adı: social_media_image_screen.dart
// Açıklama: Ürün sosyal medya görseli dens — preset chip + metin + oluştur
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/ai/ai_image.dart';
import '../../../../core/localization/app_localization.dart';
import '../../products/model/product_catalog_row.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../engine/social_media_image_service.dart';
import '../engine/social_media_prompt_builder.dart';
import '../model/social_image_size_preset.dart';

/// {@template social_media_image_screen}
/// Ürün bazlı sosyal medya görsel üretimi dens ekranı.
/// Route: `/field-sales/social-media-image`
///
/// Arguments: [ProductCatalogRow] veya map.
/// {@endtemplate}
class SocialMediaImageScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/social-media-image';

  /// [product]: Kaynak ürün
  final ProductCatalogRow? product;

  /// [service]: Test inject
  final SocialMediaImageService? service;

  /// {@macro social_media_image_screen}
  const SocialMediaImageScreen({
    Key? key,
    this.product,
    this.service,
  }) : super(key: key);

  /// Named route args → ürün
  static ProductCatalogRow? rowFromArgs(Object? args) {
    if (args is ProductCatalogRow) return args;
    if (args is Map) {
      return ProductCatalogRow.fromMap(Map<String, dynamic>.from(args));
    }
    return null;
  }

  @override
  State<SocialMediaImageScreen> createState() => _SocialMediaImageScreenState();
}

class _SocialMediaImageScreenState extends State<SocialMediaImageScreen> {
  late final SocialMediaImageService _service =
      widget.service ?? SocialMediaImageService();
  late final TextEditingController _copyCtrl;
  SocialImageSizePreset _preset = SocialImageSizePreset.instagramSquare;
  bool _busy = false;
  bool _drafting = false;
  Uint8List? _imageBytes;
  String? _statusKey;
  String? _statusDetail;

  ProductCatalogRow? get _product => widget.product;

  @override
  void initState() {
    super.initState();
    final p = _product;
    _copyCtrl = TextEditingController(
      text: SocialMediaPromptBuilder.seedAdCopy(
        productName: p?.name ?? '',
        priceText: p?.priceText ?? '',
        unit: p?.unit ?? 'ADET',
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _draftCopy());
  }

  @override
  void dispose() {
    _copyCtrl.dispose();
    super.dispose();
  }

  String _t(String key) => AppLocalization.of(context).translate(key);

  SocialMediaPromptInput _input() {
    final p = _product;
    return SocialMediaPromptInput(
      productName: p?.name ?? '',
      priceText: p?.priceText ?? '',
      unit: p?.unit ?? 'ADET',
      adCopy: _copyCtrl.text,
      preset: _preset,
      category: p?.category ?? '',
      productImageUrl: p?.imageUrl ?? '',
    );
  }

  Future<void> _draftCopy() async {
    if (_product == null || _drafting) return;
    setState(() => _drafting = true);
    try {
      final text = await _service.draftAdCopy(_input());
      if (!mounted) return;
      if (_copyCtrl.text.trim() ==
          SocialMediaPromptBuilder.seedAdCopy(
            productName: _product!.name,
            priceText: _product!.priceText,
            unit: _product!.unit,
          ).trim()) {
        _copyCtrl.text = text;
      }
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  Future<void> _generate() async {
    if (_busy) return;
    if ((_product?.name.trim() ?? '').isEmpty) {
      setState(() => _statusKey = 'field_sales.ai_social.err_product');
      return;
    }
    setState(() {
      _busy = true;
      _statusKey = null;
      _statusDetail = null;
      _imageBytes = null;
    });
    try {
      final result = await _service.generateImage(_input());
      if (!mounted) return;
      if (result.isOk) {
        setState(() {
          _imageBytes = result.bytes;
          // Claude → OpenRouter/OpenAI fallback bilgi mesajı
          _statusKey = result.l10nKey == 'ai.image_fallback_from_claude'
              ? result.l10nKey
              : null;
          _statusDetail = null;
        });
        return;
      }
      setState(() {
        _statusKey = result.l10nKey ?? 'ai.request_failed';
        if (result.status == AiImageStatus.unsupported) {
          _statusKey = 'ai.image_unsupported';
        }
        final detail = result.errorMessage?.trim();
        _statusDetail =
            (detail != null && detail.isNotEmpty) ? detail : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusKey = 'ai.request_failed';
        _statusDetail = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    try {
      await _service.shareImage(
        bytes: bytes,
        fileName: 'social_${_preset.storageKey}.png',
        text: _copyCtrl.text.trim(),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('field_sales.ai_social.err_share'))),
      );
    }
  }

  Future<void> _save() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    try {
      await _service.saveLocally(
        bytes: bytes,
        productName: _product?.name ?? 'product',
        preset: _preset,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('field_sales.ai_social.saved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('field_sales.ai_social.err_save'))),
      );
    }
  }

  InputDecoration _denseDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _t('field_sales.ai_social.title');
    final product = _product;
    final chipItems = SocialImageSizePreset.values
        .map(
          (p) => FieldSalesDensChipItem(
            label: _t(p.labelKey),
            selected: _preset == p,
            onTap: () => setState(() => _preset = p),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          if (_imageBytes != null) ...[
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.save_alt,
              onPressed: _busy ? null : _save,
              tooltip: _t('field_sales.ai_social.save'),
            ),
            FieldSalesDensAppBar.densIconButton(
              icon: Icons.share_outlined,
              onPressed: _busy ? null : _share,
              tooltip: _t('field_sales.ai_social.share'),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
        children: [
          if (product != null) ...[
            Text(
              product.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FieldSalesDensTheme.title(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${product.code} · ${product.priceText} · ${product.unit}',
              style: TextStyle(
                fontSize: 11,
                color: FieldSalesDensTheme.muted(context),
              ),
            ),
            const SizedBox(height: 8),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _t('field_sales.ai_social.err_product'),
                style: TextStyle(
                  fontSize: 12,
                  color: FieldSalesDensTheme.muted(context),
                ),
              ),
            ),
          Text(
            _t('field_sales.ai_social.preset_label'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF375A7F),
            ),
          ),
          const SizedBox(height: 4),
          FieldSalesDensChipRow(items: chipItems),
          const SizedBox(height: 8),
          TextFormField(
            controller: _copyCtrl,
            style: const TextStyle(fontSize: 13),
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            decoration: _denseDeco(_t('field_sales.ai_social.copy_label')),
          ),
          if (_drafting)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _busy || product == null ? null : _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF375A7F),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_t('field_sales.ai_social.generate')),
            ),
          ),
          if (_statusKey != null) ...[
            const SizedBox(height: 8),
            Text(
              _t(_statusKey!),
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
            if (_statusDetail != null) ...[
              const SizedBox(height: 4),
              Text(
                _statusDetail!,
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
            ],
          ],
          if (_imageBytes != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(
                aspectRatio: _preset.width / _preset.height,
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _save,
                      child: Text(
                        _t('field_sales.ai_social.save'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _share,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF375A7F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: Text(
                        _t('field_sales.ai_social.share'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
