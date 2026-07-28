# OPS Eksiksiz Depo Yönetimi (WMS) Blueprint

**Tarih:** 2026-07-28  
**Kapsam:** DEYS + Logo WMS parity referansıyla EXFINOPS `/whms` + OPS sınırları  
**Önceki araştırma:** [`2026-07-28-deys-wms-research.md`](./2026-07-28-deys-wms-research.md)  
**Blend (Logo WMS × DEYS × FAYS):** [`2026-07-28-logo-wms-deys-blend-ops.md`](./2026-07-28-logo-wms-deys-blend-ops.md)  
**Canvas:** [`Logo-WMS-DEYS-OPS-blend.canvas.tsx`](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/Logo-WMS-DEYS-OPS-blend.canvas.tsx) · DEYS: [`DEYS-WMS-arastirma.canvas.tsx`](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/DEYS-WMS-arastirma.canvas.tsx)  
**Kod:** `fs_whms` Depo menü grubu (uygulama) · **Commit:** Yok  

---

## 0. Blend referansı

Üç ayrı ürünün best-of seti (P0–P2) ve bilinçli reddedilenler için:
[`2026-07-28-logo-wms-deys-blend-ops.md`](./2026-07-28-logo-wms-deys-blend-ops.md).

| Referans | Rol |
|----------|-----|
| Logo WMS / Platform | Mal kabul kontrol, adres, FEFO yükleme, multi-pick |
| DEYS | Emir yaşam döngüsü, FIFO gün, cihaz/terminal |
| FAYS | Dinamik raf, rota/opt, picking control, akıllı barkod |

---

## 0b. Depo Yönetimi menü ağacı (zorunlu)

`fs_stock` (saha satış) **ayrı**. Merkez depo ana menü: **`fs_whms`**.

```text
Depo Yönetimi (fs_whms) → /whms
├── Emirler              → /whms
├── Tanımlamalar         → /whms/warehouses
├── Ambarlar             → /whms/warehouses
├── Sayım                → /whms/count
├── Transfer             → /whms/transfer
├── Stok Sorgu           → /whms/stock-query
├── Raporlar             → /whms/reports
└── Etiket / Cihaz       → /whms/devices
```

Rol: depocu + admin. Plasiyer görmez. Seed: `DatabaseService` + `ensureWhmsDepoMenuItems`.

---

## 0. Hedef ve sınırlar

### Hedef
Merkez depo (WHMS) için **eksiksiz** operasyon: master data → emir yaşam döngüsü → terminal yürütme → ONAY → Logo sync; OPS plasiyer van stoku ile **köprü** (yükleme emri).

### Sınırlar (mevcut mimari)
| Tut | Bırak |
|-----|--------|
| `/whms/*` ayrı namespace | `fs_stock` menüsüne WMS gömme |
| `vehicle_stocks` = plasiyer van | Merkez lokasyonu ARC ile karıştırma |
| dens AppBar / ui-no-touch | DEYS Windows UI kopyası |
| Offline-first + JobQueue | Anlık Logo DB yazımı (DEYS modeli) — adaptörle yaklaş |

---

## 1. Master data

| Master | Alanlar (min) | Önerilen tablo / store | EXFINOPS bugün |
|--------|---------------|------------------------|----------------|
| Ambar | code, name, type (center/vehicle/return), is_active | `warehouses` · `WarehouseMasterStore` | **Var** (MRK/ARC/IAD) |
| Lokasyon | warehouse_code, aisle, rack, bin, barcode, route_seq | `whms_locations` · `WhmsLocationStore` | **Yok** |
| Malzeme | product_code, name, unit_set, track_serial, track_lot, fifo_days | mevcut ürün + `whms_material_rules` | Kısmi (ürün); kural yok |
| Birim | unit_set, conversions | `unit_conversion_service.dart` | **Kısmi** |
| Lot / seri | serial/lot, expiry, product, location | `whms_serial_pool` / `batch_expiry` genişlet | `batch_expiry` seed |
| FIFO/FEFO | product_code, fifo_days, fefo_enforce | `whms_fifo_rules` | Menü stub |
| Paket tipi | code, tare_ref, after_sales_flag | `whms_package_types` | **Yok** |
| Dara | code, weight | `whms_tares` | **Yok** |
| Araç (merkez) | type, plate, capacity | `whms_vehicles` ≠ `vehicles` | Saha `vehicles` var |
| Cihaz | name, mac, os, model | `whms_devices` | **Yok** |
| Terminal | device_id, roles, default_wh | `whms_terminals` | **Yok** |
| Yetki | backoffice + terminal modül bayrakları | `permission_groups` + whms flags | Genel permission var |

---

## 2. Emir yaşam döngüsü

```text
draft → assigned → in_progress → completed → approved(ONAY=1) → synced(ONAY=2)
                                      ↘ rejected / error
```

| Aşama | Aktör | EXFINOPS kancası |
|-------|--------|------------------|
| Oluştur | Backoffice / (parametreyle) terminal | Yeni `WhmsOrderStore` |
| Ata | Kullanıcı / cihaz | `assigned_user_id` / `device_id` |
| Terminal yürüt | Barkod satırları | Flutter dens terminal ekranları |
| Onay | Admin / kural | Mevcut ONAY 0–4 |
| Logo sync | JobQueue | `WhmsTransferQueueBridge` genişlet |

**DEYS referansı:** Yönetici emir → terminal tamamla → Logo anlık. EXFINOPS: offline txn + ONAY=1 kuyruk (bilinçli sapma).

---

## 3. Emir tipleri matrisi

| Tip | Kaynak (DEYS/Logo WMS) | OPS/WHMS etkisi | Öncelik |
|-----|------------------------|-----------------|---------|
| Mal kabul (satınalma) | DEYS satınalma | Giriş + lokasyon putaway | P0 |
| Mal kabul iade | satınalma iade | Giriş | P1 |
| Yerleştirme (putaway) | lokasyon okutma (DEYS) | Ayrı tip veya mal kabul adımı | P0 |
| Toplama (pick) | rota ile toplama | Sevk öncesi | P0 |
| Sevk / satış çıkış | satış | Çıkış + FEFO | P0 |
| Satış iade | satış iade | Giriş | P1 |
| Ambar transferi | ambar transferi | `WhmsWarehouseTransferDto` | **Kısmi hazır** |
| Araç yükleme | Logo WMS araç / OPS load | `WhmsLoadOrderDto` | **Kısmi hazır** |
| Sayım | sayım | `WhmsCountResultDto` + OPS `stock_counts` | P0 (merkez UI) |
| Sarf / fire | sarf, fire | Düşük öncelik merkez | P2 |
| Üretimden giriş | üretim | OPS stub `production_receipt` | P2 |
| Konsinye | — | OPS stub | P3 |

---

## 4. Barkod / etiket

| Yetenek | DEYS/Logo | EXFINOPS hedef |
|---------|-----------|----------------|
| EAN / seri / GS1-128 / karekod | Desteklenir | Okuma: mevcut barkod; GS1 parse P1 |
| Raf / ürün etiket tasarım | DEYS Etiket modülü | P2 dens şablon + yazıcı skill |
| Barkod tarihçe | Hareket audit | `whms_barcode_events` P1 |
| Seri aralığı (ilk–son) | Satınalma | Mal kabul P1 |
| Seri listeden seç yasak | Logo WMS video | Parametre P1 |

---

## 5. Sayım / stok düzeltme

1. Sayım emri oluştur (depo / lokasyon / ürün filtresi)  
2. Çoklu terminal online sayım (DEYS) → EXFINOPS: offline birleştir + çatışma kuralı  
3. Sonuç karşılaştırma (sistem vs fiili; seri bazlı)  
4. Fark → sayım fazla/eksik fişi → ONAY=1 → Logo  
5. Mevcut: `StockCountService` + `stock_counts`; merkez `WhmsCountResultDto` henüz UI’sız  

---

## 6. Raporlar / KPI

| KPI | Tanım | Kaynak referans |
|-----|--------|-----------------|
| Açık emir sayısı | draft+assigned+in_progress | DEYS dashboard |
| Emir tamamlanma süresi | completed_at − created_at | Performans |
| Pick doğruluk % | hatalı satır / toplam | Logo WMS “hatasız sevk” |
| Sayım fark tutarı | | Sayım modülü |
| Terminal verim | satır/saat / kullanıcı | DEYS personel izleme |
| SKT risk stok | FEFO penceresi | `batch_expiry` |

Ekran: `/whms/reports` dens · mevcut MBT stok raporlarına gömme **yasak** (ayrı).

---

## 7. Offline-first + Logo REST / JobQueue

```text
Terminal / dens UI
  → SQLite txn (whms_orders, lines, location_stocks)
  → ONAY=0|1
  → JobQueue (entity: whms_order_* / stock_transfer / stock_count)
  → Logo REST / LogoStockBalancePort
  → ONAY=2 | 4
```

| Bileşen | Yol |
|---------|-----|
| JobQueue | `lib/service/job_queue_service.dart` |
| Transfer bridge | `whms_transfer_queue_bridge.dart` |
| Logo bakiye | `logo_stock_balance_port.dart` |
| Mapper | `whms_payload_mapper.dart` |
| Logo payload | `logo_payload_mapper.dart` |

**DEYS farkı:** DEYS Logo DB’ye anlık; EXFINOPS kuyruk — aynı iş sonucu, farklı sync.

---

## 8. Faz planı P0–P3

### P0 — Emir omurgası + lokasyon + FEFO kapısı
| Çıktı | İsim önerisi |
|-------|----------------|
| Emir DTO birleşik | `WhmsOrderDto` + `WhmsOrderType` |
| Store | `WhmsOrderStore` |
| Lokasyon DDL | `whms_locations` + dens `WhmsLocationListScreen` |
| Putaway adımı | mal kabul satırında `location_code` |
| FIFO kural | `WhmsFifoRuleEngine` (çıkışta engelle/uyar) |
| Sayım merkez | `/whms/count` + `WhmsCountResultDto` enqueue |
| Shell menü | `WhmsShellScreen` alt route’lar (dens) |

### P1 — Terminal / cihaz / seri / pick
| Çıktı | İsim |
|-------|------|
| Cihaz/terminal | `WhmsDeviceStore`, `WhmsTerminalSession` |
| Pick emri UI | `WhmsPickOrderScreen` + rota sırası |
| Seri okutma zorunluluğu | param (Logo WMS video parity) |
| Barkod event | `whms_barcode_events` |
| Yetki | permission_groups `whms_*` flags |

### P2 — Etiket / dara / paket / üretim
| Çıktı | İsim |
|-------|------|
| Etiket | `WhmsLabelTemplateStore` + yazıcı |
| Paket/dara | master dens listeler |
| Sarf/fire/üretim | emir tipleri + stub kaldırma |

### P3 — KPI / e-ticaret / çok depo gelişmiş
| Çıktı | İsim |
|-------|------|
| Dashboard | `WhmsKpiScreen` |
| Çoklu depo rota | opsiyonel |
| Konsinye merkez | bridge |

---

## 9. DEYS parity checklist

| # | Madde | Durum |
|---|--------|--------|
| 1 | Emir oluştur / ata / tamamla | Eksik |
| 2 | Mal kabul + lokasyon | Eksik |
| 3 | Rota ile toplama | Eksik |
| 4 | Sevk / FEFO | Eksik (SKT liste var) |
| 5 | Ambar transfer | Kısmi |
| 6 | Araç yükleme emri | Kısmi |
| 7 | Sayım çoklu + fark | Kısmi (OPS sayım) |
| 8 | Cihaz MAC / terminal yetki | Eksik |
| 9 | FIFO gün tanımı | Eksik |
| 10 | Seri/lot havuzu | Eksik |
| 11 | Etiket tasarım | Eksik |
| 12 | Dara / paket tipi | Eksik |
| 13 | Emir dashboard KPI | Eksik |
| 14 | Logo sync | Kısmi (kuyruk) |
| 15 | Android terminal istemci | Flutter OPS; ayrı depo rolü Eksik |

---

## 10. OPS P0 checklist (10 madde — uygulama öncesi kabul)

1. `WhmsOrderType` enum + `WhmsOrderDto` (mal_kabul, putaway, pick, sevk, transfer, sayim, load)  
2. `whms_orders` / `whms_order_lines` SQLite DDL + ONAY  
3. `whms_locations` master + dens liste/CRUD  
4. Mal kabul emrinde lokasyon zorunlu parametre  
5. `WhmsFifoRuleEngine`: SKT/fifo_days çıkış kontrolü (`batch_expiry` bağla)  
6. `/whms/orders` dens emir listesi (filtre: tip/durum)  
7. Transfer: mevcut bridge’i emir tipine bağla  
8. Load: `WhmsLoadOrderConsumer` emir store’dan beslensin  
9. Sayım: merkez sonuç → `WhmsCountResultDto` → JobQueue  
10. l10n: `whms.*` key’leri tüm dillere; hardcoded UI yok  

---

## 11. Riskler

| Risk | Etki | Azaltma |
|------|------|---------|
| DEYS ≠ Logo WMS karışması | Yanlış özellik | Kaynak etiketi; blueprint’te ayrım |
| Van vs merkez araç | Stok çift sayım | Domain kuralı belgede + kod yorum |
| Offline sayım çatışması | Yanlış bakiye | Cihaz satır birleştirme + ONAY |
| Anlık Logo beklentisi | Müşteri alışkanlığı | Sync SLA dokümante |
| YouTube DEYS eksikliği | Yanlış UI varsayımı | Yalnız web+ekran; Logo WMS video süreç için |
| Scope creep (e-ticaret paket) | Gecikme | P2/P3’e it |

---

## 12. Kaynaklar (özet)

Araştırma MD §7 + §10. YouTube: araştırma MD §10.3.  
İç: `lib/modules/whms/**`, `field_sales/stock/**`, `field_sales/vehicles/**`, `docs/contracts/whms-*.md`.
