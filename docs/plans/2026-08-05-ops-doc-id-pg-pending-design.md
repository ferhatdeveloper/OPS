# Ortak ops_doc_id + PG pending (Logo fail yedeği)

**Tarih:** 2026-08-05  
**Durum:** Tasarım onaylı (Accept A) — minimal uygulama

## Verdict — 3 DB ortak ID şeması

| Alan | SQLite | Logo Tiger | PostgREST |
|------|--------|------------|-----------|
| **ops_doc_id** | `invoices.id` (UUID, cihazda) | — (yerel anahtar) | `id` = `ops_doc_id` (PK upsert) |
| **NUMBER / idempotency_code** | kuyruk payload + dens `document_no` | `NUMBER` (aynı string) | `idempotency_code` |
| **logo_ref** | `logo_ref` | LOGICALREF / internal | `logo_ref` (pending’de null) |
| **Durum** | `is_synced`, `pg_synced` | fiş var/yok | `logo_synced` + `sync_status` |

**Kural:** `ops_doc_id` ve `NUMBER` fatura kesiminde bir kez üretilir; retry’da asla yenilenmez.  
`NUMBER = OutboundIdempotency.ficheNumber(entityType, ops_doc_id)` (örn. `OI` + UUID 12 hex).

## Yaklaşımlar (kısa)

1. **A — PG pending → Logo → PG confirmed** (önerilen)  
   Logo down iken merkezde yedek; aynı id ile upsert → duplicate yok.
2. **B — Logo-first (mevcut)**  
   Logo fail → PG yok; cihaz kaybında merkezde iz yok.
3. **C — Paralel Logo+PG**  
   Yarış / sıra belirsiz; muhasebe “Logo first” bozulur.

**Seçim:** A. Logo muhasebe kaynağı kalır; PG cihaz kaybına karşı pending yedek.

## Akış

```
Fatura kes → SQLite (id=ops_doc_id) + sync_queue(phase=pg_pending)
  1) PostgREST upsert pending
       id/ops_doc_id, idempotency_code=NUMBER,
       logo_synced=0, sync_status=logo_pending
  2) phase=logo → Tiger/Exfin POST (NUMBER + findByNumber)
       OK → logo_ref + is_synced=1
  3) phase=postgrest → PG upsert confirmed
       logo_ref, logo_synced=1, sync_status=confirmed
       → pg_synced=1 + kuyruk sil
```

Logo fail → kuyruk `logo`’da kalır; **PG’de pending satır durur**.  
Retry: aynı `ops_doc_id` / `NUMBER` / `findByNumber`.

## Mevcut kod uyumu / gap

| Var | Gap (kapatıldı / kapanacak) |
|-----|------------------------------|
| UUID `entityId` + kararlı NUMBER | `ops_doc_id` adı dokümante; PG body’ye yaz |
| Logo → PG iki aşama | **PG pending aşaması yoktu** → `pg_pending` |
| PG `id` upsert | pending’de `logo_synced=0` yoktu |
| `logo_ref` / findByNumber | dokunulmadı |

## Risk

- Kiracı tabloda `ops_doc_id` / `sync_status` kolonları yoksa PostgREST ignore/hata → Prefer merge + güvenli alan seti; bilinmeyen kolon hatasında retry.
- Eski kuyruk işleri `logo`/`postgrest` fazında kalabilir (normalize uyumlu).
- PG pending ≠ muhasebe onayı; raporlar `logo_synced=1` filtrelemeli.

## TODO

1. JobQueue: `pg_pending` → `logo` → `postgrest`
2. Mirror: pending vs confirmed bayrakları
3. InvoicePersist: payload `NUMBER` + `ops_doc_id`; dens `document_no` = NUMBER
4. Unit test: phase normalize + pending body
5. (Sonra) sipariş / irsaliye / tahsilat aynı şema
6. (Sonra) PG şema migration doğrulama (kolonlar)
