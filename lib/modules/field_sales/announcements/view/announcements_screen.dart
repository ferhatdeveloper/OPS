// Dosya Adı: announcements_screen.dart
// Açıklama: Duyurular dens kampanya listesi (SQLite campaigns)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../model/announcement_campaign_row.dart';

/// {@template announcements_screen}
/// Plasiyer kampanya duyuruları dens listesi (MBT parity).
///
/// Kaynak: SQLite `campaigns` (aktif satırlar).
/// Dens alanlar: Kampanya Duyurusu · Başlangıç Tarihi · Bitiş Tarihi.
///
/// Rota: `/field-sales/announcements`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, AnnouncementsScreen.routeName);
/// ```
/// {@endtemplate}
class AnnouncementsScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/announcements`
  static const String routeName = '/field-sales/announcements';

  /// Dashboard badge — SQLite aktif kampanya adedi (önbellek).
  static int densCount = 0;

  /// Son yüklenen dens satırlar (önbellek; test / badge senkron).
  static List<AnnouncementCampaignRow> densRows = const [];

  const AnnouncementsScreen({Key? key}) : super(key: key);

  /// {@template applyDensCacheFromMaps}
  /// Test / senkron: campaigns map listesinden dens önbelleğini günceller.
  ///
  /// Parametreler:
  /// - [maps]: SQLite campaigns satırları
  ///
  /// Dönüş değeri:
  /// - [int]: Aktif dens satır sayısı
  /// {@endtemplate}
  static int applyDensCacheFromMaps(List<Map<String, dynamic>> maps) {
    densRows = AnnouncementCampaignRow.fromCampaignMaps(maps);
    densCount = densRows.length;
    return densCount;
  }

  /// {@template refreshDensCache}
  /// SQLite `campaigns` tablosundan dens önbelleğini yeniler.
  ///
  /// Dönüş değeri:
  /// - [int]: Aktif dens satır sayısı (hata → 0)
  /// {@endtemplate}
  static Future<int> refreshDensCache() async {
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final maps = await sqliteDb.query('campaigns');
      return applyDensCacheFromMaps(maps);
    } catch (_) {
      densRows = const [];
      densCount = 0;
      return 0;
    }
  }

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  /// [_rows]: SQLite kampanya dens satırları
  List<AnnouncementCampaignRow> _rows = const [];

  /// [_loading]: İlk yükleme durumu
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  /// {@template _loadCampaigns}
  /// Aktif kampanyaları SQLite `campaigns` tablosundan yükler.
  /// {@endtemplate}
  Future<void> _loadCampaigns() async {
    setState(() => _loading = true);
    try {
      await AnnouncementsScreen.refreshDensCache();
      if (!mounted) return;
      setState(() {
        _rows = AnnouncementsScreen.densRows;
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
    final title = l10n.translate('field_sales.stubs.announcements');
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.announcements.empty'),
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
                        l10n.translate('field_sales.announcements.list_hint'),
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
                              'field_sales.announcements.count_label',
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
                                'field_sales.announcements.campaign_col',
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
                                'field_sales.announcements.start_date',
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
                                'field_sales.announcements.end_date',
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${l10n.translate('field_sales.announcements.start_date')}: '
                                        '${item.startDisplay}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '—',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${l10n.translate('field_sales.announcements.end_date')}: '
                                        '${item.endDisplay}',
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
