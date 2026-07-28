// Dosya Adı: company_branding_logo.dart
// Açıklama: Firma rapor logosu — eksikse l10n yedek metin
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../reports/viewmodel/report_logo_store.dart';

/// {@template company_branding_logo}
/// Yerel/merkez firma logosunu gösterir; yoksa [fallbackKey] metni.
///
/// [showFallback] false ise logo yokken boş widget döner (dashboard dens).
///
/// Kullanım örneği:
/// ```dart
/// CompanyBrandingLogo(height: 26, showFallback: false)
/// ```
/// {@endtemplate}
class CompanyBrandingLogo extends StatefulWidget {
  /// [height]: Görsel yüksekliği
  final double height;

  /// [store]: Logo deposu (test inject)
  final ReportLogoStore? store;

  /// [fallbackKey]: l10n anahtarı
  final String fallbackKey;

  /// [showFallback]: Logo yokken metin göster (false → gizle)
  final bool showFallback;

  /// {@macro company_branding_logo}
  const CompanyBrandingLogo({
    Key? key,
    this.height = 26,
    this.store,
    this.fallbackKey = 'branding.company_logo_missing',
    this.showFallback = true,
  }) : super(key: key);

  @override
  State<CompanyBrandingLogo> createState() => _CompanyBrandingLogoState();
}

class _CompanyBrandingLogoState extends State<CompanyBrandingLogo> {
  Uint8List? _bytes;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = widget.store ?? ReportLogoStore();
    try {
      final has = await store.hasLogo();
      if (!has) {
        if (mounted) setState(() => _ready = true);
        return;
      }
      final bytes = await store.loadBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  Widget _fallbackText(AppLocalization l10n) {
    if (!widget.showFallback) {
      return const SizedBox.shrink();
    }
    return Text(
      l10n.translate(widget.fallbackKey),
      style: TextStyle(
        fontSize: widget.height * 0.45,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.showFallback
          ? SizedBox(height: widget.height)
          : const SizedBox.shrink();
    }
    final l10n = AppLocalization.of(context);
    if (_bytes == null || _bytes!.isEmpty) {
      return _fallbackText(l10n);
    }
    return Image.memory(
      _bytes!,
      height: widget.height,
      fit: BoxFit.contain,
      alignment: AlignmentDirectional.centerEnd,
      errorBuilder: (_, __, ___) => _fallbackText(l10n),
    );
  }
}
