# Logo Tiger REST

## Açıklama
RetailEX `logoRestApi` / `logoRestSync` / `logoRestInvoicePush` pattern’inin OPS
Dart karşılığı. Doğrudan Logo Tiger Objects REST (`/api/v1`) üzerinden master
veri çeker ve JobQueue push’unu yazar.

Kaynak of truth: yerel **SQLite** + **JobQueue** (`sync_queue`).
Transport: Tiger açıkken Objects REST POST; kapalıysa Exfin middleware
(`LogoApiService` → `/api/v1/logo/erp/*`).

**Outbound sıra (zorunlu):** `PG pending` → `Logo` → `PG confirmed`.
Çift fatura: ortak `ops_doc_id` (= yerel UUID / `client_doc_id`) + kararlı
`NUMBER` (Tiger push’ta `force: true`) + `findByNumber` + yerel `logo_ref`.
Logo fail olsa bile PG’de pending satır kalır (`logo_synced=0` ≠ muhasebe onayı).
Detay: `docs/plans/2026-08-05-ops-doc-id-pg-pending-design.md`.

## Dosyalar
- `logo_active_firm_period.dart`: ActiveCompany → Tiger firma/dönem bellek köprüsü
- `logo_tiger_urls.dart`: URL normalize, help URI, header
- `logo_tiger_config.dart`: Bağlantı modeli (`canPush`)
- `logo_tiger_settings_store.dart`: Obfuscated SharedPreferences (+ manuel override / registry seed işareti)
- `logo_tenant_config_seeder.dart`: Tenant registry Logo cache → Tiger seed politikası
- `logo_tiger_rest_client.dart`: token, CompanyLogin, list/paginate, **create/POST**, `findByNumber`
- `logo_tiger_pull_sync.dart`: SQLite upsert (products/customers/warehouses/orders/salesmen + opsiyonel cash/banks/unitSets; currencies yerel tablo yoksa skip)
- `logo_tiger_startup_pull.dart`: İlk açılış / henüz senkronlanmamışken otomatik master pull (spam yok)
- `logo_tiger_push_adapter.dart`: LogoPayloadMapper → Tiger `restRecord` (+ idempotent NUMBER)
- `logo_tiger.dart`: barrel
- `../sync/outbound_idempotency.dart`: kararlı fiş no + ops_doc_id
- `../sync/outbound_sync_phases.dart`: `pg_pending` | `logo` | `postgrest`
- `../sync/postgrest_document_mirror.dart`: pending + confirmed upsert

## Base URL kaynak önceliği
1. Kullanıcının **manuel** Tiger ayarı — `LogoUrlSource.tigerStore`
2. Aktif kiracının **tenant registry** seed'i — `LogoUrlSource.tenantRegistry`
3. Logo REST prefs — `LogoUrlSource.logoRestSettings`
4. Sunucu `api_config` — `LogoUrlSource.serverSettings`

Registry seed `LogoTigerSettingsStore.save(..., markManualOverride: false)`
kullanır; **manuel ayarı ezmez**. Registry `api_key`, parola, `client_secret`
ve access token sağlamaz, mevcut secret'ları da temizlemez.
`logo_firm_nr` / `logo_period_nr` yalnızca bootstrap varsayılanıdır; etkin
firma/dönem `ActiveCompanyStore` seçimidir (`LogoActiveFirmPeriod` +
`ensureSession`/`CompanyLogin`). Offline: tenant'a bağlı cache
(TTL 15 dk) `PostgrestTenantService` üzerinden yeniden uygulanır.
Detay: `docs/plans/2026-07-26-postgrest-tenant-login.md` §2b.

## Pull (çek)
1. Tiger açıkken **Al** / **Tiger’dan çek** → `LogoTigerPullSync`
2. Base URL sırası: yukarıdaki kaynak önceliği
3. `LogoServerUrlBridge` — Ayarlar’da kaydedilen link Logo çekimine yazılır
4. **Düz adres yeterli:** `185.86.15.238` + Port `32001` → otomatik `http://…/api/v1`
5. **Plasiyer → kullanıcı:** Logo `salesmen` çekilince OPS’ta yoksa
   `username=CODE`, `password=1234`, `role=salesperson` oluşturulur (mevcut şifre ezilmez)
6. **Opsiyonel master pull** (`pullAll` bayrakları, varsayılan `false`):
   - `cash` → `safeDeposits`/`safes`/`cashSafes` → `cash_cards`
   - `banks` → `bankAccounts`/`banks` → `bank_cards`
   - `unitSets` → `unitSets` → `unit_sets` + `unit_set_lines`
   - `currencies` → yerel kur tablosu yoksa `message: no local table` (0 kayıt)
   - Kaynak 404/yoksa sessizce 0 kayıt; tüm pull düşmez
7. **İlk açılış otomatik pull** (`LogoTigerStartupPull`):
   - `main` Logo API init sonrası arka planda; ayrıca auto-login / başarılı login
   - Tiger kapalı, kimlik yok veya ürün+cari zaten çekilmişse **skip** (spam yok)
   - Kapsam: ürün, cari, ambar, plasiyer, kasa, banka, birim set (sipariş/döviz yok)
   - Ağ hatası UI kırmaz; `debugPrint` + `LogoPullStateStore` kaydı

## Push akışı (gönder)
1. Saha belgesi SQLite’a yazılır → `JobQueueService.enqueue` (`sync_phase=pg_pending`)
2. `processQueue` → **aşama 1 PostgREST pending** (`ops_doc_id`, `logo_synced=0`)
3. **Aşama 2 Logo** — yerelde `logo_ref` doluysa POST atlanır (çift fiş yok)
4. Tiger açıksa: kararlı NUMBER + `findByNumber` → varsa dedupe; yoksa POST
5. Logo OK → `logo_ref` + `is_synced=1` → `sync_phase=postgrest`
6. **Aşama 3 PostgREST confirmed** (`logo_ref`, `logo_synced=1`); tenant yoksa skip ok
7. PG OK → `pg_synced=1` + kuyruk sil; PG fail → phase=postgrest’te retry (Logo tekrar yazılmaz)
8. Logo fail → phase=`logo`’da kalır; **PG pending satır merkezde durur** (cihaz yedeği)
9. Tiger kapalı / desteklenmeyen entity → Exfin Logo yolu, sonra aynı confirmed aşaması

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
