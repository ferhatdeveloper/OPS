// Dosya Adı: mbt_sales_purchase_queue_body.dart
// Açıklama: MBT kuyruk dens gövde — 1-SATIŞ/2-ALIŞ + dönem filtre
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localization.dart';

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
  static const Color _primary = Color(0xFF375A7F);

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _SegmentRow(
            primary: _primary,
            leftLabel: l10n.translate('field_sales.queue_tab_sales'),
            rightLabel: l10n.translate('field_sales.queue_tab_purchase'),
            leftSelected: _docSide == MbtQueueDocSide.sales,
            onLeft: () => setState(() => _docSide = MbtQueueDocSide.sales),
            onRight: () => setState(() => _docSide = MbtQueueDocSide.purchase),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              for (final entry in <(MbtQueuePeriod, String)>[
                (MbtQueuePeriod.today, 'field_sales.period_today'),
                (MbtQueuePeriod.thisWeek, 'field_sales.period_this_week'),
                (MbtQueuePeriod.thisMonth, 'field_sales.period_this_month'),
                (MbtQueuePeriod.thisYear, 'field_sales.period_this_year'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _PeriodChip(
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
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
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
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
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
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              if (row.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  row.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
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
    );
  }
}

/// {@template _SegmentRow}
/// İki bölmeli dens sekme satırı (1-SATIŞ / 2-ALIŞ).
/// {@endtemplate}
class _SegmentRow extends StatelessWidget {
  /// [primary]: Vurgu rengi
  final Color primary;

  /// [leftLabel]: Sol sekme metni
  final String leftLabel;

  /// [rightLabel]: Sağ sekme metni
  final String rightLabel;

  /// [leftSelected]: Sol seçili mi
  final bool leftSelected;

  /// [onLeft]: Sol tap
  final VoidCallback onLeft;

  /// [onRight]: Sağ tap
  final VoidCallback onRight;

  const _SegmentRow({
    required this.primary,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SegmentButton(
            primary: primary,
            label: leftLabel,
            selected: leftSelected,
            onTap: onLeft,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SegmentButton(
            primary: primary,
            label: rightLabel,
            selected: !leftSelected,
            onTap: onRight,
          ),
        ),
      ],
    );
  }
}

/// {@template _SegmentButton}
/// Tek dens segment düğmesi.
/// {@endtemplate}
class _SegmentButton extends StatelessWidget {
  /// [primary]: Vurgu rengi
  final Color primary;

  /// [label]: Etiket
  final String label;

  /// [selected]: Seçili mi
  final bool selected;

  /// [onTap]: Tap
  final VoidCallback onTap;

  const _SegmentButton({
    required this.primary,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primary),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected ? primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// {@template _PeriodChip}
/// Dönem dens chip.
/// {@endtemplate}
class _PeriodChip extends StatelessWidget {
  /// [primary]: Vurgu rengi
  final Color primary;

  /// [label]: Etiket
  final String label;

  /// [selected]: Seçili mi
  final bool selected;

  /// [onTap]: Tap
  final VoidCallback onTap;

  const _PeriodChip({
    required this.primary,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : primary.withOpacity(0.85),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: primary),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: selected ? primary : Colors.white,
            ),
          ),
        ),
      ),
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
