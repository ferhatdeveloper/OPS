// Dosya Adı: customer_extract_screen.dart
// Açıklama: Cari hesap ekstre dens hareket listesi (SQLite/provider)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/customer_extract_movement.dart';
import '../viewmodel/customer_extract_provider.dart';

export '../model/customer_extract_movement.dart' show ExtractMovementFilter;

/// {@template ExtractPeriod}
/// Dönem hızlı seçimi (MBT dens).
/// {@endtemplate}
enum ExtractPeriod {
  /// Bugün
  today,

  /// Bu hafta
  thisWeek,

  /// Bu ay
  thisMonth,

  /// Bu yıl
  thisYear,
}

/// {@template customer_extract_screen}
/// Cari hesap ekstreleri — dens hareket listesi (SQLite kaynak).
/// Route: `/field-sales/customer-extract`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   CustomerExtractScreen.routeName,
///   arguments: 'CARI-001',
/// );
/// ```
/// {@endtemplate}
class CustomerExtractScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/customer-extract`
  static const String routeName = '/field-sales/customer-extract';

  /// [customerId]: İsteğe bağlı cari kodu / id (route args)
  final String? customerId;

  const CustomerExtractScreen({
    Key? key,
    this.customerId,
  }) : super(key: key);

  @override
  ConsumerState<CustomerExtractScreen> createState() =>
      _CustomerExtractScreenState();
}

class _CustomerExtractScreenState
    extends ConsumerState<CustomerExtractScreen> {
  /// [_filter]: Tümü / Borç / Alacak
  ExtractMovementFilter _filter = ExtractMovementFilter.all;

  /// [_period]: Dönem seçimi (varsayılan: bu ay)
  ExtractPeriod _period = ExtractPeriod.thisMonth;

  /// [_start]: Başlangıç tarihi
  late DateTime _start;

  /// [_end]: Bitiş tarihi
  late DateTime _end;

  /// [_searchController]: Ara alanı
  final TextEditingController _searchController = TextEditingController();

  /// [_primary]: OPS dens primary
  static const Color _primary = Color(0xFF375A7F);

  /// [_amountFmt]: TR tutar biçimi
  final NumberFormat _amountFmt = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    final range = _rangeForPeriod(ExtractPeriod.thisMonth);
    _start = range.$1;
    _end = range.$2;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template _reload}
  /// Provider üzerinden SQLite hareketlerini yeniler.
  /// {@endtemplate}
  Future<void> _reload() async {
    await ref.read(customerExtractProvider.notifier).load(
          customerId: widget.customerId,
          start: _start,
          end: _end,
          filter: _filter,
          search: _searchController.text,
        );
  }

  /// {@template _rangeForPeriod}
  /// Dönem seçimine göre (başlangıç, bitiş) aralığı üretir.
  ///
  /// Parametreler:
  /// - [period]: Dönem enum değeri
  ///
  /// Dönüş değeri:
  /// - [(DateTime, DateTime)]: Başlangıç ve bitiş
  /// {@endtemplate}
  (DateTime, DateTime) _rangeForPeriod(ExtractPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ExtractPeriod.today:
        return (today, today);
      case ExtractPeriod.thisWeek:
        final weekday = today.weekday;
        final start = today.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case ExtractPeriod.thisMonth:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 0);
        return (start, end);
      case ExtractPeriod.thisYear:
        return (
          DateTime(today.year, 1, 1),
          DateTime(today.year, 12, 31),
        );
    }
  }

  /// {@template _applyPeriod}
  /// Dönem seçimini uygular ve tarih aralığını günceller.
  /// {@endtemplate}
  void _applyPeriod(ExtractPeriod period) {
    final range = _rangeForPeriod(period);
    setState(() {
      _period = period;
      _start = range.$1;
      _end = range.$2;
    });
    _reload();
  }

  /// {@template _pickDate}
  /// Başlangıç veya bitiş için dens tarih seçici.
  /// {@endtemplate}
  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
        if (_start.isAfter(_end)) _start = _end;
      }
    });
    await _reload();
  }

  /// {@template _formatAmount}
  /// Tutarı dens TR biçiminde yazar; 0 ise boş.
  /// {@endtemplate}
  String _formatAmount(double value) {
    if (value <= 0) return '';
    return _amountFmt.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.customer_extract');
    final dateFmt = DateFormat('dd-MM-yyyy');
    final extractState = ref.watch(customerExtractProvider);
    final movements = extractState.movements;
    final itemCount = movements.length;
    final cariHint = widget.customerId?.trim();

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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cariHint != null && cariHint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                l10n.translate(
                  'field_sales.extract_customer_label',
                  args: {'code': cariHint},
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                for (final entry in <(ExtractMovementFilter, String)>[
                  (
                    ExtractMovementFilter.all,
                    'field_sales.extract_filter_all',
                  ),
                  (
                    ExtractMovementFilter.debit,
                    'field_sales.extract_filter_debit',
                  ),
                  (
                    ExtractMovementFilter.credit,
                    'field_sales.extract_filter_credit',
                  ),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _FilterChip(
                        primary: _primary,
                        label: l10n.translate(entry.$2),
                        selected: _filter == entry.$1,
                        onTap: () {
                          setState(() => _filter = entry.$1);
                          _reload();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                for (final entry in <(ExtractPeriod, String)>[
                  (ExtractPeriod.today, 'field_sales.period_today'),
                  (ExtractPeriod.thisWeek, 'field_sales.period_this_week'),
                  (ExtractPeriod.thisMonth, 'field_sales.period_this_month'),
                  (ExtractPeriod.thisYear, 'field_sales.period_this_year'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _FilterChip(
                        primary: _primary,
                        label: l10n.translate(entry.$2),
                        selected: _period == entry.$1,
                        onTap: () => _applyPeriod(entry.$1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _DateCell(
                    primary: _primary,
                    label: l10n.translate('field_sales.date_start_label'),
                    value: dateFmt.format(_start),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateCell(
                    primary: _primary,
                    label: l10n.translate('field_sales.date_end_label'),
                    value: dateFmt.format(_end),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('common.search'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: FieldSalesDensTheme.surface(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (_) => _reload(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: FieldSalesDensTheme.surface(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.translate('field_sales.extract_col_date'),
                      style: _headerStyle,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.translate('field_sales.extract_col_doc'),
                      style: _headerStyle,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.translate('field_sales.extract_col_desc'),
                      style: _headerStyle,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.translate('field_sales.extract_col_debit'),
                      textAlign: TextAlign.right,
                      style: _headerStyle,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.translate('field_sales.extract_col_credit'),
                      textAlign: TextAlign.right,
                      style: _headerStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: extractState.isLoading && movements.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : movements.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 56,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.translate('field_sales.extract_empty'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.translate(
                                  'field_sales.extract_skeleton_hint',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: movements.length,
                        itemBuilder: (context, index) {
                          final row = movements[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: FieldSalesDensTheme.surface(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      dateFmt.format(row.movementDate),
                                      style: _rowStyle,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      row.documentNo,
                                      style: _rowStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      row.description,
                                      style: _rowStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatAmount(row.debit),
                                      textAlign: TextAlign.right,
                                      style: _rowStyle,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatAmount(row.credit),
                                      textAlign: TextAlign.right,
                                      style: _rowStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.translate('field_sales.extract_total_debit')}: '
                    '${_amountFmt.format(extractState.totalDebit)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${l10n.translate('field_sales.extract_total_credit')}: '
                    '${_amountFmt.format(extractState.totalCredit)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              l10n.translate(
                'field_sales.queue_count_label',
                args: {'count': '$itemCount'},
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [_headerStyle]: Dens kolon başlık stili
  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF2C3E50),
  );

  /// [_rowStyle]: Dens satır metin stili
  static const TextStyle _rowStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF2C3E50),
  );
}

/// {@template _FilterChip}
/// Dens filtre / dönem chip.
/// {@endtemplate}
class _FilterChip extends StatelessWidget {
  /// [primary]: Vurgu rengi
  final Color primary;

  /// [label]: Etiket
  final String label;

  /// [selected]: Seçili mi
  final bool selected;

  /// [onTap]: Tap
  final VoidCallback onTap;

  const _FilterChip({
    required this.primary,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? primary : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primary),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: selected ? Colors.white : primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// {@template _DateCell}
/// Dens tarih hücresi.
/// {@endtemplate}
class _DateCell extends StatelessWidget {
  /// [primary]: Vurgu rengi
  final Color primary;

  /// [label]: Etiket
  final String label;

  /// [value]: Tarih metni
  final String value;

  /// [onTap]: Tarih seçici
  final VoidCallback onTap;

  const _DateCell({
    required this.primary,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
