# AI talep tahmin + tedarik talebi

**Tarih:** 2026-07-28  
**Kapsam:** Offline-first talep/bitiş öngörüsü, AI yorum (onaylı), depo tedarik talebi  
**Commit:** Yapılmadı (istek üzerine)

## Vizyon

Plasiyer / admin / depocunun elinin altında deterministic forecast + isteğe bağlı AI özet.  
**Otomatik sipariş kesilmez** — kullanıcı onaylar.

## Mimari

| Katman | Dosya | Rol |
|--------|-------|-----|
| Engine | `demand_forecast_engine.dart` | Aralık / miktar / trend / bitiş / anomali (%50+) |
| Scope | `salesperson_customer_scope.dart` | Plasiyer: routes.salesperson_id ∪ visits; admin: null |
| Store | `customer_product_consumption_store.dart` | SQLite orders+invoices → forecast |
| AI | `AiGateway` + `AiUseCase.demandForecastInsight` | Opsiyonel özet; key yok → `ai.not_configured` |
| Sipariş | `getSuggestionEnriched` + `OrderAiRecommendationBridge` | Key yoksa yerel reason |
| Uyarı | `ai_insight_notifier.dart` + dens banner (rol + kritik) | In-app dens zorunlu; local notify opsiyonel |
| Depo | `supplier_purchase_requests` + store/UI | draft → ONAY=1 → sync_queue; Aktarılmayan chip |
| Sync | `supply_request_logo_sync_mapper.dart` | Logo stub enqueue; JobQueue is_synced |
| UI | dens AppBar listeler | `ui-no-touch` / dens-minimal-ui |

### Hesap varsayımı

Son sipariş tarihi + ortalama sipariş aralığı ≈ tahmini bitiş.  
Eşik varsayılan **7 gün** → plasiyer/admin uyarı satırı.

### AI

- Prompt’ta yalnızca cari/ürün **kodları** (ünvan yok).
- Key yoksa deterministic liste çalışır; AI kutusu l10n gösterir.

## Menü / route

| Rol | Menü | Route |
|-----|------|-------|
| Plasiyer / admin | Diğer → AI Öngörüler | `/field-sales/ai-insights` |
| Depocu / admin | Stok → Tedarik Talepleri | `/field-sales/supply-requests` |
| — | Yeni talep formu | `/field-sales/supply-requests/new` |

UUID: `sub_oth_ai_insights`, `sub_stk_supply_req`  
Hub: plasiyer `ai_insights`, depocu `supply_request`  
Permission: `ensureAiDemandForecastMenuItems` → admin full + plasiyer/depocu seed merge

## SQLite

```sql
supplier_purchase_requests (
  id, product_id, product_code, product_name, quantity,
  supplier_id, supplier_code, supplier_name, warehouse_code,
  status, notes, ONAY, is_synced, is_deleted, created_by,
  created_at, updated_at
)
```

`ensureSupplierPurchaseRequestsSchema` + menü `ensureAiDemandForecastMenuItems`.

## Test

```bash
flutter test test/modules/field_sales/ai_insights/
flutter test test/modules/admin_panel/permission_group_store_test.dart
```

## Durum / risk

| Madde | Durum |
|-------|--------|
| Engine + unit test | hazır |
| AI Öngörüler dens UI | hazır |
| Plasiyer cari filtresi | hazır |
| Tedarik talep dens UI | hazır |
| ONAY + sync_queue + Aktarılmayan chip | hazır |
| Permission UUID seed merge | hazır |
| Sipariş getSuggestionEnriched | hazır |
| Anomali rozeti + uyarı bandı | hazır |
| l10n (tr + sync) | hazır / sync |
| Logo Objects gerçek REST | bilinçli ertelendi (stub) |

**Risk:** Az sipariş geçmişinde aralık gürültülü; tek olayda 30g fallback.  
**Risk:** Rota atanmamış plasiyer → boş liste (bilinçli).

## Faz 3 (bilinçli ertele)

- Canlı WHMS REST, parti/SKT, konsinye, üretim
- PostgREST permission_groups remote sync
- OS keychain migration for AI keys
- Logo satın alma Objects gerçek aktarım (şimdilik sync_queue stub)

## Alt işler (panel)

1. **Engine** — deterministic hesap + anomali + test  
2. **UI** — AI Öngörüler dens + uyarı bandı (rol)  
3. **Depo talep** — tablo + liste/form + ONAY + sync_queue  
4. **l10n** — tr + tüm diller  
5. **Permission** — seed merge UUID  
