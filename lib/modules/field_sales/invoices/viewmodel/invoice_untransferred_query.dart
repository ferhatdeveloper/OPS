// Dosya Adı: invoice_untransferred_query.dart
// Açıklama: Transfer edilmeyen fatura dens — SQLite / sync_queue bağlama
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:convert';

import '../model/invoice_untransferred_record.dart';
import '../model/invoice_untransferred_seed.dart';

/// {@template invoice_untransferred_query}
/// `invoices` (is_synced=0) + `sync_queue` (entity=invoice) dens bağlayıcı.
///
/// Kullanım örneği:
/// ```dart
/// final rows = InvoiceUntransferredQuery.onlyUnsynced(all);
/// ```
/// {@endtemplate}
class InvoiceUntransferredQuery {
  InvoiceUntransferredQuery._();

  /// {@template invoice_untransferred_query_only_unsynced}
  /// is_synced != 0 ve silinmiş kayıtları eler.
  ///
  /// Parametreler:
  /// - [rows]: Kaynak dens satırlar
  ///
  /// Dönüş değeri:
  /// - [List]: Yalnızca transfer edilmeyenler
  /// {@endtemplate}
  static List<InvoiceUntransferredRecord> onlyUnsynced(
    List<InvoiceUntransferredRecord> rows,
  ) {
    return rows
        .where((r) => r.isSynced == 0 && r.isDeleted == 0)
        .toList(growable: false);
  }

  /// {@template invoice_untransferred_query_from_invoice_sqlite}
  /// SQLite `invoices` satır map'lerinden dens kayıt üretir.
  ///
  /// Parametreler:
  /// - [maps]: invoices query sonucu
  ///
  /// Dönüş değeri:
  /// - [List]: Unsynced dens kayıtları
  /// {@endtemplate}
  static List<InvoiceUntransferredRecord> fromInvoiceSqliteMaps(
    List<Map<String, dynamic>> maps,
  ) {
    final parsed = maps.map(InvoiceUntransferredRecord.fromMap).toList();
    return onlyUnsynced(parsed);
  }

  /// {@template invoice_untransferred_query_from_sync_queue}
  /// sync_queue satırlarından entity_type=invoice dens kayıtları.
  ///
  /// Parametreler:
  /// - [jobs]: sync_queue query sonucu
  ///
  /// Dönüş değeri:
  /// - [List]: Kuyruktaki fatura dens satırları
  /// {@endtemplate}
  static List<InvoiceUntransferredRecord> fromSyncQueueJobs(
    List<Map<String, dynamic>> jobs,
  ) {
    final out = <InvoiceUntransferredRecord>[];
    for (final job in jobs) {
      final type = (job['entity_type'] ?? '').toString().toLowerCase();
      if (type != InvoiceUntransferredSeed.entityType) continue;

      Map<String, dynamic> payload = {};
      final raw = job['payload'];
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            payload = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          payload = {};
        }
      } else if (raw is Map) {
        payload = Map<String, dynamic>.from(raw);
      }

      final entityId = (job['entity_id'] ?? payload['id'] ?? '').toString();
      if (entityId.isEmpty) continue;

      final merged = <String, dynamic>{
        ...payload,
        'id': payload['id'] ?? entityId,
        'queue_job_id': job['id']?.toString(),
        'retry_count': job['retry_count'],
        'last_error': job['last_error'],
        'is_synced': 0,
      };
      out.add(InvoiceUntransferredRecord.fromMap(merged));
    }
    return out;
  }

  /// {@template invoice_untransferred_query_merge}
  /// SQLite + kuyruk satırlarını id ile birleştirir (kuyruk öncelikli).
  ///
  /// Parametreler:
  /// - [local]: invoices unsynced
  /// - [queued]: sync_queue invoice
  ///
  /// Dönüş değeri:
  /// - [List]: Birleşik dens listesi
  /// {@endtemplate}
  static List<InvoiceUntransferredRecord> mergeLocalAndQueue({
    required List<InvoiceUntransferredRecord> local,
    required List<InvoiceUntransferredRecord> queued,
  }) {
    final byId = <String, InvoiceUntransferredRecord>{};
    for (final r in local) {
      byId[r.id] = r;
    }
    for (final r in queued) {
      final existing = byId[r.id];
      if (existing == null) {
        byId[r.id] = r;
      } else {
        byId[r.id] = existing.copyWith(
          queueJobId: r.queueJobId ?? existing.queueJobId,
          retryCount: r.retryCount,
          lastError: r.lastError ?? existing.lastError,
          customerCode: r.customerCode ?? existing.customerCode,
          customerName: r.customerName ?? existing.customerName,
          amount: r.amount != 0 ? r.amount : existing.amount,
          invoiceType: r.invoiceType ?? existing.invoiceType,
          documentNo: r.documentNo.isNotEmpty
              ? r.documentNo
              : existing.documentNo,
        );
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final da = a.documentDate ?? a.createdAt ?? DateTime(1970);
        final db = b.documentDate ?? b.createdAt ?? DateTime(1970);
        return db.compareTo(da);
      });
    return list;
  }
}
