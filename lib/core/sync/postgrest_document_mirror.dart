// Dosya Adı: postgrest_document_mirror.dart
// Açıklama: Belgeyi kiracı PostgREST’e yansıtır (pending / confirmed)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:flutter/foundation.dart';

import '../../service/job_queue_entity_map.dart';
import '../../service/postgres_service.dart';
import '../tenant/postgrest_http_client.dart';
import '../tenant/postgrest_table_names.dart';
import 'outbound_idempotency.dart';
import 'outbound_mirror_status.dart';

/// {@template postgrest_document_mirror}
/// Outbound: Logo öncesi pending + Logo sonrası confirmed mirror.
///
/// Tenant URL yoksa no-op success (mirror opsiyonel; Logo yine denenir).
/// Upsert anahtarı: [ops_doc_id] = yerel UUID (`id` = `client_doc_id`).
///
/// Muhasebe: pending satır (`logo_synced=0`) cihaz kaybı yedeğidir;
/// ERP fişi değildir. Confirmed ancak Logo `logo_ref` sonrası.
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

  /// Sync durumu: Logo henüz yazılmadı (= [OutboundMirrorStatus.logoPending]).
  static const String statusLogoPending = OutboundMirrorStatus.logoPending;

  /// Sync durumu: Logo OK, mirror tamam (= [OutboundMirrorStatus.confirmed]).
  static const String statusConfirmed = OutboundMirrorStatus.confirmed;

  /// {@template postgrest_document_mirror_build_upsert_body}
  /// Pending / confirmed upsert gövdesi (HTTP’siz; test edilebilir).
  ///
  /// Parametreler:
  /// - [entityId]: ops_doc_id / client_doc_id (UUID)
  /// - [firmNr]: padded firma no
  /// - [logoRef]: Logo ref (pending’de null)
  /// - [idempotencyCode]: kararlı NUMBER
  /// - [payload]: güvenli alanlar
  /// - [logoSynced]: false → pending yedek
  /// - [syncStatus]: varsayılan logo_pending / confirmed
  ///
  /// Dönüş değeri:
  /// - [Map]: PostgREST body
  /// {@endtemplate}
  static Map<String, dynamic> buildUpsertBody({
    required String entityId,
    required String firmNr,
    String? logoRef,
    String? idempotencyCode,
    Map<String, dynamic>? payload,
    bool logoSynced = true,
    String? syncStatus,
  }) {
    final opsId = OutboundIdempotency.opsDocId(entityId);
    final status = syncStatus ??
        (logoSynced
            ? OutboundMirrorStatus.confirmed
            : OutboundMirrorStatus.logoPending);

    final body = <String, dynamic>{
      'id': opsId,
      'ops_doc_id': opsId,
      'client_doc_id': opsId,
      'firm_nr': firmNr,
      if (logoRef != null && logoRef.isNotEmpty) 'logo_ref': logoRef,
      if (idempotencyCode != null && idempotencyCode.isNotEmpty)
        'idempotency_code': idempotencyCode,
      'is_synced': logoSynced ? 1 : 0,
      'logo_synced': logoSynced ? 1 : 0,
      'sync_status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (payload != null) ..._safePayloadFieldsStatic(payload),
    };
    body.removeWhere((k, v) => v == null);
    return body;
  }

  /// {@template postgrest_document_mirror_mirror}
  /// Belgeyi firm tablosuna upsert eder (`id` / `ops_doc_id` birincil anahtar).
  ///
  /// Parametreler:
  /// - [entityType]: kuyruk tipi
  /// - [entityId]: yerel id = ops_doc_id
  /// - [logoRef]: Logo LOGICALREF (pending’de null olabilir)
  /// - [idempotencyCode]: kararlı NUMBER
  /// - [payload]: isteğe bağlı özet alanlar
  /// - [logoSynced]: true → Logo yazıldı; false → pending yedek
  /// - [syncStatus]: örn. logo_pending / confirmed
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
    bool logoSynced = true,
    String? syncStatus,
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
    final body = buildUpsertBody(
      entityId: entityId,
      firmNr: firm,
      logoRef: logoRef,
      idempotencyCode: idempotencyCode,
      payload: payload,
      logoSynced: logoSynced,
      syncStatus: syncStatus,
    );

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

  static Map<String, dynamic> _safePayloadFieldsStatic(
    Map<String, dynamic> payload,
  ) {
    final out = <String, dynamic>{};
    for (final key in const [
      'customer_code',
      'ARP_CODE',
      'total_amount',
      'NUMBER',
      'number',
      'document_no',
      'ops_doc_id',
      'client_doc_id',
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
