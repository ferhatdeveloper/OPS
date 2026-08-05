# Logo → PostgREST outbound + çift fatura engeli

**Tarih:** 2026-07-28  
**Durum:** Süpercede → `2026-08-05-ops-doc-id-pg-pending-design.md`  
(Logo muhasebe kaynağı korunur; **PG pending** Logo öncesine eklendi)

## Karar (güncel)

```
SQLite (SoT) → sync_queue
  1) PostgREST pending (ops_doc_id, logo_synced=0)  ← cihaz kaybı yedeği
  2) Logo (Tiger REST / Exfin)                     ← ERP fişi
  3) PostgREST confirmed (logo_ref, logo_synced=1)
```

Logo down iken kuyruk `phase=logo`’da kalır; **PG’de pending satır vardır**.  
Logo OK + PG confirmed down ise `phase=postgrest`’te kalır (çift Logo fişi yok).

## Çift fatura engeli

1. **ops_doc_id** — SQLite `id` = PG `id`/`ops_doc_id` (UUID, cihazda)
2. **Kararlı NUMBER** — `OutboundIdempotency.ficheNumber(type, ops_doc_id)`  
   (örn. `OI` + UUID’nin 12 hex’i). Retry’da değişmez; `~` kullanılmaz.
3. **Önce GET** — Tiger `findByNumber` → varsa POST atlanır (`deduped`).
4. **Yerel `logo_ref`** — doluysa Logo POST atlanır; doğrudan PG confirmed.
5. **Duplicate hata** — Logo “already/unique” → yeniden find → success.

## Dosyalar

- `lib/core/sync/outbound_idempotency.dart`
- `lib/core/sync/outbound_sync_phases.dart`
- `lib/core/sync/postgrest_document_mirror.dart`
- `lib/service/job_queue_service.dart` (üç aşama)
- `lib/core/logo/logo_tiger_rest_client.dart` (`findByNumber`)
- `lib/core/logo/logo_tiger_push_adapter.dart` (NUMBER inject)

## Test

`flutter test test/core/sync/outbound_idempotency_test.dart test/core/logo/`
