# WHMS

## Açıklama
Merkez depo (Warehouse Management System) domain.
Plasiyer `field_sales/stock` menüsüne gömülmez. Faz 2.1–2.5: Logo bakiye,
onaylı transfer kuyruğu, yükleme emri consume, `/whms` shell, Postgres sözleşme.

## Dosyalar
- `contract/*`: Bakiye port, DTO, route map
- `data/local_*` / `logo_*`: StockBalancePort implementasyonları
- `queue/whms_transfer_queue_bridge.dart`: ONAY=1 → JobQueue
- `engine/whms_load_order_consumer.dart`: Emir → VehicleLoadService
- `viewmodel/stock_balance_providers.dart`: Riverpod DI
- `view/whms_shell_screen.dart`: `/whms` dens kabuk
- `mapper/whms_payload_mapper.dart`: Payload map

## Kullanım
```dart
final port = await ref.watch(stockBalancePortProvider.future);
await WhmsTransferQueueBridge().enqueueApprovedFromDens(...);
await WhmsLoadOrderConsumer.consume(db: db, order: dto);
```

## Bağımlılıklar
- `field_sales/stock`, `vehicle` (VehicleLoadService)
- `LogoApiService` / JobQueue
- SQLite `warehouse_stocks` / `vehicle_stocks`
