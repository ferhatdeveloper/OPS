# PostgREST Web CORS — Geliştirme Proxy

**Tarih:** 2026-07-28  
**Araç:** `tool/postgrest_cors_proxy.dart`  
**l10n:** `auth.postgrest_web_cors` (login hata mesajı)

## Sorun

Flutter web (`localhost:8080` vb.) doğrudan `https://api.retailex.app` PostgREST’e giderken tarayıcı **CORS** engeller. Login ekranı bu durumda `auth.postgrest_web_cors` anahtarını gösterir.

## Hızlı kullanım

```bash
cd /Users/ferhatnas/App/EXFINOPS
dart run tool/postgrest_cors_proxy.dart
```

Varsayılan:

| Ayar | Değer |
|------|--------|
| Dinleme | `http://127.0.0.1:8799` |
| Upstream | `https://api.retailex.app` |

Ortam değişkenleri:

- `POSTGREST_UPSTREAM` — hedef API kökü
- `POSTGREST_PROXY_PORT` — yerel port (8787 Cursor msgsrvr ile çakışmasın diye 8799)

## Uygulama tarafı

1. Proxy’yi çalıştırın.
2. Login → dişli → **SaaS kök adresi** = `http://127.0.0.1:8799`
3. Alternatif: `flutter run -d chrome --dart-define=WEB_SAAS_ORIGIN=http://127.0.0.1:8799`
4. Kiracı kodu ile **Bağlan**.

## Kalıcı üretim

Sunucuda Caddy/nginx ile `Access-Control-Allow-Origin` içine web origin’inizi ekleyin; geliştirme proxy’si gerekmez.

## İlgili dosyalar

- `tool/postgrest_cors_proxy.dart` — OPTIONS + CORS header proxy
- `lib/view/login_screen.dart` — CORS hata eşlemesi → `auth.postgrest_web_cors`
