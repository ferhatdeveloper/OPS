# Gıda SFA CRUD Playback — Anadolu Gıda Dağıtım

**Tarih:** 2026-07-28  
**Amaç:** Gıda dağıtım / plasiyer senaryosunda cari → ürün → sipariş → tahsilat → cari ekstre ve yan CRUD’ları adım adım doğrulamak.  
**Otomatik kanıt:** `test/modules/field_sales/gida_sfa_crud_playback_test.dart`  
**Seed:** `lib/modules/field_sales/demo/gida_sfa_seed.dart`  
**Gerçek Logo REST şart değil** — `sync_queue` + `ONAY=1` / `approval_status=1` ERP simülasyonu sayılır.

## Önkoşul

```bash
flutter test test/modules/field_sales/gida_sfa_crud_playback_test.dart
```

Opsiyonel cihaz: `flutter devices` → iOS Simulator / macOS. Login engeli varsa seed + playback test yeterli.

---

## Demo firma

| Alan | Değer |
|------|--------|
| Ünvan | Anadolu Gıda Dağıtım |
| Kod | AGD |
| Ambar | MRK (Merkez Depo) |
| Plasiyer | PLS-AGD-01 |
| Risk limiti (market) | 50.000 TL |
| KDV | Un/Süt %1 · Yağ %10 · Gazoz %20 |

---

## Aşama tablosu (otomatik + manuel UI)

| # | Adım | C/R/U/D | Beklenen | Assert / UI |
|---|------|---------|----------|-------------|
| 0 | Ambar seed | C | MRK ambar | `warehouses` |
| 1a | Cari oluştur | C | Yeşil Market + Anadolu Lokantası | `customers` + queue `customer` |
| 1b | Cari listele | R | 2 aktif | dens cari listesi |
| 1c | Cari güncelle | U | telefon / adres | `customers.phone` |
| 1d | Cari soft-delete | D | `is_active=0` | queue `deactivate` |
| 2a | Ürün oluştur | C | Un, yağ, süt, gazoz | `ProductCatalogStore.upsert` |
| 2b | Lot / SKT | C | Süt OK + yağ NEAR | `batch_expiry` |
| 2c | Ürün listele | R | ≥4 SKU, KDV doğru | katalog dens |
| 2d | Ürün fiyat | U | Un 495 | `products.price` |
| 2e | Ürün sil | D | geçici SKU yok | queue `product` delete |
| 3a | Sipariş + satır | C | 3 kalem, KDV satır | `orders` + `order_items` |
| 3b | Risk kontrolü | — | bakiye+tutar ≤ limit | `GidaSfaSeed.isWithinRiskLimit` |
| 3c | Sipariş onay | U | status Approved, ONAY=1 | `OrderApprovalStore` + queue |
| 3d | Sipariş soft-delete | D | `is_deleted=1` | `OrderDensStore.softDeleteLocal` |
| 4a | Nakit / çek / senet | C | 3 tahsilat, ONAY=1 | `collections` + ekstre alacak |
| 4b | Tahsilat düzelt | U | nakit 1600 | `collections.amount` |
| 5a | Fatura stub | C | Sales + ONAY=1 | `invoices` + ekstre borç |
| 5b | Cari ekstre | R | borç+alacak + mutabakat | `CustomerExtractStore` |
| 6 | Ziyaret | C/U | Open→Completed | `visits` |
| 7 | Stok sorgu | R | MRK + GID-UN-50 | `WarehouseStockQueryStore` |
| 8 | WHMS mal kabul stub | C | JobQueue ONAY=1 | `whms_order_mal_kabul` |

---

## Manuel UI checklist (dens)

1. [ ] Cari form → Yeşil Market kaydet → listede gör
2. [ ] Ürün katalog → GID-UN-50 / GID-SUT-1L ekle
3. [ ] Parti/SKT → süt lotu görüntüle
4. [ ] Sipariş girişi → 3 satır → kaydet → onay dens’te Approved
5. [ ] Tahsilat → nakit + çek (veya senet)
6. [ ] Cari hesap ekstresi → dönem borç/alacak
7. [ ] Ziyaret check-in/out (opsiyonel)
8. [ ] Ambar stok sorgu MRK

---

## Gap listesi

| Konu | Durum | Not |
|------|-------|-----|
| Logo REST outbound | Stub | `sync_queue` ONAY=1; HTTP sync yok |
| `customers.credit_limit` | Demo ALTER | Üretim şemasında kolon yoksa risk UI alanları ayrı |
| Sync worker drain | Eksik | ONAY=2 (synced) otomatik değil |
| Fatura → Logo e-Fatura | Stub | Yerel `invoices` + ekstre |
| WHMS mal kabul UI | Stub | Yalnızca JobQueue satırı |
| UI automation (sim) | Opsiyonel | Playback test CI’da yeterli |
| PDF ekstre export | Kısmi | Dens ekstre/mutabakat var; PDF ayrı ekran |

---

## CI

```bash
flutter test test/modules/field_sales/gida_sfa_crud_playback_test.dart
```
