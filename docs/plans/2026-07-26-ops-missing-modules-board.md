# OPS Eksik Modül / Ekran Board (Merkez)

**Tarih:** 2026-07-26  
**Rol:** Merkez ajan  
**Commit:** Yok  
**Canvas:** `OPS-mbt-uygulama-durum.canvas.tsx` (§ Modül oluşturma)  
**Kaynak:** `2026-07-25-mbt-app-structure-schema.md`, `2026-07-26-ops-mbt-content-gap.md`, `tmp_mbt_analysis/MENU_TODO.md`

**Kural:** UI redesign yok — mevcut `field_sales` Material stilini kopyala; metinler dil key.

> **Öncelik:** **P0** plasiyer gününü kırar · **P1** MBT parity / sonraki · **P2** yönetici/favori/oyun (çekirdek günü bloklamaz).

> **2026-07-26 Merkez güncelleme:** Stub klasörleri + seed↔AppRoutes (62/62) + sipariş/fatura/tahsilat cari guard **hazır**.  
> Kalan P0 dar boğaz: `mobile_dashboard` title→placeholder (route atılıyor) + **Toptan Satış** çakışması.  
> Bitiş kapısı: `docs/plans/2026-07-26-ops-completion-gate.md` — **WHMS öncesi HAZIR DEĞİL**. WHMS = sonraki faz.

---

## Durum anahtarı

| Sembol | Anlam |
|--------|--------|
| UI ✓ / ~ / ✗ | Ekran var / yarım-guard / yok-placeholder |
| Route ✓ / ~ / ✗ | AppRoutes veya dashboard case bağlı / kısmi / yok |
| Seed ✓ / ~ / ✗ | `database_service` menü var / eksik alt / yok |
| Prov ✓ / ✗ | Riverpod provider var / yok |

---

## Dosya çakışması (zorunlu)

Her ajan **tek klasör veya tek route grubu**. Paylaşılan dosyada yalnızca kendi bloğu.

| Sahip ajan | Klasör / kapsam |
|------------|-----------------|
| Mobil-Orders | `lib/modules/field_sales/orders/` + seed `fs_order` + `Sipariş*` case |
| Mobil-Invoices | `invoices/` + seed `fs_invoice` + fatura case |
| Mobil-Waybills | **yeni** `waybills/` + seed `fs_waybill` |
| Mobil-Delivery | **yeni** `delivery/` + seed `fs_delivery` |
| Mobil-Collections | `collections/` + seed `fs_finance` |
| Saha-Routes | `routes/` + seed `fs_visit` |
| Mobil-Sync | `sync/` + seed `fs_sync` / `fs_settings` |
| Mobil-Stock | `stock/` + seed `fs_stock` |
| Mobil-Other | `other/` + seed `fs_other` |
| Mobil-Campaigns | `announcements/` (UI) + `campaigns/` (engine/admin) · seed `fs_announcements` |
| Dil | `assets/translations/*.json` only |
| Tester | `test/modules/field_sales/**` |
| Merkez | canvas + bu board (feature kodu yazmaz) |

**Protokol:** `database_service.dart` → kendi `fs_*` · `mobile_dashboard.dart` → kendi `case` · `routes.dart` → kendi const. Aynı PR’da iki ajan aynı bloğa girmez.

---

## Checkbox tablo

### P0

- [ ] **Güne Başlama gate + kalıcılık** · `other/view/day_status_screen.dart` · **P0**  
  UI ~ · Route ~ · Seed ~ · Prov ✗ · Sahip: **Mobil-Other** · Dil · Tester

- [ ] **Ziyaret MBT menü + cari bağlam** · `routes/` · **P0**  
  UI ~ · Route ✓ · Seed ✗ (Rota*; MBT Mevcut/Yeni/Geçmiş/Transfer yok) · Prov ✓ · Sahip: **Saha-Routes** · Dil · Tester

- [ ] **Sipariş alt menü MBT + cari seç l10n** · `orders/` + seed `fs_order` · **P0**  
  UI ~ · Route ~ · Seed ✗ (yalnız Giriş+Geçmiş) · Prov ✓ · Sahip: **Mobil-Orders** · Dil · Tester

- [ ] **Fatura cari-önce + Toptan Satış dili** · `invoices/` · **P0**  
  UI ~ (`customerId: ''`) · Route ~ · Seed ~ · Prov ✓ · Sahip: **Mobil-Invoices** · Saha · Dil · Tester

- [ ] **Tahsilat Yeni Hareket cari-önce** · `collections/` · **P0**  
  UI ~ · Route ~ · Seed ✓ · Prov ✓ · Sahip: **Mobil-Collections** · Dil · Tester

- [ ] **Kuyruk / Güncelleme triad title** · `sync/` · **P0**  
  UI ~ · Route ~ · Seed ✓ · Prov ✗ · Sahip: **Mobil-Sync** · Dil · Tester

- [ ] **Güne Bitirme çerçeve metni** · `other/day_status_screen.dart` · **P0**  
  UI ~ · Route ~ · Seed ~ · Prov ✗ · Sahip: **Mobil-Other** (P0-1 ile aynı sahip — sırayla) · Dil

- [ ] **İrsaliye modülü (klasör yok)** · `waybills/` (**yeni**) · **P0**  
  UI ✗ · Route ✗ · Seed ✓ · Prov ✗ · Sahip: **Mobil-Waybills** · Muhasebe · Dil · Tester  
  > Not: Saha panosunda P1 sayılmıştı; menü seed açık + dashboard placeholder → Merkez **P0** (kırık menü).

- [ ] **Teslimat modülü (klasör yok)** · `delivery/` (**yeni**) · **P0**  
  UI ✗ · Route ✗ · Seed ~ · Prov ✗ · Sahip: **Mobil-Delivery** · Saha · Dil · Tester

### P1

- [ ] **Sipariş Onaylama / Liste / Takip ekran** · `orders/view/` · **P1**  
  UI ✗ · Route ✗ · Seed ✗ · Prov ✓ · Sahip: **Mobil-Orders**

- [ ] **Fatura/İrsaliye Satın Alma** · invoices/ + waybills/ · **P1**  
  UI ✗/~ · Seed ~ · Sahip: Invoices **veya** Waybills (eşzamanlı aynı dosya yok)

- [ ] **Transfer Edilen Tahsilatlar** · `collections/` · **P1**  
  UI ✗ placeholder · Seed ✓ · Sahip: **Mobil-Collections**

- [ ] **Fiş Ön Değerleri MBT (AÇIKLAMA/PLAKA/ÖZELKOD)** · `sync/slip_defaults_screen.dart` · **P1**  
  UI ~ · Seed ✓ · Sahip: **Mobil-Sync** · Muhasebe · UI(key)

- [ ] **Araç EOD gerçek sayım** · `vehicles/` · **P1**  
  UI ~ stub · Sahip: **Mobil-Vehicles** (day_status’a dokunmaz; Other bitince bağ)

- [ ] **Cari risk limiti** · `customers/` + order/invoice provider · **P1**  
  UI ✗ · Prov ~ · Sahip: **Mobil-Invoices** kalem anı / customers model — Merkez sıraya koyar

- [ ] **Stok fiş wiring** · `stock/` · **P1**  
  UI ~ · Seed ✓ · Prov ✗ · Sahip: **Mobil-Stock**

- [x] **Duyurular grid (tek kaynak)** · `announcements/` (+ `campaigns-list` alias) · **P1 ✓**  
  UI ✓ dens · Route ✓ `/announcements` · Seed ✓ `fs_announcements` · Sahip: **Mobil-Campaigns** · Dil  
  > Karar: [2026-07-26-campaigns-announcements-single-source.md](./2026-07-26-campaigns-announcements-single-source.md) — `CampaignsListScreen` ayrı UI değil.

- [ ] **Rapor alt menü parametre** · `reports/` · **P1**  
  UI ~ · Seed ✓ · Prov ✓ · Sahip: reports ajanı

- [ ] **Bilgi Gönderme** · `other/` · **P1**  
  UI ✗ · Seed ✓ · Sahip: **Mobil-Other**

- [ ] **AppRoutes field_sales const tamamla** · `routes.dart` · **P1**  
  Route ✗ çoğu dashboard-only · Sahip: her ajan kendi const

### P2 (ertele)

- [ ] Favoriler kalp / `fs_favorites` · dashboard · **P2**
- [ ] Yönetici KPI gerçek veri · `manager/reports/` · **P2**
- [ ] Gamification · **P2**
- [ ] Merchandising · **P2**
- [x] NFC (MBT’de yok) · **K19 bilinçli sapma** — uydurma yok · yeni özellik yazılmaz

---

## Hazır referans (board dışı)

| Modül | Path | UI | Route | Seed | Prov |
|-------|------|----|-------|------|------|
| Cari liste/form | `customers/` | ✓ | ✓ | ✓ | ✓ |
| Sipariş entry + cari seç | `orders/` | ✓ | ✓ | ~ | ✓ |
| Döviz | `currency/` | ✓ | ~ | ✓ | ✗ |
| Şirketler | `companies/` | ✓ | ~ | ✓ | ✗ |
| Data transfer ekranı | `sync/data_transfer` | ✓ | ~ | ✓ | ✗ |
| Yönetici rapor UI | `manager/reports/` | ✓ | ~ | ✓ | ✗ |

---

## Plasiyer gün sırası → P0 bağımlılık

```
P0 Güne Başlama (Other)
  └─ Ziyaret bağlam (Routes)
       ├─ Sipariş (Orders)
       ├─ Fatura (Invoices)
       ├─ İrsaliye/Teslimat (Waybills / Delivery)  ← yeni klasör
       └─ Tahsilat (Collections)
            └─ Kuyruk/Güncelleme (Sync)
                 └─ Güne Bitirme (Other)
```

Dil işleri: `2026-07-26-ops-mbt-content-gap.md` ile **paralel** (layout yok).

---

## Panel özeti (Merkez)

| Rol | Durum | Risk | TODO |
|-----|-------|------|------|
| Merkez | hazır | Paylaşılan dosya çakışması | Bu board + canvas; ajan sırası |
| Saha | yarım | Rota vs ziyaret; boş cari satış | Ziyaret seed; plasiyer sıra |
| Dil | yarım | Key parity | Her P0 key; hardcoded 2. tur |
| Tester | yarım | Cihaz yok | Guard/empty/l10n unit |
| Mobil | yarım | waybills/delivery sıfır | Yeni klasör + case |
| UI | bekler | Redesign baskısı | Onaysız layout yok |

**İlgili:**  
`docs/plans/2026-07-26-ops-missing-modules-board.md` ·  
canvases/`OPS-mbt-uygulama-durum.canvas.tsx` ·  
`lib/service/database_service.dart` (~1051–1188) ·  
`lib/view/mobile_dashboard.dart` (`_openModule`) ·  
`lib/core/init/navigation/routes.dart`
