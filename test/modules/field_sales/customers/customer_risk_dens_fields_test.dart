// Dosya Adı: customer_risk_dens_fields_test.dart
// Açıklama: Müşteri risk dens risk/limit alan görünürlük testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_risk_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('CustomerRiskScreen availableLimit', () {
    test('limit yoksa 0', () {
      expect(
        CustomerRiskScreen.availableLimit(riskLimit: 0, balance: 100),
        0,
      );
    });

    test('bakiye altında kalan limit', () {
      expect(
        CustomerRiskScreen.availableLimit(riskLimit: 10000, balance: 2500),
        7500,
      );
    });

    test('aşımda kullanılabilir 0', () {
      expect(
        CustomerRiskScreen.availableLimit(riskLimit: 1000, balance: 1500),
        0,
      );
    });

    test('alacak bakiyede tam limit kullanılabilir', () {
      expect(
        CustomerRiskScreen.availableLimit(riskLimit: 5000, balance: -200),
        5000,
      );
    });
  });

  group('CustomerRiskScreen isLimitExceeded', () {
    test('limit aşımı', () {
      expect(
        CustomerRiskScreen.isLimitExceeded(riskLimit: 1000, balance: 1001),
        isTrue,
      );
    });

    test('limit tanımsız aşım değil', () {
      expect(
        CustomerRiskScreen.isLimitExceeded(riskLimit: 0, balance: 99999),
        isFalse,
      );
    });
  });

  group('MBT müşteri risk dens alanları', () {
    testWidgets('Risk Limiti / Bakiye / Kullanılabilir / Yaş. Borç görünür',
        (tester) async {
      await pumpStubWithL10n(
        tester,
        const CustomerRiskScreen(
          customerCode: '120.01',
          customerName: 'Demo Cari A.Ş.',
          balance: 2500,
          riskLimit: 10000,
          agingDebt: 100,
        ),
      );

      expect(find.text('Müşteri Risk'), findsWidgets);
      expect(find.text('Cari Kodu'), findsOneWidget);
      expect(find.text('Ünvan'), findsOneWidget);
      expect(find.text('Risk Limiti'), findsOneWidget);
      expect(find.text('Bakiye'), findsOneWidget);
      expect(find.text('Kullanılabilir Limit'), findsOneWidget);
      expect(find.text('Yaş. Borç'), findsOneWidget);
      expect(find.text('Risk Durumu'), findsOneWidget);
      expect(find.text('Uygun'), findsOneWidget);
      expect(find.text('120.01'), findsOneWidget);
      expect(find.text('Demo Cari A.Ş.'), findsOneWidget);
    });

    testWidgets('Limit aşımında durum etiketi', (tester) async {
      await pumpStubWithL10n(
        tester,
        const CustomerRiskScreen(
          balance: 12000,
          riskLimit: 10000,
        ),
      );
      expect(find.text('Limit Aşımı'), findsOneWidget);
    });
  });
}
