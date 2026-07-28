// Dosya Adı: permission_group_store.dart
// Açıklama: permission_groups / menus / members SQLite CRUD + efektif resolve
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/menu_permission_flags.dart';
import '../../../core/auth/permission_resolver.dart';
import '../../../core/auth/role_home_menu_filter.dart';
import '../../../core/database/migrations/SqlQuerys.dart';
import '../../../service/database_service.dart';

/// {@template permission_group_record}
/// Yetki grubu satırı.
/// {@endtemplate}
class PermissionGroupRecord {
  /// [id]: Grup PK
  final String id;

  /// [name]: Görünen ad
  final String name;

  /// [description]: Açıklama
  final String? description;

  /// [isSystem]: Seed / sistem grubu (silinemez)
  final bool isSystem;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro permission_group_record}
  const PermissionGroupRecord({
    required this.id,
    required this.name,
    this.description,
    this.isSystem = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PermissionGroupRecord.fromMap(Map<String, dynamic> row) {
    return PermissionGroupRecord(
      id: (row['id'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      description: row['description'] as String?,
      isSystem: (row['is_system'] as int?) == 1,
      isDeleted: (row['is_deleted'] as int?) == 1,
      createdAt: row['created_at'] as String?,
      updatedAt: row['updated_at'] as String?,
    );
  }
}

/// {@template permission_group_member}
/// Grup üyeliği (kullanıcı + firma).
/// {@endtemplate}
class PermissionGroupMember {
  /// [groupId]: Grup
  final String groupId;

  /// [userId]: Kullanıcı
  final String userId;

  /// [companyNo]: Firma no
  final int companyNo;

  /// {@macro permission_group_member}
  const PermissionGroupMember({
    required this.groupId,
    required this.userId,
    required this.companyNo,
  });

  factory PermissionGroupMember.fromMap(Map<String, dynamic> row) {
    return PermissionGroupMember(
      groupId: (row['group_id'] as String?) ?? '',
      userId: (row['user_id'] as String?) ?? '',
      companyNo: int.tryParse('${row['company_no']}') ?? 0,
    );
  }
}

/// {@template permission_group_store}
/// Gelişmiş yetki grupları deposu.
///
/// Kullanım örneği:
/// ```dart
/// final store = PermissionGroupStore(db);
/// final effective = await store.resolveEffective(
///   userId: uid,
///   companyNo: 1,
/// );
/// ```
/// {@endtemplate}
class PermissionGroupStore {
  /// [groupsTable]: Grup tablosu
  static const String groupsTable = 'permission_groups';

  /// [menusTable]: Grup menü paketleri
  static const String menusTable = 'permission_group_menus';

  /// [membersTable]: Üyelikler
  static const String membersTable = 'permission_group_members';

  /// Sistem grup id’leri
  static const String adminFullGroupId = 'pg_admin_full';
  static const String salespersonGroupId = 'pg_salesperson';
  static const String warehouseGroupId = 'pg_warehouse';

  /// [_db]: Açık bağlantı (null → DatabaseService)
  final Database? _db;

  /// {@macro permission_group_store}
  const PermissionGroupStore([this._db]);

  /// {@template permission_group_store_db}
  /// SQLite bağlantısı.
  /// {@endtemplate}
  Future<Database> _database() async {
    if (_db != null) return _db!;
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template permission_group_store_ensure}
  /// Tablolar yoksa oluşturur.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _database();
    await db.execute(SqlQuerys.createPermissionGroupsTable);
    await db.execute(SqlQuerys.createPermissionGroupMenusTable);
    await db.execute(SqlQuerys.createPermissionGroupMembersTable);
  }

  /// {@template permission_group_store_list}
  /// Aktif grup listesi.
  /// {@endtemplate}
  Future<List<PermissionGroupRecord>> listGroups() async {
    await ensureReady();
    final db = await _database();
    final rows = await db.query(
      groupsTable,
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return rows.map(PermissionGroupRecord.fromMap).toList();
  }

  /// {@template permission_group_store_get}
  /// Grup getir.
  /// {@endtemplate}
  Future<PermissionGroupRecord?> getGroup(String id) async {
    await ensureReady();
    final db = await _database();
    final rows = await db.query(
      groupsTable,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PermissionGroupRecord.fromMap(rows.first);
  }

  /// {@template permission_group_store_create}
  /// Yeni grup oluşturur.
  /// {@endtemplate}
  Future<PermissionGroupRecord> createGroup({
    required String name,
    String? description,
    bool isSystem = false,
    String? id,
  }) async {
    await ensureReady();
    final db = await _database();
    final now = DateTime.now().toUtc().toIso8601String();
    final groupId = id ?? const Uuid().v4();
    await db.insert(
      groupsTable,
      {
        'id': groupId,
        'name': name.trim(),
        'description': description,
        'is_system': isSystem ? 1 : 0,
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return PermissionGroupRecord(
      id: groupId,
      name: name.trim(),
      description: description,
      isSystem: isSystem,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// {@template permission_group_store_update}
  /// Grup ad/açıklama güncelle.
  /// {@endtemplate}
  Future<void> updateGroup({
    required String id,
    required String name,
    String? description,
  }) async {
    await ensureReady();
    final db = await _database();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      groupsTable,
      {
        'name': name.trim(),
        'description': description,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// {@template permission_group_store_delete}
  /// Soft delete (sistem grupları silinmez).
  /// {@endtemplate}
  Future<bool> softDeleteGroup(String id) async {
    await ensureReady();
    final existing = await getGroup(id);
    if (existing == null || existing.isSystem) return false;
    final db = await _database();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      groupsTable,
      {'is_deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    return true;
  }

  /// {@template permission_group_store_list_menus}
  /// Grubun menü paketleri.
  /// {@endtemplate}
  Future<Map<String, MenuPermissionFlags>> listGroupMenus(
    String groupId,
  ) async {
    await ensureReady();
    final db = await _database();
    final rows = await db.query(
      menusTable,
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    return PermissionResolver.fromRows(rows);
  }

  /// {@template permission_group_store_replace_menus}
  /// Grup menü paketini tamamen değiştirir.
  /// {@endtemplate}
  Future<void> replaceGroupMenus({
    required String groupId,
    required Map<String, MenuPermissionFlags> menus,
  }) async {
    await ensureReady();
    final db = await _database();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete(
        menusTable,
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
      for (final entry in menus.entries) {
        final uuid = entry.key.trim();
        if (uuid.isEmpty) continue;
        await txn.insert(
          menusTable,
          {
            'group_id': groupId,
            'menu_uuid': uuid,
            ...entry.value.toSqlMap(),
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// {@template permission_group_store_list_members}
  /// Grup üyeleri.
  /// {@endtemplate}
  Future<List<PermissionGroupMember>> listMembers(String groupId) async {
    await ensureReady();
    final db = await _database();
    final rows = await db.query(
      membersTable,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'user_id ASC, company_no ASC',
    );
    return rows.map(PermissionGroupMember.fromMap).toList();
  }

  /// {@template permission_group_store_assign}
  /// Kullanıcıyı gruba (firma ile) atar.
  /// {@endtemplate}
  Future<void> assignMember({
    required String groupId,
    required String userId,
    required int companyNo,
  }) async {
    await ensureReady();
    final db = await _database();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      membersTable,
      {
        'group_id': groupId,
        'user_id': userId,
        'company_no': companyNo,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// {@template permission_group_store_unassign}
  /// Üyelik kaldır.
  /// {@endtemplate}
  Future<void> removeMember({
    required String groupId,
    required String userId,
    required int companyNo,
  }) async {
    await ensureReady();
    final db = await _database();
    await db.delete(
      membersTable,
      where: 'group_id = ? AND user_id = ? AND company_no = ?',
      whereArgs: [groupId, userId, companyNo],
    );
  }

  /// {@template permission_group_store_has_any}
  /// Kullanıcı+firma için doğrudan veya grup yetkisi var mı?
  /// {@endtemplate}
  Future<bool> hasAnyPermissionData({
    required String userId,
    required int companyNo,
  }) async {
    await ensureReady();
    final db = await _database();
    final direct = await db.rawQuery(
      '''
      SELECT 1 FROM menu_permissions
      WHERE user_id = ? AND company_no = ?
      LIMIT 1
      ''',
      [userId, companyNo],
    );
    if (direct.isNotEmpty) return true;
    final group = await db.rawQuery(
      '''
      SELECT 1 FROM $membersTable
      WHERE user_id = ? AND company_no = ?
      LIMIT 1
      ''',
      [userId, companyNo],
    );
    return group.isNotEmpty;
  }

  /// {@template permission_group_store_resolve}
  /// Doğrudan menu_permissions ∪ grup menüleri → efektif can_*.
  /// {@endtemplate}
  Future<Map<String, MenuPermissionFlags>> resolveEffective({
    required String userId,
    required int companyNo,
  }) async {
    await ensureReady();
    final db = await _database();

    final directRows = await db.rawQuery(
      '''
      SELECT COALESCE(
               NULLIF(TRIM(p.menu_uuid), ''),
               m.uuid,
               ''
             ) AS menu_uuid,
             p.can_view, p.can_add, p.can_edit, p.can_delete
      FROM menu_permissions p
      LEFT JOIN menu m ON m.id = p.menu_id
      WHERE p.user_id = ? AND p.company_no = ?
      ''',
      [userId, companyNo],
    );
    final filledDirect = directRows
        .where((r) => ((r['menu_uuid'] as String?) ?? '').trim().isNotEmpty)
        .toList();

    final groupRows = await db.rawQuery(
      '''
      SELECT gm.menu_uuid, gm.can_view, gm.can_add, gm.can_edit, gm.can_delete
      FROM $menusTable gm
      INNER JOIN $membersTable mem ON mem.group_id = gm.group_id
      INNER JOIN $groupsTable g ON g.id = gm.group_id
      WHERE mem.user_id = ? AND mem.company_no = ?
        AND g.is_deleted = 0
      ''',
      [userId, companyNo],
    );

    return PermissionResolver.mergeSources([
      PermissionResolver.fromRows(filledDirect),
      PermissionResolver.fromRows(groupRows),
    ]);
  }

  /// {@template permission_group_store_ensure_menus}
  /// Eksik menü uuid’lerini gruba ekler (mevcutları silmez).
  /// {@endtemplate}
  Future<void> ensureMenusInGroup({
    required String groupId,
    required Set<String> uuids,
    MenuPermissionFlags flags = MenuPermissionFlags.full,
  }) async {
    await ensureReady();
    final current = await listGroupMenus(groupId);
    final missing = uuids
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty && !current.containsKey(u))
        .toSet();
    if (missing.isEmpty) return;
    final merged = Map<String, MenuPermissionFlags>.from(current);
    for (final u in missing) {
      merged[u] = flags;
    }
    await replaceGroupMenus(groupId: groupId, menus: merged);
  }

  /// {@template permission_group_store_seed}
  /// Admin full + opsiyonel plasiyer/depocu örnek gruplar.
  ///
  /// Parametreler:
  /// - [adminUserId]: Admin kullanıcı (null → atama yok)
  /// - [companyNo]: Firma
  /// - [allMenuUuids]: Tüm menü uuid’leri (admin full)
  /// {@endtemplate}
  Future<void> seedDefaults({
    String? adminUserId,
    int companyNo = 1,
    List<String> allMenuUuids = const [],
  }) async {
    await ensureReady();
    final db = await _database();

    Future<void> ensureGroup({
      required String id,
      required String name,
      required String description,
      required Set<String> uuids,
      MenuPermissionFlags flags = MenuPermissionFlags.full,
    }) async {
      final existing = await db.query(
        groupsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isEmpty) {
        await createGroup(
          id: id,
          name: name,
          description: description,
          isSystem: true,
        );
      }
      final current = await listGroupMenus(id);
      if (current.isEmpty && uuids.isNotEmpty) {
        await replaceGroupMenus(
          groupId: id,
          menus: {
            for (final u in uuids)
              if (u.trim().isNotEmpty) u.trim(): flags,
          },
        );
      } else if (uuids.isNotEmpty) {
        // Yeni menü UUID’leri (ai_insights / supply_req) mevcut gruba eklenir
        await ensureMenusInGroup(
          groupId: id,
          uuids: uuids,
          flags: flags,
        );
      }
    }

    final all = allMenuUuids.isNotEmpty
        ? allMenuUuids.toSet()
        : (await db.query('menu', columns: ['uuid']))
            .map((r) => (r['uuid'] as String?)?.trim() ?? '')
            .where((u) => u.isNotEmpty)
            .toSet();

    await ensureGroup(
      id: adminFullGroupId,
      name: 'Admin Tam Yetki',
      description: 'Tüm menüler — CRUD tam',
      uuids: all,
      flags: MenuPermissionFlags.full,
    );

    await ensureGroup(
      id: salespersonGroupId,
      name: 'Plasiyer',
      description: 'Saha satış örnek paket',
      uuids: RoleHomeMenuFilter.salespersonSeedMenuUuids,
      flags: const MenuPermissionFlags(
        canView: true,
        canAdd: true,
        canEdit: true,
        canDelete: false,
      ),
    );

    await ensureGroup(
      id: warehouseGroupId,
      name: 'Depocu',
      description: 'Ambar örnek paket',
      uuids: RoleHomeMenuFilter.warehouseSeedMenuUuids,
      flags: const MenuPermissionFlags(
        canView: true,
        canAdd: true,
        canEdit: true,
        canDelete: false,
      ),
    );

    if (adminUserId != null && adminUserId.isNotEmpty) {
      await assignMember(
        groupId: adminFullGroupId,
        userId: adminUserId,
        companyNo: companyNo,
      );
    }
  }
}
