// Dosya Adı: waybill_list_screen.dart
// Açıklama: İrsaliye dens listesi — SQLite waybills
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../model/waybill_model.dart';
import '../viewmodel/waybill_repository.dart';
import 'waybill_customer_selection_screen.dart';
import 'waybill_entry_screen.dart';

/// {@template waybill_list_screen}
/// İrsaliye dens listesi — kaynak: SQLite `waybills`.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WaybillListScreen.routeName);
/// ```
/// {@endtemplate}
class WaybillListScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/waybills`
  static const String routeName = '/field-sales/waybills';

  /// [customerId]: Opsiyonel cari filtresi
  final String? customerId;

  /// [repository]: Test enjeksiyonu (null → varsayılan)
  final WaybillRepository repository;

  const WaybillListScreen({
    Key? key,
    this.customerId,
    this.repository = const WaybillRepository(),
  }) : super(key: key);

  @override
  State<WaybillListScreen> createState() => _WaybillListScreenState();
}

class _WaybillListScreenState extends State<WaybillListScreen> {
  /// [_waybills]: SQLite dens satırları
  List<WaybillModel> _waybills = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  /// [_dateFmt]: Dens tarih formatı
  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadWaybills();
  }

  /// {@template _loadWaybills}
  /// SQLite `waybills` tablosundan dens listeyi yükler.
  /// {@endtemplate}
  Future<void> _loadWaybills() async {
    setState(() => _loading = true);
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      final rows = await widget.repository.list(
        db,
        customerId: widget.customerId,
      );
      if (!mounted) return;
      setState(() {
        _waybills = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _waybills = const [];
        _loading = false;
      });
    }
  }

  /// {@template _statusLabel}
  /// SQLite status kodunu l10n etiketine çevirir.
  /// {@endtemplate}
  String _statusLabel(AppLocalization l10n, String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
      case 'teslim':
        return l10n.translate('field_sales.status_completed');
      case 'pending':
      case 'bekliyor':
        return l10n.translate('field_sales.status_pending');
      default:
        return status.isEmpty
            ? l10n.translate('field_sales.status_completed')
            : status;
    }
  }

  /// {@template _statusColor}
  /// Durum renkleri (mevcut dens palet).
  /// {@endtemplate}
  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
      case 'teslim':
        return Colors.green;
      case 'pending':
      case 'bekliyor':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  /// {@template _displayId}
  /// Dens başlık: kısa irsaliye kimliği.
  /// {@endtemplate}
  String _displayId(WaybillModel wb) {
    final id = wb.id.trim();
    if (id.length <= 12) return id;
    return 'IRS-${id.substring(0, 8).toUpperCase()}';
  }

  /// {@template _openNewWaybill}
  /// Yeni irsaliye — cari seçim (toptan).
  /// {@endtemplate}
  void _openNewWaybill() {
    final cari = widget.customerId?.trim();
    if (cari != null &&
        WaybillCustomerSelectionScreen.isValidCustomerId(cari)) {
      Navigator.pushNamed(
        context,
        WaybillEntryScreen.routeWholesale,
        arguments: cari,
      ).then((_) {
        if (mounted) _loadWaybills();
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WaybillCustomerSelectionScreen(
          waybillType: WaybillType.wholesale,
        ),
      ),
    ).then((_) {
      if (mounted) _loadWaybills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.waybill_list');

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openNewWaybill,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _waybills.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.waybill_list_empty'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                  itemCount: _waybills.length,
                  itemBuilder: (context, index) {
                    final waybill = _waybills[index];
                    final status = waybill.status;
                    final statusColor = _statusColor(status);
                    final statusText = _statusLabel(l10n, status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: FieldSalesDensTheme.surface(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FieldSalesDensTheme.bodyBackground(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Color(0xFF375A7F),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _displayId(waybill),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _dateFmt.format(waybill.waybillDate),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              waybill.totalAmount.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewWaybill,
        backgroundColor: const Color(0xFF00A8E8),
        icon: const Icon(Icons.local_shipping, color: Colors.white),
        label: Text(
          l10n.translate('submodules.irsaliye'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
