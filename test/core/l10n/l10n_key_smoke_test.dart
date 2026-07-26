// Dosya Adı: l10n_key_smoke_test.dart
// Açıklama: Sipariş/cari akışı için kritik L10n anahtarlarının tr+en varlık smoke testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// {@template _flattenKeys}
/// Nested Map'i noktalı yol anahtarlarına düzleştirir.
/// {@endtemplate}
Set<String> _flattenKeys(dynamic node, [String prefix = '']) {
  final keys = <String>{};
  if (node is Map) {
    for (final entry in node.entries) {
      final path = prefix.isEmpty
          ? entry.key.toString()
          : '$prefix.${entry.key}';
      keys.add(path);
      keys.addAll(_flattenKeys(entry.value, path));
    }
  }
  return keys;
}

Map<String, dynamic> _loadTranslation(String relativePath) {
  final file = File(relativePath);
  expect(file.existsSync(), isTrue, reason: '$relativePath yok');
  final decoded = jsonDecode(file.readAsStringSync());
  expect(decoded, isA<Map<String, dynamic>>());
  return Map<String, dynamic>.from(decoded as Map);
}

void main() {
  /// Sipariş + cari seçim akışında kullanılan / beklenen kritik anahtarlar.
  const requiredKeys = <String>[
    'field_sales.customer_list',
    'field_sales.order_entry',
    'field_sales.order_cart_empty',
    'field_sales.no_customers',
    'field_sales.search_customer',
    'field_sales.no_customer_cards',
    'field_sales.customer_not_found',
    'field_sales.customer_selection',
    'field_sales.check_list_title',
    'field_sales.check_status_collateral',
    'field_sales.check_status_issued_company',
    'field_sales.check_list_empty',
    'field_sales.vehicle_km_label',
    'field_sales.vehicle_km_required',
    'field_sales.daily_notes',
    'field_sales.daily_notes_hint',
    'field_sales.resend_to_logo_tooltip',
    'field_sales.overall_progress',
    'field_sales.status_pending',
    'field_sales.status_skipped',
    'field_sales.status_completed',
    'field_sales.invoice_status_paid',
    'field_sales.invoice_status_pending',
    'field_sales.invoice_status_partial',
    'field_sales.collection_entry_title',
    'field_sales.payment_entry_title',
    'field_sales.virman_entry_title',
    'field_sales.stubs.payment_entry',
    'field_sales.stubs.virman',
    'field_sales.collection_confirm',
    'field_sales.amount_to_collect',
    'field_sales.payment_type_label',
    'field_sales.notes_optional',
    'field_sales.collection_notes_hint',
    'field_sales.check_details',
    'field_sales.bank_name',
    'field_sales.branch_name',
    'field_sales.check_number',
    'field_sales.check_document_no',
    'field_sales.check_due_date',
    'field_sales.check_endorsement',
    'field_sales.check_original_debtor',
    'field_sales.check_workplace',
    'field_sales.check_account_no',
    'field_sales.due_date_prefix',
    'field_sales.collection_saved',
    'field_sales.note_details',
    'field_sales.note_number',
    'field_sales.note_bank_name',
    'field_sales.note_due_date',
    'field_sales.visit_started_notif_title',
    'field_sales.visit_started_notif_body',
    'field_sales.visit_started_points_reason',
    'field_sales.route_map_empty',
    'field_sales.route_map_stops_count',
    'field_sales.route_map_point_subtitle',
    'field_sales.route_map_no_coords',
    'field_sales.route_map_pending_stop',
    'field_sales.stubs.route_map',
    'field_sales.data_transfer_title',
    'field_sales.send_from_device',
    'field_sales.receive_from_server',
    'field_sales.transferring',
    'field_sales.product_images',
    'field_sales.product_images_stub_done',
    'field_sales.customers_download_failed',
    'field_sales.products_download_failed',
    'field_sales.upload_queue_remaining',
    'modules.tahsilat_girisi',
  ];

  late Set<String> trKeys;
  late Set<String> enKeys;

  setUpAll(() {
    trKeys = _flattenKeys(_loadTranslation('assets/translations/tr.json'));
    enKeys = _flattenKeys(_loadTranslation('assets/translations/en.json'));
  });

  group('L10n key varlık smoke', () {
    for (final key in requiredKeys) {
      test('tr.json içinde $key var', () {
        expect(
          trKeys.contains(key),
          isTrue,
          reason: 'tr.json eksik: $key '
              '(yinelenen field_sales anahtarı ezmiş olabilir)',
        );
      });

      test('en.json içinde $key var', () {
        expect(
          enKeys.contains(key),
          isTrue,
          reason: 'en.json eksik: $key',
        );
      });
    }

    test('tr ve en field_sales altında en az bir ortak yaprak anahtar paylaşır',
        () {
      final trLeaves = trKeys
          .where((k) => k.startsWith('field_sales.') && k.split('.').length == 2)
          .toSet();
      final enLeaves = enKeys
          .where((k) => k.startsWith('field_sales.') && k.split('.').length == 2)
          .toSet();
      expect(trLeaves.intersection(enLeaves), isNotEmpty);
    });
  });
}
