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
| `lib/core/tenant/postgrest_tenant_service.dart` | Login apply + opsiyonel registry probe |
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
```
