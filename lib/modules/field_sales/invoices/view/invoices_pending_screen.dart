// Dosya Adı: invoices_pending_screen.dart
// Açıklama: Bekleyen faturalar dens kuyruk (SQLite invoices)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/invoice_pending_record.dart';
import '../viewmodel/invoice_pending_store.dart';
import '../widgets/invoice_pending_dens_tile.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template invoices_pending_screen}
/// Bekleyen faturalar dens kuyruk (1-SATIŞ / 2-ALIŞ · dönem filtre).
/// Kaynak: SQLite `invoices` (`approval_status=0` veya `status=Pending`).
/// Route: `/field-sales/invoices-pending`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, InvoicesPendingScreen.routeName);
/// ```
/// {@endtemplate}
class InvoicesPendingScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/invoices-pending`
  static const String routeName = '/field-sales/invoices-pending';

  /// [records]: Opsiyonel kayıtlar (null → SQLite `invoices`)
  final List<InvoicePendingRecord>? records;

  /// [store]: Opsiyonel store (null → varsayılan [InvoicePendingStore])
  final InvoicePendingStore? store;

  const InvoicesPendingScreen({
    Key? key,
    this.records,
    this.store,
  }) : super(key: key);

  @override
  State<InvoicesPendingScreen> createState() => _InvoicesPendingScreenState();
}

class _InvoicesPendingScreenState extends State<InvoicesPendingScreen> {
  /// [_rows]: Yüklenen dens kayıtları
  List<InvoicePendingRecord> _rows = const [];

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  /// {@template invoices_pending_screen_load_rows}
  /// Enjekte kayıt varsa kullanır; yoksa SQLite bekleyen faturaları okur.
  /// {@endtemplate}
  Future<void> _loadRows() async {
    final injected = widget.records;
    if (injected != null) {
      setState(() {
        _rows = injected;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final store = widget.store ?? const InvoicePendingStore();
      final rows = await store.loadPending();
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
    final title = l10n.translate('field_sales.stubs.invoices_pending');
    final rows = InvoicePendingDensTile.toQueueRows(_rows, l10n);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.invoices_pending_empty',
              rows: rows,
            ),
    );
  }
}
