// Dosya Adı: permission_group_store_test.dart
// Açıklama: PermissionGroupStore SQLite CRUD + resolve round-trip
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/auth/menu_permission_flags.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/admin_panel/viewmodel/permission_group_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PermissionGroupStore store;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute(SqlQuerys.createMenuTable);
        await database.execute(SqlQuerys.createMenuPermissionsTable);
        await database.execute(SqlQuerys.createPermissionGroupsTable);
        await database.execute(SqlQuerys.createPermissionGroupMenusTable);
        await database.execute(SqlQuerys.createPermissionGroupMembersTable);
      },
    );
    store = PermissionGroupStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertMenu(String uuid) async {
    await db.insert('menu', {
      'uuid': uuid,
      'title': uuid,
      'is_visible': 1,
      'is_deleted': 0,
      'module_name': 'FieldSales',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  test('grup CRUD + menü paketi + üye → resolve OR', () async {
    await insertMenu('fs_order');
    await insertMenu('fs_stock');

    final group = await store.createGroup(
      name: 'Test Grup',
      description: 'unit',
    );
    await store.replaceGroupMenus(
      groupId: group.id,
      menus: {
        'fs_order': MenuPermissionFlags.full,
      },
    );
    await store.assignMember(
      groupId: group.id,
      userId: 'user_a',
      companyNo: 1,
    );

    // Doğrudan yetki: fs_stock view
    await db.insert('menu_permissions', {
      'uuid': 'perm_stock',
      'menu_uuid': 'fs_stock',
      'user_id': 'user_a',
      'company_no': 1,
      'can_view': 1,
      'can_add': 0,
      'can_edit': 0,
      'can_delete': 0,
    });

    final effective = await store.resolveEffective(
      userId: 'user_a',
      companyNo: 1,
    );

    expect(effective['fs_order']!.canView, isTrue);
    expect(effective['fs_order']!.canDelete, isTrue);
    expect(effective['fs_stock']!.canView, isTrue);
    expect(effective['fs_stock']!.canAdd, isFalse);

    final has = await store.hasAnyPermissionData(
      userId: 'user_a',
      companyNo: 1,
    );
    expect(has, isTrue);

    final other = await store.hasAnyPermissionData(
      userId: 'user_b',
      companyNo: 1,
    );
    expect(other, isFalse);
  });

  test('sistem grubu soft delete engellenir', () async {
    final g = await store.createGroup(
      name: 'Sys',
      isSystem: true,
      id: 'pg_test_sys',
    );
    expect(await store.softDeleteGroup(g.id), isFalse);
    expect(await store.getGroup(g.id), isNotNull);
  });

  test('seedDefaults admin full + örnek gruplar', () async {
    await insertMenu('fs_customers');
    await insertMenu('fs_order');
    await insertMenu('fs_stock');

    await store.seedDefaults(
      adminUserId: 'admin_1',
      companyNo: 1,
      allMenuUuids: ['fs_customers', 'fs_order', 'fs_stock'],
    );

    final groups = await store.listGroups();
    expect(
      groups.map((g) => g.id),
      containsAll([
        PermissionGroupStore.adminFullGroupId,
        PermissionGroupStore.salespersonGroupId,
        PermissionGroupStore.warehouseGroupId,
      ]),
    );

    final adminMenus =
        await store.listGroupMenus(PermissionGroupStore.adminFullGroupId);
    expect(adminMenus.length, 3);
    expect(adminMenus['fs_customers']!.canDelete, isTrue);

    final effective = await store.resolveEffective(
      userId: 'admin_1',
      companyNo: 1,
    );
    expect(effective.length, 3);
  });

  test('ensureMenusInGroup AI UUID’lerini mevcut gruba ekler', () async {
    await insertMenu('fs_other');
    await insertMenu('sub_oth_ai_insights');
    await insertMenu('sub_stk_supply_req');

    await store.seedDefaults(
      allMenuUuids: ['fs_other', 'fs_stock'],
    );

    // İlk seed plasiyer ana menüleri + seed set
    final before = await store.listGroupMenus(
      PermissionGroupStore.salespersonGroupId,
    );
    expect(before.containsKey('sub_oth_ai_insights'), isTrue);

    // Eksik UUID merge
    await store.ensureMenusInGroup(
      groupId: PermissionGroupStore.warehouseGroupId,
      uuids: {'sub_stk_supply_req'},
      flags: const MenuPermissionFlags(
        canView: true,
        canAdd: true,
        canEdit: false,
        canDelete: false,
      ),
    );
    final wh = await store.listGroupMenus(
      PermissionGroupStore.warehouseGroupId,
    );
    expect(wh['sub_stk_supply_req']!.canView, isTrue);

    final admin = await store.listGroupMenus(
      PermissionGroupStore.adminFullGroupId,
    );
    await store.ensureMenusInGroup(
      groupId: PermissionGroupStore.adminFullGroupId,
      uuids: {'sub_oth_ai_insights', 'sub_stk_supply_req'},
    );
    final admin2 = await store.listGroupMenus(
      PermissionGroupStore.adminFullGroupId,
    );
    expect(admin2.length, greaterThanOrEqualTo(admin.length));
    expect(admin2.containsKey('sub_oth_ai_insights'), isTrue);
  });
}
