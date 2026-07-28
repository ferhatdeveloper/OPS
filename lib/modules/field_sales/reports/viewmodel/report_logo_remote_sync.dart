// Dosya Adı: report_logo_remote_sync.dart
// Açıklama: Merkez/PostgREST tenant branding → yerel logo önbelleği
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/tenant/postgrest_http_client.dart';
import '../../../../service/postgres_service.dart';
import 'report_logo_store.dart';

/// {@template report_logo_sync_result}
/// Merkez logo sync sonucu.
/// {@endtemplate}
class ReportLogoSyncResult {
  /// [ok]: Logo yazıldı mı
  final bool ok;

  /// [skipped]: Zaten vardı / atlandı
  final bool skipped;

  /// [messageKey]: l10n anahtarı (opsiyonel)
  final String? messageKey;

  /// [detail]: Teknik detay
  final String? detail;

  /// {@macro report_logo_sync_result}
  const ReportLogoSyncResult({
    required this.ok,
    this.skipped = false,
    this.messageKey,
    this.detail,
  });
}

/// {@template report_logo_remote_sync}
/// PostgREST kiracı branding tablolarından logo çeker (bir kez / zorla).
///
/// Denenen yollar (404 → sessizce sonraki):
/// 1. `company_branding` / `tenant_branding` (`logo_url` veya `logo_base64`)
/// 2. `settings` satırı `key=report_logo_url`
///
/// Kullanım örneği:
/// ```dart
/// final r = await ReportLogoRemoteSync().ensureCached();
/// ```
/// {@endtemplate}
class ReportLogoRemoteSync {
  /// [store]: Yerel önbellek
  final ReportLogoStore store;

  /// [client]: PostgREST JSON istemcisi
  final PostgrestHttpClient client;

  /// [httpClient]: Ham bayt indirme
  final http.Client httpClient;

  /// [postgres]: Aktif kiracı
  final PostgresService postgres;

  /// [timeout]: İndirme zaman aşımı
  final Duration timeout;

  /// {@macro report_logo_remote_sync}
  ReportLogoRemoteSync({
    ReportLogoStore? store,
    PostgrestHttpClient? client,
    http.Client? httpClient,
    PostgresService? postgres,
    this.timeout = const Duration(seconds: 20),
  })  : store = store ?? ReportLogoStore(),
        client = client ?? PostgrestHttpClient(),
        httpClient = httpClient ?? http.Client(),
        postgres = postgres ?? PostgresService.instance;

  /// {@template report_logo_remote_sync_ensure}
  /// Yerelde logo yoksa merkezden bir kez dener.
  ///
  /// Parametreler:
  /// - [force]: true → mevcut olsa bile yeniden indir
  ///
  /// Dönüş değeri:
  /// - [ReportLogoSyncResult]: Sonuç
  /// {@endtemplate}
  Future<ReportLogoSyncResult> ensureCached({bool force = false}) async {
    if (!force) {
      if (await store.hasLogo()) {
        return const ReportLogoSyncResult(
          ok: true,
          skipped: true,
          messageKey: 'field_sales.mbt_reports.logo_already_cached',
        );
      }
      if (await store.wasSyncedOnce()) {
        return const ReportLogoSyncResult(
          ok: false,
          skipped: true,
          messageKey: 'field_sales.mbt_reports.logo_center_unavailable',
        );
      }
    }

    if (!client.isConfigured) {
      await store.markSyncedOnce();
      return const ReportLogoSyncResult(
        ok: false,
        messageKey: 'field_sales.mbt_reports.logo_center_unavailable',
        detail: 'PostgREST URL yok',
      );
    }

    try {
      final fetched = await _fetchLogoBytes();
      await store.markSyncedOnce();
      if (fetched == null || fetched.isEmpty) {
        return const ReportLogoSyncResult(
          ok: false,
          messageKey: 'field_sales.mbt_reports.logo_center_unavailable',
        );
      }
      final name = ReportLogoStore.fileNameForBytes(fetched.bytes);
      await store.saveBytes(
        fetched.bytes,
        source: ReportLogoSource.center,
        fileName: name,
        remoteUrl: fetched.remoteUrl,
      );
      return const ReportLogoSyncResult(
        ok: true,
        messageKey: 'field_sales.mbt_reports.logo_synced',
      );
    } catch (e) {
      debugPrint('ReportLogoRemoteSync: $e');
      await store.markSyncedOnce();
      return ReportLogoSyncResult(
        ok: false,
        messageKey: 'field_sales.mbt_reports.logo_center_unavailable',
        detail: e.toString(),
      );
    }
  }

  Future<_FetchedLogo?> _fetchLogoBytes() async {
    for (final path in const ['company_branding', 'tenant_branding']) {
      final fromTable = await _tryBrandingTable(path);
      if (fromTable != null) return fromTable;
    }
    final fromSettings = await _trySettingsKey();
    if (fromSettings != null) return fromSettings;
    return null;
  }

  Future<_FetchedLogo?> _tryBrandingTable(String path) async {
    try {
      final rows = await client.getRows(
        path,
        query: {
          'select': 'logo_url,logo_base64,company_name',
          'limit': '1',
        },
      );
      if (rows.isEmpty) return null;
      return _bytesFromRow(rows.first);
    } on PostgrestHttpException catch (e) {
      debugPrint('ReportLogoRemoteSync $path: ${e.statusCode}');
      return null;
    } catch (e) {
      debugPrint('ReportLogoRemoteSync $path: $e');
      return null;
    }
  }

  Future<_FetchedLogo?> _trySettingsKey() async {
    try {
      final rows = await client.getRows(
        'settings',
        query: {
          'key': 'eq.report_logo_url',
          'select': 'value,key',
          'limit': '1',
        },
      );
      if (rows.isEmpty) return null;
      final url = rows.first['value']?.toString().trim() ?? '';
      if (url.isEmpty) return null;
      return _downloadUrl(url);
    } on PostgrestHttpException catch (e) {
      debugPrint('ReportLogoRemoteSync settings: ${e.statusCode}');
      return null;
    } catch (e) {
      debugPrint('ReportLogoRemoteSync settings: $e');
      return null;
    }
  }

  Future<_FetchedLogo?> _bytesFromRow(Map<String, dynamic> row) async {
    final b64 = row['logo_base64']?.toString().trim() ?? '';
    if (b64.isNotEmpty) {
      try {
        final raw = b64.contains(',') ? b64.split(',').last : b64;
        final decoded = base64Decode(raw);
        if (decoded.isEmpty) return null;
        return _FetchedLogo(Uint8List.fromList(decoded), '');
      } catch (e) {
        debugPrint('ReportLogoRemoteSync base64: $e');
      }
    }
    final url = row['logo_url']?.toString().trim() ?? '';
    if (url.isNotEmpty) return _downloadUrl(url);
    return null;
  }

  Future<_FetchedLogo?> _downloadUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;
    final headers = <String, String>{};
    // Aynı kiracı origin’indeyse PostgREST auth header ekle
    final base = postgres.activeRemoteRestUrl.trim();
    if (base.isNotEmpty && url.startsWith(base)) {
      headers.addAll(postgres.postgrestHeaders());
    }
    final res = await httpClient.get(uri, headers: headers).timeout(timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    if (res.bodyBytes.isEmpty) return null;
    return _FetchedLogo(
      Uint8List.fromList(res.bodyBytes),
      url,
    );
  }
}

/// İndirme sonucu + URL (save meta için).
class _FetchedLogo {
  final Uint8List bytes;
  final String remoteUrl;

  const _FetchedLogo(this.bytes, this.remoteUrl);

  bool get isEmpty => bytes.isEmpty;
}
