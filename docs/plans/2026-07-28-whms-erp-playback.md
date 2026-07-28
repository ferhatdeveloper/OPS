# WHMS ERP Playback — Manuel Adımlar

**Tarih:** 2026-07-28  
**Amaç:** Logo/ERP bağlıymış gibi ambar süreçlerini aşama aşama doğrulamak.  
**Otomatik kanıt:** `test/modules/whms/whms_erp_playback_test.dart`  
**Gerçek Logo REST şart değil** — JobQueue (ONAY=1) + SQLite + WHMS motorları ERP simülasyonu sayılır.

## Önkoşul

```bash
flutter test test/modules/whms/whms_erp_playback_test.dart
```

Opsiyonel cihaz: `flutter devices` → iOS sim / Android emulator varsa smoke `flutter run` (UI automation zorunlu değil).

---

## Aşama tablosu

| # | Adım | Beklenen | Assert |
|---|------|----------|--------|
| 1 | Ambar + lokasyon + ürün/stok seed | MRK/IAD ambar; A-01/B-01 lokasyon; warehouse_stocks > 0; FIFO kuralı SKU-1 | `warehouses`, `whms_locations`, `warehouse_stocks`, `whms_fifo_rules` |
| 2 | Mal kabul → putaway onay | Emir draft→done; ONAY=1; lokasyon dolu | `whms_orders` ONAY=1; JobQueue `whms_order_mal_kabul` |
| 3 | Transfer MRK→IAD | Ürün satırı + lot; ONAY=1 | JobQueue `stock_transfer` |
| 4 | Sayım emri → fiili → tamamla | variance = fiili−sistem; ONAY=1 | JobQueue `stock_count`; `whms_count_results` |
| 5 | Pick rota + seri | route_seq ASC; seri zorunlu ürün SN dolu → done | ONAY=1; JobQueue `whms_order_pick` |
| 6 | Load + FIFO + picking control | Eksik fiili → block; eşleşen + lot → vehicle_stocks | JobQueue `whms_load_order`; araç stoğu |
| 7 | Rapor KPI | totalOrders / completed / sayım fark artmış | `WhmsOrderKpiStore.loadSummary()` |
| 8 | Her adım | Store state + JobQueue + ONAY | payload `ONAY=1` |

---

## Gap listesi (gerçek ERP olsa eksik)

| Konu | Durum | Not |
|------|-------|-----|
| Logo REST outbound | Stub | JobQueue enqueue var; gerçek HTTP sync yok |
| Logo inbound stok | Stub | `LogoStockBalancePort` ayrı; playback yerel `warehouse_stocks` |
| Sync worker drain | Eksik | ONAY=1 kuyrukta kalır; ONAY=2 (synced) otomatik değil |
| Ambar bakiye güncelleme (mal kabul/transfer) | Kısmi | Emir + kuyruk; stok hareket motoru tam ERP değil |
| e-İrsaliye / sevk belgesi | Yok | Load → araç stoğu; GİB belge yok |
| UI automation (sim) | Opsiyonel | Playback test CI’da yeterli |

---

## CI

```bash
flutter test test/modules/whms/whms_erp_playback_test.dart
```
