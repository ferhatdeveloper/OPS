# AI Dinamik Rapor + Görsel Raf/Rakip Fiyat

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Yetkili kullanıcı doğal dilde rapor ister; AI **PostgREST query spec** üretir (ham SQL yok). Tek fotoğraftan raf/rakip fiyat OCR+vision → yerel katalog fuzzy eşleme.

**Architecture:** `AiGateway.proposeReport` / `visionAnalyze` → allowlist sanitize → kullanıcı onayı → yerel tanım + PostgREST GET. Merkez yazma yok.

**Tech Stack:** Flutter, AiGateway, PostgREST (`PostgrestHttpClient`), SQLite offline, image_picker, dens UI, l10n.

---

## Güvenlik (zorunlu)

| Kural | Açıklama |
|-------|----------|
| **Ham SQL yasak** | AI çıktısı `db.execute(sql)` / Postgres raw SQL ile **asla** çalıştırılmaz. |
| **PostgREST only** | Merkez veri: `GET /{table}?select=...&col=eq.x&order=...&limit=` — uygulama client çalıştırır. |
| **Allowlist** | Tablo / kolon / filter op / rpc yalnızca whitelist. |
| **rpc** | Sadece allowlist’te **ve** read-only ise. |
| **Onay** | AI önerir → kullanıcı onaylar → sonra persist. |
| **Gizlilik** | Görüntü / API key log’a yazılmaz. |

### AI çıktısı (JSON)

```json
{
  "title": "Cari bakiyeler",
  "titleKey": "field_sales.ai_reports.custom.cari_bakiye",
  "query": {
    "table": "customers",
    "select": ["code", "name", "balance"],
    "filters": [{"column": "is_active", "op": "eq", "value": "1"}],
    "order": "name.asc",
    "limit": 200
  },
  "columns": [
    {"id": "code", "labelKey": "code"},
    {"id": "name", "labelKey": "name"},
    {"id": "balance", "labelKey": "balance", "numeric": true}
  ]
}
```

Uygulama: `PostgrestQuerySanitizer` → `PostgrestQueryRunner.run(spec)` → `PostgrestHttpClient.getRows`.

Offline / merkez yok: l10n (`ai_reports.center_unavailable`); yerel SQLite yalnız aynı allowlist ile `db.query(table, columns, where, whereArgs)` — serbest SQL string yok.

---

### Task 1: AiUseCase + Gateway

**Files:**
- Modify: `lib/core/ai/ai_use_case.dart`
- Modify: `lib/core/ai/ai_chat_message.dart` (opsiyonel image)
- Modify: `lib/core/ai/ai_gateway.dart` — `proposeReport`, `visionAnalyze`
- Modify: OpenAI / Gemini clients multimodal

### Task 2: PostgREST query spec + sanitize + runner

**Files:**
- Create: `lib/core/ai/features/postgrest_query_*.dart`
- Create: `lib/core/ai/features/ai_report_proposal_service.dart`
- Test: `test/core/ai/postgrest_query_sanitizer_test.dart`

### Task 3: Yerel rapor tanımı + dens UI + menü

**Files:**
- `lib/modules/field_sales/ai_reports/`
- SqlQuerys `ai_dynamic_reports`
- `ensureAiDynamicReportMenuItems` → `fs_reports` + favorites
- Routes `/field-sales/ai-reports`
- Yetki: menü `can_view` + admin/supervisor; seed admin full

### Task 4: Vision rakip fiyat

**Files:**
- `lib/modules/field_sales/ai_vision_competitor/`
- Fuzzy match + price parse unit tests
- Route `/field-sales/competitor-shelf-vision`
- Opsiyonel kayıt → mevcut `competitor_products` / observations

### Task 5: l10n + canvas

- `tr.json` + translation_sync
- `OPS-paralel-is-durum.canvas.tsx` → Tamamlandı

**Commit:** yok (bilinçli)
