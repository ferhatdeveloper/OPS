# Muhasebe Stub Checklist — Waybill / Invoice / Collection

**Tarih:** 2026-07-26  
**Rol:** Muhasebe #12 (OPS panel)  
**Commit:** Yok · **Kod:** Minimal / yok (yalnız bu belge)  
**Board kapsam:** P0-03 … P0-12 (`2026-07-26-ops-mbt-missing-ops-board.md`)  
**Kaynak:** `2026-07-25-mbt-app-structure-schema.md`, `2026-07-26-ops-mbt-missing-ops-board.md`, `2026-07-26-ops-missing-modules-board.md`, `2026-07-26-ops-mbt-content-gap.md`, `logo_payload_mapper.dart`, `invoice_entry_screen.dart`, `waybills/*` stub’lar, `collections/*`, `orders/*`  
**Kural:** UI redesign yok. Cari-önce + LOGO fiş tipi + KDV doğruluğu; stub’lar gerçek fiş üretmeden önce bu checklist’i geçmeli.

---

## Ajan özeti

| Alan | Durum | Risk (kısa) |
|------|--------|-------------|
| Board P0-03…05 Sipariş | **Yarım** | Cari-önce + Alış UI var; mapper/queue `order_sales`/`order_purchase` eklendi; KDV/risk gate yarım |
| Board P0-06…07 Fatura | **Yarım / eksik** | TYPE 8 flatten; Satın Alma menü yolu yok; iade seed MBT’den sapma |
| Board P0-08…09 İrsaliye | **Yarım** | Dispatch TYPE yok; Satın Alma form stub; fatura/irsaliye menü çakışması |
| Board P0-10…12 Finans | **Yarım** | 7 tip sheet eksik; nakit/çek alan seti yarım; KDV yok (doğru) |
| Cari risk | **Eksik** | `credit_limit` modeli yok; bakiye var, satış öncesi gate yok |
| KDV | **Yarım** | Kalemde `vatRate` default %20; enqueue `vat_rate` kayboluyor; print/mock riski |

**Bu belge “tamamlandı” sayılmaz** — yalnızca muhasebe kabul kriterlerini sabitler.  
Implementasyon: Mobil-Orders (#3) / Mobil-Invoices (#4) / Mobil-Waybills (#5) / Mobil-Collections (#7) + Tester (#11) + Dil (#10).

---

## 0. Board P0-03…12 — LOGO TYPE / KDV / Cari (Muhasebe #12)

> Her satır: **LOGO TYPE** (veya API `invoice_type` / `payment_type`) · **KDV** · **Cari**.  
> Firma özel TRCODE tablosu canlı dönemde doğrulanır; aşağıdaki hedef değerler ExfinApi / Logo Objects alışkanlığıdır.

| Board | MBT / OPS konu | LOGO TYPE / API hedef | KDV | Cari | Muhasebe durum |
|-------|----------------|----------------------|-----|------|----------------|
| **P0-03** | Sipariş **Satış** — cari → stok/hizmet → kalem | Sipariş satış (Logo order satış kanalı; fatura TYPE **değil**). Kuyruk entity=`order`, `type=sales` / `order_channel=order_sales` | Kalem `vat_rate` (%20/%10/%1/%0); matrah+KDV taslak; **cari borç = fatura anında** (siparişte risk preview) | **Zorunlu** cari-önce; `ARP_CODE` boş engel; risk: `balance + draft > credit_limit` (limit yok → P0 backlog) | **Yarım** — TYPE map hazır; kalem KDV taşıma zayıf |
| **P0-04** | Sipariş **Alış** — ayrı tip | `type=purchase` / `order_channel=order_purchase`; **satış siparişiyle aynı payload yasak** | Tedarikçi fatura/irsaliye sonrası KDV; siparişte bilgilendirme oran OK | **Tedarikçi cari** (alış ARP); müşteri satış carisiyle karıştırma | **Hazır** — mapper + `card_role` tedarikçi gate/test (P1) |
| **P0-05** | Sipariş **Onaylama** formu | Onay fiş üretmez; onay sonrası mevcut order tipini koru (sales/purchase). Logo’ya yanlış TYPE flatten yok | Onay ekranı KDV değiştirmez; kalem oranları salt okunur / dönem kuralı | Cari zaten siparişte; onayda cari değiştirme yok (veya yeniden risk) | **Stub-only** — title; ALIŞ/SATIŞ · Sevk Edilebilir alanları muhasebe için şart |
| **P0-06** | Fatura **Toptan Satış** — kalem/katalog | **TYPE 8** / `wholesale` · `field_sales.wholesale_invoice_8` | Kalem `vat_rate`→`vat_amount`; enqueue satırda taşı; ürün oranından oku | Cari-önce; VKN → e-Fatura/e-Arşiv bayrağı (P1 GİB); `ARP_CODE` dolu | **Yarım** — entry+guard; katalog parity; kuyruk TYPE flatten riski |
| **P0-07** | Fatura **Satın Alma** (MBT menü) | Alış fatura TYPE (genelde **1/4** ailesi — **firma şeması doğrula**); yerel `purchase`. OPS seed **Toptan Satış İade (TYPE 3)** MBT Satın Alma **değil** — bilinçli sapma; Satın Alma öncelikli | Alış KDV indirilecek KDV; oran kalemden; iade (TYPE 3) ile karıştırma | **Tedarikçi cari**; satış carisi engelli / ayrı seçim listesi | **Eksik** — menü+form yolu yok; iade≠alış |
| **P0-08** | İrsaliye **Toptan** — cari → stok | `dispatches/sync` + **dispatch TYPE satış** (`waybill_wholesale`); **invoice TYPE 8 göndermek yasak** | Satırda bilgilendirme KDV OK; **cari KDV borçlanması fatura ile** | Cari-önce (`cariId`); sevkte genelde cari hareket yok/zayıf | **Yarım** — guard+placeholder; mapper’da fiş TYPE yok |
| **P0-09** | İrsaliye **Satın Alma** | Dispatch **alış TYPE** (`waybill_purchase`); toptan satış dispatch ile aynı map yasak | KDV fatura/alış faturasına bırak; irsaliyede “tahmini” | Tedarikçi cari zorunlu | **Yarım** — seed route; MBT alanlı form yok |
| **P0-10** | Finans **Yeni Hareket** — 7 tip sheet | Tahsilat: `cash` / `credit_card` / `check` / `note`(senet). Ödeme: `CashOut` / `CreditCardOut` (cari borç artırıcı / kasa çıkış). **Virman:** kasa↔kasa — `ARP` yok veya özel; **collections/sync tahsilat TYPE’ına flatten etme** | **KDV yok** (tüm 7 tip) | Tahsilat/ödeme: cari zorunlu; Virman: cari değil, kaynak/hedef **kasa** | **Yarım** — 4 tip EN literal; ödeme+virman sheet eksik |
| **P0-11** | **Nakit** tahsilat alan seti | `payment_type=cash` + `safe_code` (KASA KODU); EVRAK NO → fiche/ref | KDV yok | Cari + tutar>0; döviz/plasiyer/özelkod fiş header | **Yarım** — tutar/not; kasa/evrak/döviz/özelkod eksik; `safe_code` sabit `01` |
| **P0-12** | **Çek** tahsilat alan seti | `payment_type=check`; vade/banka/çek no Logo CL/çek alanlarına map | KDV yok | Cari zorunlu; CIRO / ASIL BORÇLU cari risk notu (teminat); tutar+vade | **Yarım** — banka/şube/çek/vade var; ciro/asıl borçlu/işyeri/hesap no eksik |

### Board kabul özeti (kod yazmadan önce)

```text
❌ BAD: P0-07 Satın Alma’yı TYPE 3 iade ile açmak; P0-08 irsaliyeyi invoice TYPE 8 kuyruğa atmak; P0-10 virmanı cash tahsilat sanmak; sipariş/fatura KDV’siz enqueue
✅ GOOD: P0-03/06 satış → cari-önce + kalem vat_rate; P0-04/07/09 alış → tedarikçi + ayrı TYPE; P0-08 dispatch TYPE; P0-10…12 KDV yok + payment_type/safe_code net
```

### P0-03…12 → mevcut bölüm çaprazı

| Board | Bu belgede | Implementasyon ajanı |
|-------|------------|----------------------|
| P0-03…05 | §1 sipariş satırı (aşağı) + §2 cari + §3 KDV | #3 Mobil-Orders |
| P0-06…07 | §1 fatura + §4.1 | #4 Mobil-Invoices |
| P0-08…09 | §1 irsaliye + §4.2 | #5 Mobil-Waybills |
| P0-10…12 | §1 finans + §4.3 | #7 Mobil-Collections |

---

## 1. LOGO fiş tipi haritası (zorunlu)

OPS plasiyer menü dili **MBT**; ERP tarafında ExfinApi / Logo Objects **TYPE** (veya `invoice_type` string → backend TRCODE) taşınır.

| Board | MBT / OPS menü | Belge | Yerel anahtar (önerilen) | Logo / API hedef | Stok etkisi | Cari etkisi |
|-------|----------------|-------|--------------------------|------------------|-------------|-------------|
| P0-03 | Sipariş → **Satış** | Satış siparişi | `order_sales` | Order satış kanalı · **≠ fatura TYPE 8** | Rezervasyon / yok (parametre) | Risk preview; borç fatura ile |
| P0-04 | Sipariş → **Alış** | Alış siparişi | `order_purchase` | Order alış · satış siparişiyle flatten yasak | Beklenen giriş | Tedarikçi ARP |
| P0-05 | Sipariş → **Onaylama** | Onay (meta) | — | Tip koru; fiş üretmez | — | Cari kilitli |
| P0-06 | Fatura → **Toptan Satış** | Satış faturası | `field_sales.wholesale_invoice_8` | **TYPE 8** / `type=wholesale` | Çıkış (depo veya araç — parametre) | Borç ↑ |
| — | Fatura → **Toptan Satış İade** (OPS seed sapması) | Satış iade faturası | `field_sales.sales_return_invoice_3` | **TYPE 3** / `type=return` | **Giriş** | Alacak / borç ↓ |
| — | Fatura → sıcak satış (dahili) | Van / araç satış | `field_sales.van_sales` | Ayrı kanal veya wholesale; **iade ile karıştırma** | Araç stok çıkış | Borç ↑ |
| P0-07 | Fatura → **Satın Alma** | Alış faturası | `purchase` / lokal enum | Alış TYPE (genelde 1/4 ailesi — firma şeması doğrula); **≠ TYPE 3** | Giriş | Alacak (tedarikçi) |
| P0-08 | İrsaliye → **Toptan Satış** | Sevk irsaliyesi | `waybill_wholesale` | `dispatches/sync` + **dispatch TYPE satış** | Çıkış / sevk | Genelde cari hareket **yok** veya zayıf (fatura sonrası kapanır) |
| P0-09 | İrsaliye → **Satın Alma** | Mal alım irsaliyesi | `waybill_purchase` | Dispatch alış TYPE | Giriş | Tedarikçi bağlamı |
| P0-10…12 | Finans → **Yeni Hareket** | Tahsilat / ödeme / virman | `cash`/`credit_card`/`check`/`note` + `CashOut`/`CreditCardOut` + virman | `collections/sync` · `payment_type` + `safe_code`; virman ayrı | Yok | Tahsilat: Alacak; Ödeme: Borç↑; Virman: kasa |
| — | Finans → **Kasa Kart Listesi** | Kasa master | — | Logo kasa kartları (CLCARD/safe) | Yok | Referans; fiş değil |

### Stub / kodda bilinen sapmalar

1. **`invoice_provider` enqueue** her zaman `'type': 'wholesale'` yazar → menüden TYPE 3 seçilse bile Logo’ya toptan gider.  
   - Dosya: `lib/modules/field_sales/invoices/viewmodel/invoice_provider.dart`  
2. **`JobQueueService` fatura** tip çözümlemesi `purchase` / `return` / `retail` / `wholesale` — sipariş kanalından ayrı.  
   - Dosya: `lib/service/job_queue_service.dart`  
3. **Sipariş sales/purchase (P0-03/04) — 2026-07-26 minimal:**  
   - `LogoPayloadMapper.resolveOrderApiType` + `orderFromLocal` → `type` / `order_type` / `order_channel` (`order_sales` | `order_purchase`)  
   - `JobQueueService._ensureOrderTypeFields` kuyruk gönderiminde kanalı garanti eder  
   - `order_provider` enqueue `orderType.storageValue` taşır  
   - Satır `TYPE` = Logo kalem (0/4); fiş kanalı değil · **≠ fatura TYPE 8**  
4. **`LogoPayloadMapper.dispatch*`** satır/header’da **fiş TYPE alanı yok**.  
   - Dosya: `lib/core/services/logo_payload_mapper.dart`  
5. Dashboard **`case 'Toptan Satış'`** yalnızca `InvoiceEntryScreen` açar → İrsaliye menüsündeki aynı başlık **fatura stub’ına düşer** (çakışma).  
   - Dosya: `lib/view/mobile_dashboard.dart`  
6. İrsaliye stub route’ları (`WaybillEntryScreen.routeWholesale`, untransferred/pending) **dashboard case’lerinde yok**; transfer listeleri generic `PendingTransfersScreen`.

```text
❌ BAD: İade faturasını wholesale ile kuyruğa atmak; boş customerId ile TYPE 8 kesmek; siparişi invoice wholesale’e flatten
✅ GOOD: Menü → yerel tip anahtarı → Logo TYPE 8/3 net map; sipariş order_sales/order_purchase; cari seçilmeden draft yok
```

---

## 2. Cari-first (cari-önce) kuralları

Sipariş kalıbı referans: `OrderCustomerSelectionScreen` + `OrderNotifier.isValidCustomerId`.

| Board | Belge | Zorunlu | Stub bugün | Muhasebe kabul |
|-------|-------|---------|------------|----------------|
| P0-03/04 | Sipariş satış / alış | Evet | Cari seçim + entry (satış); alış yolu yok | Boş cari engel; alışta **tedarikçi** ARP |
| P0-05 | Sipariş onay | Siparişteki cari | Title stub | Cari değiştirme yok / yeniden risk |
| P0-06/07 | Fatura toptan / alış | Evet | Entry+guard (toptan); Satın Alma eksik | Boş / `''` → kayıt/kuyruk **engelli**; alış≠iade |
| P0-08/09 | İrsaliye toptan / alış | Evet | `cariId` ctor; wiring yarım | Aynı guard; `cariId` route arg |
| P0-10…12 | Tahsilat / ödeme | Evet (virman: kasa) | Entry kısmi; 7 tip eksik | Tutar > 0 + cari; virman kasa kodları |
| — | Liste ekranları | Filtre opsiyonel | `customerId` nullable OK | Liste boş cari OK; **yeni fiş** cari-önce |
| — | Kasa Kart Listesi | Cari değil, kasa master | `CashCardListScreen` stub | Fiş kesmez; `safe_code` kaynağı (P0-11) |

### Cari muhasebe alanları (satış öncesi)

| Alan | Kaynak | Stub notu |
|------|--------|-----------|
| `taxNo` / `taxOffice` | `CustomerModel` | e-Fatura / e-Arşiv ayrımı için; stub’da GİB sorgu yok — en azından VKN boşsa uyarı (P1) |
| `balance` | `CustomerModel` | Gösterim OK; tahsilat sonrası yerel bakiye güncelleme doğrulanmalı |
| `credit_limit` | **Yok** | P0 backlog: `balance + draftTotal > limit` → fatura/sipariş blok veya onay |

**Aktif ziyaret:** Varsa `activeVisit.customerId` ile aç (sipariş gibi); yoksa seçim ekranı. Check-in politikası saha ajanında; muhasebe: fişte `customer_code` / `ARP_CODE` boş olamaz (`LogoPayloadMapper`).

---

## 3. KDV notları

| Konu | Kural | Stub / mevcut kod |
|------|--------|-------------------|
| Oranlar | %20 / %10 / %1 / %0 (TR) | `SlipDefaultsScreen` dropdown `0,1,10,20`; ürün `vatRate` default 20 |
| Hesap | `(qty × price − iskonto) × (rate/100)` kalem bazında; yuvarlama 2 hane | `invoice_provider.addItem` / `order_provider`: `vatAmount = price * qty * (vatRate/100)` — **iskonto yoksa OK**; kampanya iskontosu sonrası yeniden hesap zorunlu |
| Kaynak | Önce ürün `vat_rate`, yoksa fiş ön değer, yoksa %20 | Stub’larda katalog placeholder → sabit %20 kabul; gerçek bağlama P0 |
| İrsaliye | e-İrsaliye satırında KDV bilgilendirme amaçlı olabilir; **cari KDV borçlanması fatura ile** | Stub amount alanı “tutar” gösteriyor — muhasebe: irsaliye stub’ında KDV’yi fatura ile karıştırma; etiket “tahmini / fatura sonrası” |
| Tahsilat | **KDV yok** | `CollectionModel` yalnızca tutar + ödeme tipi — doğru |
| İade (TYPE 3) | Aynı oranlarla negatif/iade kalem; KDV iadesi | Tip map düzelmeden KDV de yanlış fişe gider |
| Yazdırma | Makbuz/fatura KDV satırı ürün oranından | Backlog: print KDV mock riski (`SAHA_SATIS_TODO`) |

```text
❌ BAD: Header’da tek KDV oranı uydurup kalemleri yok saymak; tahsilata KDV eklemek
✅ GOOD: Kalem vat_rate → vat_amount; toplam = matrah + KDV; Logo satırında vat_rate taşı
```

`LogoPayloadMapper.invoiceFromLocal` satırda `vat_rate` opsiyonel — enqueue `lines` şu an yalnızca `product_code/quantity/price` gönderiyor → **KDV satırı kayboluyor**. Mapper’a `vat_rate` / `vat_amount` eklenmesi muhasebe P0.

---

## 4. Belge bazlı stub checklist

### 4.0 Sipariş (`lib/modules/field_sales/orders/`) — Board P0-03…05

- [x] **P0-03** Mapper/queue: `type=sales` + `order_channel=order_sales` (≠ fatura TYPE 8)  
- [ ] **P0-03** Cari-önce + kalem satır; `vat_rate` ürün/fiş; iskonto sonrası KDV yeniden hesap  
- [x] **P0-04** Mapper/queue: `type=purchase` + `order_channel=order_purchase`; satış flatten yok  
- [ ] **P0-04** Tedarikçi cari gate / ayrı seçim listesi  
- [ ] **P0-05** Onay formu: ALIŞ/SATIŞ · Sevk Edilebilir/Edilemez · dönem; tip koru  
- [x] Sipariş entity ≠ fatura TYPE 8 kuyruğu (kanal alanları ayrı)  
- [ ] Risk preview: `balance + draftTotal` (credit_limit gelince gate)

**İlgili:** `order_entry_screen.dart`, `order_customer_selection_screen.dart`, `order_approval_screen.dart`, `order_provider.dart`, `price_engine.dart`, `logo_payload_mapper.dart`, `job_queue_service.dart`  
**Test:** `test/core/services/logo_order_type_map_test.dart`

### 4.1 Fatura (`lib/modules/field_sales/invoices/`) — Board P0-06…07

- [ ] **P0-06** Dashboard: boş `customerId` kaldır; sipariş cari-önce kopyası; katalog/kalem  
- [ ] Menü dili: plasiyer yüzünde **Toptan Satış** (Van Sales yalnızca dahili key)  
- [ ] `invoiceType` → Logo TYPE: `wholesale_invoice_8`→**8**, `sales_return_invoice_3`→**3**, `van_sales`→van/retail kanalı (wholesale’e flatten etme)  
- [ ] **P0-07** Satın Alma menü+form; alış TYPE; **iade TYPE 3 ile değiştirme**  
- [ ] İade: stok **artış**; toptan: stok **azalış**; negatif stok engeli  
- [ ] Risk limiti gate (credit_limit eklendikten sonra)  
- [ ] Job payload: `type` + kalem `vat_rate`  
- [ ] e-belge bayrağı: `isEInvoice` + VKN; stub’da en azından alan korunur  
- [ ] Liste: mock yerine SQLite (P0 backlog)

**İlgili dosyalar:**  
`invoices/view/invoice_entry_screen.dart`, `invoice_provider.dart`, `invoice_model.dart`, `mobile_dashboard.dart`, `logo_payload_mapper.dart`, `job_queue_service.dart`

### 4.2 İrsaliye (`lib/modules/field_sales/waybills/`) — Board P0-08…09

Stub dosyalar (2026-07-26):  
`waybill_entry_screen.dart`, `waybill_list_screen.dart`, `waybills_untransferred_screen.dart`, `waybills_pending_screen.dart`

- [ ] **P0-08** Fatura ile başlık çakışması: parent/uuid (`sub_inv_*` vs `sub_way_*`)  
- [ ] Entry: `cariId` zorunlu + boş guard  
- [ ] Yerel tip: `waybill_wholesale` / `waybill_purchase` — Logo dispatch TYPE map (firma doğrulaması)  
- [ ] **P0-09** Satın Alma irsaliye formu; tedarikçi cari; alış dispatch TYPE  
- [ ] Satır: miktar zorunlu; birim fiyat/KDV fatura kopyası değilse “sevk” odaklı tut  
- [ ] Transfer edilmeyen / bekleyen: entity=waybill; generic pending title parametresi  
- [ ] `createDispatch` + mapper’a TYPE / warehouse / plaka (Fiş Ön Değerleri)  
- [ ] e-İrsaliye: fatura kesilmeden sevk senaryosu — cari-first aynı

**Muhasebe notu:** İrsaliye ≠ fatura. Stub tutar göstermek OK; Logo’ya “invoice TYPE 8” göndermek **yasak**.

### 4.3 Tahsilat / kasa (`lib/modules/field_sales/collections/`) — Board P0-10…12

- [ ] **P0-10** 7 tip sheet: Nakit/KK/Çek/Senet tahsilat + Nakit/KK ödeme + Virman; EN literal→API map  
- [ ] Yeni Hareket: cari-önce + `amount > 0` (virmanda kasa-önce)  
- [ ] **P0-11** Nakit: İşlem Dövizi · EVRAK NO · KASA KODU · AÇIKLAMA · TUTAR · PLASIYER · ÖZELKOD 1  
- [ ] **P0-12** Çek: EVRAK · TUTAR · VADE · CIRO · ASIL BORÇLU · BANKA · İŞYERI · ÇEK NO · HESAP NO · AÇIKLAMA  
- [ ] `safe_code`: stub sabit `01` → Kasa Kart Listesi’nden seçim (P1)  
- [ ] KDV yok; makbuz yazdırma tahsilat tutarı  
- [ ] Transfer edilen / edilmeyen tahsilat listeleri entity ayrımı  
- [ ] Cari bakiye: tahsilat sonrası yerel güncelleme + sync idempotency

**Stub:** `cash_card_list_screen.dart` — kasa master; fiş TYPE üretmez. Seed route `/statement` ile stub `/field-sales/cash-cards` hizalanmalı (Mobil-Collections).

---

## 5. Somut TODO (muhasebe önceliği — Board P0-03…12)

1. **P0-03/06 TYPE + KDV:** Sipariş `order_sales` ≠ fatura TYPE 8; fatura `wholesale→8`; enqueue `lines` içine `vat_rate`/`vat_amount` (ürün oranından).  
2. **P0-04/07/09 Alış ayrımı:** `order_purchase` / fatura alış TYPE / `waybill_purchase`; OPS iade seed (TYPE 3) Satın Alma yerine geçmesin.  
3. **P0-05 Onay:** ALIŞ/SATIŞ + sevk edilebilirlik alanları; onayda tip flatten yok.  
4. **P0-08 İrsaliye:** mapper + job’a dispatch TYPE; `invoice` entity / TYPE 8 yasak; menü uuid/parent ayrımı.  
5. **P0-10…12 Finans:** 7 tip sheet (`payment_type` TR map); nakit `safe_code`+evrak; çek ciro/asıl borçlu; **KDV ekleme**; virman≠tahsilat.

---

## 6. Test ajanına notlar (regresyon — Board)

| Board / Test | Beklenen |
|--------------|----------|
| P0-03 Boş cari sipariş satış | Kayıt yok; l10n uyarı |
| P0-04 Alış menü | Payload `purchase`; satış order type değil |
| P0-05 Onay stub→form | Tip (alış/satış) korunur; fiş TYPE üretilmez |
| P0-06 Toptan fatura | Payload wholesale / Logo **8**; kalem `vat_rate` |
| P0-07 Satın Alma | Alış TYPE; **TYPE 3 iade değil** |
| P0-08 İrsaliye toptan | `dispatches` + dispatch TYPE; `invoice` entity yok |
| P0-09 İrsaliye alış | Dispatch alış TYPE; tedarikçi cari |
| P0-10 7 tip | Tahsilat/ödeme/virman ayrımı; EN literal→API map |
| P0-11 Nakit | KDV yok; `ARP_CODE`+`safe_code` dolu |
| P0-12 Çek | KDV yok; vade+çek no+banka; ciro alanları (eklenince) |
| Kalem KDV %1/%10/%20 | `vat_amount` 2 hane; toplam tutarlı (P0-03/06) |

---

## 7. Bilinçli dokunulmayanlar

- UI renk / gradient / kart redesign (`ui-no-touch`)  
- GİB canlı mükellef sorgu (P1+)  
- Firma özel Logo TRCODE tablosu (canlı dönem doğrulaması ayrı)  
- Commit / PR (bu oturum)

---

## 8. Referans dosya yolları

```
docs/plans/2026-07-26-accounting-stub-checklist.md   ← bu belge
docs/plans/2026-07-26-ops-mbt-missing-ops-board.md   ← Board P0-03…12
lib/core/services/logo_payload_mapper.dart
lib/core/services/logo_api_service.dart
lib/service/job_queue_service.dart
lib/modules/field_sales/orders/          ← P0-03…05
lib/modules/field_sales/invoices/        ← P0-06…07
lib/modules/field_sales/waybills/        ← P0-08…09
lib/modules/field_sales/collections/     ← P0-10…12
lib/modules/field_sales/sync/view/slip_defaults_screen.dart
lib/view/mobile_dashboard.dart
assets/translations/tr.json  (field_sales.wholesale_invoice_8 / sales_return_invoice_3)
```

---

## 9. Muhasebe #12 ajan çıktısı (bu oturum)

| Alan | Değer |
|------|--------|
| Durum | **Yarım** — Board P0-03…12 LOGO TYPE / KDV / cari notları belgede sabitlendi; kod implementasyonu yok |
| Risk | Alış (P0-04/07/09) ile iade TYPE 3 karışması; irsaliye→invoice flatten; finans virman→cash; KDV satır kaybı |
| TODO | (1) #3 order sales/purchase tip (2) #4 TYPE 8 + Satın Alma≠3 (3) #5 dispatch TYPE (4) #7 payment_type/safe_code/çek alan (5) #11 Board regresyon tablosu §6 |
| Dosyalar | Bu md · board md · `logo_payload_mapper.dart` · `orders/` · `invoices/` · `waybills/` · `collections/` |
| Commit | Yok |
