# MBT Rapor Adı ↔ İçerik Uyum Denetimi

**Tarih:** 2026-07-27  
**Kapsam:** Katalog 74 id · `MbtReportDataService` + cari/stok/documents/other query · layout defaults  
**Ölçüt:** Boş SQLite “doğru sorgu, veri yok” sayılır; yanlış/ortak sorgu “uyumsuz/kısmen”.

## Özet

| Verdict | Adet | % |
|---------|-----:|--:|
| **uyumlu** | 49 | 66% |
| **kısmen** | 25 | 34% |
| **uyumsuz** | 0 | 0% |
| **boş fallback** | 0 | 0% |
| **Toplam** | **74** | 100% |

**Sonuç:** Dört net uyumsuz rapor (liderlik / dönem karşılaştırma / hedef / rota) ayrı sorgu+layout ile düzeltildi. ~%34 hâlâ paylaşımlı/jenerik (aynı ziyaret listesi, aynı 3 satır KPI).

## Dispatch haritası

| Öncelik | Sahip | Id kapsamı |
|--------:|-------|------------|
| 1 | `OtherReportQueryService` | DİĞER core + plasiyer/yönetici/finans extras |
| 2 | `CariReportQueryService` | 15 CARİ (risk dahil) — **2026-07-27 bağlandı** |
| 3 | `DocumentReportQueryService` | 11 sipariş/fatura/irsaliye |
| 4 | `StockReportQueryService` | 12 stok (+ arac/ops_van/sayım) |
| 5 | `MbtReportDataService` switch | OPS kalan (`ops_*`) |

## Yüksek şiddet — düzeltildi (bu oturum)

| Id | Sorun | Düzeltme |
|----|-------|----------|
| Tüm CARİ | `CariReportQueryService` UI’da vardı; `MbtReportDataService` eski ortak SQL kullanıyordu (`en_cok_alim`≈`en_cok_satis`, `cari_risk`→`[]`) | Dispatch’e cari servis eklendi |
| `yonetici_fatura_alis` | Query `invoice_type = 'Return'` (iade) — alış değil | Purchase/alış taraf filtresi |
| `ops_*` özet | Satırlar `description` · layout `code/title/date/amount` | `_ozet` kolonları layout’a hizalandı |
| `finans_kasa_bakiye` | Layout kasa hareket; sorgu kart listesi | Layout → `_generic` + `amount` alanı |
| `cari_hareket` | Kod/ünvan filtre alanından geliyordu | Satırdaki cari kod/ünvan |
| `ops_sales_report` | Satış/alış ayrımı yoktu | `invoice_type` satış filtresi |

## Uyumsuz → düzeltildi (2026-07-27)

| Id | Başlık beklentisi | Düzeltme |
|----|-------------------|----------|
| `yonetici_leaderboard` | Plasiyer sıralama | `plasiyer_profile` puan / `targets` % sıralama + rank layout |
| `yonetici_period_compare` | Dönem A/B karşılaştırma | Önceki eşit uzunluk vs seçili dönem (previous/current/growth) |
| `ops_target` | Hedef gerçekleşme | `targets` tablo: hedef / gerçekleşen / % |
| `plasiyer_rota` | Rota / mesafe | `routes` + `route_customers` durakları (visit_order/weekday) |

## Kısmen (örnek gruplar)

| Grup | Id’ler | Not |
|------|--------|-----|
| Paylaşımlı ziyaret | `ziyaret_listesi_ozel`, `plasiyer_gunluk`, `plasiyer_ziyaret_ozet` | Aynı `_visits` |
| Jenerik KPI | `plasiyer_performans`, `yonetici_kpi`, `yonetici_firma_genel`, `ops_performance`, `ops_gun_sonu`, `ops_advanced` | 3–5 satır özet; ad farklı |
| Proxy maliyet | `fatura_karlilik` | Satış fatura + ~%15 brüt vekil |
| Sync≈transfer | `finans_transfer_edilen/edilmeyen` | `is_synced` tahsilat |
| Kasa bakiyesi | `finans_kasa_bakiye` | `cash_cards` listesi; bakiye 0.00 sabit |
| GPS | `yakinimdaki_cari_gps`, `gps_konum` | Müşteri lat/lng; orijin yoksa uzaklık boş |
| Stok hareket/sayım | `stok_hareket`, `stok_sayim` | Transfer / sayım fiş başlığı (kalem detay yok) |

## Uyumlu (kategori özeti)

- **CARİ:** ekstire, tahsilat, borç/alacak, ranking (satış/alım ayrı), çek/senet, hareketsiz cari  
- **STOK:** bakiye, envanter, seri/lot, depo×ürün, ranking, araç stok  
- **SİPARİŞ / FATURA / İRSALİYE:** tip + bekleyen + faturasız filtreleri `DocumentReportQueryService`  
- **OPS:** satış / tahsilat / ziyaret / van stok listeleri  
- **YÖNETİCİ belge:** fatura/sipariş satış-alış (alış tipi düzeltildi)

## Dosyalar

- `lib/modules/field_sales/reports/engine/mbt_report_data_service.dart`
- `lib/modules/field_sales/reports/cari/cari_report_query_service.dart`
- `lib/modules/field_sales/reports/other/viewmodel/other_report_query_service.dart`
- `lib/modules/field_sales/reports/model/report_layout_defaults.dart`
- `lib/modules/field_sales/reports/model/mbt_report_catalog.dart`

## Sonraki TODO

1. ~~`finans_kasa_bakiye` gerçek bakiye aggregate~~ (collections cash_code)
2. `fatura_karlilik` gerçek maliyet alanı (ürün/fiş maliyet)
3. ~~`ziyaret_listesi_ozel` / `plasiyer_gunluk` farklı kolon seti~~ (süre / günlük özet / cari özet)
4. ~~`plasiyer_rota` mesafe (orijin → haversine) doldurma~~ (durak arası)
5. ~~Pivot varsayılan görünüm rapor id~~ (`ReportPivotPreferenceStore`)
6. ~~PDF A4 footer VKN + yazdırma + sayfa~~ (`ReportPdfBrand.buildFooter`)
7. ~~Banka/çek/senet Logo sync_queue mapper stub~~ (`CollectionsLogoSyncMapper`)
8. ~~Faturasız irsaliye `invoice_id` PRAGMA + heuristic~~ 
