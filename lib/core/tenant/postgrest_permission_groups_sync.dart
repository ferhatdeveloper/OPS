// Dosya Adı: postgrest_permission_groups_sync.dart
// Açıklama: permission_groups / menus / members PostgREST → SQLite pull
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/migrations/SqlQuerys.dart';
import '../../service/database_service.dart';
import '../../service/postgres_service.dart';
import 'postgrest_http_client.dart';
import 'postgrest_table_names.dart';

/// {@template postgrest_permission_groups_sync}
/// Yetki gruplarını merkezden çeker (opsiyonel; hata yutulur).
/// Yerel seed / resolve bozulmaz — remote yoksa no-op.
///
/// Tablo adları (firma düzeyi):
/// - `rex_{FF}_permission_groups`
/// - `rex_{FF}_permission_group_menus`
/// - `rex_{FF}_permission_group_members`
///
/// Kullanım örneği:
/// ```dart
/// final n = await PostgrestPermissionGroupsSync().pullOptional();
/// ```
/// {@endtemplate}
class PostgrestPermissionGroupsSync {
  /// [client]: PostgREST
  final PostgrestHttpClient client;

  /// [postgres]: Aktif firma
  final PostgresService postgres;

  /// [db]: Test inject
  final Database? db;

  /// {@macro postgrest_permission_groups_sync}
  PostgrestPermissionGroupsSync({
    PostgrestHttpClient? client,
    PostgresService? postgres,
    this.db,
  })  : client = client ?? PostgrestHttpClient(),
        postgres = postgres ?? PostgresService.instance;

  /// {@template postgrest_permission_groups_sync_pull}
  /// Pull sync; bağlantı yok / 404 / hata → 0 (yerel bozulmaz).
  ///
  /// Dönüş değeri:
  /// - [int]: Yazılan grup satırı sayısı
  /// {@endtemplate}
  Future<int> pullOptional() async {
    if (!client.isConfigured) return 0;
    try {
      final firm = PostgrestTableNames.padFirm(postgres.activeFirmNr);
      final groups = await _pullGroups(firm);
      await _pullMenus(firm);
      await _pullMembers(firm);
      return groups;
    } catch (e) {
      debugPrint('PostgrestPermissionGroupsSync.pullOptional: $e');
      return 0;
    }
  }

  Future<Database> _db() async {
    if (db != null) return db!;
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  Future<int> _pullGroups(String firmNr) async {
    final table = PostgrestTableNames.firmTable(firmNr, 'permission_groups');
    try {
      final rows = await client.getRows(
        '/$table',
        query: {
          'select':
              'id,name,description,is_system,is_deleted,created_at,updated_at',
          'order': 'name',
          'limit': '2000',
        },
      );
      final database = await _db();
      await database.execute(SqlQuerys.createPermissionGroupsTable);
      final batch = database.batch();
      var n = 0;
      final now = DateTime.now().toIso8601String();
      for (final r in rows) {
        final id = (r['id'] ?? '').toString().trim();
        final name = (r['name'] ?? '').toString().trim();
        if (id.isEmpty || name.isEmpty) continue;
        batch.insert(
          'permission_groups',
          {
            'id': id,
            'name': name,
            'description': r['description']?.toString(),
            'is_system':
                (r['is_system'] == true || r['is_system'] == 1) ? 1 : 0,
            'is_deleted':
                (r['is_deleted'] == true || r['is_deleted'] == 1) ? 1 : 0,
            'created_at': (r['created_at'] ?? now).toString(),
            'updated_at': (r['updated_at'] ?? now).toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        n++;
      }
      await batch.commit(noResult: true);
      debugPrint('PostgREST → SQLite permission_groups: $n ($table)');
      return n;
    } catch (e) {
      debugPrint('PostgrestPermissionGroupsSync._pullGroups: $e');
      return 0;
    }
  }

  Future<int> _pullMenus(String firmNr) async {
    final table =
        PostgrestTableNames.firmTable(firmNr, 'permission_group_menus');
    try {
      final rows = await client.getRows(
        '/$table',
        query: {
          'select':
              'group_id,menu_uuid,can_view,can_add,can_edit,can_delete,'
                  'created_at,updated_at',
          'limit': '10000',
        },
      );
      final database = await _db();
      await database.execute(SqlQuerys.createPermissionGroupMenusTable);
      final batch = database.batch();
      var n = 0;
      final now = DateTime.now().toIso8601String();
      for (final r in rows) {
        final gid = (r['group_id'] ?? '').toString().trim();
        final mid = (r['menu_uuid'] ?? '').toString().trim();
        if (gid.isEmpty || mid.isEmpty) continue;
        batch.insert(
          'permission_group_menus',
          {
            'group_id': gid,
            'menu_uuid': mid,
            'can_view':
                (r['can_view'] == false || r['can_view'] == 0) ? 0 : 1,
            'can_add':
                (r['can_add'] == true || r['can_add'] == 1) ? 1 : 0,
            'can_edit':
                (r['can_edit'] == true || r['can_edit'] == 1) ? 1 : 0,
            'can_delete':
                (r['can_delete'] == true || r['can_delete'] == 1) ? 1 : 0,
            'created_at': (r['created_at'] ?? now).toString(),
            'updated_at': (r['updated_at'] ?? now).toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        n++;
      }
      await batch.commit(noResult: true);
      debugPrint('PostgREST → SQLite permission_group_menus: $n ($table)');
      return n;
    } catch (e) {
      debugPrint('PostgrestPermissionGroupsSync._pullMenus: $e');
      return 0;
    }
  }

  Future<int> _pullMembers(String firmNr) async {
    final table =
        PostgrestTableNames.firmTable(firmNr, 'permission_group_members');
    try {
      final rows = await client.getRows(
        '/$table',
        query: {
          'select': 'group_id,user_id,company_no,created_at,updated_at',
          'limit': '10000',
        },
      );
      final database = await _db();
      await database.execute(SqlQuerys.createPermissionGroupMembersTable);
      final batch = database.batch();
      var n = 0;
      final now = DateTime.now().toIso8601String();
      for (final r in rows) {
        final gid = (r['group_id'] ?? '').toString().trim();
        final uid = (r['user_id'] ?? '').toString().trim();
        if (gid.isEmpty || uid.isEmpty) continue;
        final companyNo = int.tryParse('${r['company_no']}') ?? 0;
        batch.insert(
          'permission_group_members',
          {
            'group_id': gid,
            'user_id': uid,
            'company_no': companyNo,
            'created_at': (r['created_at'] ?? now).toString(),
            'updated_at': (r['updated_at'] ?? now).toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        n++;
      }
      await batch.commit(noResult: true);
      debugPrint('PostgREST → SQLite permission_group_members: $n ($table)');
      return n;
    } catch (e) {
      debugPrint('PostgrestPermissionGroupsSync._pullMembers: $e');
      return 0;
    }
  }
}
