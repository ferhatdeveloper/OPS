# Tedarik talebi → Logo satın alma (sync_queue)

**Tarih:** 2026-07-28  
**Durum:** Gerçek kuyruk yolu aktif (`SupplyRequestLogoSyncMapper.useRealLogoPurchasePath = true`)

## Akış

1. Depocu / admin `supplier_purchase_requests` satırını onaylar (`ONAY=1`).
2. `SupplyRequestLogoSyncMapper.enqueueApproved` → `sync_queue`
   - `entity_type`: `supplier_purchase_request`
   - Payload: `LogoPayloadMapper.orderFromLocal(..., orderType: purchase)`
3. `JobQueueService` işler:
   - Flag/stub true → yerel `is_synced` işaretleme (eski stub)
   - Gerçek path → `LogoApiService.createOrder` → `POST /api/v1/logo/erp/orders` (`type=purchase`)

## Feature flag

```dart
SupplyRequestLogoSyncMapper.useRealLogoPurchasePath = false; // stub'a dön
```

## Not

Merkez Objects satın alma fişi şeması firma bazlı doğrulanmalı; payload sipariş
kanalı (`sales`/`purchase`) fatura TYPE 8 ile karıştırılmaz.
