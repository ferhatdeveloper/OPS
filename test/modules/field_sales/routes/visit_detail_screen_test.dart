// Dosya Adı: visit_detail_screen_test.dart
// Açıklama: Ziyaret detay dens ekranı enjekte kayıt smoke testi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/routes/model/visit_detail_record.dart';
import 'package:exfin_ops/modules/field_sales/routes/view/visit_detail_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('enjekte detay check-in ve not gösterir', (tester) async {
    final detail = VisitDetailRecord(
      id: 'v1',
      customerId: 'c1',
      customerName: 'Alpha Market',
      checkInAt: DateTime(2026, 7, 24, 10, 5),
      checkOutAt: DateTime(2026, 7, 24, 10, 47),
      checkInLat: 41.01,
      checkInLong: 28.97,
      notes: 'Görüşme notu',
      status: 'Completed',
      durationMinutes: 42,
    );

    await pumpStubWithL10n(
      tester,
      VisitDetailScreen(visitId: 'v1', detail: detail),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha Market'), findsOneWidget);
    expect(find.text('Görüşme notu'), findsOneWidget);
    expect(find.textContaining('24.07.2026'), findsWidgets);
  });

  test('parseVisitId String ve Map args çözülür', () {
    expect(VisitDetailScreen.parseVisitId('v9'), 'v9');
    expect(VisitDetailScreen.parseVisitId({'visitId': 'v8'}), 'v8');
    expect(VisitDetailScreen.parseVisitId(null), isNull);
  });
}
