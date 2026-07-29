# PostgREST Kiracı Login — RetailEX Parity + OPS Kullanım

**Tarih:** 2026-07-26  
**Kapsam:** Login’de kiracı kodu → PostgREST tenant context  
**Commit:** Yok  
**WHMS:** Tam entegrasyon değil  
**Logo REST:** Ayrı kalır (veri katmanı = PostgREST kiracı; ERP = Logo)

---

## 1. RetailEX teknik özet

| Konu | RetailEX davranışı | Dosyalar |
|------|--------------------|----------|
| SaaS kök | `https://api.retailex.app` | `src/core/remotePgDefaults.ts`, `config/remote-pg.defaults.json` |
| Kiracı URL | `{origin}/{kiracı_kodu}` (Caddy tek segment) | `src/services/merkezTenantRegistry.ts` → `buildSaaSTenantPostgrestUrl` |
| Etkili URL | Kök + `merkez_tenant_code` birleşimi | `resolveEffectiveRemoteRestUrl` |
| Merkez registry | `GET {merkez}/tenant_registry?code=eq.{kod}` | `fetchTenantRegistryRow`, `getMerkezRestBaseUrl` (`…/merkez`) |
| Şema | `Accept-Profile` / `Content-Profile` (varsayılan `public`) | `src/config/postgrest.config.ts`, `src/services/api/postgrestClient.ts` |
| JWT | Opsiyonel Bearer; conf’de `jwt-secret` | `config/postgrest.conf`, `postgrestClient.ts` |
| pg_bridge | Hono SQL proxy **3001**; PostgREST **3002** | `database/README_POSTGREST.md` |
| Config alanları | `merkez_tenant_code`, `remote_rest_url`, `connection_provider` | `src/services/postgres.ts` (`DB_SETTINGS`) |

**Akış (RetailEX):** Kullanıcı kiracı kodu (veya `https://api…/aqua`) girer → registry veya SaaS slug → `remote_rest_url` + `merkez_tenant_code` localStorage/config → `getPostgrestBaseUrl()`.

---

## 2. OPS uygulaması

### Dosyalar

| Dosya | Rol |
|-------|-----|
| `lib/core/tenant/tenant_connection_resolver.dart` | Saf çözümleme (RetailEX parity) |
| `lib/core/tenant/tenant_context.dart` | Bağlam modeli |
| `lib/core/tenant/tenant_store.dart` | SharedPreferences kalıcılık |
| `lib/core/tenant/postgrest_tenant_service.dart` | Login apply + registry fetch + Logo bootstrap |
| `lib/core/tenant/tenant_registry_row.dart` | Merkez satırının tipli modeli (secret yok) |
| `lib/core/tenant/merkez_tenant_registry_service.dart` | Merkez HTTP okuma (best-effort) |
| `lib/core/tenant/tenant_logo_config_cache.dart` | Tenant Logo başlangıç değerleri modeli |
| `lib/core/tenant/tenant_logo_config_store.dart` | Tek anahtarlı prefs cache |
| `lib/core/logo/logo_tenant_config_seeder.dart` | Registry → Tiger seed politikası |
| `lib/core/tenant/postgrest_tenant_defaults.dart` | SaaS kök / şema sabitleri |
| `lib/service/postgres_service.dart` | `setActiveTenantContext` / `postgrestHeaders` |
| `lib/core/tenant/saas_origin_override_dialog.dart` | Gelişmiş SaaS kök override (prefs) |
| `lib/view/login_screen.dart` | Kiracı kodu + gizli uzun basış + ayar menüsü |
| `assets/translations/*.json` | `auth.tenant_*` |
| `test/core/tenant/*_test.dart` | Resolve + store |

### Login akışı

1. Kullanıcı **Kiracı Kodu** (+ kullanıcı / şifre) girer.  
2. `PostgrestTenantService.applyTenantCode` → SaaS URL veya direct URL.  
3. Prefs’e yazılır; `PostgresService.setActiveTenantContext` bağlanır.  
4. Mevcut `AuthService` / SQLite offline login devam eder.  
5. `ActiveCompanyStore` firma/dönem ayrı; Logo REST ayrı (`LogoRestSettingsService`).

### Offline-first politika

| Durum | Davranış |
|-------|----------|
| Kiracı boş + prefs boş | Hata: `auth.tenant_required` |
| Kiracı boş + prefs dolu | Son kiracı ile devam (`usedOfflineCache`) |
| Ağ yok / registry timeout | Yerel SaaS slug hesaplanır veya son kayıt |
| Geçersiz URL / merkez path | `auth.tenant_invalid` |

SQLite offline satış verisi kiracıdan bağımsız çalışmaya devam eder; uzak PostgREST çağrıları aktif `remoteRestUrl` ister.

### Logo çakışması

- **PostgREST kiracı** = merkez / hibrit veri katmanı.  
- **Logo REST** = ERP fiş / stok senkronu; `ActiveCompanyStore` yalnızca firma/dönem sync eder.  
- İkisi aynı anda yapılandırılabilir; URL’ler karıştırılmaz.

---

## 2b. Merkez registry Logo yapılandırması (2026-07-29)

Tasarım: `docs/plans/2026-07-29-tenant-registry-logo-config-design.md`

### Kesin merkez sorgusu

```text
GET {saasOrigin}/merkez/tenant_registry
  ?code=eq.{uriEncodedTenantCode}
  &select=code,rest_base_url,display_name,is_active,logo_rest_api_url,
          logo_firm_nr,logo_period_nr,logo_db,updated_at
  &limit=1
```

Header: `Accept: application/json`, `Accept-Profile: public`.
`select` sabiti: `MerkezTenantRegistryService.selectColumns`. Regex parse
tamamen kaldırıldı; yanıt `jsonDecode` ile tipli modele çevrilir.

**Güvenlik riski:** Merkez endpoint şu an anonimdir. Production'da RLS,
sınırlı view veya merkez `apikey`/JWT ile yalnızca gerekli kolonların
okunması gerekir. Kiracı kodu `Uri.replace(queryParameters:)` ile encode
edilir; şema adı ve header sabittir.

### Logo endpoint kaynak önceliği

1. Kullanıcının **manuel** Tiger ayarı (`LogoUrlSource.tigerStore`)
2. Aktif kiracının **tenant registry** seed'i (`LogoUrlSource.tenantRegistry`)
3. Logo REST prefs (`LogoUrlSource.logoRestSettings`)
4. Genel `api_config` (`LogoUrlSource.serverSettings`)
5. Yapılandırılmamış (`LogoUrlSource.none`)

Manuel kayıt `LogoTigerSettingsStore.save(...)` varsayılanı ile
`logo_tiger_manual_override = true` işaretler. Registry seed
`markManualOverride: false` gönderir; bu nedenle **registry manuel ayarı
ezmez**.

### TTL ve offline cache

- Logo değerleri `TenantLogoConfigStore` içinde tek JSON anahtarında
  (`ops_tenant_logo_registry_cache_v1`) tenant'a bağlı saklanır.
- Varsayılan TTL **15 dakika** (`PostgrestTenantService.registryCacheTtl`).
- Cache tazeyse merkez isteği yapılmaz, cache seed edilir.
- TTL dolduğunda yenileme best-effort'tur; hata halinde **son geçerli cache
  korunur** ve yeniden uygulanır.
- Kayıtlı `remoteRestUrl` kısa devresi Logo bootstrap'ını **atlatmaz**.
- `restoreActiveContext()` ağ beklemeden aynı kiracının cache'ini seed eder.
- Farklı kiracının cache'i aktif kiracıya uygulanmaz.

### Firma / dönem sınırı

`logo_firm_nr` ve `logo_period_nr` yalnızca **bootstrap varsayılanıdır**.
Etkin çalışma bağlamı kullanıcının `ActiveCompanyStore` seçimidir; registry
seed bu seçimi değiştirmez. `LogoTigerRestClient.companyLogin(firmNr:,
periodNr:)` açık parametre aldığında config varsayılanını ezer.

### Secret sınırı

Registry `api_key`, parola, OAuth `client_id`/`client_secret` ve access token
sağlamaz; mevcut secret'ları da temizlemez. `TenantRegistryRow` ve
`TenantLogoConfigCache` bu alanları taşımaz. Loglar yalnızca hata tipini
yazar; response body / URL query loglanmaz.

### Fallback tablosu

| Durum | Davranış |
|---|---|
| Merkez timeout / ağ yok | Son tenant Logo cache'i; yoksa mevcut Logo ayarları |
| HTTP 4xx / 5xx | Mevcut SaaS slug ve Logo fallback zinciri |
| Boş registry dizisi | Registry uygulanmaz |
| `is_active=false` | Tenant ve Logo registry değerleri uygulanmaz |
| Geçersiz JSON / tip | Son geçerli cache korunur |
| Geçersiz Logo URL | Logo seed atlanır |
| Eksik firma/dönem/`logo_db` | Mevcut değerler silinmez |
| Eski / eşit `updated_at` | Daha yeni yerel seed ezilmez |
| Manuel override | Registry mevcut manuel ayarı ezmez |
| Tenant değişimi | Önceki tenant'ın Logo cache'i kullanılmaz |

**Bilinen sınır:** `LogoTigerSettingsStore.save` mevcut mimaride URL'i
`LogoTigerUrls.parseUserInput` ile host:port'a indirger ve port yoksa
`32001` ekler. Registry'de `https` + standart port kullanılıyorsa bu davranış
şemayı `http`'ye düşürür. Registry değerleri açık port ile girilmelidir.

---

## 3. Panel çıktısı

| Rol | Durum | Risk | TODO |
|-----|--------|------|------|
| Merkez | **Hazır** | Özel Caddy path’leri | — (SaaS origin override UI: prefs + gizli uzun basış + ayar menüsü) |
| Saha satış | **Hazır** | Login blokajı yanlış kodda | Plasiyer gün akışında tenant chip |
| Dil | **Hazır** | Sync script | Key’lerin tüm dillere yansıdığını doğrula |
| Tester | **Hazır** | Registry HTTP mock yok | Dio/http mock ile registry probe testi |
| Yazılım | **Hazır** | Postgres local URI hâlâ sabit | İleride remote PG endpoint prefs |
| UI | **No-touch** | Alan eklendi | Redesign yok |

```text
❌ BAD: Login’i yeniden tasarlamak; Logo baseUrl’i kiracı PostgREST ile değiştirmek
✅ GOOD: Dens TextFormField + l10n; TenantStore + setActiveTenantContext
```

---

## 4. Doğrulama

```bash
flutter test test/core/tenant/
flutter test test/core/logo/
```
