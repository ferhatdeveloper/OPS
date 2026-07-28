# Logo WMS × DEYS × FAYS → OPS Harmanı

**Tarih:** 2026-07-28  
**Kapsam:** Üç referansın en iyi özellikleri; KOBİ/saha OPS uyarlaması  
**Kod (menü):** ayrı `fs_whms` Depo Yönetimi grubu (bu tur)  
**Commit:** Yok  
**Canvas:** [`Logo-WMS-DEYS-OPS-blend.canvas.tsx`](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/Logo-WMS-DEYS-OPS-blend.canvas.tsx)  
**Önceki:** [`2026-07-28-deys-wms-research.md`](./2026-07-28-deys-wms-research.md) · [`2026-07-28-ops-complete-wms-blueprint.md`](./2026-07-28-ops-complete-wms-blueprint.md)

---

## 0. Ürün ayrımı (karıştırma yasak)

| Ürün | Kim | Ölçek | OPS ilişkisi |
|------|-----|-------|--------------|
| **Logo WMS** | Logo’nun kendi ürünü (KOBİ plug-and-play) | KOBİ | Süreç/parametre referansı |
| **Logo WMS Platform** | Logo (orta–büyük; RAD/AS/RS/3D) | Enterprise+ | Seçici P2/P3 |
| **DEYS** | Prolog — Logo ekosistem iş ortağı | KOBİ | Emir + cihaz + FIFO gün |
| **FAYS WMS** | Anlaş Otomasyon (`fays.com.tr`) | Concept→Pro | Raf/rota/son kontrol/etiket |

**Doğrulandı:** DEYS ≠ Logo WMS ≠ FAYS. Üçü de bağımsız ürün; benzer süreçleri hedefler, lisans/mimari farklıdır.

---

## 1. Logo WMS / WMS Platform — özellik envanteri

### 1.1 Logo WMS (KOBİ — doğrulandı)

| Özellik | Kaynak | Not |
|---------|--------|-----|
| Mal kabul kontrolü (hatalı/eksik) | logo.com.tr/urun/logo-wms | Sipariş/irsaliye kontrolü |
| Lokasyon / adres bazlı stok | aynı + EN broşür | Address support |
| Çoklu kullanıcı sipariş toplama | logo.com.tr | RF terminal |
| Sipariş bazlı sevkiyat planlama | logo.com.tr | |
| Palet etiketleme / paletli kabul | logo.com.tr | |
| Adres+palet sayım + fark fişi | logo.com.tr | |
| Seri/lot/varyant/SKT + 2D barkod | logo.com.tr + EN broşür | İlaç/tıbbi |
| Android el terminali | logo.com.tr | Plug-and-play |
| Personel performans ölçümü | logo.com.tr (pazarlama) | |
| Üretim modülü (ayrı lisans) | fiyat listesi PDF | |

### 1.2 Logo WMS Platform (orta–büyük — doğrulandı broşür)

| Özellik | Kaynak | Not |
|---------|--------|-----|
| Mal kabul · Yerleştirme · İkmal/Besleme | Platform broşür | Modül seti |
| Mal toplama · Sevkiyat · Stok · Üretim | aynı | |
| Sevkiyat + araç planlama | aynı | FIFO/FEFO yükleme |
| Hatalı / eksik / fazla yükleme engeli | aynı | |
| Raf/palet/seri/lot; rezerv; hasarlı/red/bloke | aynı | |
| Kalite kontrol (üretim hattı) | aynı | |
| İade: sağlam / bozuk | aynı | |
| RF: barkod / RFID / 2D | aynı | |
| 3D depo görselleştirme | ürün sayfası | Enterprise |
| AS/RS Robot modülü | ürün sayfası | Enterprise |
| RAD / WMS Script uyarlama | EN ürün + broşür | Platform farkı |
| Personel iş atama / performans | broşür | |
| Rezervasyon fişleri · vardiya | broşür | |
| Çok katmanlı taşıma kabı | broşür | |

### 1.3 Spekülasyon / doğrulanmayan (Logo)

| İddia | Durum |
|-------|--------|
| “Dalga planlama (wave)” adlı ürün modülü | **Doğrulanmadı** — resmi Logo metinlerde geçmiyor; genel WMS jargonu |
| EDI / ASN yerleşik WMS | **Doğrulanmadı** — Collector ayrı ekosistem; EDI genelde e-dönüşüm |
| Çapraz sevkiyat (cross-dock) adlı Logo modülü | **Doğrulanmadı** — broşürde yok |
| Slotting adlı ayrı ürün adı | **Kısmi** — “yerleşim / 3D düzen” var; “slotting” markası yok |

### 1.4 YouTube (Logo WMS süreç)

| URL | Öğreti |
|-----|--------|
| https://www.youtube.com/watch?v=fx44kF2cnfE | Seri listeden seç yasak → okutmaya zorla |
| https://www.youtube.com/watch?v=OmtE6cB8f6U | SKT’ye göre çıkış durdur (FEFO) |
| https://www.youtube.com/watch?v=1tSIFukIzL4 | Sevk ↔ sipariş bağlantısı / kalan |
| https://www.youtube.com/user/logoyazilim | Resmi kanal |

---

## 2. DEYS — özellik envanteri (reuse)

Özet: Prolog Logo ekosistem WMS; emir motoru (satınalma…sayım…üretim); FIFO/FEFO gün; lokasyon; cihaz/MAC/terminal yetki; dara/paket; etiket; REST + DEYS DROID; Logo DB’ye anlık yazım.

Detay: [`2026-07-28-deys-wms-research.md`](./2026-07-28-deys-wms-research.md).

**DEYS’e özgü güçlü yanlar (OPS için):** emir yaşam döngüsü, cihaz/terminal yetki, ürün bazlı fifo gün UI, KOBİ sadelik, Logo fiş tipleriyle hizalı emir seti.

---

## 3. FAYS WMS — özellik envanteri (üçüncü referans)

**Geliştirici:** Anlaş Otomasyon · https://fays.com.tr/ · https://www.anlasotomasyon.com/tr/fays-pro-wms-depo-otomasyon

### 3.1 Ürün kademeleri (doğrulandı — site)

| Paket | Odak | Öne çıkan |
|-------|------|-----------|
| Depobar | Ekonomik | Giriş-çıkış, transfer, sayım |
| FaysConcept | Küçük | + kart oluşturma, çoklu dil, dinamik raf, benzersiz barkod |
| FaysKobi | Orta | Concept seti |
| FaysPro | Büyük | + kargo-lojistik, sesli toplama |

### 3.2 Modül / yetenek (doğrulandı — web)

| Alan | Özellikler |
|------|------------|
| Core akış | Mal kabul, yerleştirme, ikmal/besleme, sevkiyat, mal toplama, stok, üretim |
| Raf | Dinamik raf yeri, raf kapasitesi, raf ömrü, raf durumu, raf/etiket transferi |
| Toplama | Sipariş toplama optimizasyon + rota; sevkiyat son kontrol (picking control) |
| Planlama | Sevkiyat sipariş planlama; transfer planlama + son kontrol |
| Barkod | Standart + “seri/akıllı barkod”; palet/koli/kutu çevrim |
| FIFO/LIFO/SKT | Sevk ve transferlerde kontrol |
| Etiket | Tasarım + baskı; üretim hattı etiket/paket |
| Sayım | El terminali hızlı sayım; fark fişleri; arşiv |
| Terminal | El terminali / endüstriyel tablet (LM_StoreS / LM_Pro) |
| FAYSPro ekstra | Sesli ürün toplama (voice picking); kargo-lojistik; kalite; kantar |
| Entegrasyon | Ticari yazılım / ERP entegrasyon modülü (FLA) |

### 3.3 FAYS spekülasyon

- Logo REST ile birebir entegrasyon detayı — **doğrulanmadı** (genel “ticari yazılım”).  
- OPS Flutter offline-first ile FAYS mimari eşlemesi — **yok**; yalnız özellik referansı.

---

## 4. “Best of three” seçilmiş set (OPS)

Seçim kriteri: KOBİ/saha + merkez depo; offline-first + JobQueue; dens Flutter; Logo REST; ui-no-touch.

| # | Özellik | Kaynak karışımı | Neden | Faz |
|---|---------|-----------------|-------|-----|
| 1 | Emir yaşam döngüsü | **DEYS** (+ Logo sipariş emri) | Tek omurga; ONAY + kuyruk | **P0** |
| 2 | Lokasyon / dinamik raf | Logo adres + **FAYS** dinamik raf + DEYS lokasyon | Putaway/pick olmadan WMS olmaz | **P0** |
| 3 | Mal kabul + yerleştirme | Logo Platform + FAYS + DEYS | İrsaliye kontrol + lokasyon zorunlu | **P0** |
| 4 | FIFO/FEFO / SKT kapısı | Logo + DEYS fifo gün + FAYS FIFO | Çıkışta engelle/uyar | **P0** |
| 5 | Ambar transfer + araç yükleme | DEYS tip + Logo araç + OPS load | Van köprüsü hazır | **P0** |
| 6 | Merkez sayım + fark | Logo + DEYS + FAYS | Count DTO + JobQueue | **P0** |
| 7 | Rota ile toplama + çoklu pick | DEYS rota + Logo multi + **FAYS** route/opt | Sevk doğruluğu | **P1** |
| 8 | Sevkiyat son kontrol | **FAYS** picking control + Logo yükleme kontrol | Eksik/fazla/yanlış engeli | **P1** |
| 9 | Seri/lot zorunlu okutma | Logo WMS video + FAYS akıllı barkod | Parametre | **P1** |
| 10 | Cihaz / terminal yetki | **DEYS** MAC/cihaz | Güvenlik | **P1** |
| 11 | Etiket tasarım / paket-dara | DEYS + FAYS etiket | Yazıcı skill | **P2** |
| 12 | Emir KPI dashboard | DEYS + Logo personel | dens `/whms/reports` | **P2** |

---

## 5. Bilinçli reddedilenler

| Özellik | Neden |
|---------|--------|
| 3D depo görselleştirme | Enterprise UI; dens/saha dışı |
| AS/RS Robot | Donanım + Platform lisansı |
| RAD / WMS Script | Flutter mimarisine uymaz |
| Anlık Logo DB yazımı (DEYS) | Offline-first + JobQueue bilinçli sapma |
| Sesli toplama (FAYSPro) | Donanım/niş; P3 |
| RFID toplu sayım | Maliyet; barkod önce |
| EDI/ASN / cross-dock “modül” | Logo’da doğrulanmadı; KOBİ OPS dışı |
| Dalga (wave) adlı motor | Spekülasyon; basit rota+çoklu pick yeterli |
| Windows CE / legacy terminal | Flutter Android/iOS |
| e-ticaret aşamalı paketleme (DEYS bayi) | P3 |

---

## 6. OPS uyarlama tablosu

| Özellik | Ekran / store / tablo | Faz |
|---------|----------------------|-----|
| Emir omurgası | `WhmsOrderDto` · `WhmsOrderStore` · `whms_orders` | P0 |
| Lokasyon | `WhmsLocationListScreen` · `whms_locations` | P0 |
| FIFO motor | `WhmsFifoRuleEngine` ↔ `batch_expiry` | P0 |
| Mal kabul/putaway | `/whms/orders` tip=mal_kabul | P0 |
| Transfer | `whms_transfer_queue_bridge` ← emir | P0 |
| Load → van | `WhmsLoadOrderConsumer` | P0 |
| Sayım | `/whms/count` · `WhmsCountResultDto` | P0 |
| **Depo menü grubu** | `fs_whms` + `sub_whms_*` → `/whms/*` | **P0 (bu tur)** |
| Pick + rota | `WhmsPickOrderScreen` | P1 |
| Son kontrol | sevk tamamla adımı | P1 |
| Cihaz/terminal | `whms_devices` | P1 |
| Etiket | `WhmsLabelTemplateStore` | P2 |
| KPI | `/whms/reports` | P2 |

---

## 7. OPS Depo Yönetimi menü ağacı (zorunlu)

Saha satış `fs_stock` **ayrı kalır**. Merkez depo:

```text
Depo Yönetimi (fs_whms)          → /whms
├── Emirler (sub_whms_orders)    → /whms
├── Tanımlamalar (sub_whms_defs) → /whms/warehouses
├── Ambarlar (sub_whms_warehouses) → /whms/warehouses
├── Sayım (sub_whms_count)       → /whms/count
├── Transfer (sub_whms_transfer) → /whms/transfer
├── Stok Sorgu (sub_whms_query)  → /whms/stock-query
├── Raporlar (sub_whms_reports)  → /whms/reports
└── Etiket / Cihaz (sub_whms_devices) → /whms/devices
```

Rol: **depocu + admin** görür; plasiyer görmez (`RoleHomeMenuFilter`).

---

## 8. Kaynak URL’ler

### Logo WMS / Platform
- https://www.logo.com.tr/urun/logo-wms  
- https://www.logo.com.tr/urun/logo-wms-platform  
- https://www.logo.com.tr/kategori/wms-depo-yonetim-sistemi  
- https://cdn.logo.com.tr/files/logocomtr/Uploads/Documents/logo-wms-platform-tanitim-brosuru-tr.pdf  
- https://cdn.logo.com.tr/files/logocomtr/Uploads/Documents/logo-wms-tanitim-brosuru-en.pdf  
- https://www.smartbth.com/logo-wms/  
- https://kurumsoft.com.tr/logo-wms-platform/  

### DEYS
- Araştırma MD §7 / §10.5  

### FAYS
- https://fays.com.tr/  
- https://www.anlasotomasyon.com/tr/fays-pro-wms-depo-otomasyon  
- http://fays.com.tr/Fays-depo-otomasyon-program-servis.html  
- http://fays.com.tr/depo-cozumleri-uygulama-danismanligi.html  

### İç
- `lib/modules/whms/**` · `docs/contracts/whms-*.md` · `lib/service/database_service.dart` (menü seed)

---

## 9. Ajan paneli

| Rol | Durum | Risk | TODO |
|-----|--------|------|------|
| Merkez | Hazır | 3 ürün karışması | Kaynak etiketi koru |
| Saha | Hazır | fs_stock ↔ fs_whms | Plasiyer stok ayrı |
| Dil | Hazır (menü key) | Çeviri sync çakışması | `translation_sync` |
| Tester | Yarım | Seed idempotent | Menü uuid smoke |
| Yazılım | Hazır (menü) | Shell stub | Emir store P0 |
| UI | No-touch | — | dens AppBar shell |
