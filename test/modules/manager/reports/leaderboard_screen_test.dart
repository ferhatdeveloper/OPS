// Dosya Adı: leaderboard_screen_test.dart
// Açıklama: Hedef sıralaması string interpolasyon smoke testi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/manager/reports/view/leaderboard_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('podium ve liste gerçek puan/rank/% gösterir, literal şablon değil', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(tester, const LeaderboardScreen());

    expect(find.text('Hedef Sıralaması'), findsOneWidget);

    // Kaçışlı literal şablonlar görünmemeli
    expect(find.textContaining(r'${rep'), findsNothing);
    expect(find.text(r'$rank'), findsNothing);
    expect(find.text(r'$rank.'), findsNothing);
    expect(find.textContaining(r'${(progress'), findsNothing);

    // Dummy veriden interpolate edilmiş değerler
    expect(find.text('8450 P'), findsOneWidget);
    expect(find.text('7200 P'), findsOneWidget);
    expect(find.text('6100 P'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
    expect(find.text('4500 Puan'), findsOneWidget);
    // Ayşe: 65000/140000 ≈ 46%
    expect(find.text('46%'), findsOneWidget);
  });
}
