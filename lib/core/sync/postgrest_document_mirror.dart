// Dosya Adı: postgrest_document_mirror.dart
// Açıklama: Logo başarılıktan sonra belgeyi kiracı PostgREST’e yansıtır
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';

import '../../service/job_queue_entity_map.dart';
import '../../service/postgres_service.dart';
import '../tenant/postgrest_http_client.dart';
import '../tenant/postgrest_table_names.dart';

/// {@template postgrest_document_mirror}
/// Outbound 2. aşama: Logo’da fiş oluştuktan sonra merkez mirror.
///
/// Tenant URL yoksa no-op success (Logo zaten yazıldı; mirror opsiyonel).
/// {@endtemplate}
class PostgrestDocumentMirror {
  /// [client]: PostgREST HTTP
  final PostgrestHttpClient client;

  /// [postgres]: aktif firma / tenant
  final PostgresService postgres;

  /// {@macro postgrest_document_mirror}
  PostgrestDocumentMirror({
    PostgrestHttpClient? client,
    PostgresService? postgres,
  })  : client = client ?? PostgrestHttpClient(),
        postgres = postgres ?? PostgresService.instance;

  /// {@template postgrest_document_mirror_is_configured}
  /// Kiracı REST URL tanımlı mı?
  /// {@endtemplate}
  bool get isConfigured {
    final url = postgres.activeRemoteRestUrl.trim();
    return url.isNotEmpty;
  }

  /// {@template postgrest_document_mirror_mirror}
  /// Belgeyi firm tablosuna upsert eder (id birincil anahtar).
  ///
  /// Parametreler:
  /// - [entityType]: kuyruk tipi
  /// - [entityId]: yerel id
  /// - [logoRef]: Logo LOGICALREF / internal ref
  /// - [idempotencyCode]: kararlı NUMBER
  /// - [payload]: isteğe bağlı özet alanlar
  ///
  /// Dönüş değeri:
  /// - true: yazıldı veya tenant yok (skip ok)
  /// - false: HTTP hata → JobQueue retry
  /// {@endtemplate}
  Future<bool> mirror({
    required String entityType,
    required String entityId,
    String? logoRef,
    String? idempotencyCode,
    Map<String, dynamic>? payload,
  }) async {
    if (!isConfigured) {
      debugPrint('PostgrestDocumentMirror: tenant yok → skip ok');
      return true;
    }

    final tableBase = jobQueueEntityTable(entityType);
    if (tableBase == null) {
      debugPrint('PostgrestDocumentMirror: tablo yok ($entityType) → skip');
      return true;
    }

    final firm = PostgrestTableNames.padFirm(postgres.activeFirmNr);
    final table = PostgrestTableNames.firmTable(firm, tableBase);

    final body = <String, dynamic>{
      'id': entityId,
      'firm_nr': firm,
      if (logoRef != null && logoRef.isNotEmpty) 'logo_ref': logoRef,
      if (idempotencyCode != null && idempotencyCode.isNotEmpty)
        'idempotency_code': idempotencyCode,
      'is_synced': 1,
      'logo_synced': 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (payload != null) ..._safePayloadFields(payload),
    };
    body.removeWhere((k, v) => v == null);

    try {
      await client.postRow(
        '/$table',
        body,
        returnRepresentation: false,
        extraHeaders: const {
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
      );
      return true;
    } catch (e) {
      debugPrint('PostgrestDocumentMirror.mirror: $e');
      return false;
    }
  }

  Map<String, dynamic> _safePayloadFields(Map<String, dynamic> payload) {
    final out = <String, dynamic>{};
    for (final key in const [
      'customer_code',
      'ARP_CODE',
      'total_amount',
      'NUMBER',
      'number',
      'invoice_date',
      'order_date',
      'status',
    ]) {
      if (payload.containsKey(key) && payload[key] != null) {
        out[key] = payload[key];
      }
    }
    return out;
  }
}
