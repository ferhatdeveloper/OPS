# Logo → PostgREST outbound + çift fatura engeli

**Tarih:** 2026-07-28  
**Durum:** Uygulandı (JobQueue iki aşama)

## Karar

```
SQLite (SoT) → sync_queue
  1) Logo (Tiger REST / Exfin)   ← önce, ERP fişi
  2) PostgREST kiracı mirror     ← sonra, merkez kopya
```

PostgREST Logo yerine geçmez. Logo down iken kuyruk `phase=logo`’da kalır;
Logo OK + PG down ise `phase=postgrest`’te kalır (çift Logo fişi yok).

## Çift fatura engeli

1. **Kararlı NUMBER** — `OutboundIdempotency.ficheNumber(type, entityId)`  
   (örn. `OI` + UUID’nin 12 hex’i). Retry’da değişmez; `~` kullanılmaz.
2. **Önce GET** — Tiger `findByNumber` → varsa POST atlanır (`deduped`).
3. **Yerel `logo_ref`** — doluysa Logo POST atlanır; doğrudan PG aşaması.
4. **Duplicate hata** — Logo “already/unique” → yeniden find → success.

## Dosyalar

- `lib/core/sync/outbound_idempotency.dart`
- `lib/core/sync/outbound_sync_phases.dart`
- `lib/core/sync/postgrest_document_mirror.dart`
- `lib/service/job_queue_service.dart` (iki aşama)
- `lib/core/logo/logo_tiger_rest_client.dart` (`findByNumber`)
- `lib/core/logo/logo_tiger_push_adapter.dart` (NUMBER inject)

## Test

`flutter test test/core/sync/outbound_idempotency_test.dart test/core/logo/`
