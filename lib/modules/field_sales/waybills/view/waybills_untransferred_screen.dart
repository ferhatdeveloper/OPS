// Dosya Adı: waybills_untransferred_screen.dart
// Açıklama: Transfer edilmeyen irsaliyeler dens kuyruk (SQLite is_synced=0)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../viewmodel/waybill_repository.dart';
import '../viewmodel/waybill_unsynced_store.dart';
import '../widgets/waybill_unsynced_dens_tile.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template waybills_untransferred_screen}
/// Transfer edilmeyen irsaliyeler dens kuyruk (MBT İRSALİYE).
/// Kaynak: SQLite `waybills` where `is_synced = 0`.
///
/// Route: `/field-sales/waybills-untransferred`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   WaybillsUntransferredScreen.routeName,
/// );
/// ```
/// {@endtemplate}
class WaybillsUntransferredScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/waybills-untransferred`
  static const String routeName = '/field-sales/waybills-untransferred';

  /// [store]: Opsiyonel store (test inject)
  final WaybillUnsyncedStore store;

  /// {@macro waybills_untransferred_screen}
  const WaybillsUntransferredScreen({
    Key? key,
    this.store = const WaybillUnsyncedStore(),
  }) : super(key: key);

  @override
  State<WaybillsUntransferredScreen> createState() =>
      _WaybillsUntransferredScreenState();
}

class _WaybillsUntransferredScreenState
    extends State<WaybillsUntransferredScreen> {
  /// [_rows]: SQLite is_synced=0 dens satırlar
  List<WaybillUnsyncedRow> _rows = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template waybills_untransferred_screen_reload}
  /// Transfer edilmeyen irsaliyeleri SQLite'tan yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    try {
      final rows = await widget.store.loadUnsynced();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.waybills_untransferred');
    final queueRows = WaybillUnsyncedDensTile.toQueueRows(_rows, l10n);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.waybills_untransferred_empty',
              rows: queueRows,
            ),
    );
  }
}
