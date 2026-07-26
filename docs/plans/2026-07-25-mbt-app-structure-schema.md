# MBT (LOGOPlus) Uygulama Yapı Şeması

**Tarih:** 2026-07-25  
**Kapsam:** Yalnızca MBT mobil uygulama keşfi (`com.mimbt.LOGOPlus`)  
**Yöntem:** (1) adb screencap + uiautomator dump (+ scrcpy); (2) MimBT / Play Store / bayi ürün sayfaları web araştırması. OPS koduna bakılmadı / değiştirilmedi.  
**Kanıt klasörü:** `tmp_mbt_analysis/`  
**Checklist:** `tmp_mbt_analysis/MENU_TODO.md`  
**Canvas:** [MBT-app-structure-schema.canvas.tsx](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/MBT-app-structure-schema.canvas.tsx)

> **Kaynak önceliği:** Çelişkide **cihazda görülen** kazanır. Web bulguları “doğrulanacak” diye ayrı tutulur; uydurma yoktur.  
> **Ürün ayrımı:** Bu belge `com.mimbt.LOGOPlus` (MBT Logo Mobil Satış / MimBT). Logo’nun ayrı ürünü **Logo Mobile Sales** menü/alan adları buraya karıştırılmaz (yalnızca “benzer ürün — karıştırılmamalı” notu).

---

## 1. Uygulama kimliği

| Alan | Değer (kanıt) |
|------|----------------|
| Paket | `com.mimbt.LOGOPlus` |
| versionName | `2.1.14.0` |
| versionCode | `21140` |
| minSdk / targetSdk | 22 / 35 |
| Ana Activity | `crc64eafd518d3695375c.MainActivity` |
| AppBar başlık | `MBT ( 001_01 )` → firma 001, dönem 01 |
| Firma | Mim Bilgi Teknolojileri Sanayi ve Ticaret Ltd. Şti. |
| Oturum | Demo Kullanıcısı |
| Footer | MBT Mobil (Logo) (Vers.2.1.14.0) |

Login: Demo oturumu açıktı. Ayrı login ekranı bu oturumda MBT içinde zorunlu görülmedi (yanlışlıkla OPS/launcher login dump’ları klasöre karışmış olabilir; MBT paketinden değil).

---

## 2. Navigasyon / bilgi mimarisi

```
MBT Dashboard (3 kolonlu kart grid)
├── AppBar: başlık · palet · senkron · hesap makinesi
├── Favori kalbi (kart köşesi)
├── Bottom sheet alt menü (çoğu modül)
│   └── 2 kolon işlem kartları
└── Doğrudan tam ekran (CARİ, YÖNETİCİ, DÖVİZ, ŞİRKETLER, GÜNCELLEME, DUYURULAR…)

Liste ekranı kalıbı (Cari Kart Listesi vb.)
├── Geri · Başlık · Hesap makinesi · Hamburger · Ana Sayfa
├── Arama alanı + yardımcı ikonlar + Ara butonu
├── Kaydırılabilir kart listesi
└── FAB (+) / alt bilgi (toplam kayıt)
```

**Plasiyer gün akışı (görülen menülerden çıkarım):**

1. **DİĞER → GÜNE BAŞLAMA** (form henüz taranmadı)  
2. **ZİYARET** (mevcut/yeni cari) → müşteri bağlamı  
3. **SİPARİŞ → SATIŞ** → önce **Cari Kart Listesi** → (kalem ekranı henüz taranmadı)  
4. **FATURA / İRSALİYE** (toptan satış vb.) veya **TESLİMAT**  
5. **FİNANS → YENİ HAREKET** (tahsilat)  
6. **GÜNCELLEME** ile gönder/al; bekleyen/transfer edilmeyen kuyruklar  
7. **DİĞER → GÜNE BİTİRME**

**Rota:** Ana grid’de ayrı “ROTA” kutusu **görülmedi**. Web: tanım yönetici panelinde (gün/sıra/müşteri); mobil giriş noktası **doğrulanacak** (§6.7 / §10).

---

## 3. Dashboard & modül haritası

Ana grid (üstten alta, soldan sağa):

| # | Modül | Açılış tipi | Alt işlemler (görülen) |
|---|--------|-------------|-------------------------|
| 1 | FAVORİLER | Sheet / kısayol | CARİ, STOK, SİPARİŞ, FATURA, İRSALİYE, DİĞER, Rapor Yedekle/İndir |
| 2 | YÖNETİCİ | Doğrudan | Yönetici Raporları |
| 3 | CARİ | Doğrudan | Cari Kart Listesi |
| 4 | FATURA | Bottom sheet | Toptan Satış, Satın Alma, Fatura Listesi, Transfer Edilmeyen, Bekleyen, Fiş Ön Değerleri |
| 5 | İRSALİYE | Bottom sheet | Toptan Satış, Satın Alma, İrsaliye Listesi, Transfer Edilmeyen, Bekleyen, Fiş Ön Değerleri |
| 6 | SİPARİŞ | Bottom sheet | Satış, Alış, Sipariş Onaylama, Sipariş Listesi, Transfer Edilmeyen, Sipariş Takibi, Bekleyen Siparişler |
| 7 | TESLİMAT | Bottom sheet | Teslimat, Beklemeye Alınanlar, Aktarılamayan Teslimatlar |
| 8 | ZİYARET | Bottom sheet | Mevcut Cari Hesap, Yeni Cari Hesap, Geçmiş Ziyaretler, Geçmiş Ziyaretler (2), Transfer Edilmeyenler |
| 9 | FİNANS | Bottom sheet | Yeni Hareket, Transfer Edilen Tahsilatlar, Transfer Edilmeyen Tahsilatlar |
|10 | STOK | Bottom sheet | Detay, Fiyat Gör, Barkod Ekle, Sayım Fişi, Ambar Fişi, Üretimden Giriş Fişi |
|11 | RAPORLAR | Sheet/kısayol | CARİ, STOK, SİPARİŞ, FATURA, İRSALİYE, DİĞER, Rapor Yedekle/İndir |
|12 | DÖVİZ | Doğrudan | Döviz Kuru (+ Kaydet); favori işaretli |
|13 | ŞİRKETLER | Doğrudan | Mobil Şirket Listesi |
|14 | GÜNCELLEME | Doğrudan | Veri Transferi |
|15 | DUYURULAR | Doğrudan | Kampanya duyurusu (badge “1”) |
|16 | DİĞER | Bottom sheet | Bilgi Gönderme, Güne Başlama / Bitirme |
|17 | ÇIKIŞ | — | Görüldü; tıklanmadı |

---

## 4. Ekran envanteri (alanlar & UI yapıları)

### 4.1 Dashboard
- **AppBar:** koyu kırmızı; başlık; palet / sync / calculator  
- **Üst metin:** firma ünvanı (kırmızı)  
- **Grid:** 3 kolon yuvarlatılmış kart; ikon + etiket; kalp (favori)  
- **Footer:** logo, kullanıcı, sürüm  
- **Overlay:** yeşil yuvarlak “S” FAB (cihaz overlay / destek; uygulama menüsü değil gibi)

### 4.2 Cari Kart Listesi
**Kanıt:** `33_cari.png`, `70_CARİ.png`, `70_siparis_submenu.png`

| UI | Detay |
|----|--------|
| AppBar | Geri, başlık, calculator, hamburger, ana sayfa |
| Arama | `Kod / Ünvan` · barkod · konum pin · **Ara** |
| Liste kartı | Avatar · Ünvan · Kod · Bakiye (Borç yeşil / Alacak pembe) · Detay (TL/USD/IQD…) |
| Alt | Toplam N kayıt · FAB (+) yeni cari |

Demo’da ~63 kayıt görüldü.

### 4.3 Yönetici Raporları
**Kanıt:** `32_yonetici.png`

- Filtre: Bugün / Bu Hafta / Bu Ay / Bu Yıl / Başlangıç–Bitiş  
- Bloklar: KASA (giriş/çıkış/fark), BANKA, ÇEK, SENET, FİRMA GENEL ANALİZ, FATURA (satış/alış), SİPARİŞ (satış/alış)

### 4.4 Fiş Ön Değerleri (Fatura altından açıldı)
**Kanıt:** `34_fatura_d1_0.png`

| Alan | Not |
|------|-----|
| AÇIKLAMA | (en az bir; ekranda iki açıklama satırı görüldü) |
| PLAKA NO | Araç/sevkiyat bağlantısı |
| ÖZELKOD 1 | Özel kod |
| Kaydet / Kapat | Ana aksiyonlar |
| Sol dikey sekmeler | İkonlu; metin okunamadı — çok sayfalı form ipucu |

### 4.5 Döviz Kuru
Tarih + para birimleri (USD, EUR, GBP, JPY, SAR, CNY, IQD, IRR, TRY, SYP, TL) + **Kaydet**.

### 4.6 Şirket / Güncelleme / Duyuru / Diğer
- **Şirketler:** MBT · Firma 001 · Dönem 01 · 01-01-2024…31-12-2024 · Seç  
- **Güncelleme:** Cihazdakileri Gönder · Sunucudan Al · Ürün Resimleri  
- **Duyurular:** Kampanya · 27-01-2026 → 27-04-2027  
- **Diğer:** Bilgi Gönderme · Güne Başlama/Bitirme (form **henüz taranmadı**)

### 4.7 Finans derin ekranlar (kısmi)
- **Kasa Kart Listesi:** kod, bakiye, MERKEZ TL/USD/EURO, ŞUBE TL (çoklu döviz + RD)  
- **Çek Listesi:** Ara, toplam/adet; durumlar: Teminata verilen, Tahsile verilen, İade, Tahsil edilen, Karşılıksız, Tahsil edilemeyen, Ödenen/Verilen firma çekleri  

### 4.8 Henüz taranmayan formlar (cihaz)
Sipariş kalem ekranı, fatura kalem/toptan fiş, ziyaret check-in, tahsilat “Yeni Hareket” formu, irsaliye fiş, stok fiş detayları, rota planı (mobil UI).  
Web’den beklenen alanlar → **§10** (doğrulanacak).

---

## 5. Sipariş süreci

### 5.A Cihazda görüldü

```
SİPARİŞ (dashboard)
  └─ bottom sheet
       ├─ SATIŞ ──► Cari Kart Listesi ──► [cari seç] ──► ??? (henüz taranmadı)
       ├─ ALIŞ
       ├─ SİPARİŞ ONAYLAMA
       ├─ SİPARİŞ LİSTESİ
       ├─ TRANSFER EDİLMEYEN SİPARİŞLER   ← offline/kuyruk
       ├─ SİPARİŞ TAKİBİ
       └─ BEKLEYEN SİPARİŞLER
```

**Plasiyer sırası (cihaz):**  
Müşteriye gel → (isteğe bağlı ziyaret) → **Sipariş → Satış** → **önce cari seç** → [kalem ekranı yok] → **Bekleyen / Transfer edilmeyen** → **Güncelleme → Gönder**.  
Cari seçim UI’si ana CARİ modülüyle aynı liste kalıbı.

### 5.B Web / dokümantasyon (doğrulanacak)

Cari seçiminden sonra beklenen fiş/kalem akışı (ürün sayfaları; ekran görüntüsü yok):

1. Ürün seç: kod/isim arama · kamera/BT barkod · stok grubu · ürün resmi  
2. Ekleme modu: **hızlı ekleme** (fiyat + miktar + indirim → listeye; detay ekranı gerekmez) veya **detaylı ekleme**  
3. Bilgi: önceki satış varsa **son satış** (miktar, tarih, iskonto oranları)  
4. Kontrol: **müşteri risk takibi** — kalem eklenirken risk aşımı anlık (v2.1.14 changelog)  
5. Fiş aksiyon: **beklemeye al** / sonra devam; parametreyle eksi stok; yetkiyle farklı depo  
6. Opsiyonel: kayıt anında GPS; dövizli işlem; karma koli; Bluetooth/WhatsApp/mail döküm  

Kaynak: Play Store, App Store, akillikobi, bimanet (§10.1).

---

## 6. Diğer süreçler

### 6.1 Fatura

**Cihazda görüldü:** tip (Toptan Satış / Satın Alma) → Liste / Bekleyen / Transfer edilmeyen → Fiş Ön Değerleri (AÇIKLAMA, PLAKA NO, ÖZELKOD 1).  
**VAN / iade** ayrı etiket **görülmedi**. Toptan satış fiş formu **henüz taranmadı**.

**Web (doğrulanacak):** Sıcak satış = sahada fatura; soğuk = sipariş (pazarlama dili). Kalem akışı siparişle aynı iskelet (hızlı/detaylı ekleme, beklemeye al, risk, barkod). e-Fatura/e-Arşiv/e-İrsaliye: fiş no + ETTN hazır XML. “VAN” kelimesi MimBT sayfalarında geçmiyor; plaka alanı araç/van senaryosuna ipucu (cihaz).

### 6.2 İrsaliye
**Cihaz:** Fatura ile aynı sheet iskeleti.  
**Web:** Aynı kalem/GPS/e-belge anlatımı; form **doğrulanacak**.

### 6.3 Ziyaret / GPS / NFC

**Cihazda görüldü:** Mevcut cari · Yeni cari · Geçmiş (2) · Transfer edilmeyenler. Alt forma girilmedi. Cari listede konum pin.

**Web (doğrulanacak):**  
- Fatura / İrsaliye / Sipariş / **Ziyaret** kaydında parametreye bağlı GPS  
- Opsiyon: **sadece müşteri konumunda işlem**  
- Yeni cari: GPS ile adres; VKN ile e-belge mükellef sorgusu  
- Rota + ziyaret: yönetici panelinden gün/sıra/müşteri; sıralı/sırasız; sadece rota carilerine işlem  

**NFC:** MimBT Play Store / App Store / mbtmobil / bayi sayfalarında **geçmiyor**. Cihazda da taranmadı → **yok** (negatif bulgu).  
**OPS K19:** Bilinçli sapma — NFC özelliği **uydurulmaz**; yeni ekran/menü/check-in bağı yazılmaz.

### 6.4 Teslimat
**Cihaz:** Teslimat · Beklemeye alınanlar · Aktarılamayanlar.  
**Web:** “Beklemeye al” fiş özelliğiyle uyumlu; detay formu yok.

### 6.5 Tahsilat / Finans

**Cihazda görüldü:** Yeni Hareket · Transfer edilen/edilmeyen; Kasa listesi; Çek listesi (durum sekmeleri). Form alanları **taranmadı**.

**Web (doğrulanacak) — “Yeni Hareket” beklenen alanlar:**  
| Ödeme tipi | Alanlar (ürün metni) |
|------------|----------------------|
| Nakit | (tutar vb. — detay yazılmamış) |
| Çek | çek numarası, borçlu bilgileri, banka bilgileri |
| Senet | senet tahsilatı (alan listesi yok) |
| Kredi kartı | kredi kartı tahsilatı (alan listesi yok) |

Çıktı: mail · yazıcı · WhatsApp. Exact label sırası **cihazda doğrulanacak**.

### 6.6 Stok / araç
**Cihaz:** Detay, Fiyat gör, Barkod ekle, Sayım, Ambar, Üretimden giriş; Fiş Ön Değerleri → PLAKA NO.  
**Web:** Sayım + depo transfer; stok/satışta kamera+BT barkod; karma koli.

### 6.7 Rotalar

**Cihazda görüldü:** Ana grid’de **ROTA kutusu yok**. TESLİMAT/ZİYARET içinde rota listesi **açılmadı**.

**Web (doğrulanacak):** Rota tanımı **yönetici panelinde** (gün + sıra + müşteri); ayrı DB; mobil tarafta filtreli cari / ziyaret kısıtı olarak gelir — ayrı dashboard kutusu beklenmez. Bu, cihazda ROTA olmamasıyla **çelişmiyor**.

---

## 7. Tasarım kalıpları

1. **Dashboard grid + bottom sheet** — ana navigasyon  
2. **Favori kalbi** — modül/alt işlem kısayolu  
3. **Koyu kırmızı AppBar** — tutarlı marka rengi  
4. **Liste + Ara + FAB** — cari/kasa tipi master data  
5. **Transfer edilmeyen / Bekleyen** — offline-first kuyruk dili (sipariş, fatura, irsaliye, ziyaret, tahsilat, teslimat)  
6. **Çoklu döviz bakiye** — cari ve kasa  
7. **Senkron triad:** AppBar sync · Güncelleme (gönder/al) · transfer edilmeyen listeleri  
8. **Güne başlama/bitirme** — saha mesai çerçeve (Diğer)  
9. **(Web)** Hızlı vs detaylı kalem ekleme; fiş beklemeye alma — cihazda doğrulanacak

---

## 8. Screenshot indeksi

Özet anahtar kanıtlar (106 PNG toplam; tekrarlar var):

| Dosya | Ekran |
|-------|--------|
| `02_dashboard.png` / `30_dashboard.png` / `21_mbt_start.png` | Ana dashboard |
| `33_cari.png` / `70_CARİ.png` | Cari Kart Listesi |
| `32_yonetici.png` | Yönetici Raporları |
| `34_fatura.png` / `44_fatura.png` / `70_FATURA.png` | Fatura alt menü |
| `34_fatura_d1_0.png` | Fiş Ön Değerleri |
| `45_irsaliye.png` | İrsaliye alt menü |
| `46_siparis.png` / `70_SİPARİŞ.png` | Sipariş alt menü |
| `70_siparis_submenu.png` | Sipariş→Satış→Cari Listesi |
| `47_teslimat.png` / `70_TESLİMAT.png` | Teslimat alt menü |
| `48_ziyaret.png` / `70_ZİYARET.png` | Ziyaret alt menü |
| `49_finans.png` | Finans alt menü |
| `90_dash.png` | Kasa Kart Listesi |
| `91_after_back.png` | Çek Listesi |
| `12_stok.png` | Stok alt menü |
| `13_raporlar.png` | Raporlar kısayolları |
| `14_doviz.png` / `52_doviz.png` | Döviz kuru |
| `15_sirketler.png` | Mobil Şirket Listesi |
| `16_guncelleme.png` | Veri Transferi |
| `17_duyurular.png` | Duyuru |
| `18_diger.png` / `56_diger.png` | Diğer alt menü |
| `03_favoriler.png` / `41_favoriler` karışık | Favoriler / yanlış etiketli dump’lar |
| `20_boot.png` | Launcher (MBT değil) |
| `01_login.png` vb. | Karışık/erken denemeler |

Tam checklist: `MENU_TODO.md`.

---

## 9. Durum özeti

| Durum | İçerik |
|-------|--------|
| Tamam (cihaz) | Dashboard tüm kutular; çoğu alt menü; cari liste; siparişte cari-önce; yönetici; döviz; şirket; güncelleme; duyuru; finans sheet + kasa/çek; fiş ön değerleri |
| Web ile dolduruldu (doğrulanacak) | Kalem ekleme alanları (fiyat/miktar/indirim); tahsilat tipleri; GPS/rota modeli; sıcak-soğuk pazarlama; risk takibi; e-belge |
| Hâlâ belirsiz | Exact form label sırası; check-in UI; NFC; VAN/iade menü etiketi; Güne başlama/bitirme alanları; rota’nın mobil giriş noktası (ZİYARET mi filtre mi) |

**Sonraki cihaz tıklamaları (öncelik):**  
1) Sipariş → Satış → cari seç → kalem ekranı (web alanlarını doğrula)  
2) Fatura → Toptan Satış  
3) Ziyaret → Mevcut Cari Hesap (GPS/konum UI)  
4) Finans → Yeni Hareket (ödeme tipi alanları)  
5) Diğer → Güne Başlama  
6) TESLİMAT / ZİYARET derin — rota listesi var mı?

---

## 10. Web / dokümantasyon bulguları

> Bu bölüm **cihaz dump’ı değildir**. Ekran alan adları ürün metninden çıkarılmıştır; pixel-level UI doğrulanmamıştır.

### 10.1 Kaynak listesi

| # | Kaynak | URL | Kullanım |
|---|--------|-----|----------|
| W1 | Google Play — MBT Logo Mobil Satış | https://play.google.com/store/apps/details?id=com.mimbt.LOGOPlus | Paket, özellik, tahsilat/barkod/GPS, changelog 2.1.14 |
| W2 | App Store — MBT Logo Mobil Satış | https://apps.apple.com/tr/app/mbt-logo-mobil-sat%C4%B1%C5%9F/id1423139082 | Aynı + karma koli, risk takibi notu |
| W3 | MimBT resmi — Logo | https://mbtmobil.com/logo | Sıcak/soğuk, rota/GPS, hibrit, e-belge, BT yazıcı |
| W4 | Saba Digital bayi | https://sabadigital.com.tr/logo-mbt-mobil/ | W3 ile aynı özellik metni |
| W5 | Akıllı KOBİ ürün | https://www.akillikobi.org.tr/mbt-logo-mobil/ | Hızlı/detaylı ekleme, stok seçim yöntemleri, tahsilat, GPS kısıtı |
| W6 | Bimanet MBT sayfası | https://bimanet.com.tr/tr/Yazilim-Cozumleri/Mobil-Cozumler/MBT.html | Modül listesi, döviz, depo, yönetici raporları |
| W7 | Aptoide mirror | https://mbt-logo.tr.aptoide.com/app | Sürüm 2.1.14.0 teyidi |
| — | Logo Mobile Sales kılavuzu | https://activeteknoloji.com.tr/mobil-sales-kullanim-kilavuzu/ | **Farklı ürün** — alan/menü kopyalanmaz |

Açık PDF kullanım kılavuzu veya alan-etiketli screenshot seti **bulunamadı**. YouTube eğitim videosu bu taramada güvenilir URL ile sabitlenemedi.

### 10.2 Web’den çıkarılan alan / akış özeti

| Konu | Web iddiası | Cihaz durumu |
|------|-------------|--------------|
| Sipariş/fatura kalem | fiyat, miktar, indirim; hızlı/detaylı; barkod; son satış; risk | Cari-önce görüldü; kalem **yok** |
| Fatura tipleri | sıcak/soğuk (pazarlama); e-belge | Menüde Toptan/Satın Alma; VAN/iade **yok** |
| Ziyaret GPS | parametreli konum; opsiyonel geofence | Alt form **yok**; cari pin var |
| NFC | — | Web’de yok; cihazda yok · **OPS K19 bilinçli sapma** |
| Rota | yönetici paneli gün/sıra/müşteri | Grid’de ROTA **yok** (uyumlu) |
| Tahsilat | nakit/çek/senet/KK; çek alanları | Sheet + kasa/çek; Yeni Hareket formu **yok** |
| Hibrit sync | online/offline; gönder/al | Güncelleme + transfer edilmeyen **görüldü** |

### 10.3 Çelişki / birleştirme notları

1. **Rota:** Web “var” der ama yönetim paneli + mobil kısıt olarak; cihazdaki “ROTA kutusu yok” ile uyumlu. Mobil giriş noktası hâlâ **doğrulanacak**.  
2. **VAN/iade:** Logo Mobile Sales’te iade menüsü var — **MBT değil**. MimBT menüsünde (cihaz) ayrı iade etiketi yok.  
3. **NFC:** Yok (negatif bulgu) → özellik varsayma. **OPS K19 bilinçli sapma** (uydurma yok).  
4. **Form label sırası:** Hiçbir kaynak pixel UI vermiyor → yalnızca cihaz dump’ı kesinleştirir.
