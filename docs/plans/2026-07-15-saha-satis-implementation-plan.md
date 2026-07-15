# Saha Satış Faz 0–1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Plasiyer gününü muhasebe/stok/sync açısından güvenilir MVP seviyesine çıkarmak (gate + Logo tip + fiyat/stok güvenlik + test iskeleti).

**Architecture:** Mevcut `field_sales` view/viewmodel/model/engine + `JobQueueService` + Logo REST korunur; yeni katman eklenmez.

**Tech Stack:** Flutter, Riverpod, SQLite (sqflite), Dio Logo REST

**Kaynak tasarım:** `docs/plans/2026-07-15-saha-satis-roadmap-design.md`

---

### Task 1: tr.json düzelt

**Files:**
- Modify: `assets/translations/tr.json`

**Step 1:** JSON parse hatasını (çift kök / çift `field_sales`) tek geçerli kök olacak şekilde birleştir.

**Step 2:** Doğrula:

```bash
python3 -c "import json; json.load(open('assets/translations/tr.json'))"
```

Expected: hata yok.

**Step 3:** Commit — `fix(l10n): tr.json geçersiz JSON düzelt`

---

### Task 2: customer_price_maps migrate + PriceEngine fallback

**Files:**
- Modify: `lib/service/database_service.dart`
- Modify: `lib/modules/field_sales/orders/engine/price_engine.dart`
- Modify: `lib/modules/field_sales/orders/viewmodel/order_provider.dart`
- Test: `test/unit/modules/field_sales/orders/price_engine_test.dart`

**Step 1:** Failing test — `getPrice` ürün kart fiyatına düşer (maps boş).

**Step 2:** `SqlQuerys.createCustomerPriceMapsTable` execute et; `defaultPrice` olarak `products.price` kullan; `defaultPrice: 0.0` kaldır.

**Step 3:** Test yeşil + commit — `fix(pricing): müşteri fiyat map + ürün fiyat fallback`

---

### Task 3: JobQueue dayanıklılık

**Files:**
- Modify: `lib/service/job_queue_service.dart`
- Test: `test/unit/service/job_queue_service_test.dart`

**Step 1:** Test — `scheduled_at` gelecekteki job işlenmez; retry≥max → dead; unknown type silinmez.

**Step 2:** WHERE `scheduled_at IS NULL OR scheduled_at <= now`; max retry dead-letter; unknown → fail.

**Step 3:** Commit — `fix(sync): job queue backoff ve dead-letter`

---

### Task 4: Logo fatura tip map + iade stok yönü

**Files:**
- Modify: `lib/service/job_queue_service.dart`
- Modify: `lib/core/services/logo_payload_mapper.dart`
- Modify: `lib/modules/field_sales/invoices/viewmodel/invoice_provider.dart`
- Test: `test/unit/core/services/logo_payload_mapper_test.dart`

**Step 1:** Test — iade TYPE 3; toptan 8; van ayrı; iadede araç stok artar.

**Step 2:** `_syncInvoice` wholesale sabitini kaldır; iade flag → stok `+=`.

**Step 3:** Commit — `fix(invoice): Logo tip map ve iade stok artışı`

---

### Task 5: Cari credit_limit + satış öncesi risk

**Files:**
- Modify: `lib/core/database/migrations/SqlQuerys.dart`
- Modify: `lib/modules/field_sales/customers/model/customer_model.dart`
- Modify: `lib/modules/field_sales/orders/viewmodel/order_provider.dart`
- Modify: `lib/modules/field_sales/invoices/viewmodel/invoice_provider.dart`
- Test: `test/unit/modules/field_sales/customers/credit_limit_test.dart`

**Step 1:** Test — bakiye+sepet > limit → reddet.

**Step 2:** Kolon + model + kaydet öncesi kontrol (peşin istisna flag opsiyonel).

**Step 3:** Commit — `feat(customers): credit_limit ve satış risk kontrolü`

---

### Task 6: Mesai gate + work_logs lokal

**Files:**
- Create: `lib/modules/field_sales/other/viewmodel/day_status_provider.dart` (mevcut other/ altına)
- Modify: `lib/modules/field_sales/other/view/day_status_screen.dart`
- Modify: `lib/view/mobile_dashboard.dart` (guard)
- Modify: `SqlQuerys.dart` + `database_service.dart`
- Test: `test/unit/modules/field_sales/other/day_status_gate_test.dart`

**Step 1:** Test — açık mesai yokken satış engeli.

**Step 2:** SQLite `work_logs`; start/end persist; dashboard `_openModule` guard.

**Step 3:** Commit — `feat(day): mesai persist ve satış gate`

---

### Task 7: visit_id zorunlu satış/tahsilat

**Files:**
- Modify: `order_provider.dart`, `invoice_provider.dart`, `collection_provider.dart`
- Modify: entry screens müşteri/visit bağlamı
- Modify: `visit_provider.dart` (`activeVisit`)

**Step 1:** Test — activeVisit yoksa kaydet false.

**Step 2:** Kayda `visit_id` yaz; dashboard boş `customerId` ile açılışı engelle.

**Step 3:** Commit — `feat(visits): satış ve tahsilatı ziyarete bağla`

---

### Task 8: Gerçek EOD

**Files:**
- Modify: `vehicle_provider.dart` `reconcileEndOfDay`
- Modify: `vehicle_eod_screen.dart`
- Test: `test/unit/modules/field_sales/vehicles/eod_test.dart`

**Step 1:** Test — sayım farkı stoku günceller; mock özet yok.

**Step 2:** Checklist gerçek (pending sync, açık visit); satış/tahsilat aggregate.

**Step 3:** Commit — `feat(vehicles): gerçek gün sonu mutabakatı`

---

### Task 9: Tahsilat makbuz + fatura liste DB

**Files:**
- Modify: `collection_entry_screen.dart` → `printCollection`
- Modify: `invoice_list_screen.dart` → SQLite query
- Modify: `bluetooth_print_service.dart` / print services (KDV/müşteri)

**Step 1:** Kayıttan sonra makbuz; listede gerçek faturalar.

**Step 2:** Commit — `feat(print+invoice): makbuz ve gerçek fatura listesi`

---

### Task 10: Production P0 checklist (docs + minimal kod)

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` (INTERNET)
- Note: signing/package id ayrı release sprint’te kullanıcı onayıyla

**Step 1:** INTERNET main’e ekle.

**Step 2:** Commit — `fix(android): release INTERNET izni`

---

## Doğrulama (her task sonrası)

```bash
flutter test test/unit/...
flutter analyze lib/modules/field_sales lib/service/job_queue_service.dart lib/core/services/
```

## Zorunlu rol kontrolü

Her merge öncesi: Test ajanı + Muhasebe + Saha satış checklist’i (`.cursor/rules/multi-agent-sfa-workflow.mdc`).
