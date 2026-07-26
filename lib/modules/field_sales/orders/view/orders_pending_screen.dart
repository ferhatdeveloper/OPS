// Dosya Adı: orders_pending_screen.dart
// Açıklama: Bekleyen siparişler dens kuyruk (SQLite + ONAY durumu)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';
import '../model/order_pending_record.dart';
import '../viewmodel/order_pending_store.dart';
import '../widgets/order_pending_dens_tile.dart';

/// {@template orders_pending_screen}
/// Bekleyen siparişler dens kuyruk (ONAY=0 · 1-SATIŞ / 2-ALIŞ).
/// Kaynak: SQLite `orders` (`approval_status=0` veya Pending/Proposal).
/// Route: `/field-sales/orders-pending`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, OrdersPendingScreen.routeName);
/// ```
/// {@endtemplate}
class OrdersPendingScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/orders-pending`
  static const String routeName = '/field-sales/orders-pending';

  /// [records]: Opsiyonel kayıtlar (null → SQLite `orders`)
  final List<OrderPendingRecord>? records;

  /// [store]: Opsiyonel store (null → varsayılan [OrderPendingStore])
  final OrderPendingStore? store;

  /// {@macro orders_pending_screen}
  const OrdersPendingScreen({
    Key? key,
    this.records,
    this.store,
  }) : super(key: key);

  @override
  State<OrdersPendingScreen> createState() => _OrdersPendingScreenState();
}

class _OrdersPendingScreenState extends State<OrdersPendingScreen> {
  /// [_rows]: Dens bekleyen satırlar
  List<OrderPendingRecord> _rows = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// {@template orders_pending_screen_reload}
  /// Enjekte kayıt varsa kullanır; yoksa SQLite bekleyen siparişleri okur.
  /// {@endtemplate}
  Future<void> _reload() async {
    final injected = widget.records;
    if (injected != null) {
      setState(() {
        _rows = List<OrderPendingRecord>.from(injected);
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final store = widget.store ?? const OrderPendingStore();
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
    final title = l10n.translate('field_sales.stubs.orders_pending');
    final queueRows = OrderPendingDensTile.toQueueRows(_rows, l10n);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MbtSalesPurchaseQueueBody(
              emptyMessageKey: 'field_sales.orders_pending_empty',
              rows: queueRows,
            ),
    );
  }
}
