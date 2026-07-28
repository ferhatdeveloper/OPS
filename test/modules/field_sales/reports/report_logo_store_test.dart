// Dosya Adı: report_logo_store_test.dart
// Açıklama: Rapor logo yerel önbellek birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_logo_auth.dart';
import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_logo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late ReportLogoStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmpDir = await Directory.systemTemp.createTemp('report_logo_');
    store = ReportLogoStore(
      prefsFactory: SharedPreferences.getInstance,
      resolveDirectory: () async => tmpDir,
    );
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  test('saveBytes + loadBytes PNG önbellek', () async {
    // Minimal 1x1 PNG
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE,
      0x02, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
      0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    final meta = await store.saveBytes(
      png,
      source: ReportLogoSource.upload,
      fileName: 'company_logo.png',
    );
    expect(meta.source, ReportLogoSource.upload);
    expect(await store.hasLogo(), isTrue);

    store.resetMemoryCacheForTest();
    final loaded = await store.loadBytes();
    expect(loaded, isNotNull);
    expect(loaded!.length, png.length);

    final path = await store.filePath();
    expect(path.contains('report_branding'), isTrue);
    expect(File(path).existsSync(), isTrue);
  });

  test('clear logo meta ve dosyayı siler', () async {
    await store.saveBytes(
      Uint8List.fromList([1, 2, 3, 4]),
      source: ReportLogoSource.center,
      fileName: 'company_logo.png',
    );
    await store.clear();
    expect(await store.hasLogo(), isFalse);
    expect((await store.loadMeta()).source, ReportLogoSource.none);
  });

  test('fileNameForBytes JPEG / PNG algılar', () {
    expect(
      ReportLogoStore.fileNameForBytes(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]),
      ),
      'company_logo.jpg',
    );
    expect(
      ReportLogoStore.fileNameForBytes(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
      ),
      'company_logo.png',
    );
  });

  test('ReportLogoAuth admin/supervisor yetkili', () async {
    final admin = ReportLogoAuth(roleResolver: () async => 'admin');
    final supervisor = ReportLogoAuth(roleResolver: () async => 'supervisor');
    final user = ReportLogoAuth(roleResolver: () async => 'user');
    final none = ReportLogoAuth(roleResolver: () async => null);

    expect(await admin.canManageLogo(), isTrue);
    expect(await supervisor.canManageLogo(), isTrue);
    expect(await user.canManageLogo(), isFalse);
    expect(await none.canManageLogo(), isFalse);
  });
}
