// Dosya Adı: mbt_sales_purchase_queue_body.dart
// Açıklama: MBT kuyruk dens gövde — 1-SATIŞ/2-ALIŞ + dönem filtre
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';
import 'field_sales_dens_app_bar.dart';
import 'field_sales_dens_filter_bar.dart';
import 'field_sales_dens_theme.dart';

/// {@template MbtQueueDocSide}
/// Belge yönü: satış veya alış.
/// {@endtemplate}
enum MbtQueueDocSide {
  /// Satış (1-SATIŞ)
  sales,

  /// Alış (2-ALIŞ)
  purchase,
}

/// {@template MbtQueuePeriod}
/// Dönem hızlı seçimi.
/// {@endtemplate}
enum MbtQueuePeriod {
  /// Bugün
  today,

  /// Bu hafta
  thisWeek,

  /// Bu ay
  thisMonth,

  /// Bu yıl
  thisYear,
}

/// {@template mbt_queue_row}
/// Dens kuyruk satırı (filtre + liste bağlama).
/// {@endtemplate}
class MbtQueueRow {
  /// [id]: Satır kimliği
  final String id;

  /// [side]: Satış / alış
  final MbtQueueDocSide side;

  /// [date]: Belge / bekletme tarihi (gün filtresi)
  final DateTime date;

  /// [title]: Ana satır metni
  final String title;

  /// [subtitle]: Alt satır metni
  final String subtitle;

  /// [searchBlob]: Ara alanında aranan birleşik metin
  final String searchBlob;

  /// [ettn]: Opsiyonel ETTN (e-Fatura / e-İrsaliye dens)
  final String? ettn;

  /// [ettnLabel]: ETTN alan etiketi (l10n çözülmüş)
  final String? ettnLabel;

  /// [gibStatusLabel]: GİB durum değeri (l10n çözülmüş)
  final String? gibStatusLabel;

  /// [gibStatusFieldLabel]: GİB durum alan etiketi
  final String? gibStatusFieldLabel;

  /// {@macro mbt_queue_row}
  const MbtQueueRow({
    required this.id,
    required this.side,
    required this.date,
    required this.title,
    required this.subtitle,
    this.searchBlob = '',
    this.ettn,
    this.ettnLabel,
    this.gibStatusLabel,
    this.gibStatusFieldLabel,
  });
}

/// {@template mbt_sales_purchase_queue_body}
/// Teslimat / sipariş kuyruk dens gövdesi (sekme + dönem + ara + adet).
///
/// Kullanım örneği:
/// ```dart
/// const MbtSalesPurchaseQueueBody()
/// ```
/// {@endtemplate}
class MbtSalesPurchaseQueueBody extends StatefulWidget {
  /// [emptyMessageKey]: Boş liste mesajı çeviri anahtarı
  final String emptyMessageKey;

  /// [rows]: Opsiyonel dens satırlar (null/boş → empty mesaj)
  final List<MbtQueueRow> rows;

  /// [onRowTap]: Satıra tıklanınca
  final ValueChanged<MbtQueueRow>? onRowTap;

  /// {@macro mbt_sales_purchase_queue_body}
  const MbtSalesPurchaseQueueBody({
    Key? key,
    this.emptyMessageKey = 'field_sales.queue_empty',
    this.rows = const [],
    this.onRowTap,
  }) : super(key: key);

  @override
  State<MbtSalesPurchaseQueueBody> createState() =>
      _MbtSalesPurchaseQueueBodyState();
}

class _MbtSalesPurchaseQueueBodyState extends State<MbtSalesPurchaseQueueBody> {
  /// [_docSide]: 1-SATIŞ / 2-ALIŞ
  MbtQueueDocSide _docSide = MbtQueueDocSide.sales;

  /// [_period]: Dönem seçimi (varsayılan: bu ay — MBT)
  MbtQueuePeriod _period = MbtQueuePeriod.thisMonth;

  /// [_start]: Başlangıç tarihi
  late DateTime _start;

  /// [_end]: Bitiş tarihi
  late DateTime _end;

  /// [_searchController]: Ara alanı
  final TextEditingController _searchController = TextEditingController();

  /// [_primary]: OPS dens primary
  static const Color _primary = FieldSalesDensAppBar.primaryColor;

  @override
  void initState() {
    super.initState();
    final range = _rangeForPeriod(MbtQueuePeriod.thisMonth);
    _start = range.$1;
    _end = range.$2;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  (DateTime, DateTime) _rangeForPeriod(MbtQueuePeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case MbtQueuePeriod.today:
        return (today, today);
      case MbtQueuePeriod.thisWeek:
        final weekday = today.weekday; // 1=Mon … 7=Sun
        final start = today.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case MbtQueuePeriod.thisMonth:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 0);
        return (start, end);
      case MbtQueuePeriod.thisYear:
        return (
          DateTime(today.year, 1, 1),
          DateTime(today.year, 12, 31),
        );
    }
  }

  /// {@template _applyPeriod}
  /// Dönem seçimini uygular ve tarih aralığını günceller.
  ///
  /// Parametreler:
  /// - [period]: Yeni dönem
  /// {@endtemplate}
  void _applyPeriod(MbtQueuePeriod period) {
    final range = _rangeForPeriod(period);
    setState(() {
      _period = period;
      _start = range.$1;
      _end = range.$2;
    });
  }

  /// {@template _pickDate}
  /// Başlangıç veya bitiş için dens tarih seçici.
  ///
  /// Parametreler:
  /// - [isStart]: true ise başlangıç
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
  }

  /// {@template _day_only}
  /// Saat bilgisini sıfırlar (gün aralığı karşılaştırması).
  /// {@endtemplate}
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// {@template _filtered_rows}
  /// Sekme · dönem · ara filtrelerini uygular.
  /// {@endtemplate}
  List<MbtQueueRow> _filteredRows() {
    final q = _searchController.text.trim().toLowerCase();
    final start = _dayOnly(_start);
    final end = _dayOnly(_end);
    return widget.rows.where((row) {
      if (row.side != _docSide) return false;
      final day = _dayOnly(row.date);
      if (day.isBefore(start) || day.isAfter(end)) return false;
      if (q.isEmpty) return true;
      final blob = '${row.title} ${row.subtitle} ${row.searchBlob} '
              '${row.ettn ?? ''} ${row.gibStatusLabel ?? ''}'
          .toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final dateFmt = DateFormat('dd-MM-yyyy');
    final filtered = _filteredRows();
    final itemCount = filtered.length;

    final periodEntries = <(MbtQueuePeriod, String)>[
      (MbtQueuePeriod.today, 'field_sales.period_today'),
      (MbtQueuePeriod.thisWeek, 'field_sales.period_this_week'),
      (MbtQueuePeriod.thisMonth, 'field_sales.period_this_month'),
      (MbtQueuePeriod.thisYear, 'field_sales.period_this_year'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(
              primary: _primary,
              items: [
                FieldSalesDensChipItem(
                  label: l10n.translate('field_sales.queue_tab_sales'),
                  selected: _docSide == MbtQueueDocSide.sales,
                  onTap: () =>
                      setState(() => _docSide = MbtQueueDocSide.sales),
                ),
                FieldSalesDensChipItem(
                  label: l10n.translate('field_sales.queue_tab_purchase'),
                  selected: _docSide == MbtQueueDocSide.purchase,
                  onTap: () =>
                      setState(() => _docSide = MbtQueueDocSide.purchase),
                ),
              ],
            ),
            FieldSalesDensChipRow(
              primary: _primary,
              fontSize: 11,
              items: [
                for (final entry in periodEntries)
                  FieldSalesDensChipItem(
                    label: l10n.translate(entry.$2),
                    selected: _period == entry.$1,
                    onTap: () => _applyPeriod(entry.$1),
                  ),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0),
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
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 4),
          child: TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.translate('common.search'),
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
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
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate(widget.emptyMessageKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final row = filtered[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: widget.onRowTap == null
                            ? null
                            : () => widget.onRowTap!(row),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: FieldSalesDensTheme.border(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: FieldSalesDensTheme.title(context),
                                ),
                              ),
                              if (row.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  row.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: FieldSalesDensTheme.muted(context),
                                  ),
                                ),
                              ],
                              if (row.ettn != null &&
                                  row.ettn!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _QueueDensField(
                                  label: row.ettnLabel ?? 'ETTN',
                                  value: row.ettn!,
                                ),
                              ],
                              if (row.gibStatusLabel != null &&
                                  row.gibStatusLabel!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _QueueDensField(
                                  label: row.gibStatusFieldLabel ?? 'GİB',
                                  value: row.gibStatusLabel!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 10),
          child: Text(
            l10n.translate(
              'field_sales.queue_count_label',
              args: {'count': '$itemCount'},
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: FieldSalesDensTheme.title(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// {@template _DateCell}
/// Başlangıç / bitiş dens tarih hücresi.
/// {@endtemplate}
class _DateCell extends StatelessWidget {
  /// [primary]: Vurgu rengi
  final Color primary;

  /// [label]: Alan etiketi
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// {@template _QueueDensField}
/// ETTN / GİB dens etiket·değer satırı.
/// {@endtemplate}
class _QueueDensField extends StatelessWidget {
  /// [label]: Alan etiketi
  final String label;

  /// [value]: Alan değeri
  final String value;

  const _QueueDensField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF375A7F),
            ),
          ),
        ),
      ],
    );
  }
}
