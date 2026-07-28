// Dosya Adı: salesperson_customer_scope.dart
// Açıklama: Plasiyer kendi carileri (routes.salesperson_id + visits)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../../core/auth/app_user_role.dart';
import '../../../../service/database_service.dart';

/// {@template salesperson_customer_scope_result}
/// Plasiyer cari kapsam sonucu + rota atanmamış bayrağı.
/// {@endtemplate}
class SalespersonCustomerScopeResult {
  /// [filterIds]: `null` = tüm cariler; dolu = filtre; boş set kullanılmaz
  final Set<String>? filterIds;

  /// [routeUnassigned]: Rota/ziyaret yok → aktif cari fallback kullanıldı
  final bool routeUnassigned;

  /// {@macro salesperson_customer_scope_result}
  const SalespersonCustomerScopeResult({
    this.filterIds,
    this.routeUnassigned = false,
  });
}

/// {@template salesperson_customer_scope}
/// AI öngörü / forecast için cari kapsamı.
/// Admin / süpervizör → filtre yok (`null`).
/// Plasiyer → `routes.salesperson_id` + `route_customers` ∪ `visits.user_id`.
/// Rota/ziyaret boşsa → aktif cariler + [routeUnassigned].
///
/// Kullanım örneği:
/// ```dart
/// final r = await SalespersonCustomerScope().resolve(
///   role: AppUserRole.salesperson,
///   userId: 'u1',
/// );
/// ```
/// {@endtemplate}
class SalespersonCustomerScope {
  /// [db]: Test enjeksiyonu
  final Database? db;

  /// {@macro salesperson_customer_scope}
  const SalespersonCustomerScope({this.db});

  /// {@template salesperson_customer_scope_resolve}
  /// Filtre + rota uyarısı.
  ///
  /// Dönüş değeri:
  /// - [SalespersonCustomerScopeResult]
  /// {@endtemplate}
  Future<SalespersonCustomerScopeResult> resolve({
    required AppUserRole role,
    String? userId,
  }) async {
    if (role.seesFullMenu) {
      return const SalespersonCustomerScopeResult();
    }
    if (role != AppUserRole.salesperson) {
      return const SalespersonCustomerScopeResult();
    }

    final uid = (userId ?? '').trim();
    if (uid.isEmpty) {
      return const SalespersonCustomerScopeResult(routeUnassigned: true);
    }

    final database = db ?? await _openDb();
    final out = <String>{};

    try {
      final routeRows = await database.rawQuery(
        '''
        SELECT DISTINCT rc.customer_id AS customer_id
        FROM route_customers rc
        INNER JOIN routes r ON r.id = rc.route_id
        WHERE TRIM(COALESCE(r.salesperson_id, '')) = ?
          AND COALESCE(r.is_active, 1) = 1
          AND rc.customer_id IS NOT NULL
          AND TRIM(rc.customer_id) != ''
        ''',
        [uid],
      );
      for (final r in routeRows) {
        final id = (r['customer_id'] ?? '').toString().trim();
        if (id.isNotEmpty) out.add(id);
      }
    } catch (_) {
      // Tablo yoksa visits ile devam
    }

    try {
      final visitRows = await database.rawQuery(
        '''
        SELECT DISTINCT customer_id
        FROM visits
        WHERE TRIM(COALESCE(user_id, '')) = ?
          AND customer_id IS NOT NULL
          AND TRIM(customer_id) != ''
        ''',
        [uid],
      );
      for (final r in visitRows) {
        final id = (r['customer_id'] ?? '').toString().trim();
        if (id.isNotEmpty) out.add(id);
      }
    } catch (_) {
      // visits yoksa rota seti yeter
    }

    if (out.isNotEmpty) {
      return SalespersonCustomerScopeResult(filterIds: out);
    }

    // Rota/ziyaret yok → aktif cariler (bilinçli boş yerine kullanılabilir)
    final active = await _activeCustomerIds(database);
    return SalespersonCustomerScopeResult(
      filterIds: active.isEmpty ? null : active,
      routeUnassigned: true,
    );
  }

  /// {@template salesperson_customer_scope_resolve_filter_ids}
  /// Yalnız filtre seti (geri uyumluluk).
  ///
  /// Dönüş değeri:
  /// - `null`: tüm cariler
  /// - dolu set: yalnızca bu cariler
  /// {@endtemplate}
  Future<Set<String>?> resolveFilterIds({
    required AppUserRole role,
    String? userId,
  }) async {
    final r = await resolve(role: role, userId: userId);
    return r.filterIds;
  }

  Future<Set<String>> _activeCustomerIds(Database database) async {
    try {
      final rows = await database.rawQuery(
        '''
        SELECT id
        FROM customers
        WHERE COALESCE(is_active, 1) = 1
          AND id IS NOT NULL
          AND TRIM(id) != ''
        ''',
      );
      final out = <String>{};
      for (final r in rows) {
        final id = (r['id'] ?? '').toString().trim();
        if (id.isNotEmpty) out.add(id);
      }
      return out;
    } catch (_) {
      return <String>{};
    }
  }

  Future<Database> _openDb() async {
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }
}
