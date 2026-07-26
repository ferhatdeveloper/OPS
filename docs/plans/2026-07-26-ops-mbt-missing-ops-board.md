# OPS ← MBT Eksik / Yarım İŞLEM Board (Merkez)

**Tarih:** 2026-07-26  
**Rol:** Merkez ajan  
**Commit:** Yok · **Kod:** Yok  
**Kaynak:** `2026-07-26-mbt-system-expertise.md`, `2026-07-26-ops-completion-gate.md`, `2026-07-26-ops-missing-modules-board.md`, canvas `MBT-system-expertise`  
**Canvas:** [OPS-mbt-uygulama-durum.canvas.tsx](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/OPS-mbt-uygulama-durum.canvas.tsx) (§ MBT işlem gap · Kalanlar · ajan turları)

> **Tanım — İŞLEM:** Menü seed + named route + ekran + **form / tip / kuyruk akışı** (alanlar, Kaydet, cari-önce, tip sheet).  
> **Değil:** Yalnız stub `Center(Text(title))` veya AppBar başlığı.  
> **Kapı ayrımı:** `ops-completion-gate` = stub/route/guard/l10n **HAZIR**. Bu board = **fiş formu parity** (bir sonraki dalga).  
> **UI:** Redesign yasak — mevcut dens flat `field_sales` stili; yalnızca alan/akış/dil.  
> **P0 skor (2026-07-26 mercek):** **15/15** kapandı · kalan işlem P0 = **0**.  
> **Ajan turu:** **A01–A30 = 30/30 hazır** (son kalan **A23** Logo queue status chips kapandı).  
> **40 ajan turu (2026-07-26):** **Hazır (40/40)** — C00 + B01–B39 · **B39** regressyon yeşil (analyze error **0** · guard/smoke/l10n/stub **253/253**).  
> **60 ajan turu (2026-07-26):** **Hazır (60/60)** — K06–K12 · K16–K20 kapandı · **D60** analyze **0** · test **281/281**.

---

## Ajan turları

| Tur | Tarih | Durum | Not |
|-----|-------|--------|-----|
| **30 ajan turu (A01–A30)** | 2026-07-26 | **Hazır (30/30)** | A23 Logo queue chips son kalan — kapandı |
| **40 ajan turu (C00 + B01–B39)** | 2026-07-26 | **Hazır (40/40)** | B39 regressyon yeşil · analyze 0 · 253/253 |
| **60 ajan turu (K06–K12 · K16–K20)** | 2026-07-26 | **Hazır (60/60)** | D60 analyze 0 · 281/281 · tüm K kapandı |
| **70 ajan WHMS turu (W01–W70)** | 2026-07-26 | **Hazır (tarama kapandı)** | Faz 2.2–2.5 · WHMS test yeşil · residual board’da · canvas güncel · commit yok |

---

## 30 ajan turu (A01–A30)

| ID | Odak | Kapsam | Durum |
|----|------|--------|--------|
| **A01** | Nakit dens | P0-11 kasa/evrak/döviz/özelkod | **hazır** |
| **A02** | Çek dens | P0-12 ciro/asıl borçlu/işyeri/hesap | **hazır** |
| **A03** | KK/Senet dens | credit_card + promissory parity | **hazır** |
| **A04** | 7 tip sheet | nakit/KK/çek/senet + ödeme + virman | **hazır** |
| **A05** | VoucherDefaults | SharedPreferences load/save | **hazır** |
| **A06** | e-İrsaliye dens | ewaybill_status + seed | **hazır** |
| **A07** | Invoice TYPE map | wholesale/purchase/return 8/3 | **hazır** |
| **A08** | Waybill TYPE map | dispatch TYPE (invoice flatten yok) | **hazır** |
| **A09** | Order TYPE map | sales/purchase → Logo queue | **hazır** |
| **A10** | Döviz dens | kur listesi + route + seed | **hazır** |
| **A11** | e-Fatura dens | einvoice_status + seed | **hazır** |
| **A12** | Compile/çatışma | invoice_entry / dashboard birleşim | **hazır** |
| **A13** | Cari ekstre | customer_extract dens liste | **hazır** |
| **A14** | Cari risk | customer_risk dens limit alanları | **hazır** |
| **A15** | Şirketler dens | firma seçim + route/seed | **hazır** |
| **A16** | Visit reason | visit_mbt sebep dropdown | **hazır** |
| **A17** | Partial delivery | partial_delivery dens form | **hazır** |
| **A18** | Güncelleme triad | data_transfer Gönder/Al/Aktarılıyor | **hazır** |
| **A19** | Vehicle load | araç yükleme dens | **hazır** |
| **A20** | Visit EKLER | foto/dosya picker stub dens | **hazır** |
| **A21** | Order purchase sync | queue type sales/purchase | **hazır** |
| **A22** | Vehicle unload | araç boşaltma dens | **hazır** |
| **A23** | Logo queue chips | sync/pending dens durum chip’leri | **hazır** |
| **A24** | Tester | guard/smoke/l10n/stub fix | **hazır** |
| **A25** | Raporlar dens | sales/collection/visit rapor UI | **hazır** |
| **A26** | Announcements | kampanya listesi dens | **hazır** |
| **A27** | İskonto persist | order_entry satır iskonto % | **hazır** |
| **A28** | Seed yenile | menü seed yenile / docs notu | **hazır** |
| **A29** | ku/zh polish | kritik field_sales key kalitesi | **hazır** |
| **A30** | Mesai chip | dashboard DayStatusStore dens chip | **hazır** |

> **Kapanış:** A01–A30 turu **30/30 hazır**. P0 işlem **15/15**. Son kalan **A23** (Logo queue status chips → `logo_queue_status_chip` + pending/sync listeler) kapandı.  
> **40 tur kapanış:** **40/40 hazır**. Bu turda kapanan K: **K01–K05 · K13–K15**.  
> **60 tur kapanış:** **60/60 hazır**. K06–K12 · K16–K20 kapandı.
> **D60 regressyon:** analyze error **0** · guard/smoke/l10n/stub **281/281**.
> **K06 D01–D04:** list ✓ · untransferred ✓ · pending ✓ · tracking ✓ (dosya dens→SQLite).
> **Bilinçli sapma:** **K19 NFC** · **K20 VAN/iade** — MBT parity hedefi değil (kapandı).

---

## Durum anahtarı

| Etiket | Anlam |
|--------|--------|
| **Eksik** | MBT işlemi menüde yok veya form akışı hiç yok |
| **Yarım** | Route/stub var; MBT alan seti / tip sheet / kuyruk işlemi eksik |
| **Stub-only** | Title ekranı; plasiyer kayıt üretemez |
| **Hazır** | Dens form / tip / kuyruk akışı mevcut (Logo/SQLite derin bağ opsiyonel) |

| P | Anlam |
|---|--------|
| **P0** | Plasiyer gününü kırar — form olmadan sahada kullanılamaz |
| **P1** | MBT parity / kuyruk derinliği — P0 sonrası |
| **P2** | Favori / yönetici / WHMS — çekirdek günü bloklamaz |

---

## Dosya çakışması (zorunlu)

Her sibling ajan **tek klasör**. Paylaşılan dosyada yalnız kendi bloğu.

| Ajan # | Sahip | Klasör / kapsam |
|--------|-------|-----------------|
| **#1** | Mobil-Other | `other/` · `eod/` · seed `fs_other` |
| **#2** | Saha-Routes | `routes/` · seed `fs_visit` |
| **#3** | Mobil-Orders | `orders/` · seed `fs_order` |
| **#4** | Mobil-Invoices | `invoices/` · seed `fs_invoice` |
| **#5** | Mobil-Waybills | `waybills/` · seed `fs_waybill` |
| **#6** | Mobil-Delivery | `delivery/` · seed `fs_delivery` |
| **#7** | Mobil-Collections | `collections/` · seed `fs_finance` |
| **#8** | Mobil-Stock | `stock/` · seed `fs_stock` (WHMS dışı) |
| **#9** | Mobil-Sync | `sync/` · `settings/voucher*` · seed `fs_sync` / Fiş Ön Değer |
| **#10** | Dil | `assets/translations/*.json` only |
| **#11** | Tester | `test/modules/field_sales/**` |
| **#12** | Muhasebe | fiş tipi / KDV / cari risk review (kod yazmaz; #3–#7 review) |
| **—** | Merkez | bu board + canvas (feature kodu yazmaz) |
| **—** | UI | onaysız layout yok |

---

## P0 — İşlem checkbox (form akışı) — 15/15 KAPANDI

- [x] **P0-01 Güne Başlama / Bitirme MBT form** · `other/view/day_status_screen.dart` (+ `day_status_mbt_fields` · store) · **Hazır** · Ajan **#1**  
  PLAKA · BAŞLANGIÇ/BİTİŞ KM · Tamamlandı · Kaydet + kalıcılık (`DayStatusStore`). Mesai gate: `day_sales_gate.dart`.  
  Sibling: Dil #10 · Tester #11 · Saha review

- [x] **P0-02 Ziyaret formu (MBT alan seti + ZIYARETI TAMAMLA)** · `routes/view/` · **Hazır** · Ajan **#2**  
  `visit_mbt_fields` + `visit_mbt_form_data` + tamamla aksiyonu.  
  Sibling: Dil #10 · Tester #11

- [x] **P0-03 Sipariş Satış — cari → stok/hizmet → kalem satır** · `orders/` · **Hazır** · Ajan **#3**  
  Cari guard + entry + MBT katalog toolbar.  
  Sibling: Muhasebe #12 · Dil #10 · Tester #11

- [x] **P0-04 Sipariş Alış — ayrı tip akışı** · `orders/` · **Hazır** · Ajan **#3**  
  `order_type_sheet` SATIŞ | ALIŞ.  
  Sibling: Muhasebe #12 · Dil #10

- [x] **P0-05 Sipariş Onaylama formu** · `orders/view/order_approval_screen.dart` · **Hazır** · Ajan **#3**  
  ALIŞ/SATIŞ · Öneri · Sevk · dönem (dens form; title stub değil).  
  Sibling: Tester #11 · Dil #10

- [x] **P0-06 Fatura Toptan Satış — kalem/katalog akışı** · `invoices/` · **Hazır** · Ajan **#4**  
  Cari guard + entry + MBT katalog toolbar.  
  Sibling: Muhasebe #12 · Dil #10 · Tester #11

- [x] **P0-07 Fatura Satın Alma (MBT menü)** · `invoices/` + seed `fs_invoice` · **Hazır** · Ajan **#4**  
  Satın Alma tip/route yolu bağlandı.  
  Sibling: Muhasebe #12 · Dil #10

- [x] **P0-08 İrsaliye Toptan — cari → stok form** · `waybills/view/waybill_entry_screen.dart` · **Hazır** · Ajan **#5**  
  Cari guard + dens entry + toolbar.  
  Sibling: Muhasebe #12 · Dil #10 · Tester #11

- [x] **P0-09 İrsaliye Satın Alma form** · `waybills/` · **Hazır** · Ajan **#5**  
  `WaybillType.purchase` + routePurchase.  
  Sibling: Muhasebe #12 · Dil #10

- [x] **P0-10 Finans Yeni Hareket — 7 tip sheet** · `collections/` · **Hazır** · Ajan **#7**  
  Nakit/KK/Çek/Senet tahsilat + ödeme (`payment_entry`) + **Virman** formları.  
  Sibling: Muhasebe #12 · Dil #10 · Tester #11

- [x] **P0-11 Nakit tahsilat alan seti (A01 dens)** · `collections/` + `collection_cash_mbt_fields` · **Hazır** · Ajan **#7 / A01**  
  İşlem Dövizi · EVRAK NO · KASA KODU · AÇIKLAMA · TUTAR · PLASIYER · ÖZELKOD 1.  
  Sibling: Muhasebe #12 · Dil #10

- [x] **P0-12 Çek tahsilat alan seti (A02 dens)** · `collections/` + `check_collection_mbt_fields` · **Hazır** · Ajan **#7 / A02**  
  CIRO · ASIL BORÇLU · BANKA · İŞYERI · ÇEK NO · HESAP NO · VADE (+ mevcut şube).  
  Sibling: Muhasebe #12 · Dil #10 · Tester #11

- [x] **P0-13 Teslimat kuyruk işlemi (1-SATIŞ / 2-ALIŞ)** · `delivery/` · **Hazır** · Ajan **#6**  
  `MbtSalesPurchaseQueueBody` + dönem sekmeleri.  
  Sibling: Saha #2 review · Dil #10 · Tester #11

- [x] **P0-14 Ambar Fişi (Kaynak→Hedef)** · `stock/warehouse_receipt` + `stock_slip_dens_form` · **Hazır** · Ajan **#8**  
  KAYNAK/HEDEF × İŞYERI · FABRIKA · AMBAR dens iskeleti.  
  Sibling: Dil #10 · Tester #11 · WHMS’e dokunma

- [x] **P0-15 Sayım Fişi form** · `stock/stock_count_screen` · **Hazır** · Ajan **#8**  
  İşyeri/Fabrika/Ambar dens diyalog + satır iskeleti.  
  Sibling: Dil #10 · Tester #11

### Çapraz (board dışı / P1–P2 — bu turda kapandı)

- [x] **Cari detay hub → belge kısayolları** · `customers/customer_detail_screen` · was P1-14  
- [x] **Belge katalog toolbar** · `shared/view/mbt_catalog_toolbar.dart` (sipariş/fatura/irsaliye)  
- [x] **Mesai gate** · `other/viewmodel/day_sales_gate.dart`  
- [x] **Favoriler kalp toggle** · dashboard + `favorites/` · was P2  
- [x] **Yönetici KPI gerçek SQLite aggregate** · `yonetici/admin_kpi_*` · **K17** ✓ (D21)  
- [x] **Sales targets dens+SQLite** · `sales_targets` · **K18** ✓ (D23)  

---

## Kalanlar — P1 / P2

UI redesign yok · Commit yok · **60 ajan turu Hazır (60/60)** · açık **0** K · **D60** 281/281.

### Bu turda kapanan (40 ajan · B01–B39)

| # | Madde | Ajan | Durum |
|---|--------|------|--------|
| **K01** | SQLite/Logo persist entry/kuyruk | B02–B05 · B24–B28 · B30 | **Hazır** |
| **K02** | GİB dens ETTN/durum (e-Fatura/e-İrsaliye) | B06–B07 | **Hazır** (canlı GİB API değil) |
| **K03** | Araç stok yükle/boşalt provider | B14–B15 | **Hazır** |
| **K04** | Duyuru/kampanya SQLite + badge | B19–B21 | **Hazır** |
| **K05** | Ürün resimleri REST/stub servis | B22 | **Hazır** |
| **K13** | B39 regressyon kapısı | B39 Tester | **Hazır** · analyze **0** · **253/253** |
| **K14** | Dil polish en/fa/ku | B34–B36 | **Hazır** |
| **K15** | Rapor export + SQLite satır + host | B16–B18 | **Hazır** |
| **K10** | Fiş Ön Değer dens + seed wiring | `#9` | **Hazır** · fatura/irsaliye/ayarlar → `/voucher-defaults` |
| **K07** | Fatura Liste/Pending/Untransferred dens→SQLite | D05–D08 · `#4` | **Hazır** |
| **K08** | İrsaliye liste dens→SQLite | D09 · `#5` | **Hazır** · waybill_list |
| **K09** | Tahsilat Transfer/Kasa/Çek dens→SQLite | D12–D15 · `#7` | **Hazır** |
| **K17** | Yönetici KPI SQLite aggregat | D21 | **Hazır** · admin_kpi |
| **K18** | Sales targets dens+SQLite/seed | D23 | **Hazır** · sales_targets |
| **K06** | Sipariş Liste/Pending/Untransferred/Takip dens→SQLite | D01–D04 · `#3` | **Hazır** · 4/4 parça |
| **K11** | Ziyaret Geçmiş/Transfer edilmeyen dens→SQLite | D17–D18 · `#2` | **Hazır** |
| **K12** | Taslak fiş uyarısı (unsaved) ortak entry | D19 | **Hazır** · unsaved_voucher |
| **K16** | WHMS R3 yerel stok txn | D20 | **Hazır** · stock txn |

### P1 / P2 kalan

**Açık K = 0.** 60 tur kapandı.

### K06 parçaları (D01–D04) — dosya doğrulama

| ID | Madde | Durum | Dosya |
|----|--------|--------|-------|
| **D01** | order_list dens→SQLite (transferred) | **Hazır** | `orders/view/order_list_screen.dart` |
| **D02** | orders_untransferred dens→SQLite+sync_queue | **Hazır** | `orders/view/orders_untransferred_screen.dart` |
| **D03** | orders_pending dens→SQLite ONAY | **Hazır** | `orders/view/orders_pending_screen.dart` |
| **D04** | order_tracking dens→SQLite | **Hazır** | `orders/view/order_tracking_screen.dart` |

### Bilinçli sapma (kapandı — iş yok)

| # | Madde | Karar | Kanıt |
|---|--------|-------|-------|
| **K19** | NFC | **Uydurma yok** · MBT parity hedefi değil · yeni NFC ekranı / menü / check-in bağı **yazılmaz** | MimBT web/store/cihazda NFC yok (`mbt-system-expertise` §7.4 · şema §6.3) |
| **K20** | VAN / iade ayrı menü | **Bilinçli sapma** · MimBT cihazda ayrı VAN/iade etiketi **yok** → OPS’te **ayrı VAN menü uydurma yok**. İade: Logo Mobile Sales tarzı **Toptan Satış İade (TYPE 3)** seed+route **bilinçli tutulur** (MBT Satın Alma ≠ iade). Yeni “VAN Satış” menü satırı **eklenmez** | Şema §10.3 · muhasebe checklist P0-07 / TYPE 3 satırı · route doğrulama aşağıda |

**Legacy not (K19):** `lib/service/nfc_service.dart` + `reports/view/dashboard_screen.dart` içinde eski NFC tarama kodu kalabilir; **genişletilmez**, ziyaret check-in’e bağlanmaz, seed/route eklenmez. Temizlik ayrı onayla.

#### K20 — İade menü route doğrulama (2026-07-26)

| Kaynak | Title / seed | Named route | Hedef ekran | `invoiceType` |
|--------|--------------|-------------|-------------|---------------|
| Cari alt menü | `Toptan Satış İade` · `sub_cust_return` | `/field-sales/wholesale-return` | cari yoksa `InvoiceCustomerSelectionScreen` · varsa `InvoiceEntryScreen` | `Satış İade Faturası (3)` → `field_sales.sales_return_invoice_3` · Logo **TYPE 3** |
| Fatura alt menü | `Toptan Satış İade` · `sub_inv_return` | `/field-sales/invoice-return` | aynı cari-önce zincir | aynı TYPE 3 |
| Dashboard title case | `'Toptan Satış İade'` | (route yok; switch) | aynı cari-önce zincir | aynı TYPE 3 |
| Day gate | — | her iki path + title | `day_sales_gate` listesinde | satış günü kapısı |

**Dosyalar:** `database_service.dart` (`fs_customers` / `fs_invoice`) · `AppRoutes.fieldSalesWholesaleReturn` / `fieldSalesInvoiceReturn` · `mobile_dashboard.dart` case · `logo_payload_mapper` / `invoice_provider` TYPE 3.

**Sapma notları (bilinçli / kapatılmaz olarak açık):**
- Ayrı **VAN** menü satırı yok — yalnızca dahili `field_sales.van_sales` (varsayılan tip); MBT etiketini uydurma.
- `/field-sales/return-entry` + `/field-sales/returns-list` stub’ları menü seed’ine **bağlı değil** (orphan stub; iade akışı fatura TYPE 3 yolu). Seed’e eklenmez.

### Legacy P1 checkbox (K* ile eşle)

- [x] **P1-01…02** → **K06** · `#3` ✓ (D01–D04)
- [x] **P1-03** → **K07** · `#4` ✓ (D05–D08)
- [x] **P1-04** → **K08** · `#5` ✓ (D09)
- [x] **P1-05…07** → **K09** · `#7` ✓ (D12–D15)
- [x] **P1-08** Üretim enqueue · B27 (K01 ile)
- [ ] **P1-09** Barkod Ekle · `#8`
- [x] **P1-10** → **K10** · `#9`
- [x] **P1-11** triad dens · **K05** ✓
- [x] **P1-12** → **K11** · `#2` ✓ (D17–D18)
- [ ] **P1-13** Bilgi Gönderme · `#1`
- [x] **P1-14** Cari hub · **Hazır**
- [x] **P1-15** → **K12** · `#3+#4` ✓ (D19 unsaved)

---

## Plasiyer gün → P0 bağımlılık

```
#1 Güne Başlama (plaka+km) ✓ + mesai gate ✓
  └─ #2 Ziyaret formu (MBT alan) ✓
       ├─ #3 Sipariş Satış/Alış + Onaylama ✓
       ├─ #4 Fatura Toptan + Satın Alma ✓
       ├─ #5 İrsaliye Toptan + Satın Alma ✓
       ├─ #6 Teslimat kuyruk ✓
       └─ #7 Finans tip sheet ✓ · nakit/çek alan ✓
            ├─ #8 Sayım / Ambar ✓
            └─ #9 Güncelleme / Fiş ön değer (K05 ✓ · K10 ✓)
                 └─ #1 Güne Bitirme ✓
```

Dil (#10) ve Tester (#11) **her P0 ile paralel**. Muhasebe (#12) fiş tipi/KDV review. UI redesign yok.

---

## Sibling ajan ne yapacak? (özet)

| Ajan | P0 | 60 tur odağı |
|------|----|----------------|
| **#1 Mobil-Other** | P0-01 ✓ | P1-13 Bilgi Gönderme |
| **#2 Saha-Routes** | P0-02 ✓ | **K11** ✓ |
| **#3 Mobil-Orders** | P0-03…05 ✓ | **K06** ✓ · **K12** ✓ |
| **#4 Mobil-Invoices** | P0-06…07 ✓ | **K07** ✓ · K12 ✓ · K02 ✓ |
| **#5 Mobil-Waybills** | P0-08…09 ✓ | **K08** ✓ · K12 ✓ · K02 ✓ |
| **#6 Mobil-Delivery** | P0-13 ✓ | — |
| **#7 Mobil-Collections** | P0-10…12 ✓ | **K09** ✓ · K12 ✓ |
| **#8 Mobil-Stock** | P0-14…15 ✓ | K03 ✓ · K01 ✓ · **K16** R3 ✓ |
| **#9 Mobil-Sync** | — | K01/K04/K05/**K10**/K15 ✓ |
| **#10 Dil** | form key ✓ | K14 ✓ · dens key izle |
| **#11 Tester** | form smoke | **D60 yeşil** 281/281 |
| **#12 Muhasebe** | #7 review | K02 dens ✓ · liste review |
| **Merkez** | board/canvas | 40/40 · **60/60 kapandı** · D60 yeşil |
| **UI** | bekler | dens flat koru |

---

## Kapı vs bu board

| | Stub kapısı (`ops-completion-gate`) | Bu board (işlem) |
|--|--------------------------------------|------------------|
| Kriter | menü → route → stub + cari guard + l10n | menü → **form alanları + kaydet akışı** |
| Durum | **HAZIR** (P0=0) | **P0: 15/15 Hazır · 0 açık** |
| Sonraki | — | **60/60 Hazır** · açık **0** · **D60** analyze 0 · **281/281** |
| WHMS | Prep OK + B37 stub · **K16 R3 ✓** · **Faz 1 iskelet** | API/Logo + `/whms` shell Faz 2 |
| B39 / **D60** | — | B39: 253/253 · **D60: analyze 0 · 281/281** |

---

## Panel özeti (Merkez)

| Rol | Durum | Risk | TODO |
|-----|-------|------|------|
| Merkez | hazır | — | 40 **40/40** · 60 **60/60** · **D60** 281/281 |
| Saha | hazır | — | **K11** ✓ |
| Dil | hazır | — | K14 ✓ |
| Tester | hazır | — | **D60 yeşil** 281/281 |
| Mobil | hazır | — | **K06** D01–D04 ✓ · **K12** ✓ |
| Muhasebe | izle | canlı GİB | K02 dens ✓ |
| UI | bekler | Redesign baskısı | Onaysız layout yok |

**İlgili:**  
`docs/plans/2026-07-26-ops-mbt-missing-ops-board.md` ·  
`docs/plans/2026-07-26-mbt-system-expertise.md` ·  
`docs/plans/2026-07-26-ops-completion-gate.md` ·  
canvases/`OPS-mbt-uygulama-durum.canvas.tsx` ·  
`lib/service/database_service.dart` (fs_* seed) ·  
`lib/modules/field_sales/**/view/`
