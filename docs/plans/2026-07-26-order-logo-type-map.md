# Sipariş Satış/Alış → Logo TYPE map (mapper / queue)

**Tarih:** 2026-07-26  
**Kapsam:** P0-03 / P0-04 — minimal kod + belge  
**Commit:** Yok  

## Harita

| MBT / yerel | SQLite `order_type` | API `type` / `order_type` | `order_channel` | Yasak |
|-------------|---------------------|---------------------------|-----------------|-------|
| Sipariş Satış | `sales` | `sales` | `order_sales` | Fatura TYPE **8** / `wholesale` |
| Sipariş Alış | `purchase` | `purchase` | `order_purchase` | Satış siparişiyle aynı kanal |

Satır alanı `TYPE` = Logo Objects **kalem** tipi (`0` mal / `4` hizmet). Fiş kanalı değildir.

## Kod yolu

1. Kayıt: `OrderNotifier.saveOrder` → `orderType.storageValue`  
2. Map: `LogoPayloadMapper.orderFromLocal` + `resolveOrderApiType`  
3. Kuyruk: `JobQueueService._syncOrder` → `_ensureOrderTypeFields`  
4. Rebuild: `_buildOrderPayload` SQLite `orders.order_type` ile aynı mapper

## Dosyalar

- `lib/core/services/logo_payload_mapper.dart`
- `lib/service/job_queue_service.dart`
- `lib/modules/field_sales/orders/viewmodel/order_provider.dart`
- `test/core/services/logo_order_type_map_test.dart`
- Checklist: `docs/plans/2026-07-26-accounting-stub-checklist.md`

## Panel özeti

| Rol | Durum | Risk | TODO |
|-----|--------|------|------|
| Merkez | hazır (bu dilim) | TRCODE canlı doğrulama | Firma şeması notu |
| Saha satış | **hazır** | Alış → tedarikçi seçim; ziyaret carisi atlanır | Logo CLCARD ACCOUNTTYPE sync |
| Dil | n/a | — | UI metin yok |
| Tester | hazır (unit) | Widget enqueue yok | Widget smoke opsiyonel |
| Yazılım | hazır | Backend `type` kabulü | ExfinApi `_normalize_order` teyit |
| UI | dokunulmadı | — | — |
| Muhasebe | yarım | KDV satır taşıma hâlâ zayıf | vat_rate enqueue |
