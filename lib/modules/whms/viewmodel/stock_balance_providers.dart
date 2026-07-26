// Dosya Adı: stock_balance_providers.dart
// Açıklama: StockBalancePort Riverpod DI — Logo + yerel fallback (Faz 2.1/2.2)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../service/database_service.dart';
import '../../../core/services/logo_api_service.dart';
import '../contract/stock_balance_port.dart';
import '../data/local_warehouse_stock_balance_port.dart';
import '../data/logo_stock_balance_port.dart';

/// {@template local_stock_balance_port_provider}
/// Yalnız SQLite [LocalWarehouseStockBalancePort].
/// {@endtemplate}
final localStockBalancePortProvider =
    FutureProvider<StockBalancePort>((ref) async {
  final dbService = await DatabaseService.getInstance();
  final db = await dbService.getDatabase();
  return LocalWarehouseStockBalancePort(db);
});

/// {@template stock_balance_port_provider}
/// Üretim varsayılanı: Logo port + yerel fallback (van yerel).
///
/// Kullanım örneği:
/// ```dart
/// final port = await ref.watch(stockBalancePortProvider.future);
/// ```
/// {@endtemplate}
final stockBalancePortProvider = FutureProvider<StockBalancePort>((ref) async {
  final local = await ref.watch(localStockBalancePortProvider.future);
  return LogoStockBalancePort.fromApi(
    api: LogoApiService(),
    fallback: local,
  );
});
