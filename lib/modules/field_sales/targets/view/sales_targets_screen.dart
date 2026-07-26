// Dosya Adı: sales_targets_screen.dart
// Açıklama: Satış hedefleri dens listesi (SQLite targets + seed)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/sales_target_record.dart';
import '../model/sales_target_seed.dart';
import '../viewmodel/sales_target_store.dart';
import '../widgets/sales_target_dens_tile.dart';

/// {@template sales_targets_screen}
/// Plasiyer satış hedefleri dens listesi (MBT Hedef menü parity).
///
/// Kaynak: SQLite `targets` (boşsa [SalesTargetSeed]).
/// Dens alanlar: Plasiyer · Tür · Dönem · Gerçekleşen/Hedef · %.
///
/// Rota: `/field-sales/sales-targets`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, SalesTargetsScreen.routeName);
/// ```
/// {@endtemplate}
class SalesTargetsScreen extends StatefulWidget {
  /// [routeName]: Named route — menü seed ile aynı
  static const String routeName = SalesTargetSeed.route;

  /// [store]: Test / DI için store (null → varsayılan SQLite)
  final SalesTargetStore? store;

  /// [initialRows]: Opsiyonel önceden yüklenmiş satırlar (test)
  final List<SalesTargetRecord>? initialRows;

  const SalesTargetsScreen({
    Key? key,
    this.store,
    this.initialRows,
  }) : super(key: key);

  @override
  State<SalesTargetsScreen> createState() => _SalesTargetsScreenState();
}

class _SalesTargetsScreenState extends State<SalesTargetsScreen> {
  /// [_store]: SQLite + seed katmanı
  late final SalesTargetStore _store =
      widget.store ?? const SalesTargetStore();

  /// [_rows]: Dens satırlar
  List<SalesTargetRecord> _rows = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final seeded = widget.initialRows;
    if (seeded != null) {
      _rows = seeded;
      _loading = false;
    } else {
      _loadTargets();
    }
  }

  /// {@template _load_targets}
  /// SQLite `targets` dens satırlarını yükler (boşsa seed).
  /// {@endtemplate}
  Future<void> _loadTargets() async {
    setState(() => _loading = true);
    try {
      final rows = await _store.loadAll();
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
    final title = l10n.translate('field_sales.stubs.sales_targets');
    final rows = _rows;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadTargets,
            tooltip: l10n.translate('field_sales.sales_targets.refresh'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.sales_targets.empty'),
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
                        l10n.translate(
                          'field_sales.sales_targets.list_hint',
                        ),
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
                            .translate(
                              'field_sales.sales_targets.count_label',
                            )
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
                                'field_sales.sales_targets.col_personnel',
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
                                'field_sales.sales_targets.col_type',
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
                                'field_sales.sales_targets.col_progress',
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
                          return SalesTargetDensTile(
                            record: rows[index],
                            l10n: l10n,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
