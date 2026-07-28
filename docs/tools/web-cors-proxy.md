# Web CORS Proxy (PostgREST / WEB_SAAS_ORIGIN)

Flutter **web** (Chrome localhost) RetailEX PostgREST’e doğrudan istek atınca
tarayıcı CORS engeller. Geliştirme için yerel proxy + `WEB_SAAS_ORIGIN` kullanın.

## One-liner

```bash
dart run tool/postgrest_cors_proxy.dart & flutter run -d chrome --web-port=8080 --dart-define=WEB_SAAS_ORIGIN=http://127.0.0.1:8799
```

veya iki terminal:

```bash
# 1) Proxy (8799 → https://api.retailex.app)
dart run tool/postgrest_cors_proxy.dart

# 2) Web
flutter run -d chrome --web-port=8080 \
  --dart-define=WEB_SAAS_ORIGIN=http://127.0.0.1:8799
```

## Ne yapar?

| Parça | Değer |
|-------|--------|
| Proxy | `http://127.0.0.1:8799` → `https://api.retailex.app` |
| Dart define | `WEB_SAAS_ORIGIN` → `PostgrestTenantDefaults.effectiveSaasOrigin` |
| Alternatif | Login dişli → SaaS Kök Adresi → `http://127.0.0.1:8799` |

## Ortam değişkenleri (proxy)

- `POSTGREST_UPSTREAM` — varsayılan `https://api.retailex.app`
- `POSTGREST_PROXY_PORT` — varsayılan `8799`

## Kalıcı çözüm

Caddy / API tarafında `Access-Control-Allow-Origin` içine
`http://localhost:8080` (ve prod web origin) ekleyin; proxy yalnızca geliştirme
içindir.

Kaynak: `tool/postgrest_cors_proxy.dart`,
`lib/core/tenant/postgrest_tenant_defaults.dart`.
