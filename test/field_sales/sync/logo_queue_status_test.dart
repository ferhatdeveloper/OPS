// Dosya Adı: logo_queue_status_test.dart
// Açıklama: LogoQueueStatus.fromJob + dens chip smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/sync/model/logo_job_record.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/logo_job_status_screen.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/logo_queue_status_chip.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/logo_sync_queue_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('LogoQueueStatus.fromJob', () {
    test('hatasız → pending', () {
      expect(
        LogoQueueStatus.fromJob({'retry_count': 0}),
        LogoQueueStatus.pending,
      );
    });

    test('last_error + retry 0 → error', () {
      expect(
        LogoQueueStatus.fromJob({
          'retry_count': 0,
          'last_error': 'timeout',
        }),
        LogoQueueStatus.error,
      );
    });

    test('last_error + retry > 0 → retry', () {
      expect(
        LogoQueueStatus.fromJob({
          'retry_count': 2,
          'last_error': 'timeout',
        }),
        LogoQueueStatus.retry,
      );
    });

    test('retry > 5 → dead', () {
      expect(
        LogoQueueStatus.fromJob({
          'retry_count': 6,
          'last_error': 'fail',
        }),
        LogoQueueStatus.dead,
      );
    });
  });

  group('LogoQueueStatusChip dens', () {
    testWidgets('retry chip metnini gösterir', (tester) async {
      await pumpStubWithL10n(
        tester,
        const Scaffold(
          body: Center(
            child: LogoQueueStatusChip(status: LogoQueueStatus.retry),
          ),
        ),
      );
      expect(find.text('Yeniden denenecek'), findsOneWidget);
    });

    testWidgets('liste satırında chip gösterir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        Scaffold(
          body: LogoSyncQueueList(
            jobs: [
              {
                'entity_type': 'order',
                'entity_id': 'O-1',
                'retry_count': 0,
                'created_at': '2026-07-26',
              },
              {
                'entity_type': 'invoice',
                'entity_id': 'I-1',
                'retry_count': 2,
                'last_error': 'Logo 500',
              },
            ],
          ),
        ),
      );

      expect(find.text('order · O-1'), findsOneWidget);
      expect(find.text('Bekliyor'), findsOneWidget);
      expect(find.text('Yeniden denenecek'), findsOneWidget);
      expect(find.byType(LogoQueueStatusChip), findsNWidgets(2));
    });

    testWidgets('boş kuyruk dens empty state', (tester) async {
      await pumpStubWithL10n(
        tester,
        const Scaffold(
          body: LogoSyncQueueList(jobs: []),
        ),
      );
      expect(find.text('Transfer edilecek belge yok'), findsOneWidget);
      expect(
        find.text('Yeni belge kaydedince burada listelenir.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('LogoJobStatusScreen gerçek job satırları', () {
    testWidgets('enjekte sync_queue satırlarını dens listeler', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        LogoJobStatusScreen(
          jobs: const [
            LogoJobRecord(
              id: 'j-real-1',
              entityType: 'order',
              entityId: 'O-REAL',
              createdAt: '2026-07-26',
            ),
            LogoJobRecord(
              id: 'j-real-2',
              entityType: 'invoice',
              entityId: 'I-REAL',
              retryCount: 2,
              lastError: 'Logo 500',
            ),
          ],
        ),
      );

      expect(find.text('Logo İş Durumu'), findsOneWidget);
      expect(find.text('order · O-REAL'), findsOneWidget);
      expect(find.text('invoice · I-REAL'), findsOneWidget);
      expect(find.text('Bekliyor'), findsOneWidget);
      expect(find.text('Yeniden denenecek'), findsOneWidget);
    });
  });
}
