// Dosya Adı: invoices_untransferred_screen.dart
// Açıklama: Transfer edilmeyen faturalar dens — canlı SQLite/queue yükleme
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/invoice_untransferred_record.dart';
import '../model/invoice_untransferred_seed.dart';
import '../viewmodel/invoice_untransferred_store.dart';
import '../widgets/invoice_untransferred_dens_tile.dart';

/// {@template invoices_untransferred_screen}
/// Transfer edilmeyen faturalar dens kuyruk (1-SATIŞ / 2-ALIŞ).
/// Kaynak: SQLite `invoices` is_synced=0 + sync_queue entity=invoice.
/// Route: `/field-sales/invoices-untransferred`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, InvoicesUntransferredScreen.routeName);
/// ```
/// {@endtemplate}
class InvoicesUntransferredScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/invoices-untransferred`
  static const String routeName = '/field-sales/invoices-untransferred';

  /// [store]: Opsiyonel store (test inject)
  final InvoiceUntransferredStore store;

  /// [records]: Opsiyonel sabit kayıtlar (null → store yükler)
  final List<InvoiceUntransferredRecord>? records;

  /// [seedOnError]: Yükleme hatasında seed fallback (varsayılan false)
  final bool seedOnError;

  /// {@macro invoices_untransferred_screen}
  const InvoicesUntransferredScreen({
    Key? key,
    this.store = const InvoiceUntransferredStore(),
    this.records,
    this.seedOnError = false,
  }) : super(key: key);

  @override
  State<InvoicesUntransferredScreen> createState() =>
      _InvoicesUntransferredScreenState();
}

class _InvoicesUntransferredScreenState
    extends State<InvoicesUntransferredScreen> {
  /// [_rows]: Yüklü dens kayıtlar
  List<InvoiceUntransferredRecord> _rows = const [];

  /// [_loading]: İlk / yenileme yüklemesi
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template invoices_untransferred_screen_reload}
  /// SQLite + sync_queue birleşik listeyi yeniler.
  /// Boş → empty state; hata → [seedOnError] ise seed.
  /// {@endtemplate}
  Future<void> _reload() async {
    if (widget.records != null) {
      if (!mounted) return;
      setState(() {
        _rows = widget.records!;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
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
        _rows = widget.seedOnError
            ? InvoiceUntransferredSeed.defaultRows
            : const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.invoices_untransferred');
    final queueRows =
        InvoiceUntransferredDensTile.toQueueRows(_rows, l10n);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            onPressed: _loading ? null : _reload,
            tooltip: l10n.translate('common.reload'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.invoices_untransferred_empty',
              rows: queueRows,
            ),
    );
  }
}
