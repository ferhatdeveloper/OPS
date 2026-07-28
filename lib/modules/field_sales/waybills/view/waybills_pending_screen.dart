// Dosya Adı: waybills_pending_screen.dart
// Açıklama: Bekleyen irsaliyeler dens kuyruk (SQLite approval_status=0)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../viewmodel/waybill_pending_store.dart';
import '../widgets/waybill_pending_dens_tile.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template waybills_pending_screen}
/// Bekleyen irsaliyeler dens kuyruk (MBT İRSALİYE → Bekleyen).
/// Kaynak: SQLite `waybills` where `approval_status = 0`.
///
/// Rota: `/field-sales/waybills-pending`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WaybillsPendingScreen.routeName);
/// ```
/// {@endtemplate}
class WaybillsPendingScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/waybills-pending`
  static const String routeName = '/field-sales/waybills-pending';

  /// [store]: Opsiyonel store (test inject)
  final WaybillPendingStore store;

  /// {@macro waybills_pending_screen}
  const WaybillsPendingScreen({
    Key? key,
    this.store = const WaybillPendingStore(),
  }) : super(key: key);

  @override
  State<WaybillsPendingScreen> createState() => _WaybillsPendingScreenState();
}

class _WaybillsPendingScreenState extends State<WaybillsPendingScreen> {
  /// [_maps]: SQLite pending dens satırlar
  List<Map<String, dynamic>> _maps = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template waybills_pending_screen_reload}
  /// Onay bekleyen irsaliyeleri SQLite'tan yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    try {
      final rows = await widget.store.loadPending();
      if (!mounted) return;
      setState(() {
        _maps = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _maps = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.waybills_pending');
    final rows = WaybillPendingDensTile.toQueueRows(_maps, l10n);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.waybills_pending_empty',
              rows: rows,
            ),
    );
  }
}
