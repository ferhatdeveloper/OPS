// Dosya Adı: cash_card_list_screen.dart
// Açıklama: Kasa kart listesi dens master seçici (MBT FİNANS → Kasa Kart Listesi)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/cash_card_master.dart';
import '../viewmodel/cash_card_store.dart';
import 'cash_card_detail_screen.dart';

/// {@template cash_card_list_screen}
/// Kasa kart listesi dens ekranı — ara · satır · Seç.
/// Route: `/field-sales/cash-cards`
///
/// Kaynak: [CashCardStore.listActive]; boş/hata → [CashCardMaster].
///
/// [selectionMode] true iken Seç, seçili [CashCardOption] ile pop eder
/// (nakit tahsilat Kasa Kodu dens seçici).
///
/// Kullanım örneği:
/// ```dart
/// final card = await Navigator.push<CashCardOption>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => const CashCardListScreen(selectionMode: true),
///   ),
/// );
/// ```
/// {@endtemplate}
class CashCardListScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/cash-cards`
  static const String routeName = '/field-sales/cash-cards';

  /// [selectionMode]: true → Seç pop sonucu döner
  final bool selectionMode;

  /// [initialCode]: Önceden seçili safe_code (varsayılan master)
  final String? initialCode;

  /// [store]: SQLite kasa kart store (test enjeksiyonu)
  final CashCardStore? store;

  /// {@macro cash_card_list_screen}
  const CashCardListScreen({
    Key? key,
    this.selectionMode = false,
    this.initialCode,
    this.store,
  }) : super(key: key);

  @override
  State<CashCardListScreen> createState() => _CashCardListScreenState();
}

class _CashCardListScreenState extends State<CashCardListScreen> {
  /// [_searchController]: Dens arama
  final TextEditingController _searchController = TextEditingController();

  /// [_all]: Store veya master kaynak satırlar
  late List<CashCardOption> _all;

  /// [_filtered]: Süzülmüş satırlar
  late List<CashCardOption> _filtered;

  /// [_selectedIndex]: Seçili dens satır
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _all = List<CashCardOption>.from(CashCardMaster.options);
    _filtered = List<CashCardOption>.from(_all);
    _selectedIndex = _indexOfCode(widget.initialCode) ?? 0;
    _loadFromStore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template _load_from_store}
  /// Store’dan aktif kasaları yükler; boş/hata → master kalır.
  /// {@endtemplate}
  Future<void> _loadFromStore() async {
    try {
      final store = widget.store ?? const CashCardStore();
      await store.ensureReady();
      final rows = await store.listActive();
      if (!mounted || rows.isEmpty) return;
      final options = rows.map((r) => r.toOption()).toList(growable: false);
      setState(() {
        _all = options;
        _applyFilterState(_searchController.text);
      });
    } catch (_) {
      // Master fallback — dens UI değişmez
    }
  }

  /// {@template _index_of_code}
  /// Listede koda göre indeks (yoksa null).
  /// {@endtemplate}
  int? _indexOfCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final trimmed = code.trim();
    for (var i = 0; i < _filtered.length; i++) {
      if (_filtered[i].code == trimmed) return i;
    }
    return null;
  }

  /// {@template _filter_local}
  /// [_all] üzerinde kod / ünvan süzgeci.
  /// {@endtemplate}
  List<CashCardOption> _filterLocal(
    AppLocalization l10n,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<CashCardOption>.from(_all);
    return _all
        .where(
          (o) =>
              o.code.toLowerCase().contains(q) ||
              o.label(l10n).toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  /// {@template _apply_filter_state}
  /// Arama metnine göre [_filtered] + seçim günceller (setState dışı).
  /// {@endtemplate}
  void _applyFilterState(String query) {
    final l10n = AppLocalization.of(context);
    final previousCode =
        (_selectedIndex != null &&
                _selectedIndex! >= 0 &&
                _selectedIndex! < _filtered.length)
            ? _filtered[_selectedIndex!].code
            : widget.initialCode;
    _filtered = _filterLocal(l10n, query);
    if (_filtered.isEmpty) {
      _selectedIndex = null;
    } else {
      _selectedIndex = _indexOfCode(previousCode) ?? 0;
    }
  }

  /// {@template _apply_filter}
  /// Ara kutusuna göre dens listeyi süzgeçler.
  /// {@endtemplate}
  void _applyFilter(String query) {
    setState(() => _applyFilterState(query));
  }

  /// {@template _on_select}
  /// Seçili kasayı döndürür (selectionMode) veya detay ekranına gider.
  /// {@endtemplate}
  void _onSelect() {
    final l10n = AppLocalization.of(context);
    final idx = _selectedIndex;
    if (idx == null || idx < 0 || idx >= _filtered.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.cash_card_select_required'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final selected = _filtered[idx];
    if (widget.selectionMode) {
      Navigator.of(context).pop<CashCardOption>(selected);
    } else {
      Navigator.of(context).pushNamed(
        CashCardDetailScreen.routeName,
        arguments: {'code': selected.code},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.cash_card_list');
    const Color primary = Color(0xFF375A7F);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: title,
        backgroundColor: primary,
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
                hintText: l10n.translate('common.search'),
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
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.translate('field_sales.cash_card_empty'),
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final row = _filtered[index];
                      final selected = _selectedIndex == index;
                      return _CashCardDensTile(
                        option: row,
                        label: row.label(l10n),
                        selected: selected,
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          if (!widget.selectionMode) {
                            Navigator.of(context).pushNamed(
                              CashCardDetailScreen.routeName,
                              arguments: {'code': row.code},
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.translate('common.select'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// {@template cash_card_dens_tile}
/// Tek kasa satırı dens kartı (kod + ünvan).
/// {@endtemplate}
class _CashCardDensTile extends StatelessWidget {
  /// [option]: Master satır
  final CashCardOption option;

  /// [label]: Yerelleştirilmiş ünvan
  final String label;

  /// [selected]: Seçili vurgusu
  final bool selected;

  /// [onTap]: Satır seçimi
  final VoidCallback onTap;

  /// {@macro cash_card_dens_tile}
  const _CashCardDensTile({
    required this.option,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: FieldSalesDensTheme.surface(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF375A7F)
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF375A7F),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
