// Dosya Adı: whms_fifo_rule_list_screen.dart
// Açıklama: WHMS FIFO/FEFO kural dens liste + form
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../field_sales/shared/view/field_sales_dens_theme.dart';

import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_filter_bar.dart';
import '../../contract/whms_route_map.dart';
import '../../engine/whms_fifo_models.dart';
import '../viewmodel/whms_fifo_rule_store.dart';

/// {@template whms_fifo_rule_list_screen}
/// Ürün bazlı FIFO/FEFO kural dens listesi — CRUD.
/// Route: `/whms/fifo`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsFifoRuleListScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsFifoRuleListScreen extends StatefulWidget {
  /// Named route
  static const String routeName = WhmsRouteMap.whmsFifo;

  /// Opsiyonel satır enjeksiyonu (test)
  final List<WhmsFifoRule>? rows;

  /// Store enjeksiyonu (test)
  final WhmsFifoRuleStore? store;

  /// {@macro whms_fifo_rule_list_screen}
  const WhmsFifoRuleListScreen({
    Key? key,
    this.rows,
    this.store,
  }) : super(key: key);

  @override
  State<WhmsFifoRuleListScreen> createState() =>
      _WhmsFifoRuleListScreenState();
}

class _WhmsFifoRuleListScreenState extends State<WhmsFifoRuleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WhmsFifoRule> _all = const [];
  List<WhmsFifoRule> _filtered = const [];
  bool _loading = true;

  /// null = tümü; true = FEFO açık; false = FEFO kapalı
  bool? _fefoFilter;

  WhmsFifoRuleStore get _store =>
      widget.store ?? const WhmsFifoRuleStore();

  @override
  void initState() {
    super.initState();
    if (widget.rows != null) {
      _all = List<WhmsFifoRule>.from(widget.rows!);
      _filtered = List<WhmsFifoRule>.from(_all);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _store.ensureReady();
      final rows = await _store.listActive(fefoEnforceOnly: _fefoFilter);
      if (!mounted) return;
      setState(() {
        _all = rows;
        _applyFilter(_searchController.text, notify: false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter(String query, {bool notify = true}) {
    final q = query.trim().toLowerCase();
    final next = q.isEmpty
        ? List<WhmsFifoRule>.from(_all)
        : _all
            .where((o) => o.productCode.toLowerCase().contains(q))
            .toList(growable: false);
    if (notify) {
      setState(() => _filtered = next);
    } else {
      _filtered = next;
    }
  }

  Future<void> _setFefoFilter(bool? value) async {
    if (_fefoFilter == value) return;
    setState(() {
      _fefoFilter = value;
      _loading = true;
    });
    await _load();
  }

  Future<void> _showEditor({WhmsFifoRule? existing}) async {
    final l10n = AppLocalization.of(context);
    final codeCtrl = TextEditingController(
      text: existing?.productCode ?? '',
    );
    final fifoCtrl = TextEditingController(
      text: (existing?.fifoDays ?? 0).toString(),
    );
    final warnCtrl = TextEditingController(
      text: (existing?.warnDays ?? 0).toString(),
    );
    var fefoEnforce = existing?.fefoEnforce ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? l10n.translate('whms.fifo.add')
                    : l10n.translate('whms.fifo.edit'),
                style: const TextStyle(fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _densField(
                      controller: codeCtrl,
                      label: l10n.translate('whms.fifo.product_code'),
                      enabled: existing == null,
                      capitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    _densField(
                      controller: fifoCtrl,
                      label: l10n.translate('whms.fifo.fifo_days'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 8),
                    _densField(
                      controller: warnCtrl,
                      label: l10n.translate('whms.fifo.warn_days'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.translate('whms.fifo.fefo_enforce'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: fefoEnforce,
                      onChanged: (v) => setLocal(() => fefoEnforce = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.translate('common.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.translate('whms.fifo.save')),
                ),
              ],
            );
          },
        );
      },
    );

    final code = codeCtrl.text.trim();
    final fifoDays = int.tryParse(fifoCtrl.text.trim()) ?? 0;
    final warnDays = int.tryParse(warnCtrl.text.trim()) ?? 0;
    codeCtrl.dispose();
    fifoCtrl.dispose();
    warnCtrl.dispose();

    if (saved != true || !mounted) return;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('whms.fifo.required_fields'),
          ),
        ),
      );
      return;
    }

    try {
      await _store.upsert(
        WhmsFifoRule(
          id: existing?.id ?? '',
          productCode: code,
          fifoDays: fifoDays,
          fefoEnforce: fefoEnforce,
          warnDays: warnDays,
          createdAt: existing?.createdAt,
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('whms.fifo.required_fields'),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(WhmsFifoRule record) async {
    final l10n = AppLocalization.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.translate('whms.fifo.delete'),
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          l10n.translate(
            'whms.fifo.delete_confirm',
            args: {'code': record.productCode},
          ),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('common.delete')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _store.softDelete(record.id);
    await _load();
  }

  Widget _densField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textCapitalization: capitalization,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
      ),
    );
  }

  List<FieldSalesDensChipItem> _fefoChips(AppLocalization l10n) {
    return [
      FieldSalesDensChipItem(
        label: l10n.translate('whms.fifo.filter_all'),
        selected: _fefoFilter == null,
        onTap: () => _setFefoFilter(null),
      ),
      FieldSalesDensChipItem(
        label: l10n.translate('whms.fifo.filter_fefo_on'),
        selected: _fefoFilter == true,
        onTap: () => _setFefoFilter(true),
      ),
      FieldSalesDensChipItem(
        label: l10n.translate('whms.fifo.filter_fefo_off'),
        selected: _fefoFilter == false,
        onTap: () => _setFefoFilter(false),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.fifo.title'),
        backgroundColor: primary,
        showCalculatorHome: false,
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add,
            tooltip: l10n.translate('whms.fifo.add'),
            onPressed: () => _showEditor(),
          ),
        ],
        bottom: FieldSalesDensFilterBar(
          children: [
            FieldSalesDensChipRow(items: _fefoChips(l10n)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.translate('whms.fifo.search_hint'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
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
              onChanged: _applyFilter,
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
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('whms.fifo.empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color: FieldSalesDensTheme.muted(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final row = _filtered[index];
                          return _FifoRuleRow(
                            rule: row,
                            l10n: l10n,
                            onEdit: () => _showEditor(existing: row),
                            onDelete: () => _confirmDelete(row),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Dens FIFO kural satırı.
class _FifoRuleRow extends StatelessWidget {
  final WhmsFifoRule rule;
  final AppLocalization l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FifoRuleRow({
    required this.rule,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fefoLabel = rule.fefoEnforce
        ? l10n.translate('whms.fifo.filter_fefo_on')
        : l10n.translate('whms.fifo.filter_fefo_off');
    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onEdit,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.productCode,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FieldSalesDensTheme.title(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${l10n.translate('whms.fifo.fifo_days_short')} '
                            '${rule.fifoDays}',
                        '${l10n.translate('whms.fifo.warn_days_short')} '
                            '${rule.warnDays}',
                        fefoLabel,
                      ].join('  ·  '),
                      style: TextStyle(
                        fontSize: 11,
                        color: FieldSalesDensTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: FieldSalesDensTheme.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
