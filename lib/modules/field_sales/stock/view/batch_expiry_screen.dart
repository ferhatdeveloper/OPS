// Dosya Adı: batch_expiry_screen.dart
// Açıklama: Parti / SKT dens listesi (SQLite + seed fallback)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/batch_expiry_record.dart';
import '../model/batch_expiry_seed.dart';
import '../viewmodel/batch_expiry_store.dart';
import '../widgets/batch_expiry_dens_tile.dart';

/// {@template batch_expiry_screen}
/// Parti / SKT dens listesi (stok · lot · SKT · ambar).
/// Kaynak: SQLite `batch_expiry`; boş/hata → stub seed.
/// Route: `/field-sales/batch-expiry`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, BatchExpiryScreen.routeName);
/// ```
/// {@endtemplate}
class BatchExpiryScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/batch-expiry`
  static const String routeName = '/field-sales/batch-expiry';

  /// [records]: Opsiyonel kayıtlar (null → SQLite / seed)
  final List<BatchExpiryRecord>? records;

  /// [store]: Opsiyonel store (null → varsayılan [BatchExpiryStore])
  final BatchExpiryStore? store;

  const BatchExpiryScreen({
    Key? key,
    this.records,
    this.store,
  }) : super(key: key);

  @override
  State<BatchExpiryScreen> createState() => _BatchExpiryScreenState();
}

class _BatchExpiryScreenState extends State<BatchExpiryScreen> {
  /// [_searchController]: Arama alanı
  final TextEditingController _searchController = TextEditingController();

  /// [_query]: Aktif arama metni
  String _query = '';

  /// [_rows]: Yüklenen dens kayıtları
  List<BatchExpiryRecord> _rows = const [];

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// {@template batch_expiry_screen_load_rows}
  /// Enjekte kayıt varsa kullanır; yoksa SQLite (boşsa seed) okur.
  /// {@endtemplate}
  Future<void> _loadRows() async {
    final injected = widget.records;
    if (injected != null) {
      setState(() {
        _rows = injected;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final store = widget.store ?? const BatchExpiryStore();
      final rows = await store.loadAllOrSeed();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = List<BatchExpiryRecord>.from(BatchExpirySeed.defaultRows);
        _loading = false;
      });
    }
  }

  /// {@template batch_expiry_screen_filtered}
  /// Arama filtresi uygulanmış dens satırlar.
  /// {@endtemplate}
  List<BatchExpiryDensRow> _filtered(
    List<BatchExpiryDensRow> rows,
  ) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.searchBlob.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.batch_expiry');
    final densRows = BatchExpiryDensTile.toDensRows(_rows, l10n);
    final rows = _filtered(densRows);
    final emptyKey = _query.trim().isEmpty
        ? 'field_sales.batch_expiry_empty'
        : 'field_sales.batch_expiry_not_found';

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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.translate(
                        'field_sales.batch_expiry_search_hint',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Text(
                            l10n.translate(emptyKey),
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              elevation: 0,
                              shadowColor: const Color(0xFF375A7F)
                                  .withOpacity(0.08),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF375A7F)
                                          .withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                    row.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        row.subtitle,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (row.warehouseLabel.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          row.warehouseLabel,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        row.statusLabel,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
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
