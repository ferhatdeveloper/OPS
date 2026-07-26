# MBT (LOGOPlus) Sistem Ekspertizi

**Tarih:** 2026-07-26  
**Paket:** `com.mimbt.LOGOPlus` · **Sürüm:** `2.1.14.0` (versionCode `21140`)  
**Cihaz:** Nothing A065 · `6544bc4b`  
**Yöntem:** adb screencap + uiautomator dump (scrcpy PATH’te yoktu; adb ile devam)  
**Kanıt:** `tmp_mbt_analysis/ekspertiz/20260726/` (~82 PNG + XML/text)  
**Önceki şema:** `docs/plans/2026-07-25-mbt-app-structure-schema.md`  
**Canvas:** [MBT-system-expertise.canvas.tsx](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/MBT-system-expertise.canvas.tsx)  
**Kapsam:** Yalnızca MBT gözlemi. OPS koduna dokunulmadı. Commit yok.

> **Kaynak önceliği:** Çelişkide cihazda görülen kazanır.  
> **Etiketler:** `OBSERVATION` = bu oturumda ekranda görüldü · `OUT_OF_SCOPE` / `PARTIAL` = tıklanmadı, a11y ile açılamadı veya kalem satırına girilmedi.

---

## 1. Genel mimari / UX dili

| Özellik | Gözlem |
|---------|--------|
| Shell | Xamarin/MAUI benzeri; çoğu kutuya `clickable=false` — dokunuş label üstü ikon alanına |
| Tema | Koyu kırmızı AppBar; beyaz yuvarlatılmış 3 kolon kart grid; kalp = favori |
| AppBar | Başlık `MBT ( 001_01 )` (firma/dönem) · palet · senkron · hesap makinesi |
| Footer | mbt mobil logo · `Demo Kullanıcısı` · `MBT Mobil (Logo) (Vers.2.1.14.0)` |
| Açılış tipi | **Doğrudan ekran** (CARİ, YÖNETİCİ, DÖVİZ…) veya **bottom sheet** 2 kolon işlem kartları |
| Liste kalıbı | Geri · başlık · calculator · hamburger · Ana Sayfa · arama · kart listesi · FAB(+) |
| Belge kalıbı | Önce **Cari Kart Listesi** (çoğu satış/finans) → tip/form → **Stok/Hizmet** arama şeridi |
| Kuyruk dili | Transfer edilen / Transfer edilmeyen / Bekleyen — fiş yaşam döngüsü |
| Oturum | Login: `demo` + kayıtlı şifre · Wan3 sunucu seçimi · Giriş ile dashboard |

**Plasiyer gün akışı (cihaz kanıtı):**

1. **DİĞER → GÜNE BAŞLAMA / BİTİRME** — plaka, başlangıç/bitiş km, “Tamamlandı?”, Kaydet  
2. **ZİYARET** — mevcut/yeni cari → ziyaret formu → ZIYARETI TAMAMLA  
3. **SİPARİŞ / FATURA / İRSALİYE** — tip seç → (genelde) cari → stok/hizmet kalem arama  
4. **TESLİMAT** — bekleyen / aktarılamayan kuyruklar (satış/alış sekmeli)  
5. **FİNANS → YENİ HAREKET** — cari → tahsilat/ödeme tipi → fiş alanları  
6. **GÜNCELLEME** — Cihazdakileri Gönder / Sunucudan Al / Ürün Resimleri  
7. **DİĞER → Güne Bitirme** (aynı formda “Tamamlandı?”)

**ROTA:** Ana grid’de ayrı kutu **yok** (`OBSERVATION`).

---

## 2. Dashboard 16+ modül envanteri

### 2.1 FAVORİLER — `OBSERVATION`

| | |
|--|--|
| Amaç | Dashboard’da kalp ile işaretlenen modüllere hızlı erişim (kısayol bottom sheet) |
| Giriş | Ana grid **FAVORİLER** kutusu (sarı yıldız +); kendi üzerinde kalp **yok** |
| Açılış | Tap ~ikon merkezi `(131,452)`; sheet açılınca a11y yalnızca favori etiketlerini gösterir |
| Boş durum | Favori yokken sheet içeriği boş → dump hâlâ dashboard gibi görünebilir (yanıltıcı) |

**Ekle / çıkar (kalp toggle):**

- Kart köşesindeki **kalp outline** = eklenebilir; **dolu turuncu/sarı kalp** = favoride (`RGB≈247,170,35`).
- Aynı kalbe tekrar tap = çıkar (sheet’ten düşer).
- Kanıt: CARİ ekle → sheet `CARİ` · DÖVİZ+YÖNETİCİ ekle → `CARİ \| DÖVİZ \| YÖNETİCİ` · CARİ çıkar → `DÖVİZ \| YÖNETİCİ` · ŞİRKETLER ekle → `DÖVİZ \| YÖNETİCİ \| ŞİRKETLER`.

**Dashboard’da kalp görülen / favoriye alınabilen (bu oturum):**

| Modül | Kalp | Toggle |
|-------|------|--------|
| YÖNETİCİ | Evet | Eklendi (`OBSERVATION`) |
| CARİ | Evet | Ekle/çıkar (`OBSERVATION`) |
| DÖVİZ | Evet | Eklendi (`OBSERVATION`) |
| ŞİRKETLER | Evet | Eklendi (`OBSERVATION`) |
| ÇIKIŞ | Evet (outline) | **Tıklanmadı** (logout riski) |
| SİPARİŞ | Bazı karelerde outline | Bu turda piksel taramasında yok / kararsız |
| FATURA / İRSALİYE / TESLİMAT / ZİYARET / FİNANS / STOK / RAPORLAR / GÜNCELLEME / DUYURULAR / DİĞER | Ana grid’de kalp **yok** | — |

**Alt menü (sheet) kartlarında kalp:** STOK / FİNANS bottom sheet öğelerinde outline kalp **görüldü** (görsel). Alt işlem kalbine isabetli toggle bu oturumda doğrulanamadı (`PARTIAL` — tap çoğu kez öğeyi açtı).

**Sheet’ten açılış:** Favori kutusuna tap → ilgili modül (ör. CARİ → Cari Kart Listesi; DÖVİZ → Döviz Kuru).

**Sıralama:** Ayrı sürükle-bırak / düzenle UI **yok**. Sheet sırası ekleme sırasına yakın (çıkarılan ortadan düşer; kalanlar korunur).

**Karıştırılmamalı:** **RAPORLAR** sheet’i (CARİ/STOK/… + Rapor Yedekle/İndir) ≠ FAVORİLER. Eski şemada FAVORİLER’e yazılan rapor kısayolları **RAPORLAR**’a aittir.

**Kanıt dosyaları:** `favoriler_100_*` … `favoriler_190_*`, `favoriler_complete_notes.json`, `favoriler_heart_map.json`.

### 2.2 YÖNETİCİ — `OBSERVATION`

| | |
|--|--|
| Amaç | Firma geneli özet rapor |
| Açılış | Doğrudan **Yönetici Raporları** |
| Filtre | Bugün / Bu Hafta / Bu Ay / Bu Yıl / Başlangıç–Bitiş |
| Bloklar | KASA, BANKA, ÇEK, SENET, FİRMA GENEL ANALİZ, FATURA (satış/alış), SİPARİŞ (satış/alış) |
| Drill-down | KASA satırına tap denendi; ayrı detay ekranı netleşmedi (`PARTIAL`) |

### 2.3 CARİ — `OBSERVATION`

| | |
|--|--|
| Amaç | Cari kart listesi + müşteri hub |
| Liste | Kod/Ünvan ara · barkod · konum pin · Ara · FAB(+) · ~çoklu döviz bakiye |
| Kart | Ünvan, Kod, Bakiye (Borç/Alacak), Detay (TL/USD/IQD…) |
| Detay hub | **Müşteri Detay Bilgisi** → sekmeler/kısayollar: FATURA · İRSALİYE · SİPARİŞ · ZİYARET · FİNANS |
| Cari→Sipariş | Detaydan SİPARİŞ → **SATIŞ / ALIŞ** seçimi (`OBSERVATION`) |
| FAB yeni cari | Bu oturumda FAB detay ekranında kaldı; form alanları `PARTIAL` |
| Risk etiketi | Liste/detayda ayrı “Risk limiti” satırı **görülmedi** (`PARTIAL` / web iddiası doğrulanmadı) |

### 2.4 FATURA — `OBSERVATION`

| Alt menü | Amaç |
|----------|------|
| TOPTAN SATIŞ | Satış faturası oluşturma (cari/bağlam sonrası stok arama) |
| SATIN ALMA | Alış faturası |
| FATURA LİSTESİ | Transfer edilenler; SATIN ALMA/TOPTAN SATIŞ sekmeli |
| TRANSFER EDİLMEYEN FATURALAR | Offline/kuyruk |
| BEKLEYEN FATURALAR | Beklemeye alınan |
| Fiş Ön Değerleri | AÇIKLAMA · PLAKA NO · ÖZELKOD 1 · Kaydet/Kapat |

**Not:** VAN / iade ayrı menü etiketi **yok**. Kalem miktar/fiyat satır formu stok seçimine girilmeden `PARTIAL`.

### 2.5 İRSALİYE — `OBSERVATION`

Fatura ile aynı sheet iskeleti (Toptan Satış, Satın Alma, Liste, Transfer edilmeyen, Bekleyen, Fiş Ön Değerleri).  
**TOPTAN SATIŞ:** Cari Kart Listesi → cari seç → `ToptanSatiş` + Stok/Hizmet arama şeridi.

### 2.6 SİPARİŞ — `OBSERVATION`

| Alt menü | Gözlem |
|----------|--------|
| SATIŞ | Cari-önce; kaydedilmemiş fiş uyarısı: Devam Et / Sil / Tamam (ör. ADNAN SATIN) |
| ALIŞ | Cari → `Aliş` + Stok Kartı / Hizmet Kartı / Kod/Ad / Barkod / Kamera / Grup / Resim / Ara |
| SİPARİŞ ONAYLAMA | ALIŞ/SATIŞ · Öneri · Sevk Edilebilir/Edilemez · dönem filtre · 0 adet |
| SİPARİŞ LİSTESİ | “Transfer Edilen Siparişler” |
| TRANSFER EDİLMEYEN | Offline kuyruk |
| SİPARİŞ TAKİBİ | Dönem filtreli takip listesi |
| BEKLEYEN | Bekleyen Siparişler |

**Belge UI (satış/alış):** Üst başlık Satış/Alış · Stok/Hizmet sekmeleri · arama araçları. Satır iskonto/miktar ekranı `PARTIAL`.

### 2.7 TESLİMAT — `OBSERVATION`

| Alt menü | Ekran |
|----------|--------|
| TESLİMAT | (tap bazen AKTARILAMAYAN ile karıştı — a11y hit area) |
| BEKLEMEYE ALINANLAR | Beklemeye Alınan Teslimatlar · 1-SATIŞ / 2-ALIŞ · tarih filtre |
| AKTARILAMAYAN | TRANSFER EDİLMEYEN SİPARİŞLER başlıklı kuyruk · 1-SATIŞ / 2-ALIŞ |

Teslimat, sipariş kuyruğu ile sıkı bağlı görünüyor.

### 2.8 ZİYARET — `OBSERVATION`

| Alt menü | |
|----------|--|
| MEVCUT CARİ HESAP | Ziyaret formu (aşağı) |
| YENİ CARİ HESAP | Aynı form iskeleti (demo’da mevcut cari ile doldu) |
| GEÇMİŞ / GEÇMİŞ (2) | Ziyaret Listesi · dönem filtre · 0 Adet |
| TRANSFER EDİLMEYENLER | Aynı liste kalıbı |

**Ziyaret formu alanları:** KOD · ÜNVAN · ADRES · İL · İLÇE · ÜLKE · ZIYARET SEBEBI (Seçim) · MÜŞTERI TIPI · BÖLÜM · İLGILI KIŞI · PROJE KODU · REFERANS KIŞI · EKLER · **ZIYARETI TAMAMLA** / VAZGEÇ.  
GPS/NFC label’ı a11y’de **görülmedi** (`PARTIAL`).

### 2.9 FİNANS — `OBSERVATION`

| Alt menü | |
|----------|--|
| YENİ HAREKET | Cari Kart Listesi → **Tahsilat Tipi** sheet |
| TRANSFER EDİLEN / EDİLMEYEN TAHSİLATLAR | Dönem filtreli listeler |

**Tahsilat / ödeme tipleri (cari sonrası):**

- NAKIT TAHSILAT  
- KREDI KART TAHSILATI  
- ÇEK TAHSILATI  
- SENET TAHSILATI  
- NAKIT ÖDEME  
- KREDI KARTI İLE ÖDEME  
- VIRMAN FIŞI  

**Nakit tahsilat alanları:** İşlem Dövizi · KOD/ÜNVAN/BAKIYE (cari) · EVRAK NO · KASA KODU · AÇIKLAMA · TUTAR · PLASIYER KODU · ÖZELKOD 1  

**Çek tahsilat alanları:** EVRAK NO · TUTAR · VADE TARIHI · CIRO · ASIL BORÇLU · BANKA · İŞYERI · ÇEK NO · HESAP NO · AÇIKLAMA (+ cari özet)

### 2.10 STOK — `OBSERVATION`

| Alt menü | |
|----------|--|
| DETAY | Kod/Ad · Barkod · Kamera · Grup · Resim · Ara |
| FİYAT GÖR | Fiyat Gör · Barkod |
| BARKOD EKLE | (ekran yakalandı) |
| SAYIM FİŞİ | İşyeri/Ambar: İŞYERI · FABRIKA · AMBAR · Seç/Kapat |
| AMBAR FİŞİ | KAYNAK / HEDEF × İŞYERI · FABRIKA · AMBAR |
| Üretimden Giriş Fişi | İşyeri ve Ambar Bilgisi diyaloğu |

### 2.11 RAPORLAR — `OBSERVATION` (sheet)

CARİ · STOK · SİPARİŞ · FATURA · İRSALİYE · DİĞER · Rapor Yedekle/İndir (FAVORİLER ile benzer kısayol grid).

### 2.12 DÖVİZ — `OBSERVATION`

Döviz Kuru · tarih · USD/EUR/GBP/JPY/SAR/CNY/IQD/IRR/TRY/SYP/TL · Kaydet.

### 2.13 ŞİRKETLER — `OBSERVATION`

Mobil Şirket Listesi · MBT · Firma 001 · Dönem 01 · 01-01-2024…31-12-2024 · Seç.

### 2.14 GÜNCELLEME — `OBSERVATION`

**Veri Transferi:** CİHAZDAKİ VERİLERİ GÖNDER · SUNUCUDAN VERİLERİ AL · ÜRÜN RESİMLERİ.  
Logo REST/job metni UI’da yok; “sunucu” soyut (`OBSERVATION`).

### 2.15 DUYURULAR — `OBSERVATION`

Kampanya duyurusu · tarih aralığı · dashboard badge “1”.

### 2.16 DİĞER — `OBSERVATION`

| Alt | |
|-----|--|
| BİLGİ GÖNDERME | (sheet öğesi) |
| GÜNE BAŞLAMA / BİTİRME | Tek form: tarih · **PLAKA NUMARASI** · **BAŞLANGIÇ KILOMETRESI** · **BITIŞ KILOMETRESI** · Tamamlandı? · Kaydet/Kapat |

### 2.17 ÇIKIŞ — `OUT_OF_SCOPE`

Görüldü; oturumu bozmamak için tıklanmadı.

---

## 3. Belge / fiş tipleri

| Aile | Tipler (cihaz) | Not |
|------|----------------|-----|
| Sipariş | Satış, Alış | Onaylama: Öneri / Sevk edilebilir / edilemez |
| Fatura | Toptan Satış, Satın Alma | VAN/iade ayrı etiket yok |
| İrsaliye | Toptan Satış, Satın Alma | Fatura ile paralel iskelet |
| Teslimat | Satış/Alış sekmeli kuyruklar | Sipariş transfer diliyle örtüşüyor |
| Finans | Nakit/KK/Çek/Senet tahsilat + nakit/KK ödeme + Virman | Cari-önce |
| Stok fiş | Sayım, Ambar (kaynak→hedef), Üretimden giriş | İşyeri/Fabrika/Ambar |
| Fiş ön değer | Açıklama, Plaka, Özelkod 1 | Fatura/İrsaliye sheet |

**Yaşam döngüsü:** düzenle → (isteğe) beklemede tut → transfer et / transfer edilmeyen kuyruk → Güncelleme ile gönder.

**Taslak koruma:** “Daha önceden başlatılmış fakat kaydedilmemiş bir fiş bulundu” → Devam Et / Sil (`OBSERVATION`, sipariş satış).

---

## 4. Cari-önce ve risk/limit

| Akış | Cari-önce? | Kanıt |
|------|------------|--------|
| Sipariş Satış/Alış | Evet (liste) veya taslak devam | `crit_siparis_*` |
| İrsaliye Toptan | Evet | `crit_irsaliye_toptan_*` |
| Finans Yeni Hareket | Evet → tip sheet | `crit2_finans_*` |
| Fatura Toptan | Bu oturumda doğrudan stok UI (muhtemel açık taslak/bağlam) | `PARTIAL` — önceki şemada cari-önce |
| Ziyaret | Cari seçimli giriş | Mevcut/Yeni |
| Cari detay hub | Cari bağlamında belge kısayolları | FATURA/İRSALİYE/SİPARİŞ/ZİYARET/FİNANS |

**Risk/limit:** Anlık risk uyarısı bu taramada **ekranda yakalanmadı**. Bakiye (Borç/Alacak) ve çoklu döviz detay var. Risk = web changelog iddiası → cihazda `PARTIAL`.

---

## 5. Offline / sync / Logo izleri

| Sinyal | Gözlem |
|--------|--------|
| Kuyruk ekranları | Transfer edilmeyen / bekleyen (sipariş, fatura, irsaliye, tahsilat, ziyaret, teslimat) |
| Güncelleme | Gönder / Al / Ürün resimleri — Logo kelimesi UI’da yok |
| Login | Wan3 sunucu adı; cihaz kayıt / printer ayarları (önceki ayarlar sheet) |
| Offline-first çıkarımı | Taslak fiş + transfer edilmeyen listeler → yerel kuyruk modeli |

---

## 6. OPS farkları (kısa)

| Konu | MBT (gerçek) | OPS (bugün — gap dokümanlarına göre) |
|------|--------------|--------------------------------------|
| Cari-önce | Sipariş/finans/irsaliye zorunlu liste | Siparişte var; fatura/tahsilatta stub/guard eksik kalabiliyor |
| Fiş tipleri | Toptan Satış / Satın Alma dili | “Sıcak Satış (Van Sales)” vb. dil sapması |
| Tahsilat tipleri | 7 tip + virman; nakit/çek alan seti zengin | Tip kodları/İngilizce kalıntı riski |
| Gün başla/bitir | Plaka + km + Tamamlandı | DayStatus yerel; plaka/km parity zayıf |
| Ziyaret | Sebep, proje, referans, ekler | Check-in var; alan seti/etiket farklı |
| Sync dili | Transfer edilmeyen / Güncelleme | Logo job / bekleyen aktarım karışık sözlük |
| Rota | Grid’de yok | OPS’te ayrı rota menüleri |
| Modül derinliği | Gerçek fiş + kuyruk | Birçok ekran stub / liste boş |

Detaylı OPS içerik gap: `docs/plans/2026-07-26-ops-mbt-content-gap.md`.

---

## 7. Eksik / belirsiz (cihazda açılamayan veya PARTIAL)

1. **FAVORİLER** — tamamlandı (2026-07-26 devam); alt-menü kalp toggle hâlâ `PARTIAL`.  
2. **Kalem satırı** (miktar, fiyat, iskonto, risk aşımı) — stok kartı seçilip satır formuna girilmedi.  
3. **GPS / geofence** — ziyaret formunda konum alanı a11y’de yok.  
4. **NFC** — yok · **OPS K19 bilinçli sapma** (uydurma yok).  
5. **VAN / iade** ayrı tip — yok.  
6. **ROTA** mobil kutu — yok.  
7. **Yeni cari FAB** form alanları — netleşmedi.  
8. **Senet / KK** tahsilat form alanları — tip listede var; form `PARTIAL`.  
9. **ÇIKIŞ** — tıklanmadı.  
10. **scrcpy** — kurulu değil / PATH yok; yalnızca adb kullanıldı.

---

## 8. Kanıt indeksi (özet)

| Klasör | İçerik |
|--------|--------|
| `tmp_mbt_analysis/ekspertiz/20260726/00_dashboard_clean.*` | Temiz dashboard |
| `mod_*` / `deep_*` | Modül sheet + alt ekranlar |
| `crit_*` / `crit2_*` | Satış/alış/fatura/irsaliye/finans/gün/ziyaret kritik yollar |
| `crit2_results.json` / `deep_progress.json` | Yapılandırılmış metin özetleri |

---

## 9. Özet skor (bu ekspertiz)

| Metrik | Değer |
|--------|-------|
| Dashboard kutusu | 17 (ÇIKIŞ hariç 16 iş kutusu) |
| Tam / derin OBSERVATION | 16 (FAVORİLER tamamlandı) |
| PARTIAL | Kalem satırı, GPS, senet/KK form, FAB yeni cari, fatura cari-önce tutarlılığı, alt-menü kalp toggle |
| OUT_OF_SCOPE | ÇIKIŞ (logout); ÇIKIŞ kalbi tıklanmadı |
| Commit | Yok |
| OPS kod değişikliği | Yok |
