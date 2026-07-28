// Dosya Adı: delivery_hold_screen.dart
// Açıklama: Beklemeye alınan teslimatlar dens kuyruk + minimal persist
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/delivery_hold_record.dart';
import '../viewmodel/delivery_hold_store.dart';

/// {@template delivery_hold_screen}
/// MBT "Beklemeye Alınan Teslimatlar" dens kuyruk ekranı.
/// SharedPreferences ile minimal kalıcılık.
/// Route: `/field-sales/delivery-hold`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, DeliveryHoldScreen.routeName);
/// ```
/// {@endtemplate}
class DeliveryHoldScreen extends StatefulWidget {
  /// {@template delivery_hold_screen_constructor}
  /// Beklemeye alınanlar dens ekranını oluşturur.
  /// {@endtemplate}
  const DeliveryHoldScreen({Key? key}) : super(key: key);

  /// [routeName]: Named route — `/field-sales/delivery-hold`
  static const String routeName = '/field-sales/delivery-hold';

  @override
  State<DeliveryHoldScreen> createState() => _DeliveryHoldScreenState();
}

class _DeliveryHoldScreenState extends State<DeliveryHoldScreen> {
  /// [_store]: SharedPreferences kalıcılık
  final DeliveryHoldStore _store = const DeliveryHoldStore();

  /// [_records]: Yüklü bekleyen kayıtlar
  List<DeliveryHoldRecord> _records = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template delivery_hold_screen_reload}
  /// Yerel bekleyen listesini yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    final list = await _store.loadAll();
    if (!mounted) return;
    setState(() {
      _records = list;
      _loading = false;
    });
  }

  /// {@template delivery_hold_screen_add_sample}
  /// Dens iskelet: örnek bekleyen kayıt ekler (minimal persist doğrulama).
  /// {@endtemplate}
  Future<void> _addSampleHold(AppLocalization l10n) async {
    final now = DateTime.now();
    final seq = _records.length + 1;
    final record = DeliveryHoldRecord(
      id: 'dh-${now.millisecondsSinceEpoch}',
      docNo: 'TSL-${seq.toString().padLeft(3, '0')}',
      customerCode: 'C${seq.toString().padLeft(3, '0')}',
      customerName: l10n.translate('field_sales.delivery_hold.sample_customer'),
      side: DeliveryHoldDocSide.sales,
      heldAt: now,
      note: l10n.translate('field_sales.delivery_hold.sample_note'),
    );
    await _store.add(record);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.delivery_hold.held_saved'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// {@template delivery_hold_screen_resume}
  /// Bekleyen kaydı listeden çıkarır (devam et).
  /// {@endtemplate}
  Future<void> _resumeHold(MbtQueueRow row, AppLocalization l10n) async {
    await _store.remove(row.id);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.delivery_hold.resumed'),
        ),
      ),
    );
  }

  /// {@template delivery_hold_screen_to_rows}
  /// Kayıtları dens kuyruk satırına çevirir.
  /// {@endtemplate}
  List<MbtQueueRow> _toRows(AppLocalization l10n) {
    final dateFmt = DateFormat('dd-MM-yyyy HH:mm');
    return _records.map((r) {
      final side = r.side == DeliveryHoldDocSide.purchase
          ? MbtQueueDocSide.purchase
          : MbtQueueDocSide.sales;
      final subtitle = l10n.translate(
        'field_sales.delivery_hold.row_subtitle',
        args: {
          'customer': '${r.customerCode} · ${r.customerName}',
          'held_at': dateFmt.format(r.heldAt),
        },
      );
      return MbtQueueRow(
        id: r.id,
        side: side,
        date: r.heldAt,
        title: r.docNo,
        subtitle: subtitle,
        searchBlob: '${r.customerCode} ${r.customerName} ${r.note}',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.delivery_hold');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: title,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.pause_circle_outline,
            onPressed: () => _addSampleHold(l10n),
            tooltip: l10n.translate('field_sales.delivery_hold.add_hold'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.delivery_hold_empty',
              rows: _toRows(l10n),
              onRowTap: (row) => _resumeHold(row, l10n),
            ),
    );
  }
}
