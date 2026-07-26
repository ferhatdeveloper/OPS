# WHMS Bridge Contract (Faz 1 + 2.1)

**Tarih:** 2026-07-26  
**Kapsam:** DTO + bakiye portu + Logo adaptör + route hizası — canlı WHMS API yok

## Alanlar

| Sözleşme | Kod |
|----------|-----|
| Bakiye portu | `StockBalancePort` / `LocalWarehouseStockBalancePort` |
| Logo bakiye | `LogoStockBalancePort` (`getStock` / inventory → `source: logo`) |
| DI | `stockBalancePortProvider` |
| Transfer kuyruk | `WhmsTransferQueueBridge` (ONAY=1) |
| Yükleme consume | `WhmsLoadOrderConsumer` → `VehicleLoadService` |
| Transfer DTO | `WhmsWarehouseTransferDto` |
| Yükleme emri | `WhmsLoadOrderDto` |
| Sayım | `WhmsCountResultDto` |
| Mapper | `WhmsPayloadMapper` |
| Route hizası | `WhmsRouteMap` + `/whms` shell |
| Postgres | `docs/contracts/whms-postgres-warehouses.md` |

## ONAY

| Int | Anlam |
|-----|--------|
| 0 | pending |
| 1 | approved (sync adayı) |
| 2 | synced |
| 3 | rejected |
| 4 | error |

## Payload zorunlu alanlar (transfer)

- `from_warehouse_code` / `to_warehouse_code` (MRK/ARC/IAD)
- `entity` = `stock_transfer`
- `lines[].product_code` + `quantity`
- `ONAY`

## Not

OPS `fs_stock` stub route’lar `/field-sales/*` kalır. WHMS UI `/whms/*` Faz 2+.
