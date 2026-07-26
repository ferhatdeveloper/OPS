// Dosya Adı: stock_transfer_service.dart
// Açıklama: Ambar transferi yerel stok txn + SQLite + Logo kuyruk
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../service/database_service.dart';
import '../../../whms/contract/whms_bridge_dto.dart';
import '../../../whms/queue/whms_transfer_queue_bridge.dart';
import '../model/stock_transfer_model.dart';
import 'warehouse_transfer_stock_txn.dart';

/// {@template stock_transfer_dens_line}
/// Dens satırından ambar transfer kalemi.
/// {@endtemplate}
class StockTransferDensLine {
  /// [productCode]: Ürün / stok kodu
  final String productCode;

  /// [productName]: Görünen ad (opsiyonel)
  final String? productName;

  /// [quantityText]: Miktar metni
  final String quantityText;

  /// [unitName]: Birim adı
  final String? unitName;

  const StockTransferDensLine({
    required this.productCode,
    this.productName,
    required this.quantityText,
    this.unitName,
  });
}

/// {@template stock_transfer_submit_result}
/// Dens Kaydet sonucu.
/// {@endtemplate}
class StockTransferSubmitResult {
  /// [success]: İşlem başarılı mı
  final bool success;

  /// [batchId]: Fiş / kuyruk entity id
  final String? batchId;

  /// [errorKey]: l10n hata anahtarı
  final String? errorKey;

  const StockTransferSubmitResult({
    required this.success,
    this.batchId,
    this.errorKey,
  });
}

/// {@template stock_transfer_service}
/// Ambar transferi: yerel stok txn + `warehouse_transfers` + Logo kuyruk.
///
/// Kullanım örneği:
/// ```dart
/// await StockTransferService.submitDensTransfer(
///   fromWarehouse: 'Merkez',
///   toWarehouse: 'Araç',
///   date: DateTime.now(),
///   lines: const [],
/// );
/// ```
/// {@endtemplate}
class StockTransferService {
  /// {@template stock_transfer_service_create}
  /// Tek satır: yerel stok txn + transfer kaydı (kuyruk yok).
  ///
  /// Parametreler:
  /// - [transfer]: Transfer modeli
  /// - [vehicleId]: Araç deposu için opsiyonel araç id
  ///
  /// Dönüş: true = insert + stok OK
  /// {@endtemplate}
  static Future<bool> createTransfer(
    StockTransferModel transfer, {
    String? vehicleId,
  }) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      await db.transaction((txn) async {
        await WarehouseTransferStockTxn.applyLine(
          db: txn,
          fromWarehouse: transfer.fromWarehouse,
          toWarehouse: transfer.toWarehouse,
          productId: transfer.productId,
          quantity: transfer.quantity,
          vehicleId: vehicleId,
        );
        final completed = StockTransferModel(
          id: transfer.id,
          fromWarehouse: transfer.fromWarehouse,
          toWarehouse: transfer.toWarehouse,
          productId: transfer.productId,
          quantity: transfer.quantity,
          unitName: transfer.unitName,
          transferDate: transfer.transferDate,
          status: 'Completed',
          isSynced: false,
          createdAt: transfer.createdAt ?? DateTime.now(),
          productCode: transfer.productCode,
          productName: transfer.productName,
        );
        await txn.insert('warehouse_transfers', completed.toMap());
      });

      return true;
    } catch (e) {
      debugPrint('StockTransferService Error: $e');
      return false;
    }
  }

  /// {@template stock_transfer_service_submit_dens}
  /// Dens Kaynak→Hedef: yerel stok txn + kayıt + Logo kuyruğu.
  ///
  /// Parametreler:
  /// - [fromWarehouse]: Kaynak ambar
  /// - [toWarehouse]: Hedef ambar
  /// - [date]: Fiş tarihi
  /// - [lines]: Kalemler
  /// - [sourceMeta]: İşyeri/fabrika (opsiyonel)
  /// - [targetMeta]: İşyeri/fabrika (opsiyonel)
  /// - [vehicleId]: Araç deposu için opsiyonel araç id
  ///
  /// Dönüş: [StockTransferSubmitResult]
  /// {@endtemplate}
  static Future<StockTransferSubmitResult> submitDensTransfer({
    required String fromWarehouse,
    required String toWarehouse,
    required DateTime date,
    required List<StockTransferDensLine> lines,
    Map<String, String?>? sourceMeta,
    Map<String, String?>? targetMeta,
    String? vehicleId,
  }) async {
    final fromWh = fromWarehouse.trim();
    final toWh = toWarehouse.trim();
    if (fromWh.isEmpty || toWh.isEmpty) {
      return const StockTransferSubmitResult(
        success: false,
        errorKey: 'field_sales.stock_slip.transfer_requires_warehouses',
      );
    }
    final sameMeta = (sourceMeta?['workplace'] ?? '') ==
            (targetMeta?['workplace'] ?? '') &&
        (sourceMeta?['factory'] ?? '') == (targetMeta?['factory'] ?? '');
    if (fromWh == toWh && sameMeta) {
      return const StockTransferSubmitResult(
        success: false,
        errorKey: 'field_sales.stock_slip.transfer_same_warehouse',
      );
    }

    final parsedLines = <({StockTransferDensLine line, double qty})>[];
    for (final line in lines) {
      final qty = double.tryParse(line.quantityText.replaceAll(',', '.')) ?? 0;
      if (qty <= 0) continue;
      if (line.productCode.trim().isEmpty) continue;
      parsedLines.add((line: line, qty: qty));
    }
    if (parsedLines.isEmpty) {
      return const StockTransferSubmitResult(
        success: false,
        errorKey: 'field_sales.stock_slip.transfer_requires_lines',
      );
    }

    final batchId = const Uuid().v4();
    final transferIds = <String>[];
    final payloadLines = <Map<String, dynamic>>[];

    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      await db.transaction((txn) async {
        for (final entry in parsedLines) {
          final line = entry.line;
          final qty = entry.qty;
          final productId = await _resolveProductId(
            txn,
            line.productCode.trim(),
          );
          final transferId = const Uuid().v4();
          transferIds.add(transferId);

          await WarehouseTransferStockTxn.applyLine(
            db: txn,
            fromWarehouse: fromWh,
            toWarehouse: toWh,
            productId: productId,
            quantity: qty,
            vehicleId: vehicleId,
          );

          final model = StockTransferModel(
            id: transferId,
            fromWarehouse: fromWh,
            toWarehouse: toWh,
            productId: productId,
            quantity: qty,
            unitName: line.unitName,
            transferDate: date,
            status: 'Completed',
            isSynced: false,
            createdAt: DateTime.now(),
            productCode: line.productCode.trim(),
            productName: line.productName,
          );
          await txn.insert('warehouse_transfers', model.toMap());

          payloadLines.add({
            'transfer_id': transferId,
            'product_id': productId,
            'product_code': line.productCode.trim(),
            'quantity': qty,
            if (line.unitName != null) 'unit_name': line.unitName,
          });
        }
      });

      final bridgeLines = payloadLines
          .map(
            (p) => WhmsBridgeLine(
              productId: p['product_id']?.toString() ?? '',
              productCode: p['product_code']?.toString() ?? '',
              quantity: (p['quantity'] as num?)?.toDouble() ?? 0,
              unitName: p['unit_name']?.toString(),
            ),
          )
          .toList(growable: false);

      // Faz 2.2: ONAY=1 + WhmsPayloadMapper alanları ile tek kuyruk
      final bridgeOutcome =
          await WhmsTransferQueueBridge().enqueueApprovedFromDens(
        batchId: batchId,
        fromWarehouse: fromWh,
        toWarehouse: toWh,
        date: date,
        transferIds: transferIds,
        lines: bridgeLines,
      );
      if (bridgeOutcome.status == WhmsTransferEnqueueStatus.failed) {
        return const StockTransferSubmitResult(
          success: false,
          errorKey: 'field_sales.stock_slip.transfer_save_failed',
        );
      }

      return StockTransferSubmitResult(success: true, batchId: batchId);
    } on StateError catch (e) {
      debugPrint('StockTransferService submitDensTransfer: $e');
      return StockTransferSubmitResult(
        success: false,
        errorKey: _errorKeyForState(e),
      );
    } catch (e) {
      debugPrint('StockTransferService submitDensTransfer: $e');
      return const StockTransferSubmitResult(
        success: false,
        errorKey: 'field_sales.stock_slip.transfer_save_failed',
      );
    }
  }

  /// StateError mesajını l10n anahtarına çevirir.
  static String _errorKeyForState(StateError e) {
    final msg = e.message;
    switch (msg) {
      case 'transfer_insufficient_stock':
        return 'field_sales.stock_slip.transfer_insufficient_stock';
      case 'transfer_unknown_warehouse':
        return 'field_sales.stock_slip.transfer_unknown_warehouse';
      case 'transfer_vehicle_required':
        return 'field_sales.stock_slip.transfer_vehicle_required';
      case 'transfer_product_missing':
        return 'field_sales.stock_slip.transfer_product_missing';
      case 'transfer_qty_invalid':
        return 'field_sales.stock_slip.transfer_requires_lines';
      default:
        return 'field_sales.stock_slip.transfer_save_failed';
    }
  }

  /// Ürün kodundan id; yoksa kodu id olarak kullanır (dens stub).
  static Future<String> _resolveProductId(
    DatabaseExecutor txn,
    String productCode,
  ) async {
    try {
      final byCode = await txn.query(
        'products',
        columns: ['id', 'code'],
        where: 'code = ? OR id = ?',
        whereArgs: [productCode, productCode],
        limit: 1,
      );
      if (byCode.isNotEmpty && byCode.first['id'] != null) {
        return byCode.first['id'].toString();
      }
    } catch (e) {
      debugPrint('StockTransferService product resolve: $e');
    }
    return productCode;
  }

  /// {@template stock_transfer_service_get}
  /// Tüm ambar transferlerini listeler.
  /// {@endtemplate}
  static Future<List<StockTransferModel>> getTransfers() async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      final results = await db.rawQuery('''
        SELECT t.*, p.name as product_name, p.code as product_code 
        FROM warehouse_transfers t
        LEFT JOIN products p ON t.product_id = p.id
        ORDER BY t.transfer_date DESC
      ''');

      return results.map((r) => StockTransferModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('StockTransferService Error: $e');
      return [];
    }
  }
}
