// Dosya Adı: unsaved_voucher_dialog_test.dart
// Açıklama: Kaydedilmemiş fiş dialog / confirmDiscard / draft karar testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/shared/view/unsaved_voucher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('resolveExistingDraftDecision', () {
    test('taslak yok → startFresh', () {
      expect(
        resolveExistingDraftDecision(hasExistingDraft: false, action: null),
        ExistingDraftDecision.startFresh,
      );
    });

    test('Sil → discardAndRestart', () {
      expect(
        resolveExistingDraftDecision(
          hasExistingDraft: true,
          action: UnsavedVoucherAction.delete,
        ),
        ExistingDraftDecision.discardAndRestart,
      );
    });

    test('Devam Et → keepExisting', () {
      expect(
        resolveExistingDraftDecision(
          hasExistingDraft: true,
          action: UnsavedVoucherAction.continueEditing,
        ),
        ExistingDraftDecision.keepExisting,
      );
    });
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await pumpStubWithL10n(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  key: const Key('confirm_empty'),
                  onPressed: () async {
                    final ok = await confirmDiscardUnsavedVoucher(
                      context: context,
                      hasUnsaved: false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('empty:$ok')),
                    );
                  },
                  child: const Text('empty'),
                ),
                ElevatedButton(
                  key: const Key('confirm_unsaved'),
                  onPressed: () async {
                    final ok = await confirmDiscardUnsavedVoucher(
                      context: context,
                      hasUnsaved: true,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('unsaved:$ok')),
                    );
                  },
                  child: const Text('unsaved'),
                ),
                ElevatedButton(
                  key: const Key('prompt_draft'),
                  onPressed: () async {
                    final decision = await promptExistingDraftVoucher(
                      context: context,
                      hasExistingDraft: true,
                      customerLabel: 'ADNAN SATIN',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('decision:$decision')),
                    );
                  },
                  child: const Text('prompt'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  testWidgets('confirmDiscard hasUnsaved=false → true (dialog yok)',
      (tester) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const Key('confirm_empty')));
    await tester.pumpAndSettle();
    expect(find.text('empty:true'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('dialog Devam Et → confirmDiscard false', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const Key('confirm_unsaved')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining(
        'Daha önceden başlatılmış fakat kaydedilmemiş bir fiş bulundu.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(find.text('unsaved:false'), findsOneWidget);
  });

  testWidgets('dialog Sil → confirmDiscard true', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const Key('confirm_unsaved')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(find.text('unsaved:true'), findsOneWidget);
  });

  testWidgets('promptExistingDraft + cari etiketi + Devam Et', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const Key('prompt_draft')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ADNAN SATIN'), findsOneWidget);
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(
      find.text('decision:ExistingDraftDecision.keepExisting'),
      findsOneWidget,
    );
  });
}
