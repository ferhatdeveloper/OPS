// Dosya Adı: report_dens_export_service_test.dart
// Açıklama: Rapor dens export stub servisi path + share birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/engine/report_dens_export_service.dart';

void main() {
  late Directory tempRoot;
  late List<String> sharedPaths;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('report_dens_export_');
    sharedPaths = <String>[];
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  ReportDensExportService buildService() {
    return ReportDensExportService(
      resolveDirectory: () async => tempRoot,
      shareFile: ({
        required String filePath,
        required String subject,
        required String text,
      }) async {
        sharedPaths.add(filePath);
      },
      clock: () => DateTime(2026, 7, 26, 12, 30, 0),
    );
  }

  group('ReportDensExportService', () {
    test('Yedekle: JSON dosya yazar, path döner, share çağırır', () async {
      final service = buildService();
      final result = await service.export(
        kind: ReportDensExportKind.backup,
        reportKey: 'field_sales.stubs.sales_report',
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 26),
        rows: const [
          ReportDensExportRow(
            title: 'Satır A',
            subtitle: 'alt',
            value: '10',
          ),
        ],
      );

      expect(result.kind, ReportDensExportKind.backup);
      expect(result.rowCount, 1);
      expect(result.filePath.contains('reports/backup/'), isTrue);
      expect(result.filePath.contains('report_backup_'), isTrue);
      expect(File(result.filePath).existsSync(), isTrue);
      expect(sharedPaths, [result.filePath]);

      final json =
          jsonDecode(await File(result.filePath).readAsString()) as Map;
      expect(json['stub'], isTrue);
      expect(json['kind'], 'backup');
      expect(json['reportKey'], 'field_sales.stubs.sales_report');
      expect(json['rowCount'], 1);
      expect((json['rows'] as List).first['title'], 'Satır A');
    });

    test('İndir: download alt klasörüne yazar ve path share eder', () async {
      final service = buildService();
      final result = await service.export(
        kind: ReportDensExportKind.download,
        reportKey: 'field_sales.stubs.collection_report',
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 26),
        rows: const [],
      );

      expect(result.kind, ReportDensExportKind.download);
      expect(result.rowCount, 0);
      expect(result.filePath.contains('reports/download/'), isTrue);
      expect(result.filePath.contains('report_download_'), isTrue);
      expect(sharedPaths, [result.filePath]);
    });
  });
}
