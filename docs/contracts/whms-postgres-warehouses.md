# WHMS ↔ Postgres `warehouses` sözleşme

**Tarih:** 2026-07-26  
**Faz:** 2.4  
**Kapsam:** Mobil SQLite ↔ SaaS Postgres alan hizası — migrasyon yok

## Mobil (`warehouses`)

| Alan | Tip | Not |
|------|-----|-----|
| `id` | TEXT PK | Yerel uuid |
| `code` | TEXT | MRK / ARC / IAD |
| `name` | TEXT | Görünen ad |
| `type` | TEXT | center / vehicle / return |
| `is_active` | INTEGER | 0/1 |
| `created_at` / `updated_at` | TEXT | ISO |
| `is_synced` | INTEGER | Sync bayrağı (DDL’de var) |
| `is_deleted` | — | **Mobil DDL’de yok** (2026-07-26); Postgres pull öncesi kolon kararı (W59) |

Seed: `WarehouseMasterSeed` (MRK/ARC/IAD).

## Bakiye (`warehouse_stocks`)

| Alan | Tip | Not |
|------|-----|-----|
| `warehouse_code` | TEXT | FK mantıksal → `warehouses.code` |
| `product_id` | TEXT | Ürün |
| `quantity` | REAL | Ana birim |
| `is_synced` | INTEGER | |

Van kovası **ayrı**: `vehicle_stocks` (Postgres WHMS deposuna map edilmez).

## Postgres (önerilen SaaS)

| Kolon | Mobil karşılık |
|-------|----------------|
| `code` | `warehouses.code` |
| `name` | `warehouses.name` |
| `warehouse_type` | `warehouses.type` |
| `tenant_id` | PostgREST kiracı |
| `is_active` | `is_active` |

## Sync kuralı

1. Master: Postgres → mobil (`warehouses`) pull  
2. Bakiye okuma: `StockBalancePort` (Logo veya yerel); WHMS REST sonra  
3. Hareket: ONAY=1 fiş → job queue → Logo/WHMS; cihaz `warehouse_stocks` txn yerel kalır  
4. Çatışma: offline-first — cihaz txn kaybolmaz; master code çakışmasında seed kodları kanonik

## Bilinçli sapma

- Canlı Postgres migrasyonu bu fazda **yok**  
- ARC mobil van; merkez WHMS Postgres’te “vehicle warehouse” açılmaz
