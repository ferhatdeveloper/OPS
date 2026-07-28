# MBT RAPORLAR Kataloğu

**Tarih:** 2026-07-27  
**Cihaz:** A065 (`6544bc4b`) · paket `com.mimbt.LOGOPlus` · sürüm UI: `MBT Mobil (Logo) (Vers.2.1.14.0)`  
**Toplam:** **40 rapor** · 6 kategori · hub + Rapor Yedekle/İndir  

**Deliverable:**
- Markdown: bu dosya
- Canvas (filtreli katalog): [MBT-raporlar-katalog.canvas.tsx](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/MBT-raporlar-katalog.canvas.tsx)
- Canvas (envanter): [MBT-raporlar-inventory.canvas.tsx](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/MBT-raporlar-inventory.canvas.tsx)

**Kaynaklar:**
- Screenshot (referans): `~/.cursor/projects/Users-ferhatnas-App-EXFINOPS/assets/image-*`
- Liste dump: `tmp_mbt_analysis/rapor_*_list*.png` / `*_texts.txt`
- Cihaz oturumu: `tmp_mbt_analysis/raporlar_20260727/`
- OPS katalog kodu: `lib/modules/field_sales/reports/model/mbt_report_catalog.dart`

| Kategori | Adet | Liste kanıtı |
|----------|-----:|--------------|
| CARİ | 14 | `image-4a736863-…` |
| STOK | 9 | `image-0049cbd2-…` |
| SİPARİŞ | 4 | `rapor_si̇pari̇ş_list.png` |
| FATURA | 3 | `rapor_fatura_list.png` |
| İRSALİYE | 4 | `rapor_i̇rsali̇ye_list.png` |
| DİĞER | 6 | `rapor_di̇ğer_list.png` |
| **Toplam** | **40** | |

---

## Hub (RAPORLAR sheet)

Screenshot: `image-b530df83-…png` · dump: `13_raporlar` / `51_raporlar`

1. CARİ  
2. STOK  
3. SİPARİŞ  
4. FATURA  
5. İRSALİYE  
6. DİĞER  
7. Rapor Yedekle/İndir  

**Akış:** Hub → kategori grid (2 sütun kart) → rapor kartı → **Parametreler** → alt aksiyonlar:

| Aksiyon | MBT |
|---------|-----|
| Görüntüle (kırmızı PDF) | `.repx` ile PDF → **Görüntüle (PDF)** |
| Paylaş | PDF paylaş |
| E-MAIL | E-posta |
| Görüntüle (sarı) | Alternatif görüntü (grid/grafik benzeri) |

Preset şerit (tarihli raporlarda): **Bugün / Bu Hafta / Bu Ay / Bu Yıl**.

---

## Parametre profilleri

| Profil | Alanlar (MBT Parametreler) | Doğrulama |
|--------|----------------------------|-----------|
| `cariExtre` | BAŞLANGIÇ/BİTİŞ (+ preset) · KOD/AD · DÖVİZ DEĞERLEME · DÖVİZ KODU · RAPORLAMA DÖVİZİ · DİZAYN | Screenshot `image-090d674a` |
| `tahsilat` | BİTİŞ · KOD/AD · KOD 2/AD 2 · ÖZELKOD 1–5 · DİZAYN | `image-bd363e1d` |
| `stokBakiye` | KOD/AD · KOD 2/AD 2 · CARİKODU/AD · '0'DAN BÜYÜK/KÜÇÜK · BAKİYESİ 0 · ÖZELKOD 1–5 · DİZAYN | `image-e3046298` |
| `belgeListesi` | BAŞLANGIÇ/BİTİŞ (+ preset) · SEÇİM (Satış/Alış) · İŞYERİ/FABRİKA/AMBAR · KOD/AD · KOD 2/AD 2 · CARİKODU/AD · ÖZELKOD · DİZAYN | `image-11a257dc` |
| `belgeStokKod` *(varyant)* | BAŞLANGIÇ/BİTİŞ · **STK.KOD / STK.AD** (×2) · KOD/AD · KOD 2/AD 2 · İŞYERİ/FABRİKA/AMBAR · DİZAYN | Cihaz uiautomator: BEKLEYEN ALIŞ SİPARİŞLERİ |
| `simpleDate` | BAŞLANGIÇ/BİTİŞ · KOD/AD · DİZAYN | Profil tahmini (liste + benzer ekran) |
| `gps` | KOD/AD · DİZAYN | Profil tahmini |

---

## Bilinen PDF çıktıları (Görüntüle)

### 1) Cari Hesap Extresi — `CariExtre.repx` ✅

- **Parametreler:** Bugün…Bu Yıl · BAŞLANGIÇ/BİTİŞ · KOD/AD · DÖVİZ DEĞERLEME · DÖVİZ KODU=`Tüm` · RAPORLAMA DÖVİZİ · DIZAYN=`CariExtre.repx`
- **PDF başlık:** “Cari Hesap Extresi” · dönem · cari kod/ünvan (ör. `MBT-00000000051` / ALMİLA…)
- **Sütunlar:** Ref No Tarih · Açıklama · Borç · Alacak · Bakiye
- **Gözlem:** Örnek dönemde gövde satırları boş görünebilir (Sayfa 1/1)
- **Kanıt:** `image-090d674a` (params) · `image-dbc48a0a` (PDF)

### 2) Tahsilat Listesi — `TahsilatListesi.repx` ✅

- **Parametreler:** BİTİŞ · KOD/AD (ör. `MBT-000000000006` / ABC FİRMASI) · KOD 2/AD 2 · ÖZELKOD 1–5 · DIZAYN=`TahsilatListesi.repx`
- **Sütunlar:** Kod · Unvan · İşlem Tarihi · Vade Tarihi · İşlem · Tutar · Kalan · FarkGün
- **Gözlem:** Çoklu döviz (TL/USD/IQD); işlem tipleri: Toptan Satış Faturası, Kredi Kartı Fişi, Nakit Tahsilat; Sayfa 1/2+
- **Kanıt:** `image-bd363e1d` · `image-70f0df65`

### 3) Stok Bakiye Listesi — `StokBakiye.repx` ✅

- **Parametreler:** KOD/AD · KOD 2/AD 2 · CARİKODU/AD · bakiye filtreleri (>0/<0/=0) · ÖZELKOD · DIZAYN=`StokBakiye.repx`
- **Sütunlar:** Stok Kodu · Stok Cinsi · Bakiye
- **Gözlem:** Negatif bakiyeler ve büyük mutlak değerler mümkün; altta toplam bakiye
- **Kanıt:** `image-e3046298` · `image-98fb7b7d`

### 4) Bekleyen Alış Siparişleri — `BekleyenAlisSiparisler.repx` ✅ (cihaz)

- **Parametreler (cihaz dump):** BAŞLANGIÇ/BİTİŞ · STK.KOD/STK.AD (çift) · KOD/AD · KOD 2/AD 2 · İŞYERİ/FABRİKA/AMBAR=`Merkez` · DIZAYN=`BekleyenAlisSiparisler.repx`
- **Not:** OPS katalog adı `BekleyenAlisSiparis.repx` (tekil) — **MBT gerçek adı çoğul `…Siparisler.repx`**
- **PDF sütunları:** Bu turda Görüntüle PDF yakalanamadı (sonraki oturumda app foreground kaybı)
- **Kanıt:** `tmp_mbt_analysis/raporlar_20260727/23_params_scrolled.*`

---

## CARİ (14)

| # | Ad | id | Profil | .repx | Amaç | PDF |
|---|----|----|--------|-------|------|-----|
| 1 | CARİ HESAP EKSTRESİ | `cari_extre` | cariExtre | `CariExtre.repx` ✅ | Cari hareket ekstresi | ✅ sütunlar yukarıda |
| 2 | TAHSİLAT LİSTESİ | `tahsilat_listesi` | tahsilat | `TahsilatListesi.repx` ✅ | Tahsilat / işlem bakiyeleri | ✅ |
| 3 | DETAYLI CARİ HESAP EKSTRESİ | `detayli_cari_extre` | cariExtre | `DetayliCariExtre.repx` * | Genişletilmiş ekstresi | — |
| 4 | YAKINIMDAKİ CARİ HESAPLAR (GPS) | `yakinimdaki_cari_gps` | gps | `YakinimdakiCari.repx` * | Konuma yakın cariler | — |
| 5 | BORÇ / ALACAK DURUM RAPORU | `borc_alacak` | simpleDate | `BorcAlacakDurum.repx` * | Borç/alacak özet | — |
| 6 | CARİ HAREKET LİSTESİ | `cari_hareket` | cariExtre | `CariHareket.repx` * | Cari hareket satırları | — |
| 7 | SATIŞ YAPILMAYAN CARİ HESAPLAR | `satis_yapilmayan_cari` | simpleDate | `SatisYapilmayanCari.repx` * | Dönemde satış yok | — |
| 8 | EN ÇOK SATIŞ YAPILAN CARİLER | `en_cok_satis_cari` | simpleDate | `EnCokSatisCari.repx` * | Satış hacmi sıralama | — |
| 9 | EN ÇOK ALIM YAPILAN CARİLER | `en_cok_alim_cari` | simpleDate | `EnCokAlimCari.repx` * | Alış hacmi sıralama | — |
| 10 | EN ÇOK TERCİH EDİLEN ÜRÜNLER ( SATIŞLAR ) | `en_cok_urun_satis` | simpleDate | `EnCokUrunSatis.repx` * | Satışta tercih ürünler | — |
| 11 | EN ÇOK TERCİH EDİLEN ÜRÜNLER ( ALIŞLAR ) | `en_cok_urun_alis` | simpleDate | `EnCokUrunAlis.repx` * | Alışta tercih ürünler | — |
| 12 | GPS (KONUM) RAPORU | `gps_konum` | gps | `GpsKonum.repx` * | Cari GPS konum | — |
| 13 | MÜŞTERİ ÇEK LİSTESİ | `musteri_cek` | simpleDate | `MusteriCek.repx` * | Müşteri çek portföyü | — |
| 14 | MÜŞTERİ SENET LİSTESİ | `musteri_senet` | simpleDate | `MusteriSenet.repx` * | Müşteri senet portföyü | — |

\* `.repx` adı: OPS katalog / isim türetme; MBT Parametreler ekranında satır satır doğrulanmadı.

---

## STOK (9)

| # | Ad | id | Profil | .repx | Amaç | PDF |
|---|----|----|--------|-------|------|-----|
| 1 | STOK BAKİYE LİSTESİ | `stok_bakiye` | stokBakiye | `StokBakiye.repx` ✅ | Stok kartı bakiyesi | ✅ |
| 2 | STOK ENVANTER RAPORU | `stok_envanter` | belgeListesi | `StokEnvanter.repx` * | Envanter / sayım | — |
| 3 | STOK HAREKET LİSTESİ | `stok_hareket` | belgeListesi | `StokHareket.repx` * | Stok giriş-çıkış | — |
| 4 | SERİ / LOT | `seri_lot` | stokBakiye | `SeriLot.repx` * | Seri/lot takip | — |
| 5 | ÜRÜN HANGİ DEPODA | `urun_hangi_depo` | stokBakiye | `UrunHangiDepo.repx` * | Ürün→depo | — |
| 6 | DEPODA HANGİ ÜRÜNLER MEVCUT | `depoda_hangi_urun` | stokBakiye | `DepodaHangiUrun.repx` * | Depo→ürün | — |
| 7 | SATIŞI YAPILMAYAN ÜRÜNLER | `satisi_yapilmayan_urun` | simpleDate | `SatisiYapilmayanUrun.repx` * | Satılmayan ürünler | — |
| 8 | EN ÇOK SATILAN ÜRÜNLER | `en_cok_satilan_urun` | simpleDate | `EnCokSatilanUrun.repx` * | En çok satılan | — |
| 9 | EN ÇOK ALINAN ÜRÜNLER | `en_cok_alinan_urun` | simpleDate | `EnCokAlinanUrun.repx` * | En çok alınan | — |

---

## SİPARİŞ (4)

| # | Ad | id | Profil | .repx | Amaç | PDF |
|---|----|----|--------|-------|------|-----|
| 1 | SATIŞ SİPARİŞLERİ | `satis_siparisleri` | belgeListesi | `SatisSiparisleri.repx` * | Satış sipariş listesi | — |
| 2 | ALIŞ SİPARİŞLERİ | `alis_siparisleri` | belgeListesi | `AlisSiparisleri.repx` * | Alış sipariş listesi | — |
| 3 | BEKLEYEN SATIŞ SİPARİŞLERİ | `bekleyen_satis_siparis` | belgeStokKod? | `BekleyenSatisSiparis(ler?).repx` * | Açık satış siparişleri | — |
| 4 | BEKLEYEN ALIŞ SİPARİŞLERİ | `bekleyen_alis_siparis` | belgeStokKod | `BekleyenAlisSiparisler.repx` ✅ | Açık alış siparişleri | — |

---

## FATURA (3)

| # | Ad | id | Profil | .repx | Amaç | PDF |
|---|----|----|--------|-------|------|-----|
| 1 | SATIŞ FATURALARI | `satis_faturalari` | belgeListesi | `SatisFaturalari.repx` * | Satış fatura listesi | — |
| 2 | ALIŞ FATURALARI | `alis_faturalari` | belgeListesi | `AlisFaturalari.repx` * | Alış fatura listesi | — |
| 3 | FATURA KARLILIK DURUMU | `fatura_karlilik` | belgeListesi | `FaturaKarlilik.repx` * | Fatura karlılığı | — |

---

## İRSALİYE (4)

| # | Ad | id | Profil | .repx | Amaç | PDF |
|---|----|----|--------|-------|------|-----|
| 1 | SATIŞ İRSALİYELERİ | `satis_irsaliyeleri` | belgeListesi | `SatisIrsaliyeleri.repx` * | Satış irsaliye listesi | — |
| 2 | ALIŞ İRSALİYELERİ | `alis_irsaliyeleri` | belgeListesi | `AlisIrsaliyeleri.repx` * | Alış irsaliye listesi | — |
| 3 | FATURA KESİLMEYEN İRSALİYELER (SATIŞLAR) | `faturasiz_irsaliye_satis` | belgeListesi | `FaturasizIrsaliyeSatis.repx` * | Faturasız satış irsaliye | — |
| 4 | FATURA KESİLMEYEN İRSALİYELER (ALIŞLAR) | `faturasiz_irsaliye_alis` | belgeListesi | `FaturasizIrsaliyeAlis.repx` * | Faturasız alış irsaliye | — |

---

## DİĞER (6)

| # | Ad | id | Profil | .repx | Amaç | PDF |
|---|----|----|--------|-------|------|-----|
| 1 | PLASİYER GPS RAPOR | `plasiyer_gps` | gps | `PlasiyerGps.repx` * | Plasiyer GPS izi | — |
| 2 | PLASİYER ROTA RAPORU | `plasiyer_rota` | simpleDate | `PlasiyerRota.repx` * | Plasiyer rota özeti | — |
| 3 | PLASİYER GÜNLÜK İŞLEMLER | `plasiyer_gunluk` | simpleDate | `PlasiyerGunluk.repx` * | Günlük işlem özeti | — |
| 4 | ZİYARET LİSTESİ | `ziyaret_listesi` | simpleDate | `ZiyaretListesi.repx` * | Ziyaret listesi | — |
| 5 | ZİYARET LİSTESİ (ÖZEL) | `ziyaret_listesi_ozel` | simpleDate | `ZiyaretListesiOzel.repx` * | Özel ziyaret listesi | — |
| 6 | KASA HAREKET RAPORU | `kasa_hareket` | simpleDate | `KasaHareket.repx` * | Kasa hareketleri | — |

---

## OPS parity notları (uygulama bu turda yok)

| | MBT | OPS (2026-07-27) |
|--|-----|------------------|
| Hub + kategori grid | Var | Var (dens) |
| Parametreler UI | Var | Dens; chrome birebir değil |
| Dizayn dosya | Gerçek `.repx` adı | Katalogda salt okunur |
| PDF gövde | DevExpress `.repx` + veri | `MbtReportActionService.buildPdfBytes` iskelet |
| `.repx` ad doğruluğu | Cihazda okunan | Bir kısmı tahmin / tekil-çoğul farkı |

**OPS dosya haritası:**
- Katalog: `lib/modules/field_sales/reports/model/mbt_report_catalog.dart`
- Parametreler: `…/view/report_parameters_screen.dart`
- Kategori listesi: `…/view/report_category_list_screen.dart`
- PDF/Paylaş: `…/engine/mbt_report_action_service.dart`

---

## Boşluklar (gaps)

1. **37 rapor** için PDF sütun başlıkları henüz Görüntüle ile yakalanmadı (yalnızca 3 tam + 1 params doğrulandı).
2. **36 `.repx` adı** hâlâ OPS katalog / isim türetme; MBT Parametreler’de satır satır okunmadı.
3. **`BekleyenAlisSiparis` vs `BekleyenAlisSiparisler`** — OPS düzeltmesi gerekir.
4. **`belgeStokKod` profili** (STK.KOD/STK.AD) OPS `belgeListesi` modelinde yok.
5. **`simpleDate` / `gps`** alan setleri screenshot ile sınırlı doğrulandı.
6. **Rapor Yedekle/İndir** hub öğesi: bu turda detay ekranı açılmadı.
7. **Cihaz oturumu sonu:** `am force-stop` sonrası MBT MainActivity cold start focus tutmuyor (Nothing launcher’a düşüyor); kalan Görüntüle turu için app’i elle açmak gerekir.
8. Yanlış navigasyonda FİNANS/çek listeleri görüldü (PORTFÖYDEKİ ÇEKLER…) — RAPORLAR dışı; karıştırılmamalı.

---

## Doğrulama checklist

- [x] 40 rapor adı + 6 kategori + hub listelendi
- [x] Extre / Tahsilat / StokBakiye: parametre + PDF sütun (screenshot)
- [x] Bekleyen Alış Siparişleri: gerçek `.repx` + STK.KOD alanları (adb dump)
- [x] Canvas kategori filtresi
- [ ] Kalan raporlar: Parametreler → Görüntüle PDF sütunları
- [ ] Tüm `.repx` adlarını cihazdan okuma
- [ ] Gerçek `.repx` motoru OPS entegrasyonu

**Commit:** yok.
