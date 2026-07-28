// Dosya Adı: discount_approval_screen.dart
// Açıklama: İskonto onaylama dens kuyruk + minimal persist
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/discount_approval_record.dart';
import '../viewmodel/discount_approval_store.dart';

/// {@template discount_approval_screen}
/// MBT "İskonto Onaylama" dens kuyruk ekranı.
/// SharedPreferences ile minimal kalıcılık.
/// Route: `/field-sales/discount-approval`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, DiscountApprovalScreen.routeName);
/// ```
/// {@endtemplate}
class DiscountApprovalScreen extends StatefulWidget {
  /// {@template discount_approval_screen_constructor}
  /// İskonto onay dens ekranını oluşturur.
  /// {@endtemplate}
  const DiscountApprovalScreen({Key? key}) : super(key: key);

  /// [routeName]: Named route — `/field-sales/discount-approval`
  static const String routeName = '/field-sales/discount-approval';

  @override
  State<DiscountApprovalScreen> createState() => _DiscountApprovalScreenState();
}

class _DiscountApprovalScreenState extends State<DiscountApprovalScreen> {
  /// [_store]: SharedPreferences kalıcılık
  final DiscountApprovalStore _store = const DiscountApprovalStore();

  /// [_records]: Yüklü bekleyen kayıtlar
  List<DiscountApprovalRecord> _records = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template discount_approval_screen_reload}
  /// Yerel bekleyen iskonto listesini yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    final list = await _store.loadAll();
    if (!mounted) return;
    setState(() {
      _records = list;
      _loading = false;
    });
  }

  /// {@template discount_approval_screen_add_sample}
  /// Dens iskelet: örnek bekleyen iskonto talebi ekler (minimal persist).
  /// {@endtemplate}
  Future<void> _addSample(AppLocalization l10n) async {
    final now = DateTime.now();
    final seq = _records.length + 1;
    final record = DiscountApprovalRecord(
      id: 'da-${now.millisecondsSinceEpoch}',
      docNo: 'SIP-${seq.toString().padLeft(3, '0')}',
      customerCode: 'C${seq.toString().padLeft(3, '0')}',
      customerName: l10n.translate(
        'field_sales.discount_approval.sample_customer',
      ),
      discountPercent: 10.0 + seq,
      amount: 1000.0 * seq,
      side: DiscountApprovalDocSide.sales,
      requestedAt: now,
      note: l10n.translate('field_sales.discount_approval.sample_note'),
    );
    await _store.add(record);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.discount_approval.request_saved'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// {@template discount_approval_screen_approve}
  /// Bekleyen talebi onaylayıp listeden çıkarır.
  /// {@endtemplate}
  Future<void> _approve(MbtQueueRow row, AppLocalization l10n) async {
    await _store.remove(row.id);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.discount_approval.approved'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// {@template discount_approval_screen_to_rows}
  /// Kayıtları dens kuyruk satırına çevirir.
  /// {@endtemplate}
  List<MbtQueueRow> _toRows(AppLocalization l10n) {
    final dateFmt = DateFormat('dd-MM-yyyy HH:mm');
    final pctFmt = NumberFormat('0.##');
    return _records.map((r) {
      final side = r.side == DiscountApprovalDocSide.purchase
          ? MbtQueueDocSide.purchase
          : MbtQueueDocSide.sales;
      final subtitle = l10n.translate(
        'field_sales.discount_approval.row_subtitle',
        args: {
          'customer': '${r.customerCode} · ${r.customerName}',
          'discount': pctFmt.format(r.discountPercent),
          'requested_at': dateFmt.format(r.requestedAt),
        },
      );
      return MbtQueueRow(
        id: r.id,
        side: side,
        date: r.requestedAt,
        title: r.docNo,
        subtitle: subtitle,
        searchBlob:
            '${r.customerCode} ${r.customerName} ${r.discountPercent} ${r.note}',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.discount_approval');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.percent,
            onPressed: () => _addSample(l10n),
            tooltip: l10n.translate(
              'field_sales.discount_approval.add_request',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.discount_approval_empty',
              rows: _toRows(l10n),
              onRowTap: (row) => _approve(row, l10n),
            ),
    );
  }
}
