// Dosya Adı: report_logo_settings_screen.dart
// Açıklama: Rapor PDF logo dens ayar — merkez sync / yetkili yükleme
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../viewmodel/report_logo_auth.dart';
import '../viewmodel/report_logo_remote_sync.dart';
import '../viewmodel/report_logo_store.dart';

/// {@template report_logo_settings_screen}
/// Rapor PDF firma logosu dens ayar ekranı.
/// Route: `/field-sales/report-logo-settings`
///
/// - Merkezden bir kez indir (PostgREST branding)
/// - Yetkili (admin/supervisor) galeriden yükle / sil
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ReportLogoSettingsScreen.routeName);
/// ```
/// {@endtemplate}
class ReportLogoSettingsScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/report-logo-settings';

  /// [store]: Test inject
  final ReportLogoStore? store;

  /// [sync]: Test inject
  final ReportLogoRemoteSync? sync;

  /// [auth]: Test inject
  final ReportLogoAuth? auth;

  /// [imagePicker]: Test inject
  final ImagePicker? imagePicker;

  /// {@macro report_logo_settings_screen}
  const ReportLogoSettingsScreen({
    Key? key,
    this.store,
    this.sync,
    this.auth,
    this.imagePicker,
  }) : super(key: key);

  @override
  State<ReportLogoSettingsScreen> createState() =>
      _ReportLogoSettingsScreenState();
}

class _ReportLogoSettingsScreenState extends State<ReportLogoSettingsScreen> {
  late final ReportLogoStore _store = widget.store ?? ReportLogoStore();
  late final ReportLogoRemoteSync _sync =
      widget.sync ?? ReportLogoRemoteSync(store: _store);
  late final ReportLogoAuth _auth = widget.auth ?? const ReportLogoAuth();
  late final ImagePicker _picker = widget.imagePicker ?? ImagePicker();

  Uint8List? _preview;
  ReportLogoMeta _meta = ReportLogoMeta.empty;
  bool _loading = true;
  bool _busy = false;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final can = await _auth.canManageLogo();
    final meta = await _store.loadMeta();
    final bytes = await _store.loadBytes();
    if (!mounted) return;
    setState(() {
      _canManage = can;
      _meta = meta;
      _preview = bytes;
      _loading = false;
    });
  }

  String _t(String key) =>
      AppLocalization.of(context).translate(key);

  Future<void> _snack(String key) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(key)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _syncFromCenter() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _sync.ensureCached(force: true);
      await _hydrate();
      await _snack(
        result.messageKey ??
            (result.ok
                ? 'field_sales.mbt_reports.logo_synced'
                : 'field_sales.mbt_reports.logo_center_unavailable'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    if (!_canManage) {
      await _snack('field_sales.mbt_reports.logo_upload_denied');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      final name = ReportLogoStore.fileNameForBytes(
        Uint8List.fromList(bytes),
      );
      await _store.saveBytes(
        Uint8List.fromList(bytes),
        source: ReportLogoSource.upload,
        fileName: name,
      );
      await _hydrate();
      await _snack('field_sales.mbt_reports.logo_uploaded');
    } catch (_) {
      await _snack('field_sales.mbt_reports.logo_upload_failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    if (!_canManage) {
      await _snack('field_sales.mbt_reports.logo_upload_denied');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _store.clear();
      await _hydrate();
      await _snack('field_sales.mbt_reports.logo_cleared');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _sourceLabel() {
    switch (_meta.source) {
      case ReportLogoSource.center:
        return _t('field_sales.mbt_reports.logo_source_center');
      case ReportLogoSource.upload:
        return _t('field_sales.mbt_reports.logo_source_upload');
      case ReportLogoSource.none:
        return _t('field_sales.mbt_reports.logo_source_none');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _t('field_sales.mbt_reports.logo_settings_title');

    return Scaffold(
      appBar: FieldSalesDensAppBar(title: title),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              children: [
                Text(
                  _t('field_sales.mbt_reports.logo_settings_hint'),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: FieldSalesDensAppBar.primaryColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _preview == null
                      ? Text(
                          _t('field_sales.mbt_reports.logo_preview_empty'),
                          style: const TextStyle(fontSize: 12),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.memory(
                            _preview!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(
                              _t(
                                'field_sales.mbt_reports.logo_preview_empty',
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_t('field_sales.mbt_reports.logo_source')}: '
                  '${_sourceLabel()}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (_meta.updatedAtIso.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_t('field_sales.mbt_reports.logo_updated')}: '
                    '${_meta.updatedAtIso}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _syncFromCenter,
                    icon: const Icon(Icons.cloud_download, size: 18),
                    label: Text(
                      _t('field_sales.mbt_reports.logo_sync_center'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FieldSalesDensAppBar.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_busy || !_canManage) ? null : _upload,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      _t('field_sales.mbt_reports.logo_upload'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FieldSalesDensAppBar.primaryColor,
                      side: const BorderSide(
                        color: FieldSalesDensAppBar.primaryColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                if (!_canManage) ...[
                  const SizedBox(height: 4),
                  Text(
                    _t('field_sales.mbt_reports.logo_upload_denied'),
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: (_busy || !_canManage || _preview == null)
                        ? null
                        : _clear,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      _t('field_sales.mbt_reports.logo_clear'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
