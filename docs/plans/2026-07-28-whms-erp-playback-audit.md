# WHMS ERP Playback Audit — 2026-07-28

## Özet

Yerel SQLite + JobQueue stub “ERP’ye gidecek” omurga varsayımıyla tüm WHMS
süreçleri denetlendi. Uzak PostgreSQL credential **istenmedi**; eksik şema
liste olarak çıkarıldı.

| Kanıt | Sonuç |
|-------|--------|
| Otomatik playback | `test/modules/whms/whms_erp_playback_test.dart` **PASS** |
| WHMS suite | `flutter test test/modules/whms/` → **120/120 PASS** |
| iOS Simulator | iPhone 16e booted; `flutter run` → uygulama açıldı (VM Service OK) |
| Küçük fix | `WhmsCountSession.complete` — `existingResultId` yoksa `findByOrderId` |

Commit / push yok. Secret yok.

---

## 1. Süreç matrisi (ERP entegre varsayımı)

Durum: **hazır** = UI + store/SQLite + ONAY/JobQueue payload + lokal motor
çalışır · **yarım** = omurga var, Logo REST / lokasyon stoğu / UI eksik ·
**kırık** = kritik tablo/kolon veya canlı sync yok.

| Süreç | Durum | UI | Store / SQLite | JobQueue payload | Logo mapper |
|-------|-------|-----|----------------|------------------|-------------|
| Mal kabul → putaway → stok | **yarım** | `/whms/receipt` + `WhmsReceiptExecuteScreen` | `whms_orders` / lines; putaway lokasyon zorunlu | `whms_order_mal_kabul` enqueue OK | **Stub** — JobQueue `default` → skipped; `warehouse_stocks` lokasyon bazlı güncelleme yok |
| Pick → seri → sevk son kontrol → load | **yarım** | Pick ekranı + shipping listesi; sevk UI ince | `completePick` + seri kuralı; `WhmsPickingControlGate`; `WhmsLoadOrderConsumer` | pick → `whms_order_pick`; load → `whms_load_order` | Load consume **yerel gerçek** (vehicle_stocks); Logo REST **yok** (skipped) |
| Transfer (ürün+barkod) → ONAY → JobQueue | **hazır*** | `/whms/transfer` + create dens | `WhmsOrderStore` / transfer DTO | `stock_transfer` + ONAY=1 | **Kısmi gerçek** — `JobQueueService` → `logo.createStockTransfer` |
| Sayım (barkod) → fark → ONAY → queue | **yarım** | Liste + execute (barkod) | `whms_count_orders` / `whms_count_results` | `stock_count` | **Stub** — `WhmsCountLogoSyncStub`; JobQueue case yok → skipped; entity map → `stock_counts` (OPS fiş tablosu) |
| Emir oluştur → advance → terminal gate | **hazır** | Order create/detail + typed lists | `advanceStatus` / `advanceAsTerminal` | Tip bazlı enqueue (ONAY=1) | Payload map var; çoğu tip Logo’da skipped |
| Ambar / lokasyon / FIFO kural | **yarım** | Warehouses + locations + FIFO dens CRUD | `warehouses`, `whms_locations`, `whms_fifo_rules` | FIFO kural sync yok | Load’da FEFO allocate **yerel**; `location_stocks` **yok** |

\*Transfer: barkod satır okutma UI kısmi; ERP fiş yolu en olgun süreç.

### Logo / JobQueue netliği

| entity_type | JobQueue sync davranışı |
|-------------|-------------------------|
| `stock_transfer` | **Gerçek** — `createStockTransfer` |
| `stock_count` | **Stub** — case yok → `skipped: true` |
| `whms_load_order` | **Stub** — case yok; lokal consume ayrı |
| `whms_order_*` (mal_kabul, pick, putaway, sevk) | **Stub** — case yok → skipped |

---

## 2. SQL gap

### 2.1 Yerel SQLite — var (`SqlQuerys` + `ensureWhmsP0Schema`)

| Tablo | Not |
|-------|-----|
| `warehouses` | OPS master |
| `warehouse_stocks` | Ambar+ürün bakiye (lokasyon yok) |
| `whms_locations` | aisle/rack/bin/barcode/route_seq |
| `whms_orders` / `whms_order_lines` | ONAY + serial/lot/location |
| `whms_fifo_rules` | |
| `whms_count_orders` / `whms_count_results` | |
| `whms_devices` | Terminal MAC + roles (ayrı `whms_terminals` yok) |
| `whms_package_types` / `whms_tares` / `whms_label_templates` | Lazy `ensureReady` (P0 schema’da değil) |
| `whms_vehicle_types` / `whms_vehicles` / `whms_lots` / `whms_reservations` / `whms_returns` | Kod+ad stub; lazy create |
| `batch_expiry` | Lot/SKT (field_sales) |
| `warehouse_transfers` / `stock_counts` | Legacy OPS fiş tabloları |

### 2.2 Eksik / zayıf kolon-tablo

| Gap | Tip | Öneri |
|-----|-----|--------|
| `products.require_serial` | **Kolon eksik** CREATE’te | `ALTER` / CREATE’e ekle: `INTEGER NOT NULL DEFAULT 0` (store runtime ALTER yapıyor) |
| `whms_location_stocks` (veya `location_stocks`) | **Tablo yok** | Putaway sonrası lokasyon bakiyesi için: `(warehouse_code, location_code, product_id, quantity, lot_no, …)` PK |
| `whms_serial_pool` | **Tablo yok** | Seri aralığı / kullanılmış seri |
| `whms_barcode_events` | **Tablo yok** | Barkod audit (blueprint P1) |
| `whms_material_rules` | **Tablo yok** | track_serial / track_lot / fifo_days ürün kuralları |
| Etiket/master tablolar | **ensureWhmsP0Schema dışı** | Boot’ta `createWhmsPackageTypesTable` vb. çağır |
| `sql/apps/*/schema.sql` + `sql/mobile` | **WHMS yok** | Uzak PG / mobil dump’ta whms_* hiç yok |

### 2.3 CREATE önerisi (lokasyon stok — kritik)

```sql
CREATE TABLE IF NOT EXISTS whms_location_stocks (
  warehouse_code TEXT NOT NULL,
  location_code TEXT NOT NULL,
  product_id TEXT NOT NULL,
  quantity REAL NOT NULL DEFAULT 0,
  lot_no TEXT,
  serial_no TEXT,
  expiry_date TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT,
  PRIMARY KEY (warehouse_code, location_code, product_id, COALESCE(lot_no, ''))
);
```

```sql
-- products CREATE’e eklenmeli (şu an yalnız ALTER)
ALTER TABLE products ADD COLUMN require_serial INTEGER NOT NULL DEFAULT 0;
```

---

## 3. Playback adımları

### 3.1 Otomatik (koştu)

Komut:

```bash
flutter test test/modules/whms/whms_erp_playback_test.dart
flutter test test/modules/whms/
```

Senaryo sırası (in-memory SQLite + sahte JobQueue):

1. Seed: ambar MRK/IAD + lokasyon A/B + ürün/stok + FIFO kuralı  
2. Mal kabul draft → `confirmReceiptPutaway` → ONAY=1 → queue  
3. Transfer draft → ONAY → `WhmsTransferQueueBridge` + order queue  
4. Sayım emri → fiili → complete (variance) → `stock_count` queue  
5. Pick rota sıralama + seri gate → completePick → queue  
6. Load + picking control block/allow + FIFO allocate → `vehicle_stocks`  
7. KPI assert (4 emir, variance −3, tip wire’ları)  
8. Tüm queue satırlarında `ONAY=1`

### 3.2 Manuel / cihaz (koştu)

| Adım | Sonuç |
|------|--------|
| `flutter devices` | iPhone 16e (sim), macOS, Chrome |
| Simulator boot | Zaten Booted |
| `flutter run -d EA2279BF-…` | Xcode build OK; app sync; DevTools URL alındı |
| UI adım adım WHMS tıklama | **Yapılmadı** (login/seed menü bağımlı); otomatik playback omurgayı kapsar |

### 3.3 Manuel checklist (sonraki oturum)

1. Login → Depo Yönetimi (`fs_whms`) → `/whms`  
2. Tanımlar: ambar / lokasyon / FIFO  
3. Emir oluştur (mal kabul) → receipt execute → putaway  
4. Transfer create → onay  
5. Sayım execute barkod → tamamla  
6. Pick → seri → shipping / load  
7. Sistem ekranında sync kuyruk satırlarını gözle  

---

## 4. Küçük fix (bu oturum)

`WhmsCountSession.complete`: `existingResultId` verilmezse
`resultStore.findByOrderId` ile taslağı yeniden kullanır — çift
`whms_count_results` satırı / KPI variance şişmesi önlenir.

Dosya: `lib/modules/whms/count/viewmodel/whms_count_session.dart`

---

## 5. Uzak PG için kullanıcıya net sorular

Credential **şimdi isteme**. Önce şu listeyi doğrula / gönder:

1. **Şema adı** nedir? (`public` / `logo` / `wms` / Kiracs özel?)  
2. Aşağıdaki tablolar PG’de var mı, kolon listesi nedir?  
   - `whms_orders`, `whms_order_lines`  
   - `whms_locations`, `whms_location_stocks` (veya eşdeğeri)  
   - `whms_fifo_rules`  
   - `whms_count_orders`, `whms_count_results`  
   - `whms_devices`  
   - `warehouse_stocks` / Logo ambar bakiye view  
3. Logo/Kiracs tarafında **ambar transfer** ve **sayım fazla/eksik** fiş
   endpoint veya tablo adları neler?  
4. Seri / lot: ayrı tablo mu (`ITEMSERIAL`, `LOT` …) yoksa satır kolonu mu?  
5. PostgREST / doğrudan PG mi? RLS veya tenant (`company_id`) kolonu var mı?

Hazır cevap örneği (kopyala-doldur):

```text
PG host: …
DB: …
Schema: …
Mevcut tablolar: [liste veya \dt whms*]
Örnek: SELECT column_name, data_type FROM information_schema.columns
       WHERE table_schema='…' AND table_name IN (...);
```

---

## 6. Ajan özeti (OPS panel)

### Merkez
- Durum: **hazır** (audit + playback + sim açılış)
- Risk: Logo sync çoğu WHMS entity’de stub; lokasyon stoğu yok
- TODO: location_stocks DDL; JobQueue case’ler; PG şema eşlemesi

### Saha satış
- Durum: **yarım** — van load consume hazır; merkez putaway→stok kopuk
- Risk: Mal kabul sonrası `warehouse_stocks` artışı playback’te assert edilmedi
- TODO: putaway → bakiye txn; saha ARC ile MRK karışmasın

### Dil
- Durum: bu oturumda dokunulmadı
- Risk: —
- TODO: yeni gap UI metinleri `.tr()` 

### Tester
- Durum: **hazır** — 120 WHMS test + ERP playback PASS
- Risk: widget/integration UI playback yok
- TODO: integration smoke `/whms` route

### Yazılım / mobil
- Durum: **yarım** — iOS sim run OK; etiket DDL lazy
- Risk: `products.require_serial` CREATE dışı
- TODO: SqlQuerys CREATE + ensureP0 etiket tabloları

### UI
- Durum: **hazır** (dokunulmadı; dens hub/route mevcut)
- Risk: —
- TODO: yalnızca kırık layout / l10n

---

## İlgili dosyalar

- `test/modules/whms/whms_erp_playback_test.dart`
- `lib/modules/whms/count/viewmodel/whms_count_session.dart`
- `lib/modules/whms/mapper/whms_payload_mapper.dart`
- `lib/modules/whms/queue/whms_order_queue_bridge.dart`
- `lib/service/job_queue_service.dart`
- `lib/core/database/migrations/SqlQuerys.dart`
- `lib/service/database_service.dart` (`ensureWhmsP0Schema`)
- `docs/plans/2026-07-28-ops-complete-wms-blueprint.md`
