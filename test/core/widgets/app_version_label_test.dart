// Dosya Adı: app_version_label_test.dart
// Açıklama: AppVersionLabel / formatAppVersionString birim ve widget testi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/widgets/app_version_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('formatAppVersionString', () {
    test('vX.Y.Z+build üretir', () {
      expect(formatAppVersionString('1.0.0', '1'), 'v1.0.0+1');
    });

    test('boş build yalnızca sürüm', () {
      expect(formatAppVersionString('2.3.4', ''), 'v2.3.4');
    });
  });

  testWidgets('Ayarlar dens satırında sürüm görünür', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'EXFINOPS',
      packageName: 'com.exfin.ops',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    await pumpStubWithL10n(
      tester,
      const Scaffold(body: AppVersionLabel()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('v1.0.0+1'), findsOneWidget);
  });
}
