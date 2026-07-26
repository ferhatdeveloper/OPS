// Dosya Adı: offline_queue_detail_test.dart
// Açıklama: Offline kuyruk detay dens payload önizleme unit/widget testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:exfin_ops/modules/field_sales/sync/view/offline_queue_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('formatPayloadPreview', () {
    test('null → empty label', () {
      expect(
        OfflineQueueDetailScreen.formatPayloadPreview(null),
        'Payload yok',
      );
    });

    test('geçersiz JSON → invalid label', () {
      expect(
        OfflineQueueDetailScreen.formatPayloadPreview('{bad'),
        'Payload okunamadı',
      );
    });

    test('JSON string → indentli önizleme', () {
      final raw = jsonEncode({'type': 8, 'customer_code': 'C001'});
      final text = OfflineQueueDetailScreen.formatPayloadPreview(raw);
      expect(text, contains('"type": 8'));
      expect(text, contains('"customer_code": "C001"'));
      expect(text, contains('\n'));
    });

    test('Map → indentli önizleme', () {
      final text = OfflineQueueDetailScreen.formatPayloadPreview({
        'lines': [
          {'code': 'P001'},
        ],
      });
      expect(text, contains('"code": "P001"'));
    });
  });

  group('OfflineQueueDetailScreen dens', () {
    testWidgets('seed job payload önizlemesini gösterir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const OfflineQueueDetailScreen(),
      );

      expect(find.text('Offline Kuyruk Detay'), findsWidgets);
      expect(find.text('Payload Önizleme'), findsWidgets);
      expect(find.textContaining('INV-DEMO-001'), findsOneWidget);
      expect(find.textContaining('"customer_code": "C001"'), findsOneWidget);
      expect(find.textContaining('"type": 8'), findsOneWidget);
    });

    testWidgets('verilen job payloadını gösterir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        OfflineQueueDetailScreen(
          job: {
            'id': 'job-1',
            'entity_type': 'order',
            'entity_id': 'ORD-9',
            'payload': jsonEncode({'type': 'sales', 'arp_code': 'A1'}),
            'retry_count': 1,
            'last_error': 'timeout',
            'created_at': '2026-07-26T12:00:00.000',
          },
        ),
      );

      expect(find.textContaining('ORD-9'), findsOneWidget);
      expect(find.textContaining('order'), findsOneWidget);
      expect(find.textContaining('"arp_code": "A1"'), findsOneWidget);
      expect(find.textContaining('timeout'), findsOneWidget);
    });
  });
}
