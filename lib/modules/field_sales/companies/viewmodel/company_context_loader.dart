// Dosya Adı: company_context_loader.dart
// Açıklama: Şirketler ekranı firma/dönem — PostgREST öncelikli, demo yok
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/foundation.dart';

import '../../../../core/tenant/postgrest_master_sync.dart';
import '../../../../core/tenant/postgrest_table_names.dart';
import '../../../../service/database_service.dart';
import '../../../../service/postgres_service.dart';

/// {@template company_context_firm}
/// Loader firma satırı (UI CompanyFirmRow ile aynı alanlar).
/// {@endtemplate}
class CompanyContextFirm {
  /// [companyId]: firms.id / companies.id
  final String companyId;

  /// [name]: Firma adı
  final String name;

  /// [companyNo]: Firma no
  final String companyNo;

  /// {@macro company_context_firm}
  const CompanyContextFirm({
    required this.companyId,
    required this.name,
    required this.companyNo,
  });
}

/// {@template company_context_period}
/// Loader dönem satırı.
/// {@endtemplate}
class CompanyContextPeriod {
  /// [companyId]: Firma id
  final String companyId;

  /// [name]: Firma adı
  final String name;

  /// [companyNo]: Firma no
  final String companyNo;

  /// [periodNo]: Dönem no
  final String periodNo;

  /// [startDate]: Başlangıç (ham / ISO)
  final String startDate;

  /// [endDate]: Bitiş
  final String endDate;

  /// {@macro company_context_period}
  const CompanyContextPeriod({
    required this.companyId,
    required this.name,
    required this.companyNo,
    required this.periodNo,
    this.startDate = '',
    this.endDate = '',
  });
}

/// {@template company_context_data}
/// Firma + dönem yükleme sonucu.
/// {@endtemplate}
class CompanyContextData {
  /// [firms]: Firma listesi
  final List<CompanyContextFirm> firms;

  /// [periods]: Tüm dönemler
  final List<CompanyContextPeriod> periods;

  /// [fromRest]: PostgREST `/firms` başarılı ve dolu
  final bool fromRest;

  /// {@macro company_context_data}
  const CompanyContextData({
    required this.firms,
    required this.periods,
    this.fromRest = false,
  });
}

/// {@template company_context_loader}
/// Firmalar | Dönemler: kiracı REST aktifse `/firms` + `/periods`;
/// aksi halde / offline SQLite (demo seed elenir). Stub üretmez.
///
/// Kullanım örneği:
/// ```dart
/// final data = await const CompanyContextLoader().loadFirmsAndPeriods();
/// print(data.firms.length);
/// ```
/// {@endtemplate}
class CompanyContextLoader {
  /// [syncFactory]: Test enjeksiyonu
  final PostgrestMasterSync Function()? syncFactory;

  /// [dbFactory]: Test enjeksiyonu
  final Future<DatabaseService> Function()? dbFactory;

  /// [restReady]: null → PostgresService URL
  final bool? restReady;

  /// [persistSqlite]: REST sonrası SQLite yaz
  final bool persistSqlite;

  /// [sqliteFallback]: Test için SQLite yerine
  final Future<
          ({List<CompanyContextFirm> firms, List<CompanyContextPeriod> periods})>
      Function()? sqliteFallback;

  /// {@macro company_context_loader}
  const CompanyContextLoader({
    this.syncFactory,
    this.dbFactory,
    this.restReady,
    this.persistSqlite = true,
    this.sqliteFallback,
  });

  /// Bilinen mock / dens seed firma mı?
  static bool isDemoCompanySeed({
    required String id,
    required String name,
  }) {
    final idT = id.trim().toLowerCase();
    final nameT = name.trim().toLowerCase();
    if (idT == 'mbt_001' || idT.startsWith('mbt_')) return true;
    if (nameT == 'mbt') return true;
    if (nameT.contains('exfin-erp demo')) return true;
    if (nameT.contains('demo firma') && nameT.contains('exfin')) return true;
    if (idT == '3' && nameT == 'logo') return true;
    return false;
  }

  /// {@template company_context_loader_load}
  /// Firma + dönem listesini yükler (REST → SQLite, stub yok).
  ///
  /// Dönüş değeri:
  /// - [CompanyContextData]: Satırlar (boş olabilir)
  /// {@endtemplate}
  Future<CompanyContextData> loadFirmsAndPeriods() async {
    final ready = restReady ??
        PostgresService.instance.activeRemoteRestUrl.trim().isNotEmpty;

    if (ready) {
      try {
        final sync = syncFactory?.call() ?? PostgrestMasterSync();
        final apiFirms = await sync.fetchFirms();
        if (apiFirms.isNotEmpty) {
          final firms = <CompanyContextFirm>[];
          final periods = <CompanyContextPeriod>[];
          for (final f in apiFirms) {
            if (!f.isActive && f.firmNr.isEmpty) continue;
            final firm = CompanyContextFirm(
              companyId: f.id.isEmpty ? f.firmNr : f.id,
              name: f.name.isEmpty ? f.firmNr : f.name,
              companyNo: f.firmNr,
            );
            firms.add(firm);
            final apiPeriods = await sync.fetchPeriodsForFirm(
              f,
              allowFallback: false,
            );
            for (final p in apiPeriods) {
              periods.add(
                CompanyContextPeriod(
                  companyId: firm.companyId,
                  name: firm.name,
                  companyNo: firm.companyNo,
                  periodNo: p.nr,
                  startDate: p.begDate,
                  endDate: p.endDate,
                ),
              );
            }
          }
          if (persistSqlite) {
            await _persistToSqlite(firms, periods);
          }
          return CompanyContextData(
            firms: firms,
            periods: periods,
            fromRest: true,
          );
        }
      } catch (e) {
        debugPrint('CompanyContextLoader REST: $e');
      }
    }

    final local = await _loadFromSqlite(stripDemo: ready);
    return CompanyContextData(
      firms: local.firms,
      periods: local.periods,
      fromRest: false,
    );
  }

  Future<
      ({
        List<CompanyContextFirm> firms,
        List<CompanyContextPeriod> periods,
      })> _loadFromSqlite({required bool stripDemo}) async {
    if (sqliteFallback != null) {
      final raw = await sqliteFallback!();
      if (!stripDemo) return raw;
      return (
        firms: raw.firms
            .where(
              (f) => !isDemoCompanySeed(id: f.companyId, name: f.name),
            )
            .toList(),
        periods: raw.periods
            .where(
              (p) => !isDemoCompanySeed(id: p.companyId, name: p.name),
            )
            .toList(),
      );
    }

    try {
      final db = await (dbFactory?.call() ?? DatabaseService.getInstance());
      final companies = await db.getCompanies();
      final periodMaps = await db.getAllCompanyPeriodsWithCompanyName();

      final firms = <CompanyContextFirm>[];
      final seen = <String>{};
      for (final c in companies) {
        final id = (c['id'] ?? '').toString();
        final name = (c['name'] ?? '').toString();
        final rawNo = (c['company_no'] ?? '').toString().trim();
        final no =
            rawNo.isEmpty ? '' : PostgrestTableNames.padFirm(rawNo);
        if (id.isEmpty && name.isEmpty && no.isEmpty) continue;
        if (stripDemo && isDemoCompanySeed(id: id, name: name)) continue;
        final key = no.isNotEmpty ? no : id;
        if (seen.contains(key)) continue;
        seen.add(key);
        firms.add(
          CompanyContextFirm(
            companyId: id.isEmpty ? key : id,
            name: name.isEmpty ? key : name,
            companyNo: no.isEmpty ? key : no,
          ),
        );
      }

      final periods = <CompanyContextPeriod>[];
      for (final p in periodMaps) {
        final name = (p['company_name'] ?? '').toString();
        final rawNo = (p['company_no'] ?? '').toString().trim();
        final companyNo =
            rawNo.isEmpty ? '' : PostgrestTableNames.padFirm(rawNo);
        final rawPeriod = (p['period_name'] ?? '').toString().trim();
        final periodNo = rawPeriod.isEmpty
            ? ''
            : PostgrestTableNames.padPeriod(rawPeriod);
        final companyId = (p['company_id'] ?? companyNo).toString();
        if (companyNo.isEmpty && name.isEmpty) continue;
        if (stripDemo &&
            isDemoCompanySeed(id: companyId, name: name)) {
          continue;
        }
        if (periodNo.isEmpty) continue;
        periods.add(
          CompanyContextPeriod(
            companyId: companyId.isEmpty ? companyNo : companyId,
            name: name.isEmpty ? companyNo : name,
            companyNo: companyNo,
            periodNo: periodNo,
            startDate: (p['start_date'] ?? '').toString(),
            endDate: (p['end_date'] ?? '').toString(),
          ),
        );
      }

      return (firms: firms, periods: periods);
    } catch (e) {
      debugPrint('CompanyContextLoader SQLite: $e');
      return (firms: <CompanyContextFirm>[], periods: <CompanyContextPeriod>[]);
    }
  }

  Future<void> _persistToSqlite(
    List<CompanyContextFirm> firms,
    List<CompanyContextPeriod> periods,
  ) async {
    try {
      final sync = syncFactory?.call() ?? PostgrestMasterSync();
      await sync.syncFirmsToSqlite(
        firms
            .map(
              (f) => PostgrestFirmRow(
                id: f.companyId,
                firmNr: f.companyNo,
                name: f.name,
              ),
            )
            .toList(),
      );
      await sync.syncPeriodsToSqlite(
        periods
            .map(
              (p) => (
                companyId: p.companyId,
                companyNo: p.companyNo,
                periodNo: p.periodNo,
                startDate: p.startDate,
                endDate: p.endDate,
              ),
            )
            .toList(),
      );
    } catch (e) {
      debugPrint('CompanyContextLoader persist: $e');
    }
  }
}
