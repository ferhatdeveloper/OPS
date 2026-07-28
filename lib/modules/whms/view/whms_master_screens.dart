// Dosya Adı: whms_master_screens.dart
// Açıklama: WHMS dens master ekran sarmalayıcıları (araç/lot/rezervasyon/iade)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../core/database/migrations/SqlQuerys.dart';
import '../contract/whms_route_map.dart';
import '../viewmodel/whms_code_name_store.dart';
import 'whms_master_code_name_list_screen.dart';

/// Araç tipi listesi — `/whms/vehicle-types`
class WhmsVehicleTypeListScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsVehicleTypes;

  /// {@macro whms_master_code_name_list_screen}
  const WhmsVehicleTypeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WhmsMasterCodeNameListScreen(
      routeName: routeName,
      titleKey: 'whms.defs.vehicle_types',
      emptyKey: 'whms.master.vehicle_type_empty',
      searchKey: 'whms.master.search',
      store: const WhmsCodeNameStore(
        tableName: 'whms_vehicle_types',
        createSql: SqlQuerys.createWhmsVehicleTypesTable,
      ),
    );
  }
}

/// Araç listesi — `/whms/vehicles`
class WhmsVehicleListScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsVehicles;

  /// {@macro whms_master_code_name_list_screen}
  const WhmsVehicleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WhmsMasterCodeNameListScreen(
      routeName: routeName,
      titleKey: 'whms.defs.vehicles',
      emptyKey: 'whms.master.vehicle_empty',
      searchKey: 'whms.master.search',
      store: const WhmsCodeNameStore(
        tableName: 'whms_vehicles',
        createSql: SqlQuerys.createWhmsVehiclesTable,
      ),
    );
  }
}

/// Lot / SKT — `/whms/lot`
class WhmsLotListScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsLot;

  /// {@macro whms_master_code_name_list_screen}
  const WhmsLotListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WhmsMasterCodeNameListScreen(
      routeName: routeName,
      titleKey: 'whms.hub.lot',
      emptyKey: 'whms.master.lot_empty',
      searchKey: 'whms.master.search',
      store: const WhmsCodeNameStore(
        tableName: 'whms_lots',
        createSql: SqlQuerys.createWhmsLotsTable,
      ),
    );
  }
}

/// Rezervasyon — `/whms/reservation`
class WhmsReservationListScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsReservation;

  /// {@macro whms_master_code_name_list_screen}
  const WhmsReservationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WhmsMasterCodeNameListScreen(
      routeName: routeName,
      titleKey: 'whms.hub.reservation',
      emptyKey: 'whms.master.reservation_empty',
      searchKey: 'whms.master.search',
      store: const WhmsCodeNameStore(
        tableName: 'whms_reservations',
        createSql: SqlQuerys.createWhmsReservationsTable,
      ),
    );
  }
}

/// İade — `/whms/returns`
class WhmsReturnListScreen extends StatelessWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsReturns;

  /// {@macro whms_master_code_name_list_screen}
  const WhmsReturnListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WhmsMasterCodeNameListScreen(
      routeName: routeName,
      titleKey: 'whms.hub.returns',
      emptyKey: 'whms.master.return_empty',
      searchKey: 'whms.master.search',
      store: const WhmsCodeNameStore(
        tableName: 'whms_returns',
        createSql: SqlQuerys.createWhmsReturnsTable,
      ),
    );
  }
}
