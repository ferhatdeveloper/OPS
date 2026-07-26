// Dosya Adı: invoice_approval_screen.dart
// Açıklama: Fatura onaylama dens — SQLite invoices gerçek kayıt
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../../../../core/sync/approval_status.dart';
import '../../../../service/database_service.dart';
import '../model/invoice_model.dart';

/// {@template invoice_approval_screen}
/// MBT Fatura Onaylama dens: Alış/Satış · Bekleyen · Onaylı · dönem.
/// Route: `/field-sales/invoices-approval`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, InvoiceApprovalScreen.routeName);
/// ```
/// {@endtemplate}
class InvoiceApprovalScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/invoices-approval`
  static const String routeName = '/field-sales/invoices-approval';

  /// [invoices]: Opsiyonel enjekte kayıtlar (null → SQLite)
  final List<InvoiceModel>? invoices;

  const InvoiceApprovalScreen({
    Key? key,
    this.invoices,
  }) : super(key: key);

  @override
  State<InvoiceApprovalScreen> createState() => _InvoiceApprovalScreenState();
}

class _InvoiceApprovalScreenState extends State<InvoiceApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// [_typeFilter]: null = hepsi, sales / purchase kuyruk
  String? _typeFilter;

  DateTime _periodFrom =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _periodTo = DateTime.now();

  List<InvoiceModel> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// {@template _loadInvoices}
  /// Yerel faturaları dönem + tip filtresine göre yükler.
  /// {@endtemplate}
  Future<void> _loadInvoices() async {
    setState(() => _loading = true);
    try {
      List<InvoiceModel> list;
      if (widget.invoices != null) {
        final end = _periodTo.add(const Duration(days: 1));
        list = widget.invoices!.where((i) {
          final d = i.invoiceDate;
          return !d.isBefore(
                DateTime(_periodFrom.year, _periodFrom.month, _periodFrom.day),
              ) &&
              d.isBefore(DateTime(end.year, end.month, end.day));
        }).toList();
      } else {
        final db = await DatabaseService.getInstance();
        final sqliteDb = await db.getDatabase();
        final from = DateFormat('yyyy-MM-dd').format(_periodFrom);
        final to = DateFormat('yyyy-MM-dd').format(
          _periodTo.add(const Duration(days: 1)),
        );
        final rows = await sqliteDb.query(
          'invoices',
          where: 'invoice_date >= ? AND invoice_date < ?',
          whereArgs: [from, to],
          orderBy: 'invoice_date DESC',
        );
        list = rows.map(InvoiceModel.fromMap).toList();
      }
      if (_typeFilter != null) {
        list = list.where(_matchesTypeFilter).toList();
      }
      if (!mounted) return;
      setState(() {
        _invoices = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _invoices = [];
        _loading = false;
      });
    }
  }

  /// {@template _matchesTypeFilter}
  /// Satış / alış kuyruk tipine göre satır eşler.
  /// {@endtemplate}
  bool _matchesTypeFilter(InvoiceModel inv) {
    if (_typeFilter == null) return true;
    final q = LogoPayloadMapper.resolveInvoiceQueueType(inv.invoiceType);
    if (_typeFilter == LogoPayloadMapper.invoiceQueuePurchase) {
      return q == LogoPayloadMapper.invoiceQueuePurchase || inv.isPurchaseSide;
    }
    return q != LogoPayloadMapper.invoiceQueuePurchase && !inv.isPurchaseSide;
  }

  /// {@template _filtered}
  /// Sekmeye göre fatura listesi.
  /// Bekleyen: ONAY=0 / Pending; Onaylı: ONAY=1|2 / Completed.
  /// {@endtemplate}
  List<InvoiceModel> get _filtered {
    final typed = _typeFilter == null
        ? _invoices
        : _invoices.where(_matchesTypeFilter).toList();
    if (_tabController.index == 0) {
      return typed.where((i) => i.isPendingApproval).toList();
    }
    return typed.where((i) => i.isApproved).toList();
  }

  InputDecoration _denseDecoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _periodFrom : _periodTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _periodFrom = picked;
      } else {
        _periodTo = picked;
      }
    });
    await _loadInvoices();
  }

  /// {@template _approvalLabel}
  /// ONAY kodunu dens etiketine çevirir.
  /// {@endtemplate}
  String _approvalLabel(AppLocalization l10n, InvoiceModel inv) {
    final status = ApprovalStatus.fromValue(inv.approvalStatus);
    switch (status) {
      case ApprovalStatus.pending:
        return l10n.translate('field_sales.invoice_approval_status_pending');
      case ApprovalStatus.approved:
        return l10n.translate('field_sales.invoice_approval_status_approved');
      case ApprovalStatus.synced:
        return l10n.translate('field_sales.invoice_approval_status_synced');
      case ApprovalStatus.rejected:
        return l10n.translate('field_sales.invoice_approval_status_rejected');
      case ApprovalStatus.error:
        return l10n.translate('field_sales.invoice_approval_status_error');
    }
  }

  /// {@template _typeLabel}
  /// Satış / alış dens tipi etiketi.
  /// {@endtemplate}
  String _typeLabel(AppLocalization l10n, InvoiceModel inv) {
    final q = LogoPayloadMapper.resolveInvoiceQueueType(inv.invoiceType);
    if (q == LogoPayloadMapper.invoiceQueuePurchase || inv.isPurchaseSide) {
      return l10n.translate('field_sales.invoice_approval_type_purchase');
    }
    return l10n.translate('field_sales.invoice_approval_type_sales');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.invoice_approval');
    final filtered = _filtered;
    final dateFmt = DateFormat('dd.MM.yyyy');

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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              text: l10n.translate(
                'field_sales.invoice_approval_tab_pending',
              ),
            ),
            Tab(
              text: l10n.translate(
                'field_sales.invoice_approval_tab_approved',
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String?>(
                  value: _typeFilter,
                  isDense: true,
                  decoration: _denseDecoration(
                    l10n.translate('field_sales.invoice_approval_type_filter'),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.translate(
                          'field_sales.invoice_approval_type_all',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: LogoPayloadMapper.invoiceQueueWholesale,
                      child: Text(
                        l10n.translate(
                          'field_sales.invoice_approval_type_sales',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: LogoPayloadMapper.invoiceQueuePurchase,
                      child: Text(
                        l10n.translate(
                          'field_sales.invoice_approval_type_purchase',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _typeFilter = v);
                    _loadInvoices();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isFrom: true),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: _denseDecoration(
                            l10n.translate(
                              'field_sales.invoice_approval_period_from',
                            ),
                          ),
                          child: Text(
                            dateFmt.format(_periodFrom),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isFrom: false),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: _denseDecoration(
                            l10n.translate(
                              'field_sales.invoice_approval_period_to',
                            ),
                          ),
                          child: Text(
                            dateFmt.format(_periodTo),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.translate(
                    'field_sales.invoice_approval_count',
                    args: {'count': '${filtered.length}'},
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate(
                            'field_sales.invoice_approval_empty',
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final inv = filtered[index];
                          return Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.customerId.isEmpty
                                            ? inv.id
                                            : inv.customerId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_typeLabel(l10n, inv)} · '
                                        '${dateFmt.format(inv.invoiceDate)} · '
                                        '${inv.totalAmount.toStringAsFixed(2)} ₺',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _approvalLabel(l10n, inv),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
