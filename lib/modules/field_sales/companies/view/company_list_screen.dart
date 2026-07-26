// Dosya Adı: company_list_screen.dart
// Açıklama: MBT Mobil Şirket Listesi — dens firma/dönem seçim
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../model/active_company_session.dart';
import '../viewmodel/active_company_store.dart';

/// {@template company_period_row}
/// Firma + dönem satırı (MBT: ad · Firma No · Dönem · tarih aralığı).
/// {@endtemplate}
class CompanyPeriodRow {
  /// [companyId]: companies.id
  final String companyId;

  /// [name]: Firma adı (ör. MBT)
  final String name;

  /// [companyNo]: Firma No (ör. 001)
  final String companyNo;

  /// [periodNo]: Dönem No / period_name (ör. 01)
  final String periodNo;

  /// [startDate]: Başlangıç (DD-MM-YYYY veya ISO)
  final String startDate;

  /// [endDate]: Bitiş (DD-MM-YYYY veya ISO)
  final String endDate;

  /// {@macro company_period_row}
  const CompanyPeriodRow({
    required this.companyId,
    required this.name,
    required this.companyNo,
    required this.periodNo,
    required this.startDate,
    required this.endDate,
  });
}

/// {@template company_list_screen}
/// MBT dens firma seçim: Ara · kart · Seç.
/// Route: `/field-sales/companies`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CompanyListScreen.routeName);
/// ```
/// {@endtemplate}
class CompanyListScreen extends StatefulWidget {
  /// [routeName]: Named route — menü seed ile aynı
  static const String routeName = '/field-sales/companies';

  const CompanyListScreen({Key? key}) : super(key: key);

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CompanyPeriodRow> _rows = const [];
  List<CompanyPeriodRow> _filtered = const [];
  int? _selectedIndex;
  bool _loading = true;

  /// MBT ekran görüntüsü ile aynı stub (DB boşsa).
  static const List<CompanyPeriodRow> _stubRows = [
    CompanyPeriodRow(
      companyId: 'mbt_001',
      name: 'MBT',
      companyNo: '001',
      periodNo: '01',
      startDate: '01-01-2024',
      endDate: '31-12-2024',
    ),
  ];

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

  /// {@template _formatDisplayDate}
  /// ISO veya ham tarihi MBT DD-MM-YYYY gösterimine çevirir.
  ///
  /// Parametreler:
  /// - [raw]: Ham tarih metni
  ///
  /// Dönüş değeri:
  /// - [String]: Görüntü tarihi
  /// {@endtemplate}
  String _formatDisplayDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    // Zaten DD-MM-YYYY
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(t)) return t;
    // YYYY-MM-DD (±time)
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (iso != null) {
      return '${iso.group(3)}-${iso.group(2)}-${iso.group(1)}';
    }
    return t;
  }

  /// {@template _loadRows}
  /// company_period + companies birleşiminden dens satırları yükler.
  /// {@endtemplate}
  Future<void> _loadRows() async {
    setState(() => _loading = true);
    try {
      final db = await DatabaseService.getInstance();
      final periods = await db.getAllCompanyPeriodsWithCompanyName();
      final List<CompanyPeriodRow> rows = [];

      for (final p in periods) {
        final name = (p['company_name'] ?? p['period_name'] ?? '').toString();
        final companyNo = (p['company_no'] ?? '').toString();
        final periodNo = (p['period_name'] ?? '').toString();
        final companyId = (p['company_id'] ?? companyNo).toString();
        if (name.isEmpty && companyNo.isEmpty) continue;
        rows.add(
          CompanyPeriodRow(
            companyId: companyId.isEmpty ? companyNo : companyId,
            name: name.isEmpty ? 'MBT' : name,
            companyNo: companyNo.isEmpty ? '001' : companyNo,
            periodNo: periodNo.isEmpty ? '01' : periodNo,
            startDate: _formatDisplayDate(
              (p['start_date'] ?? '').toString(),
            ),
            endDate: _formatDisplayDate((p['end_date'] ?? '').toString()),
          ),
        );
      }

      // Firma var, dönem yoksa companies tablosundan dens satır üret
      if (rows.isEmpty) {
        final companies = await db.getCompanies();
        for (final c in companies) {
          final id = (c['id'] ?? '').toString();
          final name = (c['name'] ?? '').toString();
          final no = (c['company_no'] ?? '').toString();
          if (id.isEmpty && name.isEmpty) continue;
          rows.add(
            CompanyPeriodRow(
              companyId: id,
              name: name.isEmpty ? 'MBT' : name,
              companyNo: no.isEmpty ? '001' : no,
              periodNo: '01',
              startDate: _formatDisplayDate(
                (c['created_at'] ?? '01-01-2024').toString(),
              ),
              endDate: _formatDisplayDate(
                (c['updated_at'] ?? '31-12-2024').toString(),
              ),
            ),
          );
        }
      }

      final effective = rows.isEmpty ? _stubRows : rows;
      final session = await const ActiveCompanyStore(
        syncLogoPrefs: false,
        syncPostgresContext: false,
      ).load();
      final selected = _indexForSession(effective, session) ??
          (effective.isEmpty ? null : 0);

      if (!mounted) return;
      setState(() {
        _rows = effective;
        _filtered = effective;
        _selectedIndex = selected;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = _stubRows;
        _filtered = _stubRows;
        _selectedIndex = 0;
        _loading = false;
      });
    }
  }

  /// {@template _index_for_session}
  /// Kayıtlı oturuma göre dens satır indeksini bulur.
  ///
  /// Parametreler:
  /// - [rows]: Dens satırlar
  /// - [session]: Aktif oturum
  ///
  /// Dönüş değeri:
  /// - [int?]: Eşleşen indeks veya null
  /// {@endtemplate}
  int? _indexForSession(
    List<CompanyPeriodRow> rows,
    ActiveCompanySession session,
  ) {
    if (session.isEmpty || rows.isEmpty) return null;
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final idMatch = session.companyId.isNotEmpty &&
          r.companyId == session.companyId;
      final noMatch = r.companyNo == session.companyNo &&
          r.periodNo == session.periodNo;
      if (idMatch || noMatch) return i;
    }
    return null;
  }

  /// {@template _applyFilter}
  /// Ara kutusuna göre dens listeyi süzgeçler.
  ///
  /// Parametreler:
  /// - [query]: Arama metni
  /// {@endtemplate}
  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _rows;
      } else {
        _filtered = _rows
            .where(
              (r) =>
                  r.name.toLowerCase().contains(q) ||
                  r.companyNo.toLowerCase().contains(q) ||
                  r.periodNo.toLowerCase().contains(q),
            )
            .toList();
      }
      _selectedIndex = _filtered.isEmpty ? null : 0;
    });
  }

  /// {@template _onSelect}
  /// Seçili firma/dönemi kalıcılaştırır ve ekranı kapatır.
  /// {@endtemplate}
  Future<void> _onSelect() async {
    final l10n = AppLocalization.of(context);
    final idx = _selectedIndex;
    if (idx == null || idx < 0 || idx >= _filtered.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.company_select_required'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final row = _filtered[idx];
    final session = ActiveCompanySession(
      companyId: row.companyId,
      companyName: row.name,
      companyNo: row.companyNo,
      periodNo: row.periodNo,
      startDate: row.startDate,
      endDate: row.endDate,
    );
    try {
      // Session + SharedPreferences (+ Logo/Postgres bağlamı)
      await const ActiveCompanyStore().save(session);

      final db = await DatabaseService.getInstance();
      if (row.companyId.isNotEmpty && row.companyId != 'mbt_001') {
        await db.updateCompanySelection(row.companyId);
      } else if (row.companyId == 'mbt_001') {
        // Stub seçimi: MBT seed kaydı varsa işaretle
        await db.addOrUpdateCompany(
          id: 'mbt_001',
          name: row.name,
          companyNo: row.companyNo,
          description: 'MBT',
          isActive: true,
          createdAt: '2024-01-01',
          updatedAt: '2024-12-31',
          isSelected: true,
        );
      }
      if (row.periodNo.isNotEmpty) {
        await db.updateCompanyPeriod(row.periodNo);
      }
    } catch (_) {
      // Offline / şema — prefs oturumu zaten yazılmış olabilir
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('field_sales.company_selected')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.company_list');
    final titleFallback = l10n.translate('submodules.mobil_sirket_listesi');
    final appTitle =
        title == 'field_sales.stubs.company_list' ? titleFallback : title;

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
          appTitle,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.translate('common.search'),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                    onChanged: _applyFilter,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.translate('field_sales.no_companies'),
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final row = _filtered[index];
                            final selected = _selectedIndex == index;
                            return _CompanyDensTile(
                              row: row,
                              selected: selected,
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _onSelect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF375A7F),
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
                            fontSize: 16,
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

/// {@template _company_dens_tile}
/// MBT dens firma satırı (ad · Firma No · Dönem · tarih).
/// {@endtemplate}
class _CompanyDensTile extends StatelessWidget {
  /// [row]: Firma/dönem satırı
  final CompanyPeriodRow row;

  /// [selected]: Seçili mi
  final bool selected;

  /// [onTap]: Satır seçimi
  final VoidCallback onTap;

  const _CompanyDensTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final firmaNo = l10n.translate('field_sales.firma_no_label');
    final donemNo = l10n.translate('field_sales.donem_no_label');
    final baslangic = l10n.translate('field_sales.baslangic_label');
    final bitis = l10n.translate('field_sales.bitis_label');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF375A7F)
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$firmaNo : ${row.companyNo}  $donemNo : ${row.periodNo}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$baslangic : ${row.startDate}  -  $bitis : ${row.endDate}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
