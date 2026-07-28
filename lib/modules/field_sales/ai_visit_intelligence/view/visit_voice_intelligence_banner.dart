// Dosya Adı: visit_voice_intelligence_banner.dart
// Açıklama: Ziyaret formu dens ses zekâ banner (KVKK + kayıt chip)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../model/visit_emotion.dart';
import '../viewmodel/visit_transcript_store.dart';
import '../viewmodel/visit_voice_recording_store.dart';

/// {@template visit_voice_intelligence_banner}
/// Check-in açıkken dens şerit: KVKK onay + kayıt chip + duygu.
/// ui-no-touch: renk/tema yok; dens chip dili.
/// {@endtemplate}
class VisitVoiceIntelligenceBanner extends ConsumerStatefulWidget {
  /// [visitId]: Açık ziyaret
  final String visitId;

  /// {@macro visit_voice_intelligence_banner}
  const VisitVoiceIntelligenceBanner({
    Key? key,
    required this.visitId,
  }) : super(key: key);

  @override
  ConsumerState<VisitVoiceIntelligenceBanner> createState() =>
      _VisitVoiceIntelligenceBannerState();
}

class _VisitVoiceIntelligenceBannerState
    extends ConsumerState<VisitVoiceIntelligenceBanner> {
  VisitEmotion? _lastEmotion;
  String? _draftHint;
  bool _busy = false;

  String _t(String key) => AppLocalization.of(context).translate(key);

  Future<void> _onConsentTap() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            _t('field_sales.visit_voice.consent_title'),
            style: const TextStyle(fontSize: 16),
          ),
          content: Text(
            _t('field_sales.visit_voice.consent_body'),
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('field_sales.visit_voice.consent_accept')),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    await ref.read(visitVoiceRecordingProvider.notifier).setConsent(
          visitId: widget.visitId,
          accepted: true,
        );
  }

  Future<void> _toggleRecord() async {
    final store = ref.read(visitVoiceRecordingProvider.notifier);
    final state = ref.read(visitVoiceRecordingProvider);
    if (state.isRecording) {
      setState(() => _busy = true);
      await store.stop();
      final result =
          await VisitTranscriptStore().processQueue(widget.visitId);
      if (mounted) {
        setState(() {
          _busy = false;
          if (result != null && result.isOk) {
            _lastEmotion = result.emotion;
            _draftHint = result.statusSuggestion ?? result.summary;
          }
        });
        if (_lastEmotion != null &&
            _lastEmotion != VisitEmotion.unknown) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t(_lastEmotion!.labelKey)),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      return;
    }
    if (!state.hasConsent) {
      await _onConsentTap();
      final after = ref.read(visitVoiceRecordingProvider);
      if (!after.hasConsent) return;
    }
    setState(() => _busy = true);
    await store.start(visitId: widget.visitId);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _approveDraft() async {
    final hint = (_draftHint ?? '').trim();
    if (hint.isEmpty) return;
    await VisitTranscriptStore().approveStatusSuggestion(
      visitId: widget.visitId,
      notesAppend: hint,
    );
    if (!mounted) return;
    setState(() => _draftHint = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('field_sales.visit_voice.status_saved')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(visitVoiceRecordingProvider);
    final primary = FieldSalesDensAppBar.primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldSalesDensChipRow(
            items: [
              FieldSalesDensChipItem(
                label: voice.hasConsent
                    ? _t('field_sales.visit_voice.consent_ok')
                    : _t('field_sales.visit_voice.consent_chip'),
                selected: voice.hasConsent,
                onTap: () {
                  if (!_busy) _onConsentTap();
                },
              ),
              FieldSalesDensChipItem(
                label: voice.isRecording
                    ? _t('field_sales.visit_voice.recording')
                    : _t('field_sales.visit_voice.record_start'),
                selected: voice.isRecording,
                onTap: () {
                  if (!_busy) _toggleRecord();
                },
              ),
              if (_lastEmotion != null &&
                  _lastEmotion != VisitEmotion.unknown)
                FieldSalesDensChipItem(
                  label: _t(_lastEmotion!.labelKey),
                  selected: true,
                  onTap: () {},
                ),
            ],
          ),
          if (voice.errorKey != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _t(voice.errorKey!),
                style: TextStyle(fontSize: 11, color: primary),
              ),
            ),
          if ((_draftHint ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _draftHint!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: _approveDraft,
                    child: Text(
                      _t('field_sales.visit_voice.approve_status'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
