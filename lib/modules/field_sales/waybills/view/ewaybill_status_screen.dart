// Dosya Adı: ewaybill_status_screen.dart
// Açıklama: e-İrsaliye durum dens listesi (ETTN + GİB · SQLite)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/ewaybill_status_record.dart';
import '../model/ewaybill_status_seed.dart';
import '../viewmodel/ewaybill_status_store.dart';
import '../widgets/ewaybill_status_dens_tile.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template ewaybill_status_screen}
/// e-İrsaliye durum takibi dens listesi (1-SATIŞ / 2-ALIŞ · ETTN/GİB).
/// Kaynak: SQLite `ewaybill_status` (boşsa stub seed).
/// Route: `/field-sales/ewaybill-status`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, EwaybillStatusScreen.routeName);
/// ```
/// {@endtemplate}
class EwaybillStatusScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/ewaybill-status`
  static const String routeName = '/field-sales/ewaybill-status';

  /// [records]: Opsiyonel kayıtlar (null → SQLite `ewaybill_status`)
  final List<EwaybillStatusRecord>? records;

  /// [store]: Test / enjeksiyon için store (null → varsayılan)
  final EwaybillStatusStore? store;

  const EwaybillStatusScreen({
    Key? key,
    this.records,
    this.store,
  }) : super(key: key);

  @override
  State<EwaybillStatusScreen> createState() => _EwaybillStatusScreenState();
}

class _EwaybillStatusScreenState extends State<EwaybillStatusScreen> {
  /// [_records]: Yüklü dens satırları
  List<EwaybillStatusRecord> _records = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// {@template ewaybill_status_screen_load}
  /// SQLite `ewaybill_status` satırlarını yükler; hata → stub seed.
  /// {@endtemplate}
  Future<void> _load() async {
    if (widget.records != null) {
      if (!mounted) return;
      setState(() {
        _records = widget.records!;
        _loading = false;
      });
      return;
    }

    try {
      final store = widget.store ?? const EwaybillStatusStore();
      final rows = await store.loadAll();
      if (!mounted) return;
      setState(() {
        _records = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _records = EwaybillStatusSeed.defaultRows;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.ewaybill_status');
    final rows = EwaybillStatusDensTile.toQueueRows(_records, l10n);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.ewaybill_status_empty',
              rows: rows,
            ),
    );
  }
}
