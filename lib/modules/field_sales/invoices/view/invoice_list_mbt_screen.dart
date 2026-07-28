// Dosya Adı: invoice_list_mbt_screen.dart
// Açıklama: MBT Fatura Listesi dens — SQLite invoices
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/invoice_list_dens_record.dart';
import '../viewmodel/invoice_list_dens_store.dart';
import '../widgets/invoice_list_dens_tile.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template invoice_list_mbt_screen}
/// MBT menü eşlemesi: FATURA → Fatura Listesi dens (SQLite `invoices`).
///
/// Route: `/field-sales/invoices-list-mbt`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, InvoiceListMbtScreen.routeName);
/// ```
/// {@endtemplate}
class InvoiceListMbtScreen extends StatefulWidget {
  /// [routeName]: Named route sabit değeri.
  static const String routeName = '/field-sales/invoices-list-mbt';

  /// [store]: Opsiyonel store (test enjeksiyonu)
  final InvoiceListDensStore? store;

  const InvoiceListMbtScreen({Key? key, this.store}) : super(key: key);

  @override
  State<InvoiceListMbtScreen> createState() => _InvoiceListMbtScreenState();
}

class _InvoiceListMbtScreenState extends State<InvoiceListMbtScreen> {
  /// [_store]: SQLite dens okuyucu
  late final InvoiceListDensStore _store =
      widget.store ?? const InvoiceListDensStore();

  /// [_records]: Yüklenen fatura dens kayıtları
  List<InvoiceListDensRecord> _records = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template invoice_list_mbt_screen_reload}
  /// SQLite `invoices` dens listesini yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    try {
      final list = await _store.loadAll();
      if (!mounted) return;
      setState(() {
        _records = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _records = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.invoice_list'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.invoice_list_empty',
              rows: InvoiceListDensTile.toQueueRows(_records, l10n),
            ),
    );
  }
}
