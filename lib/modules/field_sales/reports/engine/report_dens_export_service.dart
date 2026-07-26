// Dosya Adı: report_dens_export_service.dart
// Açıklama: Rapor dens Yedekle/İndir dosya/export stub servisi (path + share)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// {@template report_dens_export_kind}
/// Rapor dens dışa aktarım türü: yedek veya indirme.
/// {@endtemplate}
enum ReportDensExportKind {
  /// Yerel yedek dosyası
  backup,

  /// İndirme / paylaşım dosyası
  download,
}

/// {@template report_dens_export_row}
/// Export satırı (dens satırlarından bağımsız DTO).
///
/// Kullanım örneği:
/// ```dart
/// const ReportDensExportRow(title: 'A', subtitle: 'B', value: '1');
/// ```
/// {@endtemplate}
class ReportDensExportRow {
  /// [title]: Satır başlığı
  final String title;

  /// [subtitle]: Alt metin
  final String subtitle;

  /// [value]: Değer
  final String value;

  const ReportDensExportRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  /// {@template report_dens_export_row_to_map}
  /// JSON satırına dönüştürür.
  ///
  /// Dönüş değeri:
  /// - [Map]: Serileştirilmiş satır
  /// {@endtemplate}
  Map<String, String> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'value': value,
      };
}

/// {@template report_dens_export_result}
/// Stub export sonucu: dosya yolu ve meta.
/// {@endtemplate}
class ReportDensExportResult {
  /// [filePath]: Oluşturulan dosyanın mutlak yolu
  final String filePath;

  /// [kind]: Yedek veya indirme
  final ReportDensExportKind kind;

  /// [rowCount]: Yazılan satır adedi
  final int rowCount;

  const ReportDensExportResult({
    required this.filePath,
    required this.kind,
    required this.rowCount,
  });
}

/// {@template report_dens_share_fn}
/// Path share geri çağrısı (testte no-op enjekte edilebilir).
/// {@endtemplate}
typedef ReportDensShareFn = Future<void> Function({
  required String filePath,
  required String subject,
  required String text,
});

/// {@template report_dens_export_service}
/// Rapor dens satırlarını JSON dosyaya yazar; yolu döner ve share eder.
///
/// Kullanım örneği:
/// ```dart
/// final result = await ReportDensExportService().export(
///   kind: ReportDensExportKind.backup,
///   reportKey: 'field_sales.stubs.sales_report',
///   dateFrom: DateTime(2026, 1, 1),
///   dateTo: DateTime(2026, 1, 31),
///   rows: const [],
/// );
/// print(result.filePath);
/// ```
/// {@endtemplate}
class ReportDensExportService {
  /// [_resolveDirectory]: Hedef kök dizin (test inject)
  final Future<Directory> Function() _resolveDirectory;

  /// [_shareFile]: Path share (varsayılan share_plus)
  final ReportDensShareFn _shareFile;

  /// [_clock]: Dosya adı zaman damgası
  final DateTime Function() _clock;

  /// {@template report_dens_export_service_constructor}
  /// Stub export servisini oluşturur.
  ///
  /// Parametreler:
  /// - [resolveDirectory]: Opsiyonel dizin sağlayıcı
  /// - [shareFile]: Opsiyonel path share
  /// - [clock]: Opsiyonel saat
  /// {@endtemplate}
  ReportDensExportService({
    Future<Directory> Function()? resolveDirectory,
    ReportDensShareFn? shareFile,
    DateTime Function()? clock,
  })  : _resolveDirectory =
            resolveDirectory ?? getApplicationDocumentsDirectory,
        _shareFile = shareFile ?? _defaultShare,
        _clock = clock ?? DateTime.now;

  /// {@template report_dens_export_service_default_share}
  /// share_plus ile dosya paylaşır.
  /// {@endtemplate}
  static Future<void> _defaultShare({
    required String filePath,
    required String subject,
    required String text,
  }) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
      text: text,
    );
  }

  /// {@template report_dens_export_service_export}
  /// Dens satırlarını stub JSON dosyaya yazar, path share eder.
  ///
  /// Parametreler:
  /// - [kind]: Yedek veya indirme
  /// - [reportKey]: Rapor l10n anahtarı / etiket
  /// - [dateFrom]: Başlangıç
  /// - [dateTo]: Bitiş
  /// - [rows]: Export satırları
  /// - [shareSubject]: Paylaşım konusu
  /// - [shareText]: Paylaşım metni (path eklenebilir)
  ///
  /// Dönüş değeri:
  /// - [ReportDensExportResult]: Dosya yolu ve meta
  ///
  /// Fırlatılan hatalar:
  /// - [IOException]: Dosya yazılamazsa
  /// {@endtemplate}
  Future<ReportDensExportResult> export({
    required ReportDensExportKind kind,
    required String reportKey,
    required DateTime dateFrom,
    required DateTime dateTo,
    required List<ReportDensExportRow> rows,
    String shareSubject = 'EXFINOPS Report',
    String? shareText,
  }) async {
    final root = await _resolveDirectory();
    final subDirName =
        kind == ReportDensExportKind.backup ? 'backup' : 'download';
    final dir = Directory(p.join(root.path, 'reports', subDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final stamp = _clock()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll('-', '');
    final prefix =
        kind == ReportDensExportKind.backup ? 'report_backup' : 'report_download';
    final filePath = p.join(dir.path, '${prefix}_$stamp.json');

    final payload = <String, dynamic>{
      'stub': true,
      'kind': kind.name,
      'reportKey': reportKey,
      'dateFrom': dateFrom.toIso8601String(),
      'dateTo': dateTo.toIso8601String(),
      'exportedAt': _clock().toIso8601String(),
      'rowCount': rows.length,
      'rows': rows.map((r) => r.toMap()).toList(),
    };

    final file = File(filePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );

    final text = shareText ?? filePath;
    await _shareFile(
      filePath: filePath,
      subject: shareSubject,
      text: text,
    );

    return ReportDensExportResult(
      filePath: filePath,
      kind: kind,
      rowCount: rows.length,
    );
  }
}
