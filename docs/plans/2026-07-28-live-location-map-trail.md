# Canlı konum harita + kişi trail

**Tarih:** 2026-07-28  
**Kapsam:** `GpsTrackingScreen` Liste|Harita, canlı pin, kişi bazlı `gps_logs` polyline

## Sonuç

| Parça | Durum |
|-------|--------|
| Liste \| Harita dens chip | AppBar `FieldSalesDensFilterBar` |
| Canlı personel Marker | `GpsTrackingMapPane` + `OfflineAwareTileProvider` |
| Kişi seçimi | Liste satırı / pin / yatay chip → zoom |
| Geçmiş trail | Bugün / Bu Hafta dens chip → `PersonnelLocationTrailStore` |
| Kaynak sırası | PostgREST `/gps_logs` → PG → yerel SQLite |

## Akış

1. Canlı satırlar: mevcut `PersonnelLiveLocationStore` / Realtime-poll
2. Harita: pin tap → seçim + zoom; trail yükle
3. `PersonnelLocationTrailStore.loadTrail(code, start, end)` → `mergeChronological`
4. Polyline (≥2 nokta); boşsa dens empty metin

## Dosyalar

- `gps/view/gps_tracking_screen.dart`
- `gps/view/gps_tracking_map_pane.dart`
- `gps/viewmodel/personnel_location_trail_store.dart`
- `gps/model/personnel_location_trail_point.dart`

## Test

```bash
flutter test test/modules/field_sales/gps/personnel_location_trail_store_test.dart
flutter test test/modules/field_sales/gps/gps_tracking_map_smoke_test.dart
flutter test test/modules/field_sales/gps/gps_last_location_store_test.dart
```
