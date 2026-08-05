# Dönem Karşılaştırma — Esnek Matris Sihirbazı Tasarımı

**Tarih:** 2026-08-04  
**Geliştirici:** Ferhat NAS  
**Durum:** Onaylandı (brainstorming)  
**Rota (mevcut):** `/field-sales/period-comparison`  
**Modül:** `lib/modules/manager/reports/`

---

## 1. Amaç

Mevcut A/B dönem karşılaştırma ekranını, yöneticinin **şablon + eksen + filtre** ile
çok boyutlu analiz yapabileceği bir **4 adımlı sihirbaz**a dönüştürmek.

Kullanıcı:

- 1+ firma seçebilir (filtre ve matris ekseni)
- En fazla **6 dönem/sütun** kıyaslayabilir
- Satır/sütun ekseni seçer: dönem, firma, ürün, müşteri, tedarikçi, plasiyer,
  bölge, ürün grubu, marka
- Sonuçları grafik + pivot tablo + metrik ile görür
- PDF üretir → önizler → paylaşır

---

## 2. Karar Özeti

| Karar | Değer |
|-------|--------|
| Mimari yaklaşım | **A — Adım adım sihirbaz** |
| Birincil model | Esnek matris (eksen seçimi + şablonlar) |
| Dönem sütunu | Max **6** |
| Firma | Hem filtre hem matris ekseni |
| Boyut seti | Full OPS (core + plasiyer + bölge + ürün grubu/marka) |
| PDF | Oluştur → `ReportPdfViewerScreen` → paylaş |
| UI | Dens (`FieldSalesDensAppBar` / chip); renk redesign yok (`ui-no-touch`) |
| Veri | Offline-first SQLite; tablo yoksa graceful 0 / empty |

---

## 3. Sihirbaz Akışı

```text
[1 Şablon] → [2 Eksen] → [3 Filtre & Dönemler] → [4 Sonuç]
     ↑______________ Geri / state korunur ______________|
```

### Adım 1 — Şablon

| ID | Satır × Sütun | Dönem sayısı (varsayılan) |
|----|---------------|---------------------------|
| `period_overview` | — (global KPI) × Dönem | 2 (A/B, mevcut davranış) |
| `company_period` | Firma × Dönem | 2–6 |
| `product_period` | Ürün × Dönem | 2–6 |
| `customer_period` | Müşteri × Dönem | 2–6 |
| `supplier_period` | Tedarikçi × Dönem | 2–6 |
| `salesman_period` | Plasiyer × Dönem | 2–6 |
| `brand_category` | Marka/Kategori × Dönem | 2–6 |
| `region_period` | Bölge × Dönem | 2–6 |
| `custom` | Kullanıcı seçer | 2–6 |

Şablon seçilince satır/sütun preset dolar; `custom` adım 2’yi açık tutar.

### Adım 2 — Eksen

- **Satır boyutu** (`CompareAxis`)
- **Sütun boyutu** (pratikte çoğu şablonda `period`; firma×ürün vb. de geçerli)
- Aynı eksen satır ve sütunda seçilemez (validation)
- `period` sütunda ise dönem sayısı 2–6

### Adım 3 — Filtre & Dönemler

**Firma (çoklu):**
- Boş = yetkili tüm firmalar (toplam / context)
- 1+ seçili = filtre; satır ekseni firma ise seçilenler satır olur

**Dönemler (max 6):**
- Hızlı ekleme: Bu ay, Geçen ay, Bu hafta, Bu yıl, Geçen yıl aynı dönem, özel aralık
- Liste düzenle/sil; min 2 dönem (veya sütun ≠ period ise tek dönem yeter — o zaman zaman filtresi 1 aralık)

**Diğer boyut çoklu seçim (opsiyonel):**
- Ürün, müşteri, tedarikçi, plasiyer, bölge, ürün grubu, marka
- Boş + satırda o boyut = TOP-N (varsayılan 15, ayarlanabilir 5/10/15/25)
- Dolu = yalnızca seçilen varlıklar

### Adım 4 — Sonuç

1. Özet şeridi: şablon adı, eksen, dönem aralıkları, aktif filtreler (chip)
2. KPI strip (global/seçili metrikler)
3. Grafikler (aşağıda)
4. Yatay kaydırmalı dens pivot tablo
5. AppBar: PDF + paylaş; pull-to-refresh; AI insight (mevcut banner reuse, satır map)

---

## 4. Domain Modeli

Konum: `lib/modules/manager/reports/model/`

```dart
/// Matris eksenleri
enum CompareAxis {
  period,
  company,
  product,
  customer,
  supplier,
  salesman,
  region,
  productGroup,
  brand,
}

/// Şablon kimlikleri
enum CompareTemplate {
  periodOverview,
  companyPeriod,
  productPeriod,
  customerPeriod,
  supplierPeriod,
  salesmanPeriod,
  brandCategory,
  regionPeriod,
  custom,
}

/// Tek dönem dilimi (A…F)
class ComparePeriodSlot {
  final String id;        // uuid / local
  final String label;     // "Bu Ay", özel isim
  final PeriodDateRange range;
}

/// Sihirbaz state (Riverpod Notifier)
class ComparisonWizardState {
  final int step; // 0..3
  final CompareTemplate template;
  final CompareAxis rowAxis;
  final CompareAxis columnAxis;
  final List<ComparePeriodSlot> periods; // ≤6
  final List<String> companyIds;
  final List<String> productIds;
  final List<String> customerIds;
  final List<String> supplierIds;
  final List<String> salesmanIds;
  final List<String> regionIds;
  final List<String> productGroupIds;
  final List<String> brandIds;
  final int topN;
  final PeriodMetricKind primaryMetric; // grafik vurgusu
}

/// Sonuç hücresi
class CompareMatrixCell {
  final String rowKey;
  final String colKey;
  final double value;
}

/// Matris sonucu
class CompareMatrixResult {
  final ComparisonWizardState query;
  final List<String> rowKeys;
  final List<String> rowLabels;
  final List<String> colKeys;
  final List<String> colLabels;
  final List<CompareMatrixCell> cells;
  final List<PeriodMetricRow> summaryMetrics; // KPI
}
```

Mevcut `PeriodDateRange`, `PeriodMetricKind`, `PeriodMetricRow` korunur/reuse edilir.

---

## 5. Veri Katmanı

### 5.1 Repository

**Dosya:** `period_comparison_repository.dart` (genişlet) veya  
`compare_matrix_repository.dart` (önerilen ayırım — mevcut A/B testleri bozulmasın).

```text
fetchMatrix(Database db, ComparisonWizardState query)
  → CompareMatrixResult
```

- Dönem dilimleri için her (satır_key, col_key) hücresi
- Metrik: varsayılan **satış tutarı**; kullanıcı primaryMetric ile sipariş/tahsilat seçebilir
- `summaryMetrics`: dönem 1 vs dönem N (veya ilk iki dilim) A/B özeti (eski davranış)

### 5.2 SQL stratejisi

| Boyut | Kaynak (var olan / güvenli) |
|-------|-----------------------------|
| Dönem | `invoice_date` / `order_date` / `collection_date` / `check_in_at` aralık |
| Firma | `company_id` / `firm_nr` kolonları (yoksa filtre atlanır) |
| Ürün | invoice/order lines → `product_id` / `item_code` |
| Müşteri | `customer_id` |
| Tedarikçi | satın alma / supplier alanları; yoksa empty + UI mesaj |
| Plasiyer | `salesman_code` / `user_id` |
| Bölge | customer region / route bölgesi (schema-dependent) |
| Marka / grup | product master alanları |

`_safeQuery` pattern korunur; tablo/kolon yoksa 0 satır.

### 5.3 Performans

- TOP-N satır öncesi: aralıkta agregasyon → sort → limit
- Max 6 × 25 hücre burketi (sınır 150 hücre)
- Loading skeleton dens

---

## 6. UI Bileşenleri

| Widget | Görev |
|--------|--------|
| `PeriodComparisonReportScreen` | Sihirbaz shell (step + AppBar) |
| `CompareWizardStepIndicator` | Dens 1–4 adım |
| `CompareTemplateGrid` | Adım 1 kart/chips |
| `CompareAxisPickers` | Adım 2 |
| `CompareFilterStep` | Adım 3 multi-select + dönem listesi |
| `CompareResultStep` | Adım 4 |
| `CompareGroupedBarChart` | fl_chart gruplu bar |
| `CompareLineChart` | çok seri çizgi |
| `CompareHeatmapTable` | pivot renk skalası |
| `CompareMatrixPivot` | dens tablo |
| `ComparePdfBuilder` | pdf package |
| Multi-select sheets | Mevcut firma/müşteri picker pattern reuse |

**UI kuralları:** `FieldSalesDensAppBar`, `FieldSalesDensChip*`, dens padding; gradient redesign yok.

---

## 7. PDF

1. `ComparePdfBuilder.build(result, l10n)` → `Uint8List`
2. Temp dosya + `ReportPdfViewerScreen` (mevcut rota)
3. Share: `Share.shareXFiles` (mutabakat pattern)
4. İçerik: kapak (başlık, şablon, dönemler, filtreler, tarih), KPI, tablo, metrik özeti
5. Grafik: PDF’te tablo + sade bar temsili (opsiyonel; MVP’de tablo öncelikli)

---

## 8. State (Riverpod)

```text
comparisonWizardProvider → NotifierProvider<WizardNotifier, ComparisonWizardState>
compareMatrixResultProvider → FutureProvider.autoDispose (step==3 iken fetch)
```

Adımlar state içinde; Geri/İleri notifier metodları (`nextStep`, `prevStep`, `applyTemplate`).

---

## 9. Lokalizasyon

`advanced.*` altına yeni key’ler (`tr.json` kaynak):

- Sihirbaz adımları, şablon adları/açıklamaları
- Eksen adları, empty states, TOP-N, PDF başlıkları
- Hata: `period_compare_error`, tedarikçi/şema yok uyarıları

Sonra automatic-translation skill ile diğer diller.

Hardcoded UI metin yok.

---

## 10. Test Stratejisi

| Katman | Kapsam |
|--------|--------|
| Unit | Template → axis mapping; max 6 period guard; pctChange reuse; matrix pivot builder |
| Unit | Repository memory SQLite fixture (invoices/lines/products) |
| Widget | Step indicator; template apply; axis validation; empty state |
| PDF | Builder non-empty bytes (golden opsiyonel) |

Mevcut `period_comparison_*_test` regresyonu korunur.

---

## 11. Riskler

| Risk | Azaltma |
|------|---------|
| Schema sapması (tedarikçi/bölge/marka) | safeQuery + empty row + l10n mesaj |
| Performans (büyük invoice) | TOP-N + tarih indeksi filtre; max hücre |
| UI şişkinlik | Sihirbaz adımları; sonuç scroll dens |
| ui-no-touch ihlali | Dens reuse; yeni renk/tema yok |
| Eski A/B kullanıcı | `period_overview` şablonu = eski deneyim |

---

## 12. Fazlama (uygulama)

| Faz | İçerik |
|-----|--------|
| **P0** | Model + wizard state + period_overview (mevcut A/B) gömülü + adım UI |
| **P1** | company/product/customer matris + grafik + TOP-N |
| **P2** | supplier/salesman/region/brand + PDF + share |
| **P3** | Heatmap + AI map + l10n all langs |

---

## 13. Onay

- Yaklaşım A (sihirbaz): ✓  
- Bölüm 1 (akış/şablon): ✓  
- Bölüm 2 (veri/grafik/PDF): ✓  

**Sonraki adım:** `docs/plans/2026-08-04-period-comparison-matrix-implementation.md`
