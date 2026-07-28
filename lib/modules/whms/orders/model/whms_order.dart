// Dosya Adı: whms_order.dart
// Açıklama: Emir dens liste satır adaptörü + tek store kaynağı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../model/whms_order_dto.dart';
import '../../model/whms_order_status.dart';
import '../../model/whms_order_type.dart';
import '../../viewmodel/whms_order_store.dart';

export '../../model/whms_order_dto.dart';
export '../../model/whms_order_status.dart';
export '../../model/whms_order_type.dart';

/// {@template whms_order}
/// Dens emir liste satırı — [WhmsOrderDto] özeti.
///
/// Kullanım örneği:
/// ```dart
/// final row = WhmsOrder.fromDto(dto);
/// ```
/// {@endtemplate}
class WhmsOrder {
  /// [id]: Yerel kimlik
  final String id;

  /// [code]: Görünen emir kodu / referans
  final String code;

  /// [type]: Emir tipi
  final WhmsOrderType type;

  /// [status]: Yaşam durumu
  final WhmsOrderStatus status;

  /// [date]: Emir tarihi
  final DateTime? date;

  /// [warehouseCode]: Ambar kodu
  final String? warehouseCode;

  /// [lineCount]: Satır adedi
  final int lineCount;

  /// [note]: Kısa not
  final String? note;

  /// {@macro whms_order}
  const WhmsOrder({
    required this.id,
    required this.code,
    required this.type,
    required this.status,
    this.date,
    this.warehouseCode,
    this.lineCount = 0,
    this.note,
  });

  /// DTO → liste satırı.
  factory WhmsOrder.fromDto(WhmsOrderDto dto) {
    final ref = (dto.referenceNo ?? '').trim();
    return WhmsOrder(
      id: dto.id,
      code: ref.isNotEmpty ? ref : dto.id,
      type: dto.orderType,
      status: dto.status,
      date: DateTime.tryParse(dto.orderDate),
      warehouseCode: dto.warehouseCode,
      lineCount: dto.lines.length,
      note: dto.notes,
    );
  }
}

/// {@template whms_order_list_source}
/// Tek emir listesi kaynağı — [WhmsOrderStore] üzerinden.
///
/// Kullanım örneği:
/// ```dart
/// final rows = await const WhmsOrderListSource().list();
/// ```
/// {@endtemplate}
class WhmsOrderListSource {
  /// [store]: Emir persist
  final WhmsOrderStore store;

  /// {@macro whms_order_list_source}
  const WhmsOrderListSource({
    this.store = const WhmsOrderStore(),
  });

  /// {@template whms_order_list_source_list}
  /// Tip/durum store filtresi; dönem + arama yerelde.
  ///
  /// Parametreler:
  /// - [type]: Tip (null = tümü)
  /// - [status]: Durum (null = tümü)
  /// - [from] / [to]: Dönem (dahil)
  /// - [query]: id / referans / ambar / not
  ///
  /// Dönüş değeri:
  /// - [List]: [WhmsOrderDto] satırları
  /// {@endtemplate}
  Future<List<WhmsOrderDto>> list({
    WhmsOrderType? type,
    WhmsOrderStatus? status,
    DateTime? from,
    DateTime? to,
    String query = '',
  }) async {
    await store.ensureReady();
    final rows = await store.list(type: type, status: status);
    final q = query.trim().toLowerCase();
    return rows.where((dto) {
      final parsed = DateTime.tryParse(dto.orderDate.trim());
      if (from != null && parsed != null) {
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day.isBefore(from)) return false;
      }
      if (to != null && parsed != null) {
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day.isAfter(to)) return false;
      }
      if (q.isEmpty) return true;
      final hay = [
        dto.id,
        dto.referenceNo ?? '',
        dto.warehouseCode ?? '',
        dto.notes ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList(growable: false);
  }
}
