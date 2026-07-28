# DEYS (Depo Yönetim Sistemi) Araştırma — LOGO Ekosistem WMS

**Tarih:** 2026-07-28  
**Kapsam:** İnternet araştırması + ekran görüntüsü menü gözlemi + EXFINOPS WHMS gap analizi  
**Kod:** Yok (yalnız araştırma / plan)  
**Commit:** Yok  
**Canvas:** [`DEYS-WMS-arastirma.canvas.tsx`](/Users/ferhatnas/.cursor/projects/Users-ferhatnas-App-EXFINOPS/canvases/DEYS-WMS-arastirma.canvas.tsx) — toparlandı (tek scroll, sekmesiz)

---

## 1. Ürün özeti

| Alan | Bulgu | Güven |
|------|--------|--------|
| **Ad** | DEYS — Depo Yönetim Otomasyonu / Depo Yönetim Sistemi | Doğrulandı |
| **Geliştirici** | Prolog Yazılım (Logo çözüm geliştirme iş ortağı) | Doğrulandı |
| **Konumlandırma** | KOBİ odaklı; el terminali + barkod ile Logo ERP’ye anlık stok hareketi | Doğrulandı |
| **Logo Store** | Tiger 3 DEYS vb. paketler (ekosistem çözüm) | Doğrulandı |
| **Mobil istemci** | Native Android (“DEYS DROID”); 3G/4.5G; REST servis mimarisi | Doğrulandı (bayi/kaynak) |
| **Veri** | Logo veritabanlarında çalışma (Prolog sitesi) | Doğrulandı (pazarlama) |
| **Sürüm (site)** | DEYS V7.1.1 indirme referansı (Prolog, 2026-07 erişim) | Doğrulandı (site metni) |
| **Ekran görüntüsü uygulaması** | Windows backoffice; LOGO dönem 2024; firma `036/01`; kullanıcı NIHAT; Admin | Gözlem (müşteri ekranı) |

**Kısa tanım (kaynaklara dayalı):** DEYS, Prolog’un geliştirdiği Logo onaylı ekosistem WMS’idir. Yönetici **emir** oluşturur; depo personeli **el terminali** ile barkod okutarak emri tamamlar; hareketler Logo stok/fiş dünyasına yansır. Parametrik yapı, lokasyon, FIFO, seri/lot, etiket ve sayım öne çıkan yeteneklerdir.

**Logo’nun kendi WMS ailesi ile ayrım (doğrulandı):** Logo ayrıca **Logo WMS** ve **Logo WMS Platform** ürünlerini pazarlar. DEYS bunlardan ayrı, **iş ortağı (Prolog)** ürünüdür; benzer süreçler (mal kabul, sevk, FIFO/FEFO, el terminali) hedeflese de ürün kodu / lisans / mimari farklıdır. Ekran görüntüsündeki Windows UI, Logo WMS Platform broşüründen ziyade DEYS/Prolog backoffice’e uyumludur (doğrudan ürün sürüm doğrulaması yapılmadı — **doğrulanmadı: build/versiyon string**).

---

## 2. LOGO ilişkisi

### 2.1 Uyumlu / anılan Logo ürünleri

Kaynaklarda (Logo ekosistem sayfası + Store + bayi) anılan aileler:

- Logo GO 3 / GO Wings  
- Logo Tiger 3 / Tiger 3 Enterprise  
- Logo Tiger Wings / Tiger Wings Enterprise  

Entegrasyon modeli (kaynak özeti):

- Stok işlem bilgisi **işlem anında** Logo ürünlerine yazılır / okunur.  
- Emir → terminal tamamla → Logo fiş/stok senkronu.  
- Üretim: GO’da üretimden giriş; Tiger’da hızlı üretim; Tiger Enterprise’da üretim/iş emri tamamlandı + süre/duruş (**bayi teknik özeti**).

### 2.2 Emir tipleri (ürün siteleri — doğrulandı)

Satınalma, satınalma iade, satış, satış iade, ambar transferi, sarf, fire, sayım, üretimden giriş, hızlı üretimden giriş.

### 2.3 Teknik iddialar (bayi — kısmen doğrulandı)

| İddia | Kaynak | Not |
|-------|--------|-----|
| REST servis mimarisi | kontrolyazilim.com.tr | Doğrulandı (pazarlama) |
| Native Android istemci | aynı + Prolog | Doğrulandı (pazarlama) |
| E-ticaret depo modülleri | aynı | Doğrulandı (pazarlama); EXFINOPS için ikincil |
| Varyant desteği | Logo FAQ başlığı var | Cevap metni sayfada kısmi — **doğrulanmadı (detay)** |
| Fiyat (2023 bayi listesi) | Kontrol Yazılım | Tarih damgalı; güncel fiyat **doğrulanmadı** |
| Store Tiger 3 DEYS fiyatı | store2.logo.com.tr | Liste fiyatı değişebilir — anlık doğrulama gerekir |

---

## 3. Ekran görüntüsünden menü ağacı (gözlem)

Kaynak: kullanıcı ekran görüntüsü (`…/assets/image-a0447dcb-0c22-4069-8c1d-43075a1428d3.png`), Windows masaüstü, uzak masaüstü (AlpemixPro).

### 3.1 Üst şerit / oturum

- Dönem: **2024 Yılı**  
- Ürün/bağlam etiketi: **LOGO**  
- Firma/dönem kodu: **036/01**  
- Uzak IP / kullanıcı: `26.87.17.162` · **NIHAT**  
- Rol (status): **Admin** · Sistem  

### 3.2 Ana modül düğmeleri (sol alt)

| Modül | Durum (görüntü) |
|-------|-----------------|
| **Emirler** | Görünür (içerik açılmadı) |
| **Tanımlamalar** | Seçili |
| **Sistem** | Görünür |
| **Raporlar** | Görünür |
| **Etiket** | Görünür |

### 3.3 Tanımlamalar alt menü (görüntü — doğrulandı gözlem)

1. Dönem Tanımları  
2. Rol / Yetki Tanımları  
3. Kullanıcı Tanımları  
4. Cihaz Tanımları *(açık: “Cihazlar” grid + “Cihaz - Yeni” modal)*  
5. Terminal Rol / Yetki Tanımları  
6. Terminal Tanımları  
7. Araç Tipi / Araç Tanımları  
8. Lokasyon Tanımları  
9. Malzeme Fifo / Fefo Gün Tanımları  
10. Paket Tipi / Satış Sonrası Paket Tipi Tanımları  
11. Dara Tanımları  

### 3.4 Cihaz kaydı alanları (görüntü)

- Cihaz Adı  
- Mac Adresi  
- İşletim Sistemi (ör. Android)  
- Cihaz Modeli  

CRUD toolbar: Yeni · Değiştir · Sil · Kopyala · İncele · Yazdır · Yenile  

### 3.5 Emirler / Sistem / Raporlar / Etiket alt ağacı

Görüntüde **açılmadı**. Web kaynaklarından beklenen içerik (aşağı §4); ekran menü eşlemesi **doğrulanmadı**.

---

## 4. Modül haritası (web + ekran birleşik)

| Alan | Web (Prolog / Logo / bayi) | Ekran (Tanımlamalar) | Not |
|------|----------------------------|----------------------|-----|
| Emir motoru | Satın alma… sayım… üretim | Ana düğme “Emirler” | Emir listesi UI **doğrulanmadı** |
| FIFO | Ürün bazlı fifo gün | Fifo/Fefo Gün Tanımları | FEFO menüde var; web metin daha çok FIFO |
| Lokasyon | Mal kabul sonrası barkod/liste | Lokasyon Tanımları | Rota ile toplama (bayi) |
| Seri/Lot | Seri lot havuzu, tarihçe | — | Tanımlamalarda ayrı satır yok (muhtemel stok/emir) |
| El terminali | Yetki, işyeri/ambar, DROID | Cihaz + Terminal + Terminal yetki | MAC kilidi gözlemi |
| Araç | Sevk/araç planı (Logo WMS Platform’da net) | Araç Tipi / Araç | DEYS’te depo içi araç mı / sevkiyat mı — **doğrulanmadı** |
| Etiket | Etiket tasarım, barkod yazdırma | Ana düğme Etiket | — |
| Rapor | Rapor şablonları, dashboard | Ana düğme Raporlar | — |
| Üretim | GO/Tiger/Enterprise farkları | — | Emir tipi olarak |
| Dara / paket tipi | — | Dara, Paket tipi | Web özetlerde zayıf; ekranda net |
| Sistem | Parametre, dil, tema (site) | Ana düğme Sistem | Alt menü **doğrulanmadı** |

---

## 5. EXFINOPS depo / WHMS ile gap analizi

Kaynak EXFINOPS: `docs/plans/2026-07-26-whms-integration-prep.md`, `docs/contracts/whms-bridge.md`, `lib/modules/whms/`, OPS `field_sales/stock` + `vehicles`.

### 5.1 Mevcut EXFINOPS WHMS yüzeyi (özet)

| Yetenek | Durum |
|---------|--------|
| `/whms` dens shell | İskelet |
| Ambar master MRK/ARC/IAD + `warehouse_stocks` | Var |
| `StockBalancePort` (yerel + Logo) | Var |
| Onaylı transfer kuyruk (`WhmsTransferQueueBridge`) | Var |
| Yükleme emri → araç stok (`WhmsLoadOrderConsumer`) | Var |
| Sayım DTO (`WhmsCountResultDto`) | Sözleşme |
| Canlı WHMS REST / zengin depo UI | Yok |
| Lokasyon (raf/göz), cihaz/terminal kaydı | Yok |
| FIFO/FEFO gün tanımı UI/motor | Yok (OPS’ta `batch-expiry` stub route var) |
| Etiket tasarım / dara / paket tipi | Yok |
| Emir backlog (mal kabul/sevk/sayım UI) | Yok |

### 5.2 Gap matrisi (DEYS referans → EXFINOPS)

| DEYS / WMS yetenek | EXFINOPS karşılık | Gap | Öncelik önerisi |
|--------------------|-------------------|-----|-----------------|
| Emirler (mal kabul, sevk, transfer, sayım…) | Transfer kuyruk + load consume + count DTO | Emir UI + durum makinesi yok | **P0** — emir sözleşmesini DEYS emir tiplerine genişlet |
| Cihaz / terminal / MAC | Yok | Tam boş | **P1** — cihaz kaydı + yetki (güvenlik) |
| Lokasyon (bin) | Ambar kodu (MRK…) yalnız | Raf/göz yok | **P0** — Postgres + mobil lokasyon master |
| FIFO / FEFO gün | `batch-expiry` stub | Motor yok | **P0** — sevk/yüklemede SKT kuralı |
| Araç tipi / araç | `vehicles` / `vehicle_stocks` (saha) | Merkez WMS araç ≠ plasiyer van — sınır netleştir | **P1** — domain sınırı dokümante |
| Etiket / barkod yazdırma | Barkod tarama (OPS); yazıcı skill var | Merkez etiket tasarım yok | **P2** |
| Dara / paket tipi | Yok | Boş | **P2** |
| Rol/yetki (backoffice + terminal) | Permission groups (yeni) + menü flag | Depo terminal yetkisi yok | **P1** |
| Raporlar / dashboard emir | Raporlar (MBT/OPS) | Depo KPI yok | **P2** |
| Logo anlık fiş | Logo sync / job queue (kısmi) | DEYS kadar “işlem anı” WMS yok | **P0** — bridge’i emir tamamla olayına bağla |
| Android terminal istemci | Flutter OPS (plasiyer) | Ayrı depo terminal uygulaması yok | **P1** — WHMS mobil rol veya ayrı flavor |

### 5.3 Bilinçli sınır (mevcut mimariyle uyum)

- OPS plasiyer menüsü (`fs_stock`) **WHMS’e gömülmez** (mevcut kural).  
- ARC / `vehicle_stocks` = saha van; merkez lokasyon deposu ile karıştırılmamalı.  
- DEYS’i kopyalamak hedef değil; **sözleşme ve emir modeli** referans alınmalı.

---

## 6. EXFINOPS için öneriler (3–5)

1. **Emir sözleşmesi (P0):** `WhmsLoadOrderDto` / transfer / count’u DEYS emir tipleriyle hizalı tek `WhmsOrder` modeline çıkarın (tip, satırlar, lokasyon, ONAY, terminal_user).  
2. **Lokasyon master (P0):** Ambar altında `location_code` (koridor/raf/göz); mal kabul ve sayım DTO’larına zorunlu/opsiyonel alan.  
3. **FIFO/FEFO kural motoru (P0):** Ürün bazlı gün + SKT; yükleme/sevk consume’da engelle veya uyarı (DEYS “fifo gün tanımları” parity).  
4. **Cihaz + terminal yetki (P1):** MAC/cihaz kimliği + rol; permission_groups ile depo menü bayrakları.  
5. **Etiket / dara (P2):** Merkez etiket şablonu sonra; önce barkod yazdırma kuyruğu + paket tipi kodları (Logo birim/paket ile map).

---

## 7. Kaynak URL’ler

| URL | Ne için |
|-----|---------|
| https://www.logo.com.tr/logo-ekosistem-cozumleri/deys | Resmi Logo ekosistem DEYS sayfası |
| https://www.logo.com.tr/en/logo-ecosystem-solutions/deys | İngilizce özet |
| https://prolog.com.tr/deys/ | Geliştirici (Prolog) ürün sayfası — modüller |
| https://store2.logo.com.tr/product/tiger-plus-deys-depo-yonetim-sistemi | Logo Store Tiger 3 DEYS |
| https://www.kontrolyazilim.com.tr/urun/deys/ | Bayi teknik özellik + fiyat (2023) |
| https://www.kontrolyazilim.com.tr/prolog-depo-yonetim-sistemi/ | Emir çalışma prensibi özeti |
| http://pronic.com.tr/deys/ | Bayi/partner özeti + referans listesi |
| https://www.logo.com.tr/kategori/wms-depo-yonetim-sistemi | Logo WMS / WMS Platform (kardeş ürün ailesi) |
| https://cdn.logo.com.tr/files/logocomtr/Uploads/Documents/logo-wms-platform-tan%C4%B1t%C4%B1m-bro%C5%9F%C3%BCr%C3%BC-tr.pdf | Logo WMS Platform broşür (FIFO/FEFO, araç planlama) |
| https://www.smartbth.com/logo-wms/ | Logo WMS bayi özeti |

**İç repo:**

- `docs/plans/2026-07-26-whms-integration-prep.md`  
- `docs/contracts/whms-bridge.md`  
- `docs/contracts/whms-postgres-warehouses.md`  
- `lib/modules/whms/`  

---

## 8. Spekülasyon / doğrulanmayanlar

- Ekran görüntüsündeki build’in kesin ürün adı string’i (pencere başlığı kısmi) — DEYS olduğu **yüksek olasılık**, sürüm numarası **doğrulanmadı**.  
- “Araç Tanımları”nın forklift / sevkiyat kamyonu / plasiyer van ayrımı — **doğrulanmadı**.  
- Emirler alt menü listesinin birebir ekran eşlemesi — **doğrulanmadı** (web emir tipleriyle tahmin).  
- Güncel liste fiyatı — Store/bayi rakamları tarihli; teklif alınmadan kullanılmamalı.  
- Prolog sitesindeki bazı dashboard paragrafları (erişim sırasında) alakasız içerik enjekte görünümü — istatistik iddialarına güven **düşük**.

---

## 9. Ajan paneli (OPS kuralı — araştırma çıktısı)

| Rol | Durum | Risk | TODO |
|-----|--------|------|------|
| Merkez | Hazır (araştırma) | Spekülasyon karışması | Emir DTO genişletme kararı |
| Saha satış | Hazır | Van vs merkez araç karışması | Domain sınırı notunu WHMS planına ekle |
| Dil | Eksik | — | Uygulama yok; key yok |
| Tester | Hazır | — | Gap maddeleri için acceptance checklist taslağı |
| Yazılım/mobil | Hazır | REST canlı yok | P0 lokasyon + FIFO tasarım spike |
| UI | No-touch | — | Canvas/md only; uygulama UI yok |

```text
❌ BAD: DEYS Windows UI’ını EXFINOPS’a birebir kopyalamak
✅ GOOD: Emir + lokasyon + FIFO sözleşmesini WHMS bridge’e almak; OPS menüsünü ayrı tutmak
```

---

## 10. Derin araştırma eki (2026-07-28 — tur 2)

**İlgili blueprint:** [`2026-07-28-ops-complete-wms-blueprint.md`](./2026-07-28-ops-complete-wms-blueprint.md)

### 10.1 Genişletilmiş özellik listesi (web — doğrulandı)

| Özellik | Kaynak | Not |
|---------|--------|-----|
| Sipariş toplama / rota ile toplama | ata-destek, debisoft, kontrolyazilim | Sevk öncesi pick |
| Toplu sipariş hazırlama + aşamalı paketleme | ata-destek | e-ticaret depo |
| GS1-128 / EAN / karekod / seri | debisoft, ata-destek | Etiket + okuma |
| Mal kabul sonrası lokasyon zorunluluğu (parametre) | Prolog / ata-destek | Putaway benzeri |
| Çoklu terminal online sayım + karşılaştırma | Prolog / ata-destek | Stok+seri fark ekranı |
| Ardışık seri aralığı (ilk–son barkod) | ata-destek | Satınalma |
| Laser start/stop SDK etkileşimi | ata-destek | Windows CE/Mobile + Android |
| FIFO: ürün bazlı gün; serili takip şartı | ata-destek | FEFO ekran menüde |
| Emir dashboard + grafik KPI | Prolog | Performans izleme |
| Etiket tasarım (ürün + raf) | debisoft | Sınırsız tasarım iddiası |
| REST + native Android (DEYS DROID) | debisoft / kontrol | 3G/4.5G |
| Windows CE / Mobile legacy | ata-destek | Eski terminal |
| Emir oluşturma yetkisi terminale verilebilir | kontrolyazilim | Parametre |

### 10.2 Emir yaşam döngüsü (kaynak modeli)

```text
Yönetici emir oluşturur
  → (opsiyonel) kullanıcıya / terminale ata
  → Terminal barkod okutarak yürütür
  → Emir tamamlanır / yöneticiye döner
  → Logo stok/fiş anlık yansır
```

Kaynak: kontrolyazilim.com.tr/prolog-depo-yonetim-sistemi — **doğrulandı (pazarlama)**.  
Yerleştirme (putaway) ayrı emir tipi olarak adı geçmez; mal kabul + lokasyon okutma ile sağlanır — **doğrulanmadı: ayrı “yerleştirme emri” ekranı**.

### 10.3 YouTube kaynakları

**Bulgu:** “DEYS” / “Prolog DEYS” aramasında **herkese açık, indekslenmiş DEYS markalı demo videosu** güvenilir şekilde bulunamadı (YouTube sonuç sayfaları JS; WebSearch müzik/Prolog dil gürültüsü). Aşağıdaki liste: **Logo WMS / Logo ERP depo** süreç videoları + arama URL’leri (DEYS parity için süreç referansı). Transcript = WebSearch snippet’ten; tam video izlenmedi.

| # | URL | Ne öğretir | Kanıt tipi |
|---|-----|------------|------------|
| 1 | https://www.youtube.com/watch?v=fx44kF2cnfE | Logo WMS ürün toplama: seri listeden seç vs zorunlu okutma parametresi (v1.56) | Başlık + transcript snippet |
| 2 | https://www.youtube.com/watch?v=TBqEpy-MedE | Logo WMS ↔ Tiger: ilaç/tıbbi cihaz geliştirmeleri | Başlık (transcript sayfada yok) |
| 3 | https://www.youtube.com/watch?v=OmtE6cB8f6U | Sarf fişlerinde seri/lot SKT’ye göre çıkış durdurma parametreleri (FEFO benzeri) | Başlık + açıklama |
| 4 | https://www.youtube.com/watch?v=EelVhGvFcds | GO3/Tiger3 ambar sayım: Excel aktarım, sayım fazlası fişi | Transcript snippet |
| 5 | https://www.youtube.com/watch?v=1tSIFukIzL4 | Sevk satırlarında sipariş bağlantısı / kalan miktar takibi | Başlık + açıklama |
| 6 | https://www.youtube.com/watch?v=d1wLNiPoQfQ | Talep fişi karşılama türü (satınalma / ambar transfer) öndeğer | Transcript snippet |
| 7 | https://www.youtube.com/user/logoyazilim | Logo resmi kanal — WMS/ERP eğitim keşfi | Kanal |
| 8 | https://www.youtube.com/results?search_query=DEYS+depo+y%C3%B6netim | DEYS arama sonuçları (indeks boş/gürültülü — **doğrulanmadı**) | Arama URL |
| 9 | https://www.youtube.com/results?search_query=Prolog+Yaz%C4%B1l%C4%B1m+DEYS | Prolog DEYS arama | Arama URL |
| 10 | https://www.youtube.com/results?search_query=Logo+WMS+el+terminali | Logo WMS terminal videoları | Arama URL |

**OPS çıkarımı (YouTube + web):** Terminalde seri okutmaya zorlama, SKT/FEFO çıkış engeli, çoklu kullanıcı toplama, sayım fark fişi — EXFINOPS WHMS P0–P1 checklist’ine alındı.

### 10.4 EXFINOPS kod taraması (somut yollar)

| Alan | Dosya / tablo | Olgunluk |
|------|---------------|----------|
| WHMS shell | `lib/modules/whms/view/whms_shell_screen.dart` | İskelet |
| DTO | `lib/modules/whms/contract/whms_bridge_dto.dart` | Load/Transfer/Count |
| Transfer kuyruk | `lib/modules/whms/queue/whms_transfer_queue_bridge.dart` | ONAY=1 |
| Load consume | `lib/modules/whms/engine/whms_load_order_consumer.dart` | → araç |
| Bakiye | `logo_stock_balance_port.dart` / `local_*` | Var |
| Route map | `whms_route_map.dart` | OPS stub ↔ /whms |
| Ambar master | `warehouse_master_store.dart` + `warehouses` DDL | MRK/ARC/IAD |
| Transfer txn | `warehouse_transfer_stock_txn.dart` | Var |
| Sayım OPS | `stock_count_service.dart` + `stock_counts` | Yerel+queue |
| Parti/SKT | `batch_expiry_store.dart` + `batch_expiry` | Seed/list; motor yok |
| Araç stok | `vehicles/*` + `vehicle_stocks` | Saha van |
| Inventory placeholder | `inventory/view/warehouse_management_screen.dart` | Boş |
| Job queue | `service/job_queue_service.dart` | Genel |

### 10.5 Ek web kaynakları (tur 2)

- https://www.atadestek.com/icerik/depo-yonetim-yazilimi---deys  
- https://www.debisoft.net/ekosistem-cozumleri/depo-yonetimi-210.aspx.html  
- https://www.logo.com.tr/urun/logo-wms  
- https://www.logo.com.tr/urun/logo-wms-platform  
- https://www.emabilgisayar.com/post/depo-yönetim-otomasyonunda-verimli-stok-takibi  
