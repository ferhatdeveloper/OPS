# 100-Ajan Modül Entegrasyonu — Merkez Özeti

**Tarih:** 2026-07-26  
**Rol:** Merkez entegrasyon (seed ↔ route)  
**Commit:** Yok  
**UI redesign:** Yok  

---

## Yapılan birleştirme

### `lib/core/init/navigation/routes.dart`
- Tek kaynak: `AppRoutes.generateRoute` (`main.dart` `onGenerateRoute`).
- `_page(settings, builder)` helper → tüm `MaterialPageRoute` `settings: settings` taşır (`route.settings.name` null olmaz).
- Alias: `invoice-defaults` → `VoucherDefaultsSettingsScreen` (geri uyumluluk).
- `fieldSalesWaybillWholesale` const = `/field-sales/waybill-wholesale`.
- Rapor seed: `/field-sales/report-*` prefix → `LogoReportsScreen` (alias).

### Menü seed (`database_service.dart` → `subMenus`)
| Eskiden | Sonra |
|---------|--------|
| `/field-sales/invoice-defaults` | `/field-sales/voucher-defaults` (tek path) |
| `/sales-order` | `/field-sales/orders` |
| `/sales-history` | `/field-sales/orders-list` |
| `/field-sales/collection` | `/field-sales/collections` |
| `/sales-report` | `/field-sales/report-sales` |

`waybill-wholesale` / `invoice-wholesale` seed path’leri `AppRoutes` + `WaybillEntryScreen.routeWholesale` ile aynı.

---

## Seed vs route matrisi

Kaynak seed: `lib/service/database_service.dart` `subMenus` (62 path).  
Kaynak route: `AppRoutes` const / `Screen.routeName` / prefix alias.

**Lejant:** ✓ = doğrudan kayıtlı · alias = başka path/ekrana yönlendirilir · eksik = generateRoute fallback (“rota bulunamadı”)

| Seed path | Hedef | Durum |
|-----------|--------|-------|
| `/field-sales/manager-dashboard` | `fieldSalesManagerDashboard` | ✓ |
| `/field-sales/period-comparison` | `fieldSalesPeriodComparison` | ✓ |
| `/field-sales/target-assignment` | `fieldSalesTargetAssignment` | ✓ |
| `/field-sales/target-ranking` | `fieldSalesTargetRanking` | ✓ |
| `/field-sales/customers` | `fieldSalesCustomers` | ✓ |
| `/field-sales/customer-new` | `fieldSalesCustomerNew` | ✓ |
| `/field-sales/customers-map` | `fieldSalesCustomersMap` | ✓ |
| `/field-sales/wholesale` | `fieldSalesWholesale` → fatura cari seç | ✓ |
| `/field-sales/wholesale-return` | `fieldSalesWholesaleReturn` | ✓ |
| `/field-sales/invoice-wholesale` | `fieldSalesInvoiceWholesale` | ✓ |
| `/field-sales/invoice-return` | `fieldSalesInvoiceReturn` | ✓ |
| `/field-sales/invoices-list-mbt` | `InvoiceListMbtScreen.routeName` | ✓ |
| `/field-sales/invoices-untransferred` | `InvoicesUntransferredScreen.routeName` | ✓ |
| `/field-sales/invoices-pending` | `InvoicesPendingScreen.routeName` | ✓ |
| `/field-sales/invoices-approval` | `InvoiceApprovalScreen.routeName` | ✓ |
| `/field-sales/waybill-wholesale` | `fieldSalesWaybillWholesale` / `routeWholesale` | ✓ |
| `/field-sales/waybill-purchase` | `fieldSalesWaybillPurchase` | ✓ |
| `/field-sales/waybills` | `fieldSalesWaybills` | ✓ |
| `/field-sales/waybills-untransferred` | `WaybillsUntransferredScreen.routeName` | ✓ |
| `/field-sales/waybills-pending` | `WaybillsPendingScreen.routeName` | ✓ |
| `/field-sales/orders` | `fieldSalesOrders` | ✓ |
| `/field-sales/orders-list` | `OrderListScreen.routeName` | ✓ |
| `/field-sales/orders-approval` | `OrderApprovalScreen.routeName` | ✓ |
| `/field-sales/orders-untransferred` | `OrdersUntransferredScreen.routeName` | ✓ |
| `/field-sales/orders-pending` | `OrdersPendingScreen.routeName` | ✓ |
| `/field-sales/delivery-list` | `fieldSalesDeliveryList` | ✓ |
| `/field-sales/delivery-hold` | `DeliveryHoldScreen.routeName` | ✓ |
| `/field-sales/delivery-untransferred` | `DeliveryUntransferredScreen.routeName` | ✓ |
| `/field-sales/visit-existing` | `VisitExistingCustomerScreen.routeName` | ✓ |
| `/field-sales/visit-new` | `VisitNewCustomerScreen.routeName` | ✓ |
| `/field-sales/visit-history` | `VisitHistoryScreen.routeName` | ✓ |
| `/field-sales/visit-untransferred` | `VisitUntransferredScreen.routeName` | ✓ |
| `/field-sales/collections` | `fieldSalesCollections` | ✓ |
| `/field-sales/finance-transferred` | `CollectionsTransferredScreen.routeName` | ✓ |
| `/field-sales/finance-untransferred` | `CollectionsUntransferredScreen.routeName` | ✓ |
| `/field-sales/cash-cards` | `CashCardListScreen.routeName` | ✓ |
| `/field-sales/checks` | `fieldSalesChecks` | ✓ |
| `/field-sales/products` | `fieldSalesProducts` → `MaterialsScreen` | ✓ |
| `/field-sales/prices` | `fieldSalesPrices` → `PriceCheckScreen` | ✓ |
| `/field-sales/stock-barcode` | alias → `BarcodeScanScreen` (`barcode-scan`) | alias |
| `/field-sales/stock-count` | `fieldSalesStockCount` | ✓ |
| `/field-sales/stock-warehouse` | `fieldSalesStockWarehouse` | ✓ |
| `/field-sales/stock-production` | `ProductionReceiptScreen.routeName` | ✓ |
| `/field-sales/stock-transferred` | `fieldSalesStockTransferred` | ✓ |
| `/field-sales/stock-untransferred` | `fieldSalesStockUntransferred` | ✓ |
| `/field-sales/report-cari` | prefix → `LogoReportsScreen` | alias |
| `/field-sales/report-stock` | prefix → `LogoReportsScreen` | alias |
| `/field-sales/report-sales` | `SalesReportScreen.routeName` | ✓ |
| `/field-sales/report-invoice` | prefix → `LogoReportsScreen` | alias |
| `/field-sales/report-waybill` | prefix → `LogoReportsScreen` | alias |
| `/field-sales/report-other` | prefix → `LogoReportsScreen` | alias |
| `/field-sales/report-backup` | prefix → `LogoReportsScreen` | alias |
| `/field-sales/currency-rates` | `fieldSalesCurrencyRates` | ✓ |
| `/field-sales/companies` | `fieldSalesCompanies` | ✓ |
| `/field-sales/data-transfer` | `fieldSalesDataTransfer` | ✓ |
| `/field-sales/data-update` | alias → `DataTransferScreen` | alias |
| `/field-sales/untransferred-slips` | `fieldSalesUntransferredSlips` | ✓ |
| `/field-sales/voucher-defaults` | `VoucherDefaultsSettingsScreen.routeName` | ✓ |
| `/system/logs` | `systemLogs` | ✓ |
| `/field-sales/send-info` | `SendInfoScreen.routeName` | ✓ |
| `/field-sales/day-status` | `fieldSalesDayStatus` | ✓ |
| `/field-sales/image-settings` | `fieldSalesImageSettings` | ✓ |

### Özet sayım

| Durum | Adet |
|-------|------|
| ✓ | 54 |
| alias | 8 |
| eksik | 0 |
| **Toplam seed** | **62** |

### Geri uyumluluk alias (seed’de yok; generateRoute’da var)

| Path | Durum |
|------|--------|
| `/field-sales/invoice-defaults` | alias → `voucher-defaults` ekranı |
| `/field-sales/collection` | alias → `collections` |
| `/sales-order` / `/sales-history` / `/sales-report` | legacy alias |

### Stub var, menü seed’de yok (bilgi)

Örn. `product-catalog`, `price-list`, `day-open` / `day-close`, `vehicle-load`, `gps-tracking` — seed path’i değil; doğrudan `pushNamed` / dashboard ile açılabilir.

---

## Analyze / smoke

| Komut | Sonuç |
|-------|--------|
| `flutter analyze` routes + main + smoke test | **0 error** (yalnızca mevcut info) |
| `flutter analyze` + `database_service.dart` | 0 error; mevcut warning (`unused_element`) + `avoid_print` info |
| Smoke navigation + stub + l10n | **107/107 geçti** |

Smoke: `settings.name` named path’lerde korunuyor.

---

## Durum / risk / TODO

| Alan | Durum |
|------|--------|
| Seed `voucher-defaults` tek path | hazır |
| waybill/invoice wholesale hizası | hazır |
| `settings` taşıma | hazır |
| `send-info` | hazır |

**Risk:** Mevcut cihaz DB’sinde eski `invoice-defaults` satırı kalabilir (alias ile çalışır; tam tekilleşme için menü re-seed). Dashboard hâlâ title ile `_openModule` açabilir.

### TODO
1. ~~`send-info` stub ekranı + `routeName` + seed wiring~~ (tamam)
2. İsteğe bağlı: seed `products` → `product-catalog`, `prices` → `price-list` (stub ekran tercihi)
3. Cihaz menü reset sonrası smoke: waybill-wholesale → invoice-wholesale → voucher-defaults
4. `report-*` ayrı stub istenirse LogoReports yerine modül ekranlarına ayır
5. Dashboard `_openModule` ↔ named route parity (UI redesign yok)

### İlgili dosyalar
- `lib/core/init/navigation/routes.dart`
- `lib/main.dart`
- `lib/service/database_service.dart`
- `test/core/navigation/app_routes_generate_route_smoke_test.dart`
- `docs/plans/2026-07-26-100-agent-module-integration.md`
