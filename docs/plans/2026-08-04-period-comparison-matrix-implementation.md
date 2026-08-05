# Esnek Dönem Karşılaştırma Matrisi Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Dönem Karşılaştırma ekranını 4 adımlı esnek matris sihirbazına çevirmek (çoklu firma/dönem, ürün/müşteri/tedarikçi/plasiyer/bölge/marka eksenleri, grafik, PDF önizle+paylaş).

**Architecture:** Sihirbaz state Riverpod Notifier’da; `CompareMatrixRepository` SQLite’tan matris agrege eder; sonuç dens UI + fl_chart; PDF `pdf` + mevcut viewer + `share_plus`. Mevcut A/B preset `period_overview` şablonu olarak korunur.

**Tech Stack:** Flutter, Riverpod, SQLite (sqflite), fl_chart, pdf, share_plus, easy_localization / AppLocalization

**Design:** `docs/plans/2026-08-04-period-comparison-matrix-design.md`

**Skills:** @flutter-saha-satis, @flutter-testing-expert, @automatic-translation, dens-minimal-ui, ui-no-touch

---

### Task 1: Domain modelleri (eksen / şablon / state)

**Files:**
- Create: `lib/modules/manager/reports/model/compare_matrix_models.dart`
- Test: `test/modules/manager/reports/compare_matrix_models_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/manager/reports/model/compare_matrix_models.dart';
import 'package:exfin_ops/modules/manager/reports/model/period_comparison_models.dart';

void main() {
  test('template periodOverview maps axes to global×period', () {
    final s = ComparisonWizardState.fromTemplate(CompareTemplate.periodOverview);
    expect(s.rowAxis, CompareAxis.none); // veya special: none
    expect(s.columnAxis, CompareAxis.period);
    expect(s.periods.length, 2);
  });

  test('periods cannot exceed 6', () {
    final base = ComparisonWizardState.fromTemplate(CompareTemplate.productPeriod);
    final many = List.generate(
      7,
      (i) => ComparePeriodSlot(
        id: '$i',
        label: 'P$i',
        range: PeriodDateRange(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 1, 31),
        ),
      ),
    );
    expect(() => base.copyWith(periods: many), throwsA(isA<ArgumentError>()));
    // veya copyWith clamp: periods.length == 6
  });

  test('same row and column axis is invalid', () {
    final s = ComparisonWizardState.fromTemplate(CompareTemplate.custom).copyWith(
      rowAxis: CompareAxis.product,
      columnAxis: CompareAxis.product,
    );
    expect(s.isAxesValid, isFalse);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/modules/manager/reports/compare_matrix_models_test.dart`  
Expected: FAIL (library not found)

**Step 3: Write minimal implementation**

`compare_matrix_models.dart`:
- `CompareAxis` enum: `none, period, company, product, customer, supplier, salesman, region, productGroup, brand`
- `CompareTemplate` enum + `ComparisonWizardState.fromTemplate`
- `ComparePeriodSlot`, `ComparisonWizardState` (step 0–3, lists, topN, primaryMetric)
- `isAxesValid`, `copyWith` with period max 6 clamp/assert
- `CompareMatrixCell`, `CompareMatrixResult`
- File header TR docblock

**Step 4: Run tests — PASS**

**Step 5: Commit** (sadece kullanıcı isterse)

```bash
git add lib/modules/manager/reports/model/compare_matrix_models.dart \
  test/modules/manager/reports/compare_matrix_models_test.dart
git commit -m "feat(reports): compare matrix domain models"
```

---

### Task 2: Wizard Notifier provider

**Files:**
- Create: `lib/modules/manager/reports/viewmodel/comparison_wizard_provider.dart`
- Modify: mevcut `period_comparison_provider.dart` ile köprü veya deprecate selection → wizard
- Test: `test/modules/manager/reports/comparison_wizard_provider_test.dart`

**Step 1: Failing test**

```dart
test('applyTemplate productPeriod sets axes and resets to step 0', () {
  final n = ComparisonWizardNotifier();
  n.applyTemplate(CompareTemplate.productPeriod);
  expect(n.state.rowAxis, CompareAxis.product);
  expect(n.state.columnAxis, CompareAxis.period);
  expect(n.state.step, 0);
});

test('nextStep blocked when axes invalid on step 1', () {
  final n = ComparisonWizardNotifier();
  n.applyTemplate(CompareTemplate.custom);
  n.state = n.state.copyWith(
    rowAxis: CompareAxis.product,
    columnAxis: CompareAxis.product,
  );
  n.nextStep();
  expect(n.state.step, 1);
});
```

**Step 2–4:** `Notifier` + `comparisonWizardProvider`; metodlar: `applyTemplate`, `nextStep`, `prevStep`, `setAxis`, `setPeriods`, `setCompanies`, `setEntityIds`, `setTopN`, `setPrimaryMetric`.

**Note:** Mevcut `periodCompareSelectionProvider` adım 3 dönem preset’ine map edilebilir (geriye dönük test için).

---

### Task 3: Matrix repository — period overview (mevcut A/B)

**Files:**
- Create: `lib/modules/manager/reports/viewmodel/compare_matrix_repository.dart`
- Test: `test/modules/manager/reports/compare_matrix_repository_test.dart`
- Keep: `period_comparison_repository.dart` (delegate veya dual)

**Step 1: Memory DB fixture** (mevcut `period_comparison_repository_test` pattern)

```dart
test('periodOverview returns 2 columns and summary metrics', () async {
  final db = await openMemoryDbWithInvoices();
  final repo = CompareMatrixRepository();
  final query = ComparisonWizardState.fromTemplate(CompareTemplate.periodOverview);
  final result = await repo.fetchMatrix(db, query);
  expect(result.colKeys.length, 2);
  expect(result.summaryMetrics, isNotEmpty);
});
```

**Step 2–4:** `fetchMatrix` first implement only `periodOverview` / `columnAxis==period && rowAxis==none` path by wrapping `PeriodComparisonRepository.fetch`.

---

### Task 4: Matrix repository — product × period + TOP-N

**Files:**
- Modify: `compare_matrix_repository.dart`
- Test: aynı test dosyası

**SQL sketch:**

```sql
SELECT l.product_id AS row_key,
       COALESCE(p.name, l.product_id) AS row_label,
       COALESCE(SUM(l.amount), 0) AS value
FROM invoice_lines l
JOIN invoices i ON i.id = l.invoice_id
WHERE date(...) BETWEEN ? AND ?
  AND (? empty OR i.company_id IN (...))
GROUP BY row_key
ORDER BY value DESC
LIMIT ?
```

Period’lar için her col ayrı query veya CASE/UNION. safeQuery.

**Test:** 2 ürün, 2 dönem → 2×2 cells; topN=1 → 1 satır.

---

### Task 5: customer / company axes

**Files:** `compare_matrix_repository.dart` + tests

- `customer` group by `customer_id`
- `company` group by `company_id`
- Company filter applied to all

---

### Task 6: supplier / salesman / region / brand / productGroup

**Files:** repository + tests (schema missing → empty matrix, no throw)

- Probe column existence once per DB session if needed
- Document required columns in design

---

### Task 7: Wizard UI shell (steps 1–3 dens)

**Files:**
- Modify: `lib/modules/manager/reports/view/period_comparison_report.dart`
- Create:
  - `widgets/compare_wizard_step_indicator.dart`
  - `widgets/compare_template_step.dart`
  - `widgets/compare_axis_step.dart`
  - `widgets/compare_filter_step.dart`

**UI rules:**
- `FieldSalesDensAppBar` title l10n
- Step indicator dens (1–4)
- Chip row for templates
- Step 3: period list max 6 + multi-select bottomsheets
- İleri/Geri alt dens CTA (~40h)

**Do NOT:** new colors/gradients; redesign metric cards chrome.

**Widget test:** template tap advances axes; next disabled when invalid.

---

### Task 8: Result step — graphs + pivot

**Files:**
- Create: `widgets/compare_result_step.dart`
- Create: `widgets/compare_grouped_bar_chart.dart`
- Create: `widgets/compare_line_chart.dart`
- Create: `widgets/compare_matrix_pivot.dart`
- Reuse: `period_comparison_chart.dart` for periodOverview KPI

**Step result body:**
1. Caption chips
2. `summaryMetrics` cards/table
3. Grouped bar if cols ≤ 6
4. Line optional toggle chip
5. Pivot table horizontal scroll
6. Heatmap optional Fase P3 — skip if time

**Provider:** `compareMatrixResultProvider` watches wizard + fetches when step==3.

---

### Task 9: PDF builder + AppBar share

**Files:**
- Create: `lib/modules/manager/reports/service/compare_pdf_builder.dart`
- Modify: result step / AppBar actions
- Test: `test/modules/manager/reports/compare_pdf_builder_test.dart`

**Flow:**
1. Build PDF (title, template, ranges, pivot rows, KPIs)
2. Write temp file
3. Navigate to / open `ReportPdfViewerScreen`
4. Share via `Share.shareXFiles`

Pattern: `customer_reconciliation_screen.dart` PDF + share.

**Test:** `builder.build(...)` returns non-empty `Uint8List`.

---

### Task 10: l10n keys (TR + all langs)

**Files:**
- Modify: `assets/translations/tr.json` (`advanced` section)
- Run automatic-translation skill for: en, de, ar, ar-iq, ku, fa, ru, es, fr, zh

**Keys (örnek):**
- `advanced.compare_step_template` … `compare_step_result`
- `advanced.template_period_overview` … `template_custom`
- `advanced.axis_product`, `axis_customer`, …
- `advanced.compare_pdf`, `compare_share`, `compare_top_n`
- `advanced.compare_schema_missing`

No hardcoded strings in wizard UI.

**Test:** parse all json files (existing l10n parse test if any).

---

### Task 11: Regression + documentation

**Commands:**

```bash
flutter test test/modules/manager/reports/
flutter analyze lib/modules/manager/reports/
```

**Update:**
- Design doc status if needed
- Keep route `/field-sales/period-comparison`
- Menu title unchanged (l10n `period_comparison`)

**Manual QA checklist:**
- [ ] period_overview ≈ old A/B behavior
- [ ] product×period 3 dilim
- [ ] multi company filter
- [ ] PDF önizle + paylaş
- [ ] RTL: chip/row direction
- [ ] Empty data

---

## Execution Handoff

Plan hazır. Seçenekler:

1. **Bu oturumda uygula** — Task 1’den başla (TDD sırası, P0→P2)
2. **Başka oturumda** — `executing-plans` skill ile task-by-task
3. **Sadece P0** — model + wizard shell + periodOverview (hızlı görünür ilerleme)

İstersen “uygula” veya “sadece P0” yaz; commit yalnızca sen isterse atılır.
