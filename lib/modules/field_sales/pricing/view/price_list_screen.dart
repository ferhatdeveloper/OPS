// Dosya Adı: price_list_screen.dart
// Açıklama: Fiyat listesi dens ekranı (SQLite price_lists + seed)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/price_list_dens_row.dart';
import '../model/price_list_seed.dart';
import '../viewmodel/price_list_store.dart';

/// {@template price_list_screen}
/// Fiyat listesi dens listesi (ad · para birimi · kalem adedi).
/// Route: `/field-sales/price-list`
///
/// Kaynak: SQLite `price_lists` (+ seed fallback).
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, PriceListScreen.routeName);
/// ```
/// {@endtemplate}
class PriceListScreen extends StatefulWidget {
  /// [routeName]: Named route — menü seed ile aynı
  static const String routeName = PriceListSeed.route;

  /// [rows]: Opsiyonel dens satırlar (null → SQLite / seed)
  final List<PriceListDensRow>? rows;

  /// [store]: Test için enjekte edilebilir store
  final PriceListStore? store;

  /// {@macro price_list_screen}
  const PriceListScreen({
    Key? key,
    this.rows,
    this.store,
  }) : super(key: key);

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  /// [_rows]: Dens fiyat listesi satırları
  List<PriceListDensRow> _rows = const [];

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  /// {@template price_list_screen_load}
  /// Dens satırları store veya enjekte listeden yükler.
  /// {@endtemplate}
  Future<void> _loadRows() async {
    if (widget.rows != null) {
      setState(() {
        _rows = widget.rows!;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final store = widget.store ?? const PriceListStore();
    try {
      final rows = await store.loadDensRows();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = PriceListDensRow.fromSeed();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.price_list');
    final rows = _rows;

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.price_list.empty'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        l10n.translate('field_sales.price_list.list_hint'),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        l10n
                            .translate('field_sales.price_list.count_label')
                            .replaceAll('{count}', '${rows.length}'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              l10n.translate(
                                'field_sales.price_list.name_col',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.translate(
                                'field_sales.price_list.currency_col',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.translate(
                                'field_sales.price_list.items_col',
                              ),
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = rows[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: FieldSalesDensTheme.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF375A7F)
                                      .withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.currency,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${item.itemCount}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
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
