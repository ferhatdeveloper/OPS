# WHMS Entegrasyon Ön Hazırlık — Depo Yönetim Sistemi

**Tarih:** 2026-07-26  
**Kapsam:** Ön hazırlık + **Faz 1** + **Faz 2.1–2.5** (Logo port, kuyruk, load consume, shell, Postgres sözleşme)  
**Kod:** Faz 2.2–2.5 dilimi · **Commit:** Yok  
**Durum:** **Faz 2.2–2.5 largely hazır** · 70 ajan turu **devam** (W01–W15 hazır; W16–W70 açık)  
**WHMS test:** **16/16 yeşil** · l10n `whms.phase2_shell`  
**Kaynak taraması:** `lib/modules/field_sales/stock/`, `vehicle/` + `vehicles/`, `lib/modules/inventory/`, `SqlQuerys`, menü seed (`database_service`), `AppRoutes`, `vehicleProvider` / `materialProvider`, MBT şema + ops board  
**İlgili planlar:** `2026-07-25-mbt-app-structure-schema.md`, `2026-07-26-ops-missing-modules-board.md`, `2026-07-26-accounting-stub-checklist.md`, `2026-07-26-whms-70-agent-board.md`  
**Sözleşme:** `docs/contracts/whms-bridge.md`, `docs/contracts/whms-postgres-warehouses.md`

---

## Faz 1 — başladı / tamamlanan (2026-07-26)

| Madde | Durum | Not |
|-------|--------|-----|
| R2 ambar master MRK/ARC/IAD | **Tamam** | `warehouses` + seed (önceki) |
| R3 `WarehouseTransferStockTxn` | **Tamam** | K16; merkez↔merkez → `warehouse_stocks` |
| R1 `StockBalancePort` | **Tamam (yerel)** | `LocalWarehouseStockBalancePort` |
| R1 Logo adaptör | **Tamam (Faz 2.1)** | `LogoStockBalancePort` + satır parser; van→yerel |
| R1 DI provider | **Tamam (Faz 2.2)** | `stockBalancePortProvider` |
| Onaylı transfer kuyruk | **Tamam (Faz 2.2)** | `WhmsTransferQueueBridge` + dens hook |
| Yükleme emri consume | **Tamam (Faz 2.3)** | `WhmsLoadOrderConsumer` → `VehicleLoadService` |
| Postgres warehouses sözleşme | **Tamam (Faz 2.4)** | `docs/contracts/whms-postgres-warehouses.md` |
| `/whms` shell | **Tamam (Faz 2.5)** | `WhmsShellScreen` + AppRoutes (menüye gömülmez) |
| `warehouse_stocks` şema | **Tamam** | `SqlQuerys.createWarehouseStocksTable` |
| Mapper / DTO sözleşmesi | **Tamam** | `WhmsPayloadMapper` + bridge DTO |
| Menü / route hizası | **Tamam** | `WhmsRouteMap` + fs_stock seed zaten bağlı |
| `lib/modules/whms/` iskelet | **Tamam** | barrel + README + shell |
| WHMS REST canlı API | **Yok** | Faz 3+ (bilinçli İzle) |
| WHMS zengin UI | **Yok** | ui-no-touch; yalnız dens kabuk |

### Faz 2.2–2.5 durum özeti (W70 Merkez)

| Faz | Madde | Durum |
|-----|--------|--------|
| **2.2** | Bridge + DI + ONAY=1 kuyruk | **Tamam** |
| **2.3** | Load order consumer → araç stok | **Tamam** |
| **2.4** | Postgres `warehouses` sözleşme | **Tamam** (migrasyon yok) |
| **2.5** | `/whms` dens shell + `phase2_shell` | **Tamam (iskelet)** · canlı REST yok |

### Faz 1–2.5 dosya kökleri
- `lib/modules/whms/`
- `docs/contracts/whms-bridge.md`
- `docs/contracts/whms-postgres-warehouses.md`
- `docs/plans/2026-07-26-whms-70-agent-board.md`
- `test/modules/whms/` (**16/16 yeşil**)

### Sonraki faz önerisi
1. ~~Logo StockBalancePort~~ **Tamam (2.1)**  
2. ~~Onaylı ambar fişi kuyruk~~ **Tamam (2.2)**  
3. ~~Yükleme emri consume~~ **Tamam (2.3)**  
4. ~~`/whms` shell~~ **Tamam (2.5 dens)**  
5. ~~Postgres sözleşme~~ **Tamam (2.4)**  
6. Canlı WHMS REST + bakiye kaynağı geçişi  
7. dens shell → gerçek merkez depo ekranları (UI onayıyla)  
8. W16–W65 residual + W66–W70 panel kapanışı

---

## Ajan paneli özeti

| Rol | Durum | Risk (kısa) | TODO (özet) |
|-----|--------|-------------|-------------|
| Merkez | **Yarım / 2.2–2.5** | Residual + panel açık | W16–W70 kapat; commit yok |
| Saha satış | **Yarım (sınır OK)** | fs_stock gömülmedi | W66 plasiyer doğrulama |
| Dil | **Yarım** | `phase2_shell` eklendi | W67 tam dil paneli |
| Tester | **Hazır (WHMS 16/16)** | Tam regress açık | W68 analyze + D70 |
| Yazılım / mobil | **Hazır / 2.5** | Canlı REST yok | Faz 3+ API |
| UI | **No-touch** | Shell dens | W69 audit; redesign yasak |

```text
❌ BAD: WHMS’i field_sales stub ekranlarının içine gömmek; merkez depo UI’sını plasiyer dashboard’unda yeniden tasarlamak
✅ GOOD: OPS’ta MBT stok yüzeyi stub/kalır; WHMS ayrı domain; sözleşmeli API/queue ile bağlanır
```

---

## 1. Amaç ve kapsam dışı

### Amaç
OPS (saha satış) ile gelecekteki **WHMS (Warehouse Management System)** entegrasyonu için mevcut stok yüzeylerini, bağlanacak noktaları, önerilen domain sınırını, riskleri ve adım sırasını sabitlemek.

### Bu belgede yapılmayanlar
- WHMS kodu / klasörü ekleme
- Menü seed, route, provider değişikliği
- Logo / Postgres depo şeması migrasyonu
- UI redesign

### Terminoloji
| Terim | Anlam |
|-------|--------|
| **OPS stok** | Plasiyer cihazındaki MBT-parity stok menüsü (`fs_stock`), araç stoku, ambar/sayım fiş stub’ları |
| **Inventory modülü** | Eski/ERP-benzeri `lib/modules/inventory/` (malzeme + depo yönetimi placeholder) |
| **WHMS** | Merkez depo yönetim sistemi (henüz yok; bu belge hazırlık) |
| **Araç deposu** | Plasiyer van stoku (`vehicle_stocks`) — saha satış domain’inde kalır |

---

## 2. Mevcut OPS stok yüzeyleri (tarama sonucu)

### 2.1 Klasör haritası

| Alan | Yol | Olgunluk | Not |
|------|-----|----------|-----|
| Field sales stok | `lib/modules/field_sales/stock/` | **Yarım / stub ağırlıklı** | 16 dosya: view + model + engine; **stock Provider yok** |
| Araç (tekil stub) | `lib/modules/field_sales/vehicle/` | **Stub** | `vehicle_load` / `unload` / `inventory` — l10n stub mesajı |
| Araç (çoğul, canlı) | `lib/modules/field_sales/vehicles/` | **Yarım-çalışır** | `vehicleProvider` + SQLite `vehicles` / `vehicle_stocks` / loadings |
| Inventory (ERP) | `lib/modules/inventory/` | **Placeholder + sample** | `WarehouseManagementScreen` boş; `materialProvider` sample data |
| Admin depo | `company_management.dart` → `WarehouseTab` | **CRUD tab** | Postgres `warehouses` tablosu referansı |
| Sync fiş varsayılan | `slip_defaults_screen.dart` | **UI mock** | Hardcoded depo listesi (`Merkez`, `Araç`, `İade`) |

### 2.2 `field_sales/stock` yüzeyleri

| Ekran | Route | Tip | Bağlı servis / not |
|-------|-------|-----|---------------------|
| `price_check_screen` | `/field-sales/prices` | Kısmi UI | Seed: Fiyat Gör |
| `barcode_scanner_screen` / `BarcodeScanScreen` | `/field-sales/stock-barcode` | UI | Seed: Barkod Ekle |
| `warehouse_receipt_screen` | `/field-sales/stock-warehouse` | **Yarı-gerçek** | Dummy ambar listesi; `warehouse_transfers` insert |
| `production_receipt_screen` | `/field-sales/stock-production` | **Stub** | Route var; seed bağlı; iş kuralı yok |
| `stock_transfer_screen` | (named route zayıf) | Liste | `StockTransferService` → `warehouse_transfers` |
| `warehouse_transfer_screen` | `/field-sales/warehouse-transfer` | **Stub** | Route kayıtlı |
| `warehouse_stock_query_screen` | `/field-sales/warehouse-stock-query` | **Stub** | Route kayıtlı; seed’de yok |
| `multi_warehouse_screen` | `/field-sales/multi-warehouse` | **Stub** | Route kayıtlı; seed’de yok |
| `stock_movement_screen` | `/field-sales/stock-movement` | **Stub** | Route kayıtlı |
| `batch_expiry_screen` | `/field-sales/batch-expiry` | **Stub** | Route kayıtlı |
| `consignment_screen` | `/field-sales/consignment` | **Stub** | Route kayıtlı |
| Engine: `stock_transfer_service` | — | SQLite yaz/oku + yerel stok txn | `WarehouseTransferStockTxn` (R3/K16) |
| Engine: `unit_conversion_service` | — | Yardımcı | Birim setleri |
| Models: `product_model`, `stock_transfer_model`, `unit_set_model` | — | Yerel | Logo ITEMS ile tam sync belirsiz |

### 2.3 Araç stok yüzeyleri (çift klasör)

| Ekran / provider | Route | Tip |
|------------------|-------|-----|
| `VehicleLoadingScreen` | `/field-sales/vehicle-loading` | Çalışır UI + `vehicleProvider.loadStockIntoVehicle` |
| `VehicleStockSummaryScreen` | `/field-sales/vehicle-stock` | Çalışır okuma |
| `VehicleEodScreen` | `/field-sales/vehicle-eod` | Stub / zayıf reconcile |
| `VehicleLoadScreen` | `/field-sales/vehicle-load` | Stub (MBT parity) |
| `VehicleUnloadScreen` | `/field-sales/vehicle-unload` | Stub |
| `VehicleInventoryScreen` | `/field-sales/vehicle-inventory` | Stub |
| `vehicleProvider` | — | **Tek gerçek stok state** (araç tarafı) |

**Çift isimlendirme riski:** `vehicle/` (stub) vs `vehicles/` (provider). WHMS entegrasyonunda araç yükleme **OPS’ta kalmalı**; merkez ambar çıkışı WHMS’ten gelmeli.

### 2.4 Inventory modülü

| Bileşen | Durum |
|---------|--------|
| `MaterialsScreen` + `materialProvider` | Sample malzeme; seed “Detay” → `/field-sales/products` buraya gidiyor |
| `StockCountScreen` | `/field-sales/stock-count` (inventory paketinde); seed Sayım Fişi |
| `WarehouseManagementScreen` | Placeholder (“modül” metni); dashboard `Depo Yönetimi` case’i |
| `CreateMaterialScreen` | Malzeme oluşturma UI |
| `AppRoutes.inventory*` | `/inventory`, `/inventory/items`, `/inventory/warehouses` const var; WHMS değil |

### 2.5 Veri katmanı (SQLite)

| Tablo | Tanım | Kullanım |
|-------|--------|----------|
| `warehouse_transfers` | from/to ambar string, product, qty, status, is_synced | Ambar fişi + `StockTransferService` |
| `vehicles` | plaka, salesperson | Araç master |
| `vehicle_stocks` | (vehicle_id, product_id) PK, quantity, ONAY benzeri `approval_status` | Satış/yükleme düşümü |
| `vehicle_loadings` + `vehicle_loading_items` | Yükleme fişi | `vehicleProvider` |
| `products` | Ürün master (FK) | Transfer / araç stok join |
| **`warehouses` master (SQLite)** | **Yok** | Ambarlar hardcoded string; WHMS öncesi gap |

Postgres tarafında admin `warehouses` ve `postgres_service` firm prefix `_warehouses` izi var — mobil offline şema ile hizalı değil.

### 2.6 Logo / sync izleri

| API / nokta | Dosya | Not |
|-------------|-------|-----|
| `getStock` / `getInventoryReport` / `getStockStatus` | `logo_api_service.dart` | ERP stok sorgu; WHMS değil |
| Payload mapper stok alanları | `logo_payload_mapper.dart` | Warehouse/stock özel map **yok** (grep boş) |
| Fatura → `vehicle_stocks` düşümü | `invoice_provider.dart` | Saha satış stok etkisi |
| Extra ops | `extra_ops_service.dart` | `vehicle_stocks` güncelleme |

---

## 3. WHMS’e bağlanacak noktalar (entegrasyon yüzeyi)

Entegrasyon başladığında **dokunulacak / sözleşme kurulacak** yerler. Şimdi kod değişmez.

### 3.1 Menü seed (`database_service` → `fs_stock`)

Ana menü: `uuid: fs_stock`, title `Stok`, order 9, `module_name: FieldSales`.

| uuid | Title (TR seed) | route | WHMS ilişkisi |
|------|-----------------|-------|----------------|
| `sub_stk_detail` | Detay | `/field-sales/products` | Ürün kartı OPS; stok bakiyesi ileride WHMS/Logo okuma |
| `sub_stk_price` | Fiyat Gör | `/field-sales/prices` | Fiyat OPS; depo bakiyesi opsiyonel overlay |
| `sub_stk_barcode` | Barkod Ekle | `/field-sales/stock-barcode` | OPS; WHMS lot/seri sonra |
| `sub_stk_count` | Sayım Fişi | `/field-sales/stock-count` | **Araç / plasiyer sayım** OPS; **merkez sayım** WHMS |
| `sub_stk_warehouse` | Ambar Fişi | `/field-sales/stock-warehouse` | **Kritik köprü:** çıkış WHMS / giriş araç OPS |
| `sub_stk_production` | Üretimden Giriş | `/field-sales/stock-production` | WHMS / üretim domain; OPS stub kalabilir |
| `sub_stk_transferred` | Transfer Edilenler | `/field-sales/stock-transferred` | Sync kuyruk dili; WHMS job status ayrı |
| `sub_stk_untransferred` | Transfer Edilmeyenler | `/field-sales/stock-untransferred` | Aynı (şu an `PendingTransfersScreen`) |

Rapor: `sub_rep_stok` → `/field-sales/report-stock`.

**Seed’de olmayan ama route’u olan stub’lar** (WHMS adayları / P1+):  
`multi-warehouse`, `warehouse-stock-query`, `warehouse-transfer`, `stock-movement`, `batch-expiry`, `consignment`.

### 3.2 Routes (`lib/core/init/navigation/routes.dart`)

| Const / case | Hedef widget | WHMS notu |
|--------------|--------------|-----------|
| `fieldSalesStockCount` | `StockCountScreen` (inventory) | OPS sayım; WHMS sayım ayrı route namespace önerilir |
| `fieldSalesStockBarcode` | `BarcodeScanScreen` | OPS |
| `fieldSalesStockWarehouse` | `WarehouseReceiptScreen` | Köprü fiş |
| `fieldSalesStockTransferred` / `Untransferred` | `PendingTransfersScreen` | Generic — stok özel liste yok |
| `fieldSalesProducts` | `MaterialsScreen` | Malzeme; WHMS SKU sync sonra |
| `fieldSalesPrices` | `PriceCheckScreen` | OPS |
| `fieldSalesVehicleLoading` / `Stock` / `Eod` | vehicles/* | OPS araç |
| `ProductionReceiptScreen.routeName` | stub | WHMS/üretim |
| `MultiWarehouseScreen` vb. | stub’lar | WHMS domain adayı |
| `inventoryMain` / `Items` / `Warehouses` | (kısmi) | Eski inventory; WHMS ile karıştırılmamalı |

### 3.3 Providers / state

| Provider | Konum | WHMS bağlanınca |
|----------|--------|-----------------|
| `vehicleProvider` | `vehicles/viewmodel/vehicle_provider.dart` | **Kalır OPS dens UI**; WHMS emir consume etmez. Consume = `WhmsLoadOrderConsumer` → `VehicleLoadService` |
| `materialProvider` | `inventory/viewmodel/material_provider.dart` | Sample → Logo/WHMS ürün master okuma |
| **Yok: StockNotifier** | — | OPS stub wiring için Mobil-Stock; WHMS için ayrı `Whms*` provider |
| `invoiceProvider` (stok yan etkisi) | invoices | Araç stok düşümü OPS; merkez rezervasyon WHMS |
| `reportProvider` | reports | `vehicle_stocks` sorgu — WHMS raporları ayrı |

### 3.4 Dashboard wiring (`mobile_dashboard.dart`)

Hardcoded `case` başlıkları: `Stok`, `Depo Yönetimi`, `Depolar Arası Transfer`, `Depo Sayım`, `Araç Stokları`, `Ambar Fişi`, vb.  
WHMS açılırken: **dashboard case’lerine WHMS ekranı gömme**; WHMS kendi shell/route’u ile gelsin. Plasiyer `Stok` bottom sheet MBT dilinde kalsın.

### 3.5 Veri / sync köprü adayları

1. **Yükleme emri:** WHMS merkez çıkış → `WhmsLoadOrderConsumer` → `vehicle_stocks` (ONAY=1; dens `vehicle_loadings` fişi opsiyonel/ayrı)  
2. **Ambar fişi:** OPS `warehouse_transfers` → WHMS / Logo ambar hareketi (TYPE)  
3. **Stok sorgu:** `LogoApiService.getStock` vs WHMS real-time — tek okuma kaynağı seçilmeli  
4. **Sayım:** Plasiyer sayım ≠ depo sayım (farklı ONAY / sync kuralları)

---

## 4. Önerilen sınır: field_sales stub vs WHMS domain

```
┌─────────────────────────────────────────────────────────────┐
│ OPS / Field Sales (cihaz, offline-first)                      │
│  • fs_stock MBT menü + stub/yarı UI                           │
│  • vehicle_stocks, yükleme/EOD, satış stok düşümü             │
│  • Ambar fişi “talep / yerel kayıt” + sync kuyruk             │
│  • Fiyat / barkod / ürün detay (plasiyer)                     │
└───────────────────────────┬─────────────────────────────────┘
                            │ Sözleşme: emir / fiş / bakiye DTO
                            │ (REST veya job queue; ONAY=1 sync)
┌───────────────────────────▼─────────────────────────────────┐
│ WHMS domain (yeni; henüz yok)                                 │
│  • Merkez / şube depo master, lokasyon, raf, lot/SKT          │
│  • Depolar arası transfer, üretimden giriş, konsinye          │
│  • Merkez sayım, rezervasyon, picking                         │
│  • Opsiyonel: Logo ITEM/warehouse master sync sahibi           │
└─────────────────────────────────────────────────────────────┘
```

### OPS’ta kalacak (field_sales + vehicles)

- MBT Stok bottom sheet ve plasiyer dili  
- Araç yükleme / stok özeti / EOD  
- Offline `vehicle_stocks` ve satış anı düşüm  
- Transfer edilmeyen stok fiş listesi (cihaz kuyruğu)  
- Stub ekranlar: plasiyer için yeterli mesaj; WHMS UI’sı buraya taşınmaz  

### WHMS domain’e gidecek (gelecek paket)

- Çoklu depo master, depo sorgu, depolar arası transfer (merkez)  
- Üretimden giriş, konsinye, parti/SKT, stok hareket defteri  
- `inventory/WarehouseManagementScreen` yerine veya üzerine WHMS shell  
- Admin `WarehouseTab` ile hizalı master data  

### Köprü (her iki tarafa dokunan, ince katman)

- **Ambar Fişi / araç yükleme emri** DTO + job queue  
- Bakiye okuma adaptörü: `StockBalancePort` (implementasyon: Logo şimdi, WHMS sonra)  
- `warehouse_transfers` şemasının `from_warehouse_code` / `to_warehouse_code` (string isim yerine kod) — migrasyon WHMS sprint’inde  

### Anti-pattern

| Yapma | Neden |
|-------|--------|
| `lib/modules/field_sales/stock/` altına tam WHMS yazmak | Saha offline + depo WMS karmaşası |
| `inventory/` ile WHMS’i sessizce aynı saymak | İsim çakışması; placeholder ile üretim karışır |
| `vehicle/` ve `vehicles/` ikisini WHMS’e taşımak | Plasiyer gün akışı kırılır |
| Dashboard’da “Depo Yönetimi”ni WHMS’e çevirip Stok menüsünü bozmak | MBT parity + UI no-touch ihlali |

---

## 5. Riskler

| # | Risk | Etki | Azaltma |
|---|------|------|---------|
| R1 | **Çift stok gerçeği** (Logo ERP + WHMS + `vehicle_stocks`) | Yanlış bakiye / eksi satış | Tek `StockBalancePort`; araç stoku ayrı “van bucket” |
| R2 | Ambar master SQLite’ta yok; string isimler | Sync eşleşmez | WHMS öncesi `warehouses` + kod alanı |
| R3 | `StockTransferService` stok düşmüyor | Yerel tutarsızlık | **Mitige (K16):** `WarehouseTransferStockTxn` aynı txn’de araç/depo günceller |
| R4 | Stok transferred/untransferred → generic `PendingTransfersScreen` | Stok fişi kaybolur | Stok-özel kuyruk filtresi veya ayrı liste |
| R5 | `vehicle/` vs `vehicles/` çift yüzey | Yanlış ekrana bağlanma | Tek “araç stok” sahibi: `vehicles/` + stub’ları birleştirme planı |
| R6 | `materialProvider` sample data | Sahte stok | Logo ITEMS / WHMS master gelene kadar UI’da “örnek” etiketi / guard |
| R7 | Fatura/sipariş depo seçimi vs WHMS rezervasyon | Çifte rezervasyon | Muhasebe checklist + WHMS hold API sırası |
| R8 | Erken WHMS UI’ı plasiyer menüsüne gömmek | MBT sapması, UI touch | Bu belgedeki sınır; ayrı module entry |
| R9 | Postgres `warehouses` vs mobil şema | Admin/mobil drift | Entegrasyon adım 2’de şema sözleşmesi |
| R10 | ONAY / is_synced kuralları depo fişinde belirsiz | Yanlış sync | `sync_approval_rules` + stok fiş status enum |

---

## 6. Entegrasyon sırası (7 adım — kod yok, sıra kilit)

> WHMS kodu **şimdi yazılmaz**. Sıra, ileride ayrı sprint/PR seti içindir.

1. **Sınır onayı**  
   Bu belge + Merkez: OPS stub vs WHMS domain (bölüm 4) product onayı.

2. **Sözleşme / DTO**  
   Yükleme emri, ambar transfer, bakiye sorgu, sayım sonucu alanları; ONAY ve `is_synced` anlamları. (Yalnız doküman veya `docs/contracts/` — henüz implementasyon zorunlu değil.)

3. **Mobil ambar master hazırlığı (OPS içi, WHMS’siz)**  
   SQLite `warehouses` (kod, ad, tip: merkez/araç/iade) + seed; `WarehouseReceiptScreen` dummy listesini kod’a bağla. Hâlâ WHMS yok.

4. **Mobil-Stock wiring (P1 board ile uyum)**  
   `fs_stock` fişleri için minimal provider; transferred/untransferred stok filtresi; `StockTransferService` txn. WHMS çağrısı yok.

5. **Araç yükleme köprüsü (OPS tarafı)**  
   `WhmsLoadOrderConsumer` → `VehicleLoadService` (provider’a dokunma); EOD sayım gerçekliği. Kaynak mock veya Logo; dens UI ayrı.

6. **WHMS domain iskeleti (ayrı paket)**  
   `lib/modules/whms/` (veya eşdeğer) + kendi routes/menu; **field_sales menüsüne karışmaz**. UI no-touch / mevcut inventory placeholder’ı replace politikası ayrı PR.

7. **Uçtan uca bağlama**  
   WHMS çıkış → OPS yükleme; OPS ambar fişi → WHMS/Logo; bakiye port WHMS’e geçer; Tester contract + saha regresyon; muhasebe stok etkisi (TYPE) doğrulama.

*(İsteğe bağlı 8.)* Lot/SKT, konsinye, üretimden giriş — WHMS olgunlaşınca stub route’lar WHMS’e delegate.

---

## 7. Board / sahiplik eşlemesi

| İş | Sahip (öneri) | WHMS mi? |
|----|---------------|----------|
| Stok fiş wiring | Mobil-Stock | Hayır (adım 3–4) |
| Araç EOD / yükleme | Mobil-Vehicles | Hayır (adım 5); emir kaynağı sonra WHMS |
| Merkez depo WMS | **WHMS ajanı** (gelecek) | Evet (adım 6–7) |
| Fatura stok düşümü | Mobil-Invoices + Muhasebe | OPS van; merkez WHMS hold |
| Dil key’leri | Dil çevirmeni | Stub key koru; `whms.*` sonra |
| Regresyon | Tester | Adım 4 ve 7 gate |
| UI | UI uzmanı | No-touch; yalnız kırık layout / l10n |

Ops board maddesi: **Stok fiş wiring · P1 · Prov ✗** — WHMS’ten **bağımsız** tamamlanabilir ve tamamlanmalıdır.

---

## 8. Kabul kriterleri (bu prep belgesi)

- [x] Mevcut stock / warehouse / inventory / vehicle yüzeyleri tarandı  
- [x] Seed `fs_stock`, kritik routes, provider boşlukları listelendi  
- [x] OPS stub vs WHMS domain sınırı yazıldı  
- [x] Riskler ve 7 adımlık sıra belirlendi  
- [x] Faz 1: domain iskelet + `warehouse_stocks` + mapper + route map  
- [x] Faz 2.2–2.5: bridge · load consumer · Postgres sözleşme · dens shell  
- [ ] Canlı WHMS REST → **Faz 3+**  
- [x] Commit → **yok** (bu tur)

---

## 9. Sonraki adım (insan onayı)

WHMS entegrasyonuna geçilmeden önce:

1. Bölüm 4 sınırını onayla  
2. Adım 3–4’ü (ambar master + Mobil-Stock wiring) OPS P1 olarak planla  
3. WHMS domain’i ayrı epik olarak aç; OPS MBT stok menüsüne gömme  

**Karar (güncel):** Prep tamam; **Faz 1 iskelet başladı**. Tam WHMS UI/API ayrı faz.
