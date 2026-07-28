# Logo Tiger REST

## Açıklama
RetailEX `logoRestApi` / `logoRestSync` / `logoRestInvoicePush` pattern’inin OPS
Dart karşılığı. Doğrudan Logo Tiger Objects REST (`/api/v1`) üzerinden master
veri çeker ve JobQueue push’unu yazar.

Kaynak of truth: yerel **SQLite** + **JobQueue** (`sync_queue`).
Transport: Tiger açıkken Objects REST POST; kapalıysa Exfin middleware
(`LogoApiService` → `/api/v1/logo/erp/*`).

**Outbound sıra (zorunlu):** `Logo önce` → başarıda `PostgREST mirror`.
Çift fatura: kararlı `NUMBER` + `findByNumber` + yerel `logo_ref`.
Detay: `docs/plans/2026-07-28-logo-then-postgrest-outbound.md`.

## Dosyalar
- `logo_tiger_urls.dart`: URL normalize, help URI, header
- `logo_tiger_config.dart`: Bağlantı modeli (`canPush`)
- `logo_tiger_settings_store.dart`: Obfuscated SharedPreferences
- `logo_tiger_rest_client.dart`: token, CompanyLogin, list/paginate, **create/POST**, `findByNumber`
- `logo_tiger_pull_sync.dart`: SQLite upsert (products/customers/warehouses/orders)
- `logo_tiger_push_adapter.dart`: LogoPayloadMapper → Tiger `restRecord` (+ idempotent NUMBER)
- `logo_tiger.dart`: barrel
- `../sync/outbound_idempotency.dart`: kararlı fiş no
- `../sync/outbound_sync_phases.dart`: `logo` | `postgrest`
- `../sync/postgrest_document_mirror.dart`: 2. aşama kiracı upsert

## Pull (çek)
1. Tiger açıkken **Al** / **Tiger’dan çek** → `LogoTigerPullSync`
2. Base URL sırası: Tiger store → Logo REST prefs → **Sunucu ayarları** (`api_config`)
3. `LogoServerUrlBridge` — Ayarlar’da kaydedilen link Logo çekimine yazılır

## Push akışı (gönder)
1. Saha belgesi SQLite’a yazılır → `JobQueueService.enqueue` (`sync_phase=logo`)
2. `processQueue` → **aşama 1 Logo**
3. Yerelde `logo_ref` doluysa POST atlanır (çift fiş yok)
4. Tiger açıksa: kararlı NUMBER + `findByNumber` → varsa dedupe; yoksa POST
5. Logo OK → `logo_ref` + `is_synced=1` → `sync_phase=postgrest` (kuyruk silinmez)
6. **Aşama 2 PostgREST** mirror (`rex_{FF}_invoices` vb.); tenant yoksa skip ok
7. PG OK → `pg_synced=1` + kuyruk sil; PG fail → phase=postgrest’te retry (Logo tekrar yazılmaz)
8. Tiger kapalı / desteklenmeyen entity → Exfin Logo yolu, sonra aynı PG aşaması

### Tiger’a yazılan entity’ler
| Kuyruk tipi | REST kaynak |
|-------------|-------------|
| order (sales) | `salesOrders` |
| order (purchase) / supply request | `purchaseOrders` |
| invoice (wholesale/return/retail) | `salesInvoices` |
| invoice (purchase) | `purchaseInvoices` |
| waybill/dispatch | `salesDispatches` / `purchaseDispatches` |

### Exfin’de kalan (Tiger push yok)
- tahsilat / virman (`collection`)
- stok transfer, üretimden giriş, kampanya, ziyaret stub’ları

## Kullanım
1. Saha Satış → Güncelleme → Logo REST ayarları
2. **Tiger REST ile veri çek/gönder** aç
3. Base URL (host:port) + api_key + OAuth alanları kaydet
4. Help ping veya Bağlantı test
5. Pull: **Tiger’dan çek** veya Güncelleme → Al
6. Push: normal “cihazdakileri gönder” / JobQueue — Tiger açıksa Objects POST

## Bağımlılıklar
- `dio`, `shared_preferences`, `sqflite`
- `RememberMeCrypto` (secret obfuscation)
- JobQueue: `lib/service/job_queue_service.dart`
