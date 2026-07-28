// Dosya Adı: ai_voice_agent_bottom_bar_test.dart
// Açıklama: Dens AI sohbet kısayol ikonu smoke
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/ai/widgets/ai_voice_agent_bottom_bar.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_app_bar.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(ensureStubL10nLoaded);

  testWidgets('AiVoiceAgentBottomBar — dens AI ikon tap', (tester) async {
    var tapped = false;
    await pumpStubWithL10n(
      tester,
      Scaffold(
        body: Center(
          child: AiVoiceAgentBottomBar(
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ai_voice_agent_cta')), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

    final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome_rounded));
    expect(icon.color, FieldSalesDensAppBar.primaryColor);
    expect(icon.size, AiVoiceAgentBottomBar.iconSize);

    await tester.tap(find.byKey(const Key('ai_voice_agent_cta')));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
