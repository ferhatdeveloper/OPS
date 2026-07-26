import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/services/gps_service.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../../../../service/database_service.dart';
import '../../../../service/gamification_service.dart';
import '../../../../service/job_queue_service.dart';
import '../../../../service/notification_service.dart';
import '../model/route_model.dart';
import '../model/visit_mbt_form_data.dart';
import '../model/visit_reason_master.dart';

class VisitState {
  final List<RouteModel> availableRoutes;
  final RouteModel? activeRoute;
  final List<RouteCustomerModel> routeCustomers;
  final VisitModel? activeVisit;
  final List<String> completedCustomerIds;
  final bool isLoading;
  final String? error;

  VisitState({
    this.availableRoutes = const [],
    this.activeRoute,
    this.routeCustomers = const [],
    this.activeVisit,
    this.completedCustomerIds = const [],
    this.isLoading = false,
    this.error,
  });

  VisitState copyWith({
    List<RouteModel>? availableRoutes,
    RouteModel? activeRoute,
    List<RouteCustomerModel>? routeCustomers,
    VisitModel? activeVisit,
    List<String>? completedCustomerIds,
    bool? isLoading,
    String? error,
  }) {
    return VisitState(
      availableRoutes: availableRoutes ?? this.availableRoutes,
      activeRoute: activeRoute ?? this.activeRoute,
      routeCustomers: routeCustomers ?? this.routeCustomers,
      activeVisit: activeVisit ?? this.activeVisit,
      completedCustomerIds: completedCustomerIds ?? this.completedCustomerIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VisitNotifier extends StateNotifier<VisitState> {
  Timer? _locationTimer;

  VisitNotifier() : super(VisitState()) {
    _initialize();
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    // Start continuous location tracking via GpsService singleton
    GpsService().startTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await fetchRoutes();
    await fetchActiveVisit();
    await fetchCompletedVisits();
  }

  Future<void> fetchCompletedVisits() async {
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      final results = await sqliteDb.query(
        'visits',
        where: "status = 'Completed' AND check_in_at LIKE ?",
        whereArgs: ['$today%'],
      );

      final completedIds = results.map((r) => r['customer_id'] as String).toList();
      state = state.copyWith(completedCustomerIds: completedIds);
    } catch (e) {
      debugPrint('Error fetching completed visits: $e');
    }
  }

  Future<void> fetchRoutes() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      
      // Get today's day of week (1-7)
      final today = DateTime.now().weekday;
      
      final routeResults = await sqliteDb.query(
        'routes',
        where: 'is_active = 1 AND day_of_week = ?',
        whereArgs: [today],
      );

      final routes = <RouteModel>[];
      for (final r in routeResults) {
        final custResults = await sqliteDb.query(
          'route_customers',
          where: 'route_id = ?',
          whereArgs: [r['id']],
          orderBy: 'visit_order',
        );
        
        // Join with customers table for names and addresses
        // In a real app, this would be a single complex query with JOIN
        final customers = <RouteCustomerModel>[];
        for (final rc in custResults) {
          final custInfo = await sqliteDb.query(
            'customers',
            columns: ['name', 'address', 'latitude', 'longitude'],
            where: 'id = ?',
            whereArgs: [rc['customer_id']],
          );
          
          final mapWithInfo = Map<String, dynamic>.from(rc);
          if (custInfo.isNotEmpty) {
            mapWithInfo['customer_name'] = custInfo.first['name'];
            mapWithInfo['customer_address'] = custInfo.first['address'];
            mapWithInfo['latitude'] = custInfo.first['latitude'];
            mapWithInfo['longitude'] = custInfo.first['longitude'];
          }
          customers.add(RouteCustomerModel.fromMap(mapWithInfo));
        }
        
        routes.add(RouteModel.fromMap(r, customers));
      }

      state = state.copyWith(
        availableRoutes: routes,
        activeRoute: routes.isNotEmpty ? routes.first : null,
        routeCustomers: routes.isNotEmpty ? routes.first.customers : [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchActiveVisit() async {
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      
      final results = await sqliteDb.query(
        'visits',
        where: 'status = ?',
        whereArgs: ['Open'],
        limit: 1,
      );

      if (results.isNotEmpty) {
        state = state.copyWith(activeVisit: VisitModel.fromMap(results.first));
      } else {
        state = state.copyWith(activeVisit: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> checkIn(String customerId) async {
    if (state.activeVisit != null) {
      // UI: AppLocalization.translate(error) — l10n key
      state = state.copyWith(error: 'field_sales.visit_already_open');
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final gps = GpsService();
      final hasPermission = await gps.checkPermissions();
      if (!hasPermission) {
        state = state.copyWith(
          isLoading: false,
          error: 'customer.location_permission_denied',
        );
        return false;
      }

      // Geofencing Check
      final routeCustomer = state.routeCustomers.firstWhere((rc) => rc.customerId == customerId);
      if (routeCustomer.latitude != null && routeCustomer.longitude != null) {
        final inRange = await gps.isWithinVisitRange(routeCustomer.latitude!, routeCustomer.longitude!);
        if (!inRange) {
          state = state.copyWith(
            isLoading: false,
            error: 'field_sales.too_far_from_customer',
          );
          return false;
        }
      }

      final position = await gps.getCurrentPosition();
      final visitId = const Uuid().v4();
      final visit = VisitModel(
        id: visitId,
        customerId: customerId,
        checkInAt: DateTime.now(),
        checkInLat: position?.latitude,
        checkInLong: position?.longitude,
        status: 'Open',
      );

      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      await sqliteDb.insert('visits', visit.toMap());

      state = state.copyWith(activeVisit: visit, isLoading: false);

      // Bildirim — NotificationService refactor yok; l10n key bağlama
      final l10n = await AppLocalization.resolve();
      await NotificationService().showNotification(
        id: 100,
        title: l10n.translate('field_sales.visit_started_notif_title'),
        body: l10n.translate('field_sales.visit_started_notif_body'),
      );

      // Phase 9: Reward Points
      final session = await db.getUserSession();
      final userId = session?['id'] as String? ?? 'current_user';
      await GamificationService().addPoints(
        userId,
        GamificationService.pointsPerVisit,
        l10n.translate('field_sales.visit_started_points_reason'),
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> checkOut(
    String notes, {
    String? signatureData,
    String? reasonCode,
  }) async {
    if (state.activeVisit == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final position = await GpsService().getCurrentPosition();

      final checkOutTime = DateTime.now();
      final duration =
          checkOutTime.difference(state.activeVisit!.checkInAt).inMinutes;

      final code = reasonCode?.trim();
      final updatedVisit = state.activeVisit!.copyWith(
        checkOutAt: checkOutTime,
        checkOutLat: position?.latitude,
        checkOutLong: position?.longitude,
        notes: notes,
        reasonCode: (code != null && code.isNotEmpty) ? code : null,
        status: 'Completed',
        durationMinutes: duration,
        signatureData: signatureData,
      );

      final db = await DatabaseService.getInstance();
      await db.ensureVisitsTableSchema();
      final sqliteDb = await db.getDatabase();
      await sqliteDb.update(
        'visits',
        updatedVisit.toMap(),
        where: 'id = ?',
        whereArgs: [updatedVisit.id],
      );

      await _enqueueVisitSync(sqliteDb, updatedVisit);

      state = state.copyWith(
        activeVisit: null,
        completedCustomerIds: [
          ...state.completedCustomerIds,
          updatedVisit.customerId,
        ],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// {@template completeMbtVisit}
  /// MBT ziyaret formunu tamamlar (ZIYARETI TAMAMLA).
  ///
  /// Açık ziyaret varsa check-out; yoksa tamamlanmış kayıt ekler.
  ///
  /// Parametreler:
  /// - [customerId]: Cari kimliği
  /// - [form]: MBT alan seti (not / sonuç / sebep…)
  ///
  /// Dönüş değeri:
  /// - [bool]: Başarı durumu
  /// {@endtemplate}
  Future<bool> completeMbtVisit({
    required String customerId,
    required VisitMbtFormData form,
  }) async {
    final notes = form.toPersistedNotes();
    if (notes.trim().isEmpty) {
      state = state.copyWith(error: 'field_sales.note_required');
      return false;
    }

    final reasonCode = form.visitReason.trim();
    if (!VisitReasonMaster.contains(reasonCode)) {
      state = state.copyWith(error: 'field_sales.visit_reason_required');
      return false;
    }

    final active = state.activeVisit;
    if (active != null && active.customerId == customerId) {
      return checkOut(notes, reasonCode: reasonCode);
    }

    state = state.copyWith(isLoading: true);
    try {
      final position = await GpsService().getCurrentPosition();
      final now = DateTime.now();
      final visit = VisitModel(
        id: const Uuid().v4(),
        customerId: customerId,
        checkInAt: now,
        checkOutAt: now,
        checkInLat: position?.latitude,
        checkInLong: position?.longitude,
        checkOutLat: position?.latitude,
        checkOutLong: position?.longitude,
        notes: notes,
        reasonCode: reasonCode,
        status: 'Completed',
        durationMinutes: 0,
      );

      final db = await DatabaseService.getInstance();
      await db.ensureVisitsTableSchema();
      final sqliteDb = await db.getDatabase();
      await sqliteDb.insert('visits', visit.toMap());

      await _enqueueVisitSync(sqliteDb, visit);

      state = state.copyWith(
        activeVisit: null,
        completedCustomerIds: [
          ...state.completedCustomerIds,
          customerId,
        ],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// {@template enqueue_visit_sync}
  /// Tamamlanan ziyareti Logo/sync kuyruğuna ekler (`reason_code` → SPECODE).
  /// {@endtemplate}
  Future<void> _enqueueVisitSync(
    Database sqliteDb,
    VisitModel visit,
  ) async {
    try {
      String customerCode = visit.customerId;
      String? customerName;
      final rows = await sqliteDb.query(
        'customers',
        where: 'id = ?',
        whereArgs: [visit.customerId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final c = rows.first;
        customerCode =
            (c['code'] ?? c['tax_no'] ?? c['id'] ?? visit.customerId)
                .toString();
        customerName = c['name']?.toString();
      }

      String? salesmanCode;
      try {
        final db = await DatabaseService.getInstance();
        final session = await db.getUserSession();
        salesmanCode = session?['code']?.toString() ??
            session?['username']?.toString();
      } catch (_) {}

      final payload = buildVisitSyncPayload(
        visit: visit,
        customerCode: customerCode,
        customerName: customerName,
        salesmanCode: salesmanCode,
      );

      await JobQueueService().enqueue(
        entityType: LogoPayloadMapper.visitEntityType,
        entityId: visit.id,
        payload: payload,
        priority: 1,
      );
    } catch (e) {
      debugPrint('Visit sync enqueue failed: $e');
    }
  }
}

/// {@template build_visit_sync_payload}
/// VisitModel → Logo/sync payload (`reason_code` dahil).
///
/// Kullanım örneği:
/// ```dart
/// final p = buildVisitSyncPayload(
///   visit: visit,
///   customerCode: 'C1',
/// );
/// assert(p['SPECODE'] == 'ORDER');
/// ```
/// {@endtemplate}
Map<String, dynamic> buildVisitSyncPayload({
  required VisitModel visit,
  required String customerCode,
  String? customerName,
  String? salesmanCode,
}) {
  return LogoPayloadMapper.visitFromLocal(
    visit: visit.toMap(),
    customerCode: customerCode,
    customerName: customerName,
    salesmanCode: salesmanCode,
  );
}

final visitProvider = StateNotifierProvider<VisitNotifier, VisitState>((ref) {
  return VisitNotifier();
});

extension VisitModelExtension on VisitModel {
  VisitModel copyWith({
    String? id,
    String? customerId,
    String? userId,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    double? checkInLat,
    double? checkInLong,
    double? checkOutLat,
    double? checkOutLong,
    String? notes,
    String? reasonCode,
    String? status,
    int? durationMinutes,
    bool? isSynced,
    String? signatureData,
  }) {
    return VisitModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLong: checkInLong ?? this.checkInLong,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLong: checkOutLong ?? this.checkOutLong,
      notes: notes ?? this.notes,
      reasonCode: reasonCode ?? this.reasonCode,
      status: status ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isSynced: isSynced ?? this.isSynced,
      signatureData: signatureData ?? this.signatureData,
    );
  }
}
