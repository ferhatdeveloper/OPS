# OPS ← MBT İçerik / Akış Gap Listesi (Saha Satış)

**Tarih:** 2026-07-26  
**Rol:** Saha satış uzmanı  
**Kaynak:** `docs/plans/2026-07-25-mbt-app-structure-schema.md`  
**Kapsam:** Dil, etiket, plasiyer akış sırası, boş/yardım metinleri, kuyruk sözlüğü.  
**Dışarıda:** UI layout / görsel redesign / renk-grid değişikliği.  
**Commit:** Yok (yalnızca bu belge).

> **Amaç:** Plasiyer MBT’deki gün dilini OPS’te tanısın. Menü kutusu yeniden çizilmez; metin, guard mesajı, kuyruk adı ve “önce ne yapılır” kopyası hizalanır.

---

## 1. Plasiyer gün sırası (MBT kanıt → OPS hedef)

MBT çıkarımı (`2026-07-25` §2 / §5):

| # | MBT adım | OPS bugün | Gap |
|---|----------|-----------|-----|
| 1 | **DİĞER → Güne Başlama** | `DayStatusScreen` var; yerel toggle, sync/kalıcılık yok | P0 dil + “mesai çerçevesi” kopyası |
| 2 | **ZİYARET** (mevcut/yeni cari) | Rut planı + check-in; MBT etiketleri farklı | P0 ziyaret sözlüğü |
| 3 | **SİPARİŞ → Satış → önce cari** | Kısmen: `OrderCustomerSelectionScreen` | P0 boş liste + l10n |
| 4 | **FATURA / İRSALİYE / TESLİMAT** | Fatura boş `customerId` ile açılıyor | P0 cari-önce kopya/guard |
| 5 | **FİNANS → Yeni Hareket** | Tahsilat boş cari; İngilizce tip kodları UI’da | P0 cari + ödeme dili |
| 6 | **GÜNCELLEME** gönder/al + transfer edilmeyen | “Bekleyen Aktarımlar / Logo senkron” karışık | P0 kuyruk sözlüğü |
| 7 | **DİĞER → Güne Bitirme** | Aynı ekranda birleşik; gün sonu araç EOD ayrı | P1 ayrık etiket / rehber metin |

**Plasiyer için tek cümle hedef kopya (OPS’e eklenecek yardım/onboarding metni):**  
*Güne başla → ziyarette cari bağlamı → sipariş/fatura/tahsilat (cari seçili) → transfer edilmeyenleri gönder → günü bitir.*

---

## 2. P0 — Dil / içerik TODO’ları (dosya yolları)

Öncelik: plasiyerin **bugün sahada takıldığı** noktalar. Layout yok; string, guard, menü başlığı, boş durum CTA.

### P0-1 Sipariş: cari önce — boş liste fix

| Durum | Detay |
|-------|--------|
| Hazır | Cari seçim ekranı + `OrderNotifier.isValidCustomerId` + aktif ziyarette doğrudan sipariş |
| Yarım | Boş liste metni hardcoded; sync CTA yok; çeviri anahtarı yok |
| Risk | DB’de cari varken mapping/filtre nedeniyle boş görünürse plasiyer “cari yok” sanır |

**TODO:**
1. `lib/modules/field_sales/orders/view/order_customer_selection_screen.dart` — `emptyMessage`, AppBar, hint, yardımcı cümleyi `assets/translations/tr.json` (`field_sales.*`) anahtarlarına taşı; EN/DE/AR/… ayna.
2. Aynı dosya — boş durumda (sorgu boş + liste boş): **“Sunucudan cari al / Güncelleme”** CTA metni + route ipucu (`/field-sales/data-transfer` veya mevcut Güncelleme menü başlığı). Layout kartı büyütme yok; TextButton/SnackBar yeterli.
3. `lib/modules/field_sales/customers/viewmodel/customer_provider.dart` — hata varken boş liste ile aynı “Henüz cari kart yok” mesajını **ayırma** (`error` → “Cari listesi yüklenemedi: … / Yenile”).
4. `lib/modules/field_sales/orders/view/order_entry_screen.dart` — SnackBar “Cari seçilmeden…” → l10n.
5. `test/modules/field_sales/orders/order_customer_guard_test.dart` + `test/modules/field_sales/customers/customer_model_from_map_test.dart` — boş mesaj / error ayrımı regression.

**MBT referans dili:** “Cari Kart Listesi”, `Kod / Ünvan` arama (§4.2 / §5).

---

### P0-2 Fatura: cari-önce kopya + tip dili

| Durum | Detay |
|-------|--------|
| Eksik | `InvoiceEntryScreen(customerId: '')` — siparişteki guard yok |
| Risk | Boş cari ile sıcak satış/VAN etiketi plasiyeri MBT “Toptan Satış” dilinden koparır |

**TODO:**
1. `lib/view/mobile_dashboard.dart` (`Satış Faturası` / `Toptan Satış` / `Toptan Satış İade` case’leri ~1608–1623) — siparişle aynı: aktif ziyaret cari → yoksa **cari seçim** (mevcut `OrderCustomerSelectionScreen` yeniden kullan veya paylaşılan seçim kopyası; layout yeniden yazma yok).
2. `lib/modules/field_sales/invoices/view/invoice_entry_screen.dart` — default `invoiceType: 'Sıcak Satış (Van Sales)'` plasiyer yüzünde MBT menü diliyle hizala: **Toptan Satış**; “Van Sales” yalnızca dahili/parametre notu.
3. `assets/translations/tr.json` — `field_sales` / `submodules`: fatura boş-cari uyarı, “önce cari seç” cümlesi (siparişle tutarlı).
4. `lib/modules/field_sales/invoices/view/invoice_list_screen.dart` — hardcoded “Faturalar” / “Yeni Fatura” → l10n (`submodules.fatura_listesi` vb.).

**MBT:** Fatura sheet: Toptan Satış, Satın Alma, Liste, Transfer Edilmeyen, Bekleyen, Fiş Ön Değerleri (§6.1).

---

### P0-3 Ziyaret sözlüğü (MBT menü ↔ OPS rut)

| Durum | Detay |
|-------|--------|
| Yarım | Check-in / form var; menü dili “Rut Planı”, MBT “Ziyaret → Mevcut/Yeni/Geçmiş/Transfer edilmeyen” |
| Risk | Plasiyer “ziyaret” arar, “rut” görür; transfer edilmeyen ziyaret kuyruğu adı belirsiz |

**TODO:**
1. `lib/service/database_service.dart` (ziyaret/rota seed menü title’ları) + `assets/translations/tr.json` `submodules` — plasiyer görünen başlıkları MBT’ye yaklaştır: **Mevcut Cari Hesap**, **Geçmiş Ziyaretler**, **Transfer Edilmeyenler** (fonksiyon aynı kalabilir: `RoutePlanScreen` / visit list).
2. `lib/modules/field_sales/routes/viewmodel/visit_provider.dart` — hardcoded “Hali hazırda bir ziyaretiniz açık.” / “Müşteriye çok uzaktasınız…” → l10n.
3. `lib/modules/field_sales/routes/view/visit_form_screen.dart` — “Dinleniyor... (Simülasyon)” üretim dilinden çıkar veya debug flag; plasiyer görmemeli.
4. Yardım satırı (AppBar altı Text veya boş durum): *“Önce ziyaret/check-in; sipariş ve tahsilat bu cari bağlamında açılır.”* — `route_plan_screen.dart` / `visit_form_screen.dart`.

**MBT:** Ziyaret sheet §6.3; rota ayrı kutu değil (§6.7).

---

### P0-4 Rota: giriş noktası dili (ayrı “ROTA ürünü” değil)

| Durum | Detay |
|-------|--------|
| Yarım | OPS’te Bugünkü Rotam / Harita / Optimizasyon ayrı alt menü |
| MBT | Ana grid’de ROTA yok; rota = yönetici gün/sıra/müşteri kısıtı |

**TODO:**
1. `assets/translations/tr.json` — `submodules.bugunku_rotam`, `rota_haritasi`, `rota_optimizasyonu` alt açıklama/yardım: *“Bugünkü ziyaret sırası (yönetici rotası)”* — plasiyerin “ayrı rota modülü” sanmaması.
2. `lib/modules/field_sales/routes/view/route_plan_screen.dart` — `no_route_today` metnini güçlendir: *Güne başlama yapıldı mı? / Güncelleme ile rota alındı mı?* CTA cümleleri.
3. `lib/view/mobile_dashboard.dart` — rota case’lerinde gösterilen başlıkların TR seed ile birebir kaldığını doğrula (çeviri anahtarı sapması yok).

**Not:** Rota UI kaldırma / birleştirme = redesign → bu belgede yok; yalnızca dil ve boş durum.

---

### P0-5 Tahsilat (Yeni Hareket) dili + cari

| Durum | Detay |
|-------|--------|
| Eksik | `CollectionEntryScreen(customerId: '')` |
| Bug | `submodules.transfer_edilmeyen_tahsilatlar` = **"Transfer Edilmeyen Faturalar"** (yanlış kopya) |
| Risk | Ödeme tipi değerleri `Cash`/`Check`/`CreditCard`; etiket “Kredi” (MBT: Kredi kartı) |

**TODO:**
1. `assets/translations/tr.json` L469 — `transfer_edilmeyen_tahsilatlar` → **"Transfer Edilmeyen Tahsilatlar"**; EN/AR/… aynı bug’ı düzelt (`en.json` L359 da “Non-Transferred Invoices”).
2. `lib/view/mobile_dashboard.dart` (`Tahsilat Girişi` / `Yeni Hareket`) — cari-önce (aktif ziyaret veya seçim ekranı); boş cari ile kayıt engeli mesajı.
3. `lib/modules/field_sales/collections/view/collection_entry_screen.dart` — tüm hardcoded TR + SnackBar → l10n; “Kredi” → **Kredi Kartı**; Senet seçeneği etiketi (MBT web §6.5) en azından UI label olarak.
4. `lib/modules/field_sales/collections/viewmodel/collection_provider.dart` — boş `customerId` guard + hata metni (sipariş guard kalıbı).

---

### P0-6 Offline kuyruk dili (Transfer edilmeyen / Bekleyen / Güncelleme)

MBT triad (§7): AppBar sync · **Güncelleme (gönder/al)** · **Transfer edilmeyen** listeleri.

| OPS bugün | MBT hedef dil |
|-----------|----------------|
| “Bekleyen Aktarımlar” | Transfer Edilmeyen {Sipariş/Fatura/…} veya Bekleyen |
| “Bekleyen Logo aktarımı yok” | Transfer edilecek belge yok / Bekleyen yok |
| “Veri Transferi (Logo)” / “Logo ile Senkronize Et” | **Güncelleme** · Cihazdakileri Gönder · Sunucudan Al |
| Tek `PendingTransfersScreen` çok menüye | Menü başlığı = entity adı (içerik aynı kalsa bile AppBar title parametresi) |

**TODO:**
1. `lib/modules/field_sales/sync/view/pending_transfers_screen.dart` — title parametresi (`Transfer Edilmeyen Faturalar` vb.); boş metin MBT diline.
2. `lib/view/mobile_dashboard.dart` (~1686–1692) — her case’te doğru başlıkla `PendingTransfersScreen` aç.
3. `lib/modules/field_sales/sync/view/data_transfer_screen.dart` — “Veri Transferi (Logo)” / “Bekleyen Belgeler (Logo)” / “Senkronize ediliyor…” → **Güncelleme / Cihazdakileri Gönder / Sunucudan Al / Aktarılıyor** (Logo kelimesi ayarlar ekranında kalsın).
4. `lib/service/database_service.dart` sipariş alt menü seed (~1133) — MBT eksikleri **en azından menü etiketi** olarak: Transfer Edilmeyen Siparişler, Bekleyen Siparişler (route mevcut pending ekrana bağlanabilir). Sipariş Onaylama / Takip / Liste = P1 içerik.
5. `assets/translations/tr.json` — `pending_sync` vs `transfer_edilmeyen*` tutarlılığı; plasiyer yüzünde “Senkronizasyon” yerine mümkün olduğunca **Transfer / Güncelleme**.

---

### P0-7 Güne başlama / bitirme — plasiyer çerçeve metni

| Durum | Detay |
|-------|--------|
| Yarım | Ekran var; kalıcı gün kaydı / zorunluluk yok |
| Bug | Saat satırlarında `\$\{_startTime...\}` literal kaçış — plasiyer yanlış metin görür |

**TODO:**
1. `lib/modules/field_sales/other/view/day_status_screen.dart` — string interpolation düzelt; metinleri l10n’a al (`gune_baslama_bitirme`, başarı SnackBar’ları).
2. Aynı dosya — kısa sıra rehberi (Text, redesign değil): *1 Başla → 2 Ziyaret → 3 Sipariş/Fatura/Tahsilat → 4 Güncelleme → 5 Bitir*.
3. `assets/translations/tr.json` — `submodules.gune_baslama_bitirme` MBT’ye: isteğe bağlı iki etiket **Güne Başlama** / **Güne Bitirme** (tek route kalsa bile butonlar zaten ayrık).
4. Menü seed `lib/service/database_service.dart` — “Güne Başlama Bitirme” → boşluklu **Güne Başlama / Bitirme**.

---

## 3. P1 — Sonraki (P0 sonrası; hâlâ içerik/akış)

| # | Konu | Dosyalar | Not |
|---|------|----------|-----|
| P1-1 | Sipariş alt menü: Onaylama, Liste, Takip | `database_service.dart`, dashboard case’leri | MBT §5; ekran yoksa “geliştirme” değil, liste/pending reuse + doğru title |
| P1-2 | İrsaliye / Teslimat kuyruk başlıkları | `tr.json`, `pending_transfers_screen.dart` | Fatura ile aynı triad dili |
| P1-3 | Fiş Ön Değerleri alan etiketleri | `slip_defaults_screen.dart` | MBT: AÇIKLAMA, PLAKA NO, ÖZELKOD 1 |
| P1-4 | Gün kaydı kalıcılığı / EOD bağlama | `day_status_screen.dart`, `vehicle_eod_screen.dart` | İçerik + iş kuralı; UI redesign değil |
| P1-5 | Tahsilat Senet formu alan etiketleri | `collection_entry_screen.dart` | MBT web §6.5 doğrulanacak |

---

## 4. Bilinçli dışı bırakılanlar

- Dashboard grid / AppBar rengi / kart layout (MBT koyu kırmızı vb.) → redesign.
- NFC, VAN menü kutusu (MBT’de yok / belirsiz).
- Logo Mobile Sales menü kopyası (farklı ürün).
- Kalem ekranı alan sırası (MBT cihazda taranmadı) — muhasebe/ürün ajanı ile sonra.

---

## 5. Doğrulama (saha / test ajanı)

1. Sipariş Girişi → cari listesi dolu/boş/hata mesajları ayrışık mı?  
2. Fatura / Yeni Hareket → boş cari ile ilerlenemiyor mu?  
3. Menü: Transfer Edilmeyen Tahsilatlar doğru TR mi?  
4. Pending ekran AppBar’ı menü başlığıyla aynı mı?  
5. Güne Başla rehber metni + saat gösterimi doğru mu?  
6. Unit: `order_customer_guard_test`, `customer_model_from_map_test` + yeni l10n/empty CTA testleri.

---

## 6. Özet skor (saha satış uzmanı)

| Alan | Skor | Tek cümle |
|------|------|-----------|
| Sipariş cari-önce | %70 | Ekran var; boş liste/l10n/CTA P0 |
| Fatura/tahsilat cari | %20 | Boş customerId — plasiyer kırılır |
| Kuyruk dili | %40 | Kelimeler karışık; tahsilat çeviri bug’ı P0 |
| Ziyaret/rota dili | %50 | Fonksiyon var; MBT sözlük hizasız |
| Gün sırası | %35 | Ekran var; çerçeve metni + bug + kalıcılık eksik |

**P0 tamam sayılır:** yukarıdaki P0-1…P0-7 metin/guard TODO’ları dosya yollarında uygulanmış; layout değişmemiş; test ajanı §5 checklist yeşil.
