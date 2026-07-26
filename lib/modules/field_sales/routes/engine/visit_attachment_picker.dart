// Dosya Adı: visit_attachment_picker.dart
// Açıklama: Ziyaret EKLER için image_picker / file_picker seçimi veya platform stub path
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// {@template visit_attach_kind}
/// EKLER seçim türü (dosya / foto).
/// {@endtemplate}
enum VisitAttachKind {
  /// Dosya seçimi
  file,

  /// Foto seçimi
  photo,
}

/// {@template visit_attachment_pick_result}
/// EKLER seçim sonucu (gerçek path veya net stub URI).
///
/// Kullanım örneği:
/// ```dart
/// final r = await VisitAttachmentPicker().pickPhoto();
/// print(r?.path);
/// ```
/// {@endtemplate}
class VisitAttachmentPickResult {
  /// [path]: Gerçek dosya yolu veya `stub://…` URI
  final String path;

  /// [isStub]: Platform stub mu
  final bool isStub;

  /// [kind]: Dosya / foto
  final VisitAttachKind kind;

  /// {@macro visit_attachment_pick_result}
  const VisitAttachmentPickResult({
    required this.path,
    required this.isStub,
    required this.kind,
  });
}

/// {@template visit_attachment_picker}
/// Mobilde gerçek picker; destek yoksa net `stub://kind/platform/…` path.
///
/// Kullanım örneği:
/// ```dart
/// final picker = VisitAttachmentPicker();
/// final photo = await picker.pickPhoto();
/// final file = await picker.pickFile();
/// ```
/// {@endtemplate}
class VisitAttachmentPicker {
  /// [imagePicker]: Test / DI için ImagePicker
  final ImagePicker _imagePicker;

  /// [platformLabel]: Test için sabit platform etiketi
  final String _platformLabel;

  /// [clock]: Stub zaman damgası
  final DateTime Function() _clock;

  /// [forceStub]: Birim testlerinde gerçek picker atla
  final bool _forceStub;

  /// {@macro visit_attachment_picker}
  VisitAttachmentPicker({
    ImagePicker? imagePicker,
    String? platformLabel,
    DateTime Function()? clock,
    bool forceStub = false,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _platformLabel = platformLabel ?? _resolvePlatformLabel(),
        _clock = clock ?? DateTime.now,
        _forceStub = forceStub;

  /// {@template visit_attachment_picker_build_stub_path}
  /// Net platform stub URI üretir.
  ///
  /// Parametreler:
  /// - [kind]: dosya / foto
  /// - [platform]: android / ios / windows / …
  /// - [now]: zaman damgası (opsiyonel)
  ///
  /// Dönüş değeri:
  /// - [String]: `stub://photo/android/visit_….jpg` biçimi
  /// {@endtemplate}
  static String buildStubPath({
    required VisitAttachKind kind,
    required String platform,
    DateTime? now,
  }) {
    final stamp = _formatStamp(now ?? DateTime.now());
    final kindSeg = kind == VisitAttachKind.photo ? 'photo' : 'file';
    final ext = kind == VisitAttachKind.photo ? 'jpg' : 'bin';
    final safePlatform = platform.trim().isEmpty ? 'unknown' : platform.trim();
    return 'stub://$kindSeg/$safePlatform/visit_$stamp.$ext';
  }

  /// {@template visit_attachment_picker_pick_photo}
  /// Galeriden foto seçer; olmazsa image file_picker; o da olmazsa stub.
  ///
  /// Dönüş değeri:
  /// - [VisitAttachmentPickResult]: seçim veya stub
  /// - `null`: kullanıcı iptal
  /// {@endtemplate}
  Future<VisitAttachmentPickResult?> pickPhoto() async {
    if (_forceStub) {
      return _stubResult(VisitAttachKind.photo);
    }

    if (_preferImagePicker) {
      try {
        final image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
        if (image != null && image.path.trim().isNotEmpty) {
          return VisitAttachmentPickResult(
            path: image.path,
            isStub: false,
            kind: VisitAttachKind.photo,
          );
        }
        // Desteklenen platformda null = iptal
        return null;
      } catch (_) {
        // Plugin / izin hatası → file_picker veya stub
      }
    }

    final viaFile = await _pickViaFilePicker(
      kind: VisitAttachKind.photo,
      type: FileType.image,
    );
    switch (viaFile.status) {
      case _FilePickStatus.picked:
        return viaFile.result;
      case _FilePickStatus.cancelled:
        return null;
      case _FilePickStatus.unavailable:
        return _stubResult(VisitAttachKind.photo);
    }
  }

  /// {@template visit_attachment_picker_pick_file}
  /// Dosya seçer; destek yoksa net platform stub path.
  ///
  /// Dönüş değeri:
  /// - [VisitAttachmentPickResult]: seçim veya stub
  /// - `null`: kullanıcı iptal
  /// {@endtemplate}
  Future<VisitAttachmentPickResult?> pickFile() async {
    if (_forceStub) {
      return _stubResult(VisitAttachKind.file);
    }

    final viaFile = await _pickViaFilePicker(
      kind: VisitAttachKind.file,
      type: FileType.any,
    );
    switch (viaFile.status) {
      case _FilePickStatus.picked:
        return viaFile.result;
      case _FilePickStatus.cancelled:
        return null;
      case _FilePickStatus.unavailable:
        return _stubResult(VisitAttachKind.file);
    }
  }

  /// {@template visit_attachment_picker_prefer_image_picker}
  /// image_picker’ın birincil olduğu platformlar.
  /// {@endtemplate}
  bool get _preferImagePicker {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  /// {@template visit_attachment_picker_pick_via_file_picker}
  /// file_picker sonucu (seçildi / iptal / kullanılamaz).
  /// {@endtemplate}
  Future<_FilePickOutcome> _pickViaFilePicker({
    required VisitAttachKind kind,
    required FileType type,
  }) async {
    try {
      // file_picker ≥11: FilePicker.platform kaldırıldı → static pickFiles
      final result = await FilePicker.pickFiles(
        type: type,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        return const _FilePickOutcome.cancelled();
      }
      final file = result.files.single;
      final path = file.path?.trim();
      if (path != null && path.isNotEmpty) {
        return _FilePickOutcome.picked(
          VisitAttachmentPickResult(
            path: path,
            isStub: false,
            kind: kind,
          ),
        );
      }
      final name = file.name.trim();
      if (name.isNotEmpty) {
        return _FilePickOutcome.picked(
          VisitAttachmentPickResult(
            path: name,
            isStub: true,
            kind: kind,
          ),
        );
      }
      return const _FilePickOutcome.unavailable();
    } catch (_) {
      return const _FilePickOutcome.unavailable();
    }
  }

  /// {@template visit_attachment_picker_stub_result}
  /// Platform stub sonucu.
  /// {@endtemplate}
  VisitAttachmentPickResult _stubResult(VisitAttachKind kind) {
    return VisitAttachmentPickResult(
      path: buildStubPath(
        kind: kind,
        platform: _platformLabel,
        now: _clock(),
      ),
      isStub: true,
      kind: kind,
    );
  }

  /// {@template visit_attachment_picker_resolve_platform}
  /// Hedef platform etiketi (stub URI segmenti).
  /// {@endtemplate}
  static String _resolvePlatformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// {@template visit_attachment_picker_format_stamp}
  /// `yyyyMMddHHmmss` damgası.
  /// {@endtemplate}
  static String _formatStamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}'
        '${two(dt.month)}'
        '${two(dt.day)}'
        '${two(dt.hour)}'
        '${two(dt.minute)}'
        '${two(dt.second)}';
  }
}

/// {@template _FilePickStatus}
/// file_picker iç sonucu.
/// {@endtemplate}
enum _FilePickStatus {
  /// Dosya seçildi
  picked,

  /// Kullanıcı iptal
  cancelled,

  /// Plugin / platform kullanılamıyor
  unavailable,
}

/// {@template _FilePickOutcome}
/// file_picker sarmalayıcı sonucu.
/// {@endtemplate}
class _FilePickOutcome {
  /// [status]: Sonuç durumu
  final _FilePickStatus status;

  /// [result]: Seçim (yalnızca picked)
  final VisitAttachmentPickResult? result;

  const _FilePickOutcome._(this.status, this.result);

  /// Seçildi.
  const _FilePickOutcome.picked(VisitAttachmentPickResult result)
      : this._(_FilePickStatus.picked, result);

  /// İptal.
  const _FilePickOutcome.cancelled()
      : this._(_FilePickStatus.cancelled, null);

  /// Kullanılamaz → stub adayı.
  const _FilePickOutcome.unavailable()
      : this._(_FilePickStatus.unavailable, null);
}
