// Dosya Adı: cash_card_detail_screen.dart
// Açıklama: Kasa kart detay — Dizayn Dosya + Tarih/İşlem/Evrak No hareketleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/cash_card_master.dart';
import '../model/cash_movement_row.dart';
import '../viewmodel/cash_movement_store.dart';

/// {@template cash_card_detail_screen}
/// Kasa hareket detay dens ekranı (MBT KASA drill-down).
/// Route: `/field-sales/cash-card-detail`
///
/// Kaynak: [movements] enjekte edilirse o; yoksa [CashMovementStore]
/// (`collections` cash_code / target_cash_code).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   CashCardDetailScreen.routeName,
///   arguments: {'code': '100 01 01'},
/// );
/// ```
/// {@endtemplate}
class CashCardDetailScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/cash-card-detail';

  /// Kasa kodu
  final String? cashCode;

  /// Opsiyonel hareket satırları (null → SQLite store)
  final List<CashMovementRow>? movements;

  /// Store enjeksiyonu (test)
  final CashMovementStore? store;

  /// {@macro cash_card_detail_screen}
  const CashCardDetailScreen({
    Key? key,
    this.cashCode,
    this.movements,
    this.store,
  }) : super(key: key);

  @override
  State<CashCardDetailScreen> createState() => _CashCardDetailScreenState();
}

class _CashCardDetailScreenState extends State<CashCardDetailScreen> {
  final TextEditingController _filterController = TextEditingController();
  String _designFile = 'default';
  List<CashMovementRow> _loaded = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.movements != null) {
      setState(() {
        _loaded = List<CashMovementRow>.from(widget.movements!);
        _loading = false;
      });
      return;
    }
    try {
      final store = widget.store ?? const CashMovementStore();
      final code = (widget.cashCode ?? CashCardMaster.defaultCode).trim();
      final rows = await store.listByCashCode(code);
      if (!mounted) return;
      setState(() {
        _loaded = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loaded = const [];
        _loading = false;
      });
    }
  }

  List<CashMovementRow> get _source => _loaded;

  List<CashMovementRow> get _filtered {
    final q = _filterController.text.trim().toLowerCase();
    if (q.isEmpty) return _source;
    return _source
        .where(
          (r) =>
              r.date.toLowerCase().contains(q) ||
              r.operation.toLowerCase().contains(q) ||
              r.documentNo.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = FieldSalesDensAppBar.primaryColor;
    final code = (widget.cashCode ?? CashCardMaster.defaultCode).trim();
    final titleLabel = CashCardMaster.labelOf(l10n, code);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.cash_card_detail'),
        backgroundColor: primary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Text(
              '$code · $titleLabel',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.translate('field_sales.design_file'),
                labelStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: FieldSalesDensTheme.surface(context),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _designFile,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C3E50),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'default',
                      child: Text(
                        l10n.translate('field_sales.design_file_default'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'detail',
                      child: Text(
                        l10n.translate('field_sales.design_file_detail'),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _designFile = v);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _filterController,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('common.search'),
                filled: true,
                fillColor: FieldSalesDensTheme.surface(context),
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
          Container(
            color: primary.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.translate('field_sales.movement_date'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.translate('field_sales.movement_operation'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n.translate('field_sales.collection_document_no'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.translate('field_sales.cash_movements_empty'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final row = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    row.date,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    row.operation,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    row.documentNo,
                                    style: const TextStyle(fontSize: 12),
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
