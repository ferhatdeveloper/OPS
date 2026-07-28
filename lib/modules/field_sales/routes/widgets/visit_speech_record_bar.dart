// Dosya Adı: visit_speech_record_bar.dart
// Açıklama: Ziyaret STT dens kayıt durumu şeridi (not alanı üstü)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../viewmodel/visit_speech_to_text_store.dart';

/// {@template visit_speech_record_bar}
/// Dens mikrofon chip + durum metni (renk/tema redesign yok).
///
/// Kullanım örneği:
/// ```dart
/// VisitSpeechRecordBar(
///   status: VisitSpeechStatus.listening,
///   listeningLabel: 'Dinleniyor',
///   idleLabel: 'Sesli not',
///   partialText: 'Merhaba…',
///   onToggle: () {},
/// )
/// ```
/// {@endtemplate}
class VisitSpeechRecordBar extends StatelessWidget {
  /// [status]: STT durumu
  final VisitSpeechStatus status;

  /// [listeningLabel]: Aktif chip metni
  final String listeningLabel;

  /// [idleLabel]: Pasif chip metni
  final String idleLabel;

  /// [partialText]: Anlık tanıma (opsiyonel)
  final String partialText;

  /// [statusHint]: Hata / izin ipucu
  final String? statusHint;

  /// [onToggle]: Mikrofon aç/kapa
  final VoidCallback? onToggle;

  /// [enabled]: Chip aktif mi
  final bool enabled;

  /// {@macro visit_speech_record_bar}
  const VisitSpeechRecordBar({
    super.key,
    required this.status,
    required this.listeningLabel,
    required this.idleLabel,
    this.partialText = '',
    this.statusHint,
    this.onToggle,
    this.enabled = true,
  });

  /// [isListening]: Dinleme aktif
  bool get _listening => status == VisitSpeechStatus.listening;

  @override
  Widget build(BuildContext context) {
    final busy = status == VisitSpeechStatus.initializing;
    final chipLabel = _listening ? listeningLabel : idleLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                child: FieldSalesDensChip(
                  label: busy ? '…' : chipLabel,
                  selected: _listening,
                  onTap: (!enabled || busy) ? null : onToggle,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _listening ? Icons.mic : Icons.mic_none,
                size: 18,
                color: FieldSalesDensAppBar.primaryColor,
              ),
              if (partialText.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    partialText.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5A6A7A),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (statusHint != null && statusHint!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              statusHint!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A4B4B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
