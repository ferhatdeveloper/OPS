// Dosya Adı: customer_reconciliation_screen.dart
// Açıklama: Cari mutabakat dens — dönem özeti + onay + PDF paylaş
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';
import 'dart:typed_data';
import '../../shared/view/field_sales_dens_theme.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/customer_reconciliation_summary.dart';
import '../viewmodel/customer_extract_store.dart';
import 'customer_extract_screen.dart' show ExtractPeriod;

/// {@template customer_reconciliation_screen}
/// Cari mutabakat dens ekranı — bakiye özeti + dönem + onay/PDF.
/// Route: `/field-sales/customer-reconciliation`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   CustomerReconciliationScreen.routeName,
///   arguments: {
///     'customerId': 'C-100',
///     'customerCode': '120.01',
///     'customerName': 'Demo',
///   },
/// );
/// ```
/// {@endtemplate}
class CustomerReconciliationScreen extends StatefulWidget {
  /// [routeName]: Named route
  static const String routeName = '/field-sales/customer-reconciliation';

  /// [customerId]: Cari id
  final String customerId;

  /// [customerCode]: Görünen kod
  final String? customerCode;

  /// [customerName]: Ünvan
  final String? customerName;

  /// [store]: Test enjeksiyonu
  final CustomerExtractStore? store;

  /// [shareBytes]: PDF paylaşım (test override)
  final Future<void> Function(Uint8List bytes, String title)? shareBytes;

  /// {@macro customer_reconciliation_screen}
  const CustomerReconciliationScreen({
    Key? key,
    required this.customerId,
    this.customerCode,
    this.customerName,
    this.store,
    this.shareBytes,
  }) : super(key: key);

  @override
  State<CustomerReconciliationScreen> createState() =>
      _CustomerReconciliationScreenState();
}

class _CustomerReconciliationScreenState
    extends State<CustomerReconciliationScreen> {
  ExtractPeriod _period = ExtractPeriod.thisMonth;
  late DateTime _start;
  late DateTime _end;
  CustomerReconciliationSummary _summary =
      CustomerReconciliationSummary.empty;
  bool _loading = true;
  bool _confirmed = false;
  DateTime? _confirmedAt;

  final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy');

  CustomerExtractStore get _store =>
      widget.store ?? const CustomerExtractStore();

  @override
  void initState() {
    super.initState();
    final range = _rangeForPeriod(ExtractPeriod.thisMonth);
    _start = range.$1;
    _end = range.$2;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  (DateTime, DateTime) _rangeForPeriod(ExtractPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ExtractPeriod.today:
        return (today, today);
      case ExtractPeriod.thisWeek:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return (monday, today);
      case ExtractPeriod.thisMonth:
        return (DateTime(now.year, now.month, 1), today);
      case ExtractPeriod.thisYear:
        return (DateTime(now.year, 1, 1), today);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _confirmed = false;
      _confirmedAt = null;
    });
    try {
      final summary = await _store.reconciliationSummary(
        customerId: widget.customerId,
        start: _start,
        end: _end,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = CustomerReconciliationSummary.empty;
        _loading = false;
      });
    }
  }

  void _applyPeriod(ExtractPeriod period) {
    final range = _rangeForPeriod(period);
    setState(() {
      _period = period;
      _start = range.$1;
      _end = range.$2;
    });
    _reload();
  }

  void _confirm() {
    final l10n = AppLocalization.of(context);
    setState(() {
      _confirmed = true;
      _confirmedAt = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.customer_reconciliation_confirmed'),
        ),
      ),
    );
  }

  Future<void> _sharePdf() async {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.customer_reconciliation');
    final bytes = await buildReconciliationPdf(
      title: title,
      customerLabel: _customerLabel(l10n),
      periodLabel:
          '${_dateFmt.format(_start)} – ${_dateFmt.format(_end)}',
      summary: _summary,
      confirmed: _confirmed,
      confirmedAt: _confirmedAt,
      money: _money,
      dateFmt: _dateFmt,
      l10n: l10n,
    );
    if (widget.shareBytes != null) {
      await widget.shareBytes!(bytes, title);
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'mutabakat_${widget.customerId.hashCode}.pdf',
    );
    await File(path).writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      <XFile>[XFile(path)],
      subject: title,
      text: title,
    );
  }

  String _customerLabel(AppLocalization l10n) {
    final code = (widget.customerCode ?? '').trim();
    final name = (widget.customerName ?? '').trim();
    if (code.isNotEmpty && name.isNotEmpty) return '$code · $name';
    if (code.isNotEmpty) return code;
    if (name.isNotEmpty) return name;
    return widget.customerId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title =
        l10n.translate('field_sales.stubs.customer_reconciliation');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        backgroundColor: FieldSalesDensAppBar.primaryColor,
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(
              items: [
                for (final entry in <(ExtractPeriod, String)>[
                  (ExtractPeriod.today, 'field_sales.period_today'),
                  (ExtractPeriod.thisWeek, 'field_sales.period_this_week'),
                  (ExtractPeriod.thisMonth, 'field_sales.period_this_month'),
                  (ExtractPeriod.thisYear, 'field_sales.period_this_year'),
                ])
                  FieldSalesDensChipItem(
                    label: l10n.translate(entry.$2),
                    selected: _period == entry.$1,
                    onTap: () => _applyPeriod(entry.$1),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              children: [
                Text(
                  l10n.translate(
                    'field_sales.extract_customer_label',
                    args: {'code': _customerLabel(l10n)},
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_dateFmt.format(_start)} – ${_dateFmt.format(_end)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                _SummaryTile(
                  label: l10n.translate(
                    'field_sales.customer_reconciliation_opening',
                  ),
                  value: _money.format(_summary.openingBalance),
                ),
                _SummaryTile(
                  label: l10n.translate(
                    'field_sales.extract_total_debit',
                  ),
                  value: _money.format(_summary.periodDebit),
                ),
                _SummaryTile(
                  label: l10n.translate(
                    'field_sales.extract_total_credit',
                  ),
                  value: _money.format(_summary.periodCredit),
                ),
                _SummaryTile(
                  label: l10n.translate(
                    'field_sales.customer_reconciliation_closing',
                  ),
                  value: _money.format(_summary.closingBalance),
                  emphasize: true,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.translate(
                    'field_sales.customer_reconciliation_count',
                    args: {'count': '${_summary.movementCount}'},
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_confirmed && _confirmedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate(
                      'field_sales.customer_reconciliation_confirmed_at',
                      args: {
                        'at': DateFormat('dd.MM.yyyy HH:mm')
                            .format(_confirmedAt!),
                      },
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FieldSalesDensAppBar.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.translate(
                        'field_sales.customer_reconciliation_confirm',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sharePdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(
                      l10n.translate(
                        'field_sales.customer_reconciliation_pdf',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// {@template reconciliation_summary_tile}
/// Dens mutabakat satırı.
/// {@endtemplate}
class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryTile({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasize ? 13 : 12,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 14 : 13,
              fontWeight: FontWeight.w700,
              color: FieldSalesDensAppBar.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// {@template build_reconciliation_pdf}
/// Mutabakat özet PDF baytları üretir (unit test edilebilir).
/// {@endtemplate}
Future<Uint8List> buildReconciliationPdf({
  required String title,
  required String customerLabel,
  required String periodLabel,
  required CustomerReconciliationSummary summary,
  required bool confirmed,
  required DateTime? confirmedAt,
  required NumberFormat money,
  required DateFormat dateFmt,
  required AppLocalization l10n,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(customerLabel, style: const pw.TextStyle(fontSize: 12)),
            pw.Text(periodLabel, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
            _pdfRow(
              l10n.translate('field_sales.customer_reconciliation_opening'),
              money.format(summary.openingBalance),
            ),
            _pdfRow(
              l10n.translate('field_sales.extract_total_debit'),
              money.format(summary.periodDebit),
            ),
            _pdfRow(
              l10n.translate('field_sales.extract_total_credit'),
              money.format(summary.periodCredit),
            ),
            _pdfRow(
              l10n.translate('field_sales.customer_reconciliation_closing'),
              money.format(summary.closingBalance),
              bold: true,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              l10n.translate(
                'field_sales.customer_reconciliation_count',
                args: {'count': '${summary.movementCount}'},
              ),
              style: const pw.TextStyle(fontSize: 11),
            ),
            if (confirmed && confirmedAt != null) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                l10n.translate(
                  'field_sales.customer_reconciliation_confirmed_at',
                  args: {
                    'at': DateFormat('dd.MM.yyyy HH:mm').format(confirmedAt),
                  },
                ),
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ],
        );
      },
    ),
  );
  return doc.save();
}

pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
