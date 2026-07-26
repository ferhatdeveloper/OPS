// Dosya Adı: check_list_screen.dart
// Açıklama: MBT Çek Listesi dens — collections check tipi + durum sekmeleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/check_list_row.dart';
import '../model/check_list_seed.dart';
import '../model/check_list_status.dart';
import '../model/collection_model.dart';

/// {@template check_list_screen}
/// Çek Listesi dens ekranı — `payment_type=check` collections.
///
/// MBT durum sekmeleri: teminata, tahsile, iade, tahsil edilen,
/// karşılıksız, tahsil edilemeyen, ödenen/verilen firma çekleri.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CheckListScreen.routeName);
/// // veya collections → dens:
/// CheckListScreen.fromCollections(models);
/// ```
/// {@endtemplate}
class CheckListScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/checks`
  static const String routeName = '/field-sales/checks';

  /// [rows]: Opsiyonel dens satırlar (null → [CheckListSeed.defaultRows])
  final List<CheckListRow>? rows;

  /// {@macro check_list_screen}
  const CheckListScreen({
    super.key,
    this.rows,
  });

  /// {@template check_list_screen_from_collections}
  /// Collections listesinden yalnızca check tipi dens ekranı.
  /// {@endtemplate}
  factory CheckListScreen.fromCollections(
    List<CollectionModel> collections, {
    Key? key,
  }) {
    return CheckListScreen(
      key: key,
      rows: CheckListRow.fromCollections(collections),
    );
  }

  @override
  State<CheckListScreen> createState() => _CheckListScreenState();
}

class _CheckListScreenState extends State<CheckListScreen>
    with SingleTickerProviderStateMixin {
  /// [_searchController]: Durum listesi arama alanı
  final TextEditingController _searchController = TextEditingController();

  /// [_tabController]: Durum sekmeleri denetleyicisi
  late TabController _tabController;

  /// [_source]: Check tipi dens kaynak satırlar
  late List<CheckListRow> _source;

  @override
  void initState() {
    super.initState();
    _source = List<CheckListRow>.from(
      widget.rows ?? CheckListSeed.defaultRows,
    );
    _tabController = TabController(
      length: CheckListStatus.tabs.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant CheckListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _source = List<CheckListRow>.from(
        widget.rows ?? CheckListSeed.defaultRows,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// {@template _active_status}
  /// Seçili sekme durumu.
  /// {@endtemplate}
  CheckListStatus get _activeStatus {
    final i = _tabController.index.clamp(0, CheckListStatus.tabs.length - 1);
    return CheckListStatus.tabs[i];
  }

  /// {@template _filtered}
  /// Aktif durum + arama süzgeçli dens satırlar.
  /// {@endtemplate}
  List<CheckListRow> get _filtered {
    return CheckListRow.filter(
      _source,
      status: _activeStatus,
      query: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    const Color appBarBlue = Color(0xFF375A7F);
    final filtered = _filtered;
    final totalText = CheckListRow.formatAmount(
      CheckListRow.totalAmount(filtered),
    );
    final countText = '${filtered.length}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: appBarBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n.translate('field_sales.stubs.check_list'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: [
            for (final status in CheckListStatus.tabs)
              Tab(text: l10n.translate(status.l10nKey)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.translate('common.search'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate(
                      'field_sales.check_total_label',
                      args: {'amount': totalText},
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Text(
                  l10n.translate(
                    'field_sales.check_count_label',
                    args: {'count': countText},
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final status in CheckListStatus.tabs)
                  _buildStatusBody(l10n, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// {@template _buildStatusBody}
  /// Durum sekmesi dens liste veya boş durum.
  /// {@endtemplate}
  Widget _buildStatusBody(AppLocalization l10n, CheckListStatus status) {
    final rows = CheckListRow.filter(
      _source,
      status: status,
      query: _searchController.text,
    );
    if (rows.isEmpty) {
      return _buildStatusEmpty(l10n, status);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _CheckDensTile(row: rows[index]);
      },
    );
  }

  /// {@template _buildStatusEmpty}
  /// Seçili durum için boş dens görünümü.
  /// {@endtemplate}
  Widget _buildStatusEmpty(AppLocalization l10n, CheckListStatus status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate(status.l10nKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('field_sales.check_list_empty'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('field_sales.check_list_stub_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate(
                'field_sales.check_total_label',
                args: {'amount': '0,00'},
              ),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              l10n.translate(
                'field_sales.check_count_label',
                args: {'count': '0'},
              ),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// {@template _check_dens_tile}
/// Çek dens satır kartı (çek no · banka · tutar · vade).
/// {@endtemplate}
class _CheckDensTile extends StatelessWidget {
  /// [row]: Dens satır
  final CheckListRow row;

  /// {@macro _check_dens_tile}
  const _CheckDensTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final due = row.dueDate;
    final dueText = due == null
        ? ''
        : '${due.day.toString().padLeft(2, '0')}.'
            '${due.month.toString().padLeft(2, '0')}.'
            '${due.year}';
    final subtitleParts = <String>[
      if ((row.bankName ?? '').isNotEmpty) row.bankName!,
      if ((row.customerName ?? row.customerId).isNotEmpty)
        (row.customerName ?? row.customerId),
      if (dueText.isNotEmpty)
        l10n.translate(
          'field_sales.due_date_prefix',
          args: {'date': dueText},
        ),
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.checkNumber.isEmpty
                          ? (row.documentNo ?? row.id)
                          : row.checkNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleParts.join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                CheckListRow.formatAmount(row.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
