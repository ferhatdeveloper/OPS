# Dashboard Modül Grid Gap Listesi (Ana 16 Kutu)

**Tarih:** 2026-07-26  
**Rol:** Merkez / saha satış / mobil  
**Kapsam:** Ana dashboard **modül grid kartları** (3 kolon). Alt menü derinliği ayrı board’larda; burada sadece **kutuya tıklama**.  
**Commit:** Yok · **Kod:** P0 uygulandı (Stok onTap / Home sheet route / Duyurular seed).  
**Kaynak:** `lib/view/mobile_dashboard.dart`, `lib/service/menu_service.dart`, `lib/service/database_service.dart` (`seedFieldSalesMockData`), `docs/plans/2026-07-25-mbt-app-structure-schema.md` §3.

> **UI no-touch:** Grid layout / renk / kart stili değiştirilmez. Düzeltme = seed + navigasyon bağlama + (gerekirse) `onTap` mantığı.

---

## Durum özeti (2026-07-26)

| Kalem | Öncelik | Durum |
|-------|---------|-------|
| Stok özel onTap → sheet | **P0** | **✓** |
| Home sheet → route ile `_openModule` | **P0** | **✓** |
| Duyurular seed (`fs_announcements`) | **P0** | **✓** |
| Tester regresyon | — | **89/89** geçti |
| Favoriler grid kutu | **P1** | Kalan |
| Tek-alt / MBT-doğrudan açılış | **P1** | Kalan |
| Cihaz re-seed | — | **Risk** (eski DB’de yeni seed yok) |

**Kalan iş:** P1 (Favoriler kutu, tek-alt doğrudan) + cihaz re-seed riski.  
**P0 grid kapısı:** kapatıldı.

---

## 1. Grid nasıl render ediliyor?

| Adım | Dosya | Ne olur |
|------|--------|---------|
| 1 | `MobileDashboard._buildHomeScreen` | `FutureBuilder` → `MenuService.getMobileModuleCards(languageCode: 'tr')` |
| 2 | `MenuService.getMobileModuleCards` | SQLite `menu` tablosu: `parent_id IS NULL` → her ana menü + alt başlık/route listesi |
| 3 | Seed | `DatabaseService.seedFieldSalesMockData()` → `module_name = 'FieldSales'`, uuid `fs_*` |
| 4 | UI | `SliverGrid` (3 kolon) → `_buildModuleCard(...)` |

**Liste kaynağı:** Hardcoded `MenuConstants.moduleCards` **kullanılmıyor** (boş). Kaynak = seed + SQLite + `MenuService`.

**P0 sonrası (✓):** Home sheet alt tık → seed `route` ile `_openModule(..., route:)`. Stok özel onTap kaldırıldı → diğer kutular gibi sheet. Duyurular ana grid’de.

```text
Home grid kartı
  └─ hasSubmenus? → _showModuleSubmenuDialog (sheet)
       └─ alt tık → _openModule(context, title, route: seedRoute)  ✓ P0
  └─ Stok → varsayılan sheet (özel onTap yok)  ✓ P0
```

Menü sekmesi / favoriler zaten `route:` geçiriyordu; home grid artık aynı modeli kullanır.

---

## 2. Seed ana grid (`fs_*`)

`database_service.dart` → FieldSales `mainMenus` (Duyurular dahil; Ayarlar grid hizası P2).

| # | Seed uuid | Başlık (TR) | Not |
|---|-----------|-------------|-----|
| 1 | `fs_manager` | Yönetici | P1: doğrudan |
| 2 | `fs_customers` | Cari | P1: doğrudan |
| 3 | `fs_invoice` | Fatura | Sheet ✓ + route ✓ |
| 4 | `fs_waybill` | İrsaliye | Sheet ✓ + route ✓ |
| 5 | `fs_order` | Sipariş | Sheet ✓ + route ✓ |
| 6 | `fs_delivery` | Teslimat | Sheet ✓ + route ✓ |
| 7 | `fs_visit` | Ziyaret | Sheet ✓ + route ✓ |
| 8 | `fs_finance` | Finans | Sheet ✓ + route ✓ |
| 9 | `fs_stock` | Stok | Sheet ✓ (P0 onTap fix) |
|10 | `fs_reports` | Raporlar | Sheet ✓ + route ✓ |
|11 | `fs_currency` | Döviz | P1: doğrudan |
|12 | `fs_companies` | Şirketler | P1: doğrudan |
|13 | `fs_sync` | Güncelleme | P1: doğrudan |
|14 | `fs_announcements` | Duyurular | **P0 ✓** seed |
|15 | `fs_other` | Diğer | Sheet ✓ |
| — | `fs_favorites` | Favoriler | Ana grid’de yok → **P1** |
| — | `fs_settings` | Ayarlar | MBT hizası → **P2** |

---

## 3. MBT §3 (16 dashboard) ↔ OPS grid

| MBT # | MBT modül | OPS seed / grid | Grid tıklama | Durum | Öncelik |
|-------|-----------|-----------------|--------------|-------|---------|
| 1 | FAVORİLER | Grid’de yok; üst şerit | Şerit → route | ~ | **P1** |
| 2 | YÖNETİCİ | `fs_manager` | Sheet (çok alt) | ~ doğrudan | **P1** |
| 3 | CARİ | `fs_customers` | Sheet | ~ doğrudan | **P1** |
| 4–9, 11 | FATURA…FİNANS, RAPORLAR | `fs_*` | Sheet + route ✓ | ✓ | P0 ✓ |
|10 | STOK | `fs_stock` | Sheet ✓ | **✓** | **P0 ✓** |
|12–14 | DÖVİZ / ŞİRKETLER / GÜNCELLEME | `fs_*` | Sheet (tek/çok alt) | ~ doğrudan | **P1** |
|15 | DUYURULAR | `fs_announcements` | Seed + route ✓ | **✓** | **P0 ✓** |
|16 | DİĞER | `fs_other` | Sheet ✓ | ✓ | — |
| — | AYARLAR | `fs_settings` / sekme | — | ~ | P2 |
|17 | ÇIKIŞ | Header logout | — | ✓ | — |

---

## 4. Checkbox tablo — ana grid kalemleri

Durum: **✓** çalışır · **~** yarım · **kırık** · **eksik**

- [x] **STOK** · `fs_stock` · özel onTap kaldırıldı → sheet · **✓** · **P0 ✓**
- [x] **DUYURULAR** · `fs_announcements` seed · **✓** · **P0 ✓**
- [x] **Grid sheet → route** · `_openModule(..., route:)` · **✓** · **P0 ✓**
- [ ] **FAVORİLER (grid kutu)** · üst şerit var · **eksik** (MBT #1) · **P1**
- [ ] **YÖNETİCİ / CARİ / DÖVİZ / ŞİRKETLER / GÜNCELLEME doğrudan** · tek-alt veya whitelist · **~** · **P1**
- [ ] **AYARLAR grid MBT hizası** · **~** · **P2**
- [x] **FATURA / İRSALİYE / SİPARİŞ / TESLİMAT / ZİYARET / FİNANS / RAPORLAR / DİĞER** · sheet + route · **✓**

---

## 5. P0 — tamamlandı · kalan riskler

### P0 ✓ (kapandı)

1. **Stok kutusu** — özel `onTap` silindi; varsayılan sheet.  
2. **Home sheet route** — `ModuleCardData` / `getMobileModuleCards` route taşır; sheet `onTap` → `_openModule(..., route:)`.  
3. **Duyurular** — seed `fs_announcements` + route `/field-sales/announcements`.

### Tester

- Regresyon / smoke paketi: **89/89** geçti (home grid Stok sheet + alt → named route dahil ilgili smoke’lar).

### Kalan — P1 + cihaz

4. **Tek-hedefli kutular sheet açıyor** (Yönetici, Cari, Döviz, Şirketler, Güncelleme) — MBT doğrudan.  
5. **FAVORİLER MBT #1 grid kutusu** — ürün kararı + `fs_favorites` ana kart (opsiyonel).  
6. **Cihaz re-seed riski** — mevcut cihazda eski SQLite menü kalırsa yeni `fs_announcements` / route güncellemeleri görünmez.  
   - **Ayarlar → Geliştirici → FieldSales menü seed yenile**  
     (`DatabaseService.reseedFieldSalesMenus` / `seedFieldSalesMockData(menusOnly: true)`).  
     Yalnızca `module_name = 'FieldSales'` menü satırlarını yazar; cari/sipariş DROP etmez.  
   - Alternatif: uygulama verisini temizle / tam seed / DB migrate.  
   - Sonrasında dashboard’a dönüp menüyü yenileyin (`MenuService.reloadAll`).

### P2

7. **Ayarlar** grid fazlalığı — sekme ile koordine.

---

## 6. Mobil ajan — TODO checklist

```text
[x] P0-1  mobile_dashboard: Stok özel onTap sil → varsayılan sheet
[x] P0-2  ModuleCardData + getMobileModuleCards: alt menü route taşı
[x] P0-3  _showModuleSubmenuDialog: route ile _openModule
[x] P0-4  seed: fs_announcements (Duyurular) ana grid
[x] P0-5  test: home grid smoke · Tester 89/89
[ ] P1-1  tek-alt / MBT-doğrudan whitelist (Cari, Döviz, Şirketler, Güncelleme, Yönetici)
[ ] P1-2  (opsiyonel) fs_favorites ana kutu
[ ] P2-1  fs_settings grid sırası / MBT hizası
[x] Cihaz  re-seed: Ayarlar → Geliştirici → FieldSales menü seed yenile (+ docs)
```

**Dokunulmayacak:** kart radius/renk/gradient, 3 kolon grid metriği, AppBar redesign.

**Dosya sahipliği (çakışma önleme):**

| Dosya | Sahip |
|-------|--------|
| `lib/view/mobile_dashboard.dart` | Mobil-Dashboard |
| `lib/service/menu_service.dart` | Mobil-Dashboard |
| `lib/service/database_service.dart` | Mobil-Dashboard |
| `assets/translations/*.json` | Dil çevirmeni |
| `test/...` grid/smoke | Tester |

---

## 7. Panel özeti (zorunlu roller)

| Rol | Durum | Risk | TODO (kısa) |
|-----|-------|------|-------------|
| Merkez | hazır | P0 kapandı; P1 parity açık | Canvas’a “Dashboard grid P0 ✓” |
| Saha satış | yarım | Tek-alt doğrudan + Favoriler kutu | MBT doğrudan matrisi P1 |
| Dil | hazır* | Yeni key gelirse ayna | `dashboard.duyurular` kontrol |
| Tester | hazır | **89/89**; cihaz re-seed smoke | Cihazda Stok sheet + Duyurular |
| Yazılım/mobil | hazır (P0 + re-seed) | Eski DB seed | P1 tek-alt; Ayarlar Geliştirici menü yenile ✓ |
| UI | hazır (dokunma) | Redesign yok | Yalnız navigasyon / seed / l10n |

\* Dil key’leri P0 ile birlikte bağlandıysa “hazır”; aksi halde tek key turu.

---

## 8. Referans satırlar

| Konu | Konum |
|------|--------|
| Grid FutureBuilder | `mobile_dashboard.dart` |
| Stok sheet (P0 ✓) | `mobile_dashboard.dart` — özel onTap yok |
| Sheet + route (P0 ✓) | `mobile_dashboard.dart` `_showModuleSubmenuDialog` |
| `_openModule` seedRoute | `mobile_dashboard.dart` |
| Seed mainMenus + Duyurular | `database_service.dart` |
| getMobileModuleCards | `menu_service.dart` |
| MBT 16 tablo | `2026-07-25-mbt-app-structure-schema.md` §3 |
| Duyurular ekran | `announcements_screen.dart` (`/field-sales/announcements`) |
| Canvas | `canvases/OPS-mbt-uygulama-durum.canvas.tsx` |
