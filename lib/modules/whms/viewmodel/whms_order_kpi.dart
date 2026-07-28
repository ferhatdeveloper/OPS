// Dosya Adı: whms_order_kpi.dart
// Açıklama: WHMS emir KPI özet modeli (offline SQLite agregasyon)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../model/whms_order_status.dart';
import '../model/whms_order_type.dart';

/// {@template whms_order_kpi}
/// Emir KPI snapshot — tip / durum sayıları.
///
/// Kullanım örneği:
/// ```dart
/// final kpi = WhmsOrderKpi.empty();
/// print(kpi.total);
/// ```
/// {@endtemplate}
class WhmsOrderKpi {
  /// [total]: Soft-delete hariç toplam emir
  final int total;

  /// [byType]: Tip → adet
  final Map<WhmsOrderType, int> byType;

  /// [byStatus]: Durum → adet
  final Map<WhmsOrderStatus, int> byStatus;

  /// [approvedCount]: ONAY=1
  final int approvedCount;

  /// [pendingApproval]: ONAY=0
  final int pendingApproval;

  /// [openCount]: draft|assigned|in_progress
  final int openCount;

  /// [doneCount]: done
  final int doneCount;

  /// {@macro whms_order_kpi}
  const WhmsOrderKpi({
    required this.total,
    required this.byType,
    required this.byStatus,
    required this.approvedCount,
    required this.pendingApproval,
    required this.openCount,
    required this.doneCount,
  });

  /// Boş KPI.
  factory WhmsOrderKpi.empty() => const WhmsOrderKpi(
        total: 0,
        byType: {},
        byStatus: {},
        approvedCount: 0,
        pendingApproval: 0,
        openCount: 0,
        doneCount: 0,
      );

  /// Tip sayacı (yoksa 0).
  int countForType(WhmsOrderType type) => byType[type] ?? 0;

  /// Durum sayacı (yoksa 0).
  int countForStatus(WhmsOrderStatus status) => byStatus[status] ?? 0;
}
