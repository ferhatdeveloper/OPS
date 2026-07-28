// Dosya Adı: offline_queue_detail_screen.dart
// Açıklama: Offline kuyruk detay — dens alanlar + payload önizleme
//   (MBT GÜNCELLEME → Transfer / kuyruk detay)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';
import '../../shared/view/field_sales_dens_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import 'logo_queue_status_chip.dart';

/// {@template offline_queue_detail_screen}
/// Offline senkron kuyruk kaydı detayı — dens meta + JSON payload önizleme.
/// Route: `/field-sales/offline-queue-detail`
///
/// [job] veya route `arguments` (Map) yoksa [densSeedJob] kullanılır.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   OfflineQueueDetailScreen.routeName,
///   arguments: jobMap,
/// );
/// ```
/// {@endtemplate}
class OfflineQueueDetailScreen extends StatelessWidget {
  /// [routeName]: Named route — `/field-sales/offline-queue-detail`
  static const String routeName = '/field-sales/offline-queue-detail';

  /// [job]: sync_queue satırı (null → route args / dens seed)
  final Map<String, dynamic>? job;

  const OfflineQueueDetailScreen({
    Key? key,
    this.job,
  }) : super(key: key);

  /// {@template offline_queue_dens_seed_job}
  /// Dens önizleme için örnek sync_queue satırı.
  ///
  /// Dönüş değeri:
  /// - [Map]: Seed iş kaydı
  /// {@endtemplate}
  static Map<String, dynamic> densSeedJob() {
    return <String, dynamic>{
      'id': 'seed-offline-1',
      'entity_type': 'invoice',
      'entity_id': 'INV-DEMO-001',
      'payload': jsonEncode(<String, dynamic>{
        'type': 8,
        'customer_code': 'C001',
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'code': 'P001',
            'qty': 2,
            'price': 100.0,
            'vat_rate': 20,
          },
        ],
      }),
      'priority': 0,
      'retry_count': 0,
      'last_error': null,
      'created_at': '2026-07-26T10:00:00.000',
    };
  }

  /// {@template offline_queue_format_payload_preview}
  /// Payload alanını okunabilir JSON metnine çevirir.
  ///
  /// Parametreler:
  /// - [raw]: `payload` sütunu (String JSON / Map / null)
  /// - [emptyLabel]: Boş payload metni
  /// - [invalidLabel]: Parse hatası metni
  ///
  /// Dönüş değeri:
  /// - [String]: Önizleme metni
  /// {@endtemplate}
  static String formatPayloadPreview(
    dynamic raw, {
    String emptyLabel = 'Payload yok',
    String invalidLabel = 'Payload okunamadı',
  }) {
    if (raw == null) return emptyLabel;
    if (raw is Map) {
      return const JsonEncoder.withIndent('  ').convert(raw);
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return emptyLabel;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map || decoded is List) {
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return text;
    } catch (_) {
      return invalidLabel;
    }
  }

  /// {@template offline_queue_resolve_job}
  /// Constructor / route arguments / dens seed sırasıyla işi çözer.
  /// {@endtemplate}
  Map<String, dynamic> _resolveJob(BuildContext context) {
    if (job != null) return Map<String, dynamic>.from(job!);
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return Map<String, dynamic>.from(args);
    }
    if (args is Map) {
      return Map<String, dynamic>.from(args);
    }
    return densSeedJob();
  }

  InputDecoration _denseDecoration(BuildContext context, String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: FieldSalesDensTheme.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _denseField({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return InputDecorator(
      decoration: _denseDecoration(context, label),
      child: Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.offline_queue_detail');
    final resolved = _resolveJob(context);
    final status = LogoQueueStatus.fromJob(resolved);
    final entityType = resolved['entity_type']?.toString() ?? '—';
    final entityId = resolved['entity_id']?.toString() ?? '—';
    final retry = '${resolved['retry_count'] ?? 0}';
    final created = resolved['created_at']?.toString() ?? '—';
    final errorRaw = resolved['last_error']?.toString();
    final errorText = (errorRaw == null || errorRaw.isEmpty)
        ? l10n.translate('field_sales.offline_queue.no_error')
        : errorRaw;
    final payloadText = formatPayloadPreview(
      resolved['payload'],
      emptyLabel: l10n.translate('field_sales.offline_queue.payload_empty'),
      invalidLabel:
          l10n.translate('field_sales.offline_queue.payload_invalid'),
    );
    final isSeed = resolved['id']?.toString() == 'seed-offline-1';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: l10n.translate(
              'field_sales.offline_queue.payload_preview',
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payloadText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.translate(
                      'field_sales.offline_queue.payload_copied',
                    ),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          if (isSeed) ...[
            Text(
              l10n.translate('field_sales.offline_queue.seed_hint'),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.translate('field_sales.offline_queue.status'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    LogoQueueStatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 10),
                _denseField(
                  context: context,
                  label: l10n.translate(
                    'field_sales.offline_queue.entity_type',
                  ),
                  value: entityType,
                ),
                const SizedBox(height: 8),
                _denseField(
                  context: context,
                  label: l10n.translate(
                    'field_sales.offline_queue.entity_id',
                  ),
                  value: entityId,
                ),
                const SizedBox(height: 8),
                _denseField(
                  context: context,
                  label: l10n.translate(
                    'field_sales.offline_queue.retry_count',
                  ),
                  value: retry,
                ),
                const SizedBox(height: 8),
                _denseField(
                  context: context,
                  label: l10n.translate(
                    'field_sales.offline_queue.created_at',
                  ),
                  value: created,
                ),
                const SizedBox(height: 8),
                _denseField(
                  context: context,
                  label: l10n.translate(
                    'field_sales.offline_queue.last_error',
                  ),
                  value: errorText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('field_sales.offline_queue.payload_preview'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SelectableText(
              payloadText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
