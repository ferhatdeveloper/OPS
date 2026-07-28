# Canlı konum taşıma — Realtime / poll

**Tarih:** 2026-07-28  
**Kapsam:** `LiveLocationRealtimeClient`, `LiveLocationPoller`, `GpsTrackingScreen`

## Sonuç

| Seçenek | Durum |
|---------|--------|
| Supabase Realtime (`*.supabase.co`) | **Dener** — `live_location_snapshots` Postgres changes |
| Özel WebSocket URL (tenant) | **Dener** — JSON satır / diff mesajları |
| Standart PostgREST (yalnız REST) | Realtime yok → **HTTP poll** + fingerprint backoff |
| UI | Doğruluk bandı (iyi/orta/zayıf) + transport rozeti |

## Akış

1. `PersonnelLiveLocationStore.createWatchClient()` → `LiveLocationRealtimeClient`
2. İlk `loadLive()` (PostgREST → PG → SQLite)
3. Supabase Realtime veya custom WS başarılıysa push + 45 sn safety poll
4. Aksi halde `LiveLocationPoller` (değişimde 3 sn, aynı snapshot’ta backoff)

## Doküman notu

Saf PostgREST Realtime sunmaz. Kiracı Supabase/WS değilse poll zorunludur — bu beklenen davranıştır.
