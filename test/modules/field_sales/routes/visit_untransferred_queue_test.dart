// Dosya Adı: visit_untransferred_queue_test.dart
// Açıklama: K11 visit_untransferred dens → visit queue widget smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/routes/view/visit_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/logo_queue_status_chip.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/logo_sync_queue_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('boş visit kuyruk dens empty state', (tester) async {
    await pumpStubWithL10n(
      tester,
      VisitUntransferredScreen(
        pendingJobsLoader: () async => const [],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.stubs.visit_untransferred');
    expect(find.byType(LogoSyncQueueList), findsOneWidget);
    expect(find.text('Transfer edilecek belge yok'), findsOneWidget);
  });

  testWidgets('visit job satırı Logo durum chip gösterir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      VisitUntransferredScreen(
        pendingJobsLoader: () async => [
          {
            'entity_type': 'visit',
            'entity_id': 'VIS-1',
            'retry_count': 0,
            'created_at': '2026-07-26T10:00:00',
          },
          {
            'entity_type': 'order',
            'entity_id': 'ORD-1',
            'retry_count': 0,
            'created_at': '2026-07-26T10:00:00',
          },
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('visit · VIS-1'), findsOneWidget);
    expect(find.text('order · ORD-1'), findsNothing);
    expect(find.byType(LogoQueueStatusChip), findsOneWidget);
    expect(find.text('Bekliyor'), findsOneWidget);
  });
}
