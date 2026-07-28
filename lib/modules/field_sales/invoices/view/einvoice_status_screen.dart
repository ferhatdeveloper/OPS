// Dosya Adı: einvoice_status_screen.dart
// Açıklama: e-Fatura durum dens listesi (ETTN + GİB; SQLite)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/einvoice_status_record.dart';
import '../viewmodel/einvoice_status_store.dart';
import '../widgets/einvoice_status_dens_tile.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';

/// {@template einvoice_status_screen}
/// e-Fatura durum takibi dens listesi (1-SATIŞ / 2-ALIŞ · ETTN/GİB).
/// Kaynak: SQLite `einvoice_status` (soft-delete hariç).
/// Route: `/field-sales/einvoice-status`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, EinvoiceStatusScreen.routeName);
/// ```
/// {@endtemplate}
class EinvoiceStatusScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/einvoice-status`
  static const String routeName = '/field-sales/einvoice-status';

  /// [records]: Opsiyonel kayıtlar (null → SQLite `einvoice_status`)
  final List<EinvoiceStatusRecord>? records;

  /// [store]: Opsiyonel store (null → varsayılan [EinvoiceStatusStore])
  final EinvoiceStatusStore? store;

  const EinvoiceStatusScreen({
    Key? key,
    this.records,
    this.store,
  }) : super(key: key);

  @override
  State<EinvoiceStatusScreen> createState() => _EinvoiceStatusScreenState();
}

class _EinvoiceStatusScreenState extends State<EinvoiceStatusScreen> {
  /// [_rows]: Yüklenen dens kayıtları
  List<EinvoiceStatusRecord> _rows = const [];

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  /// {@template _loadRows}
  /// Enjekte kayıt varsa kullanır; yoksa SQLite `einvoice_status` okur.
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
      final store = widget.store ?? const EinvoiceStatusStore();
      final rows = await store.loadAll();
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
    final title = l10n.translate('field_sales.stubs.einvoice_status');
    final rows = EinvoiceStatusDensTile.toQueueRows(_rows, l10n);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.einvoice_status_empty',
              rows: rows,
            ),
    );
  }
}
