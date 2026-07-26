// Dosya Adı: visit_history_screen_test.dart
// Açıklama: Geçmiş ziyaret dens ekranı enjekte kayıt smoke testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/routes/model/visit_history_record.dart';
import 'package:exfin_ops/modules/field_sales/routes/view/visit_history_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('enjekte kayıtları dens listede gösterir', (tester) async {
    final records = [
      VisitHistoryRecord(
        id: 'v1',
        customerId: 'c1',
        customerName: 'Alpha Market',
        checkInAt: DateTime(2026, 7, 24, 10),
        status: 'Completed',
        durationMinutes: 42,
      ),
    ];

    await pumpStubWithL10n(
      tester,
      VisitHistoryScreen(records: records),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha Market'), findsOneWidget);
    expect(find.text('24.07.2026'), findsOneWidget);
  });
}
