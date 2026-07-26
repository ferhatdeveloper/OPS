# OPS Bitiş Kapısı — WHMS Öncesi

**Tarih:** 2026-07-26  
**Rol:** Merkez ajan  
**Commit:** Yok  
**Canvas:** [OPS-mbt-uygulama-durum.canvas.tsx](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/OPS-mbt-uygulama-durum.canvas.tsx)  
**Kaynak:** `2026-07-26-ops-missing-modules-board.md`, `2026-07-26-100-agent-module-integration.md`, `2026-07-26-ops-mbt-content-gap.md`, `2026-07-26-whms-integration-prep.md`

> **Kabul kuralı:** Gerçek veri / SQLite / Logo bağlama **zorunlu değil** — stub tamam sayılır.  
> **Kapı kırıcı:** kırık menü · route · l10n · cari guard.

---

## WHMS notu (sonraki faz)

- [ ] **WHMS depo yönetimi entegrasyonu** — **bu kapının dışında**  
  Prep: `docs/plans/2026-07-26-whms-integration-prep.md` (kod yok).  
  Kullanıcı: OPS bitişinden sonra.  
  Şimdi dokunma: `WarehouseManagementScreen` / Depo Yönetimi case’leri WHMS ajanına.  
  OPS stok stub’ları (`fs_stock`) plasiyer sayım/ambar fişi ile sınırlı kalır.

**WHMS’e geçiş şartı:** Aşağıdaki P0 kapı maddeleri yeşil — **karşılandı**. OPS stub/route/guard/l10n kapısı **hazır**; WHMS entegrasyonuna geçilebilir.

---

## Kapı özeti

| Sonuç | Durum |
|-------|--------|
| Seed path → AppRoutes (62/62) | ✅ Hazır |
| Stub klasörleri (waybills/delivery dahil) | ✅ Hazır (içerik stub) |
| Cari guard sipariş/fatura/tahsilat | ✅ Hazır |
| Dashboard menü→ekran (route-first) | ✅ Hazır — `seedRoute` → `pushNamed` |
| Title çakışması (Toptan Satış irsaliye≠fatura) | ✅ Hazır — route ile ayrıldı |
| İrsaliye cari guard + dash | ✅ Hazır — `WaybillCustomerSelection` + test |
| Teslimat (liste stub; boş cari ile yeni fiş yok) | ✅ Hazır (liste OK) |
| TR stub l10n (5 key) + hardcoded P0 | ✅ Hazır — Dil P0-11 (agent 20ff2c15) |
| **WHMS öncesi hazır mı?** | **HAZIR** |

### WHMS öncesi karar

| Etiket | Anlam |
|--------|--------|
| **Hazır** | Tüm P0 yeşil — tam yeşil kapı |
| **Koşullu hazır** | Navigasyon + cari guard yeşil; yalnız dil/l10n P0 açık. WHMS prep doc ile faz başlatılabilir; dil fix’i paralel veya hemen önce kapatılmalı. |
| **Hazır değil** | Menü/route/guard kırık |

**Şu an: HAZIR** — stub/route/guard/l10n P0 kapandı; kalan P0 = 0. Sonraki faz: WHMS.

---

## A. Navigasyon / menü (P0)

- [x] `lib/view/mobile_dashboard.dart` — alt menüde `SubMenuItemData.route` kullan;  
      `Navigator.pushNamed(context, seedRoute, …)` route-first; title-switch yalnız legacy fallback  
- [x] Aynı dosya — **Toptan Satış** çakışması: `fs_waybill` seed route → `WaybillEntry` / wholesale;  
      `fs_invoice` ayrı path (route ile ayrıldı)  
- [x] Aynı dosya — **Transfer Edilmeyenler** çakışması: `fs_visit` vs `fs_stock` (route ile ayrıldı)  
- [x] Ziyaret seed title’ları açılıyor:  
      Mevcut Cari Hesap · Yeni Cari Hesap · Geçmiş Ziyaretler · Transfer Edilmeyenler  
      → `lib/modules/field_sales/routes/view/visit_*.dart` (seed route)  
- [x] Teslimat: Teslimat · Beklemeye Alınanlar · Aktarılamayan Teslimatlar  
      → `lib/modules/field_sales/delivery/view/`  
- [x] Sipariş: Sipariş Onaylama · Sipariş Listesi · Transfer Edilmeyen Siparişler  
      → `lib/modules/field_sales/orders/view/`  
- [x] İrsaliye: İrsaliye Listesi · Satın Alma (+ wholesale route)  
      → `lib/modules/field_sales/waybills/view/`  
- [x] Fatura: Onaylama → `invoices/view/invoice_approval_screen.dart`  
- [x] Finans: Transfer Edilen Tahsilatlar · Kasa Kart Listesi · Çek Listesi  
      → `collections/view/`  
- [x] Stok (plasiyer): Sayım Fişi · Üretimden Giriş Fişi · Transfer Edilenler  
      → `stock/view/`  
- [x] Diğer: Bilgi Gönderme → `settings/view/send_info_screen.dart`  
- [x] AppRoutes smoke yeşil kalır (`test/core/navigation/app_routes_generate_route_smoke_test.dart`)

---

## B. Guard (P0)

- [x] Sipariş cari-önce — `OrderCustomerSelectionScreen` + test  
- [x] Fatura cari-önce — `InvoiceCustomerSelectionScreen` + test  
- [x] Tahsilat cari-önce — `CollectionCustomerSelectionScreen` + test  
- [x] İrsaliye cari-önce — `WaybillEntryScreen(cariId:)` + `WaybillCustomerSelectionScreen` + test  
- [x] Teslimat girişlerinde boş cari ile “yeni fiş” yok (liste OK)

---

## C. Dil / içerik (P0 — stub key) — **kapandı (Dil P0-11)**

- [x] `assets/translations/tr.json` (+ tüm diller):  
      - `field_sales.barcode_scan_stub_message`  
      - `field_sales.sales_targets_stub_message`  
      - `field_sales.vehicle_unload_stub_message`  
      - `field_sales.warehouse_management_desc`  
      - `submodules.konsinye`  
- [x] `lib/modules/field_sales/routes/view/visit_form_screen.dart` —  
      hardcoded `Dinleniyor... (Simülasyon)` → l10n  
- [x] `lib/modules/field_sales/routes/view/route_map_screen.dart` —  
      hardcoded `Rota Optimizasyonu & Harita` → l10n  
- [x] `transfer_edilmeyen_tahsilatlar` doğru metin (TR)  
- [x] Locale key parity (tr→en/de/ar/…): 0 gap — yeni key eklenince ayna zorunlu

---

## D. Bilinçli kabul (kapı dışı / P1)

Bunlar **yeşil olmadan** WHMS’e geçilebilir (stub turu):

- [ ] Liste/kuyruk/entry → gerçek SQLite + provider  
- [ ] `invoice_provider` TYPE 3 → her zaman `wholesale` flatten  
- [ ] Gün kaydı kalıcılığı / araç EOD bağlama  
- [ ] Cari `credit_limit` gate  
- [ ] Fiş Ön Değerleri MBT alan etiketleri (PLAKA / ÖZELKOD)  
- [ ] `PendingTransfersScreen` entity AppBar title parametresi  
- [ ] Duyurular / favoriler seed  
- [ ] Cihaz (A065) manuel smoke

---

## E. P2 / ertele

- [ ] Favoriler kalp / gamification / merchandising / yönetici KPI gerçek  
- [x] NFC (MBT’de yok — **bilinçli sapma / uydurma yok** · K19 kapandı)  
- [ ] **WHMS depo yönetimi** (ayrı faz — prep doc hazır; kod yok)

---

## Sibling ajan ataması (P0 kapandı)

| Ajan | Durum | Not |
|------|-------|-----|
| **Merkez** | hazır | Kapı/canvas → **HAZIR**; sonraki faz WHMS |
| **Dil** | hazır | P0-11: 5 key + ayna tüm locale (agent 20ff2c15) |
| **Saha-Routes** | hazır | visit_form + route_map → l10n |
| **Tester** | hazır / izle | l10n parse + guard regresyon; cihaz smoke P1 |
| **UI** | bekler | Redesign yok |

**Not:** Dashboard route-first tamam — `mobile_dashboard.dart` title-switch yalnız seed route boşsa fallback.

---

## Doğrulama (kapı yeşil kriteri)

1. Plasiyer: Ziyaret → Mevcut Cari Hesap → stub (placeholder değil). ✅ route-first  
2. İrsaliye → Toptan Satış → **irsaliye** stub (fatura değil) + cari-önce. ✅  
3. Teslimat / Sipariş Onaylama / Bilgi Gönderme → ilgili stub. ✅  
4. `flutter test` guard + navigation smoke yeşil. ✅ (mevcut suite)  
5. Yeni l10n key’lerde locale parity 0 gap. ✅ Dil P0-11  

**WHMS öncesi OPS hazır = EVET (tam)** → WHMS fazına geçilebilir.  
Kalan P0 = 0.

---

## Panel özeti (Merkez)

| Rol | Durum | Risk | TODO |
|-----|-------|------|------|
| Merkez | hazır | Yok (P0 kapandı) | WHMS fazını başlat |
| Saha | hazır | — | P1 gerçek veri / EOD |
| Dil | hazır | Yeni key eklenince ayna | Parity izle |
| Tester | hazır / izle | Cihaz smoke P1 | Guard + l10n regresyon |
| Mobil | hazır | Legacy title fallback | Dokunma yok (route-first) |
| UI | bekler | Redesign baskısı | Onaysız layout yok |

**İlgili:**  
`docs/plans/2026-07-26-ops-completion-gate.md` ·  
`docs/plans/2026-07-26-whms-integration-prep.md` ·  
`docs/plans/2026-07-26-ops-missing-modules-board.md` ·  
`lib/view/mobile_dashboard.dart` (`_openModule` route-first) ·  
`lib/service/menu_service.dart` (`SubMenuItemData.route`) ·  
`lib/core/init/navigation/routes.dart`
