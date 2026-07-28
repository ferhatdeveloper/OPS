# Yetki Grupları (Permission Groups) — Tasarım Notu

**Tarih:** 2026-07-28  
**Durum:** Uygulandı (admin-only yönetim + runtime resolve)

## Kararlar

1. Yalnızca **admin** yetki grubu oluşturur, menü paketini bağlar, kullanıcıya (firma ile) atar.
2. Saha kullanıcısı menüyü görür; **favori kalbi** (`menu_favorites`) bağımsız kalır.
3. Gelişmiş seviye = **CRUD + firma kapsamı**: `can_view` / `can_add` / `can_edit` / `can_delete` + `company_no`.

## Şema (SQLite)

| Tablo | Amaç |
|-------|------|
| `permission_groups` | Grup tanımı (`is_system`, soft delete) |
| `permission_group_menus` | `group_id` + `menu_uuid` + can_* |
| `permission_group_members` | `group_id` + `user_id` + `company_no` |

Mevcut `menu_permissions` korunur. Resolve: **doğrudan ∪ grup** → aynı `menu_uuid` için bayraklar **OR**.

## Runtime

- `PermissionGroupStore.resolveEffective` → efektif harita
- `DatabaseService.getMenusByUserAndCompany` → can_view uuid seti
- `MenuService.getMobileModuleCards(userId, companyNo)` → ana grid permission filtresi
- `RoleHomeMenuFilter` ile **permission ∩ rol**
- Yetki kaydı yoksa **legacy**: tüm menü + yalnızca rol filtresi

## Seed

- `pg_admin_full` — tüm menüler, CRUD full; oturum kullanıcısına atanır
- `pg_salesperson` / `pg_warehouse` — örnek paketler (rol uuid setleri)

## Admin UI

- Dens: `PermissionGroupsScreen` / `PermissionGroupEditScreen`
- Admin panel sekmesi + `UserAuthorization` AppBar güvenlik ikonu

## Test

```bash
flutter test test/core/auth/permission_resolver_test.dart
flutter test test/modules/admin_panel/permission_group_store_test.dart
```
