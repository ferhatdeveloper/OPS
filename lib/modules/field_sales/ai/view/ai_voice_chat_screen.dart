// Dosya Adı: ai_voice_chat_screen.dart
// Açıklama: Dens field-sales AI sohbet — STT + TTS interrupt döngüsü
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/ai/ai_chat_message.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/ai/features/ai_chat_report_pdf_builder.dart';
import '../../../../core/ai/features/ai_chat_reply_sanitizer.dart';
import '../../../../core/ai/features/field_sales_chat_agent.dart';
import '../../../../core/ai/voice/ai_openai_tts_engine.dart';
import '../../../../core/ai/voice/ai_speech_focus.dart';
import '../../../../core/ai/voice/ai_speech_language_detector.dart';
import '../../../../core/ai/voice/ai_tts_service.dart';
import '../../../../core/ai/voice/ai_tts_voice.dart';
import '../../../../core/ai/voice/ai_voice_phase.dart';
import '../../../../core/ai/voice/ai_voice_session.dart';
import '../../../../core/localization/app_localization.dart';
import '../../reports/model/report_pdf_viewer_args.dart';
import '../../reports/view/report_pdf_viewer_screen.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../../shared/view/field_sales_dens_filter_bar.dart';
import '../../shared/view/field_sales_dens_theme.dart';
import '../widgets/ai_chat_composer.dart';
import '../widgets/ai_chat_empty_state.dart';
import '../widgets/ai_chat_message_bubble.dart';
import '../widgets/ai_speech_language_picker.dart';
import '../widgets/ai_tts_engine_picker.dart';
import 'ai_settings_screen.dart';

/// {@template ai_voice_chat_screen}
/// Dens sesli/metin AI sohbet UI. Route: `/field-sales/ai-chat`
/// Field sales dens diline uyumlu; global tema değişmez.
/// {@endtemplate}
class AiVoiceChatScreen extends StatefulWidget {
  /// Named route
  static const String routeName = '/field-sales/ai-chat';

  /// [agent]: Test inject
  final FieldSalesChatAgent? agent;

  /// [displayName]: Selamlama adı (ör. oturum kullanıcı adı)
  final String? displayName;

  /// [tts]: Test inject TTS
  final AiTtsService? tts;

  /// [session]: Test inject oturum
  final AiVoiceSession? session;

  /// {@macro ai_voice_chat_screen}
  const AiVoiceChatScreen({
    Key? key,
    this.agent,
    this.displayName,
    this.tts,
    this.session,
  }) : super(key: key);

  @override
  State<AiVoiceChatScreen> createState() => _AiVoiceChatScreenState();
}

class _AiVoiceChatScreenState extends State<AiVoiceChatScreen>
    with SingleTickerProviderStateMixin {
  late final FieldSalesChatAgent _agent =
      widget.agent ?? FieldSalesChatAgent();
  late final AiVoiceSession _session =
      widget.session ?? AiVoiceSession();
  late final AiTtsService _tts = widget.tts ??
      AiTtsService(
        enabled: true,
        cloudEngine: OpenAiTtsEngine(
          apiKeyResolver: () =>
              AiGateway().settingsStore.readApiKey(AiProvider.openAi),
        ),
        hasOpenAiKey: () async {
          final k = await AiGateway()
              .settingsStore
              .readApiKey(AiProvider.openAi);
          return k != null && k.trim().isNotEmpty;
        },
      );

  final _scroll = ScrollController();
  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();
  final _speech = SpeechToText();
  final _picker = ImagePicker();

  /// History index ile hizalı balon zamanları
  final List<DateTime> _msgTimes = [];

  bool _speechReady = false;
  String? _statusKey;
  String? _dataNoteKey;
  String _partialTranscript = '';
  String _speechLang = AiSpeechLanguageDetector.auto;
  bool _cloudTts = true;
  bool _hasOpenAiKey = false;
  double _soundLevel = 0;
  bool _voiceFocused = false;

  late final AnimationController _pulse;

  bool get _busy => _session.isProcessing;
  bool get _listening => _session.isListening;
  bool get _speaking => _session.isSpeaking;

  static const Color _primary = FieldSalesDensAppBar.primaryColor;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _tts.bindHandlers(
      onComplete: _onTtsComplete,
      onCancel: _onTtsCancel,
    );
    _loadTtsPref();
  }

  Future<void> _loadTtsPref() async {
    try {
      final snap = await AiGateway().loadSettings();
      if (!mounted) return;
      final appLang =
          AppLocalization.of(context).locale.languageCode;
      _session.ttsEnabled = snap.ttsEnabled;
      _tts.enabled = snap.ttsEnabled;
      _tts.cloudTtsEnabled = snap.cloudTtsEnabled;
      _tts.speechLanguagePreference = snap.speechLanguage;
      _tts.voicePersona =
          AiTtsVoicePersonaX.parse(snap.ttsVoicePersona);
      _tts.fallbackLang =
          AiSpeechLanguageDetector.normalize(appLang) ?? 'tr';
      final openAiCfg = snap.configs[AiProvider.openAi];
      setState(() {
        _speechLang = snap.speechLanguage;
        _cloudTts = snap.cloudTtsEnabled;
        _hasOpenAiKey = openAiCfg?.hasApiKey == true;
      });
    } catch (_) {}
  }

  Future<void> _setSpeechLanguage(String code) async {
    final normalized =
        AiSpeechLanguageDetector.normalizePreference(code);
    setState(() => _speechLang = normalized);
    _tts.speechLanguagePreference = normalized;
    try {
      await AiGateway().settingsStore.setSpeechLanguage(normalized);
    } catch (_) {}
  }

  Future<void> _setCloudTts(bool cloud) async {
    setState(() => _cloudTts = cloud);
    _tts.cloudTtsEnabled = cloud;
    try {
      await AiGateway().settingsStore.setCloudTtsEnabled(cloud);
    } catch (_) {}
  }

  void _onTtsComplete() {
    if (!mounted) return;
    _session.onSpeakCompleted();
    setState(() {});
  }

  void _onTtsCancel() {
    if (!mounted) return;
    // Interrupt akışında phase zaten listening’e geçmiş olabilir
    if (_session.phase == AiVoicePhase.speaking) {
      _session.onSpeakInterrupted();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    _speech.stop();
    _tts.dispose();
    super.dispose();
  }

  String _t(String key, {Map<String, String>? args}) =>
      AppLocalization.of(context).translate(key, args: args);

  String get _greetingName {
    final raw = (widget.displayName ?? '').trim();
    if (raw.isEmpty) return '…';
    final first = raw.split(RegExp(r'[\s._@]+')).first;
    if (first.isEmpty) return raw;
    return first[0].toUpperCase() + first.substring(1);
  }

  /// History ile [_msgTimes] uzunluğunu hizala
  void _syncMsgTimes() {
    final n = _agent.history.length;
    while (_msgTimes.length < n) {
      _msgTimes.add(DateTime.now());
    }
    if (_msgTimes.length > n) {
      _msgTimes.removeRange(n, _msgTimes.length);
    }
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String? _timeAt(int index) {
    if (index < 0 || index >= _msgTimes.length) return null;
    return _fmtTime(_msgTimes[index]);
  }

  /// {@template ai_voice_chat_submit_text}
  /// Klavye ile metin talebi — TTS interrupt + aynı [_send] pipeline.
  /// {@endtemplate}
  Future<void> _submitTypedText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _busy) return;
    _textCtrl.clear();
    _textFocus.unfocus();
    await _send(text);
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;
    // Metin / ses — TTS açıksa interrupt; STT odağını bırak
    await _interruptTts();
    try {
      await _speech.stop();
    } catch (_) {}
    _session.beginProcessing();
    setState(() {
      _statusKey = null;
      _partialTranscript = '';
      _dataNoteKey = null;
    });
    final result = await _agent.reply(trimmed);
    if (!mounted) return;
    _syncMsgTimes();
    final note = _agent.lastDataBundle?.sourceNoteKey;
    if (!result.isOk) {
      _session.onReplyFail();
      setState(() {
        _statusKey = result.l10nKey ?? 'ai.request_failed';
        _dataNoteKey = note;
      });
      _scrollToEnd();
      return;
    }
    final reply = (result.text ?? '').trim();
    final shouldSpeak = _session.onReplyOk(reply);
    setState(() {
      _dataNoteKey = note;
    });
    _scrollToEnd();
    if (shouldSpeak) {
      // STT → TTS geçişi (Android audio focus)
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      try {
        final ok = await _tts.speakIfEnabled(reply);
        if (!ok && mounted) {
          _session.onSpeakInterrupted();
          setState(() => _statusKey = 'ai.tts_unavailable');
        }
      } catch (_) {
        if (!mounted) return;
        _session.onSpeakInterrupted();
        setState(() => _statusKey = 'ai.tts_unavailable');
      }
    }
  }

  Future<void> _sendImage(Uint8List bytes, {String? hint}) async {
    if (_busy || bytes.isEmpty) return;
    await _interruptTts();
    _session.beginProcessing();
    setState(() => _statusKey = null);
    final result = await _agent.replyWithImage(
      imageBase64: base64Encode(bytes),
      imageMimeType: 'image/jpeg',
      hint: hint,
    );
    if (!mounted) return;
    _syncMsgTimes();
    if (!result.isOk) {
      _session.onReplyFail();
      setState(() {
        _statusKey = result.l10nKey ?? 'ai.request_failed';
      });
      _scrollToEnd();
      return;
    }
    final reply = (result.text ?? '').trim();
    final shouldSpeak = _session.onReplyOk(reply);
    setState(() {});
    _scrollToEnd();
    if (shouldSpeak) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      try {
        final ok = await _tts.speakIfEnabled(reply);
        if (!ok && mounted) {
          _session.onSpeakInterrupted();
          setState(() => _statusKey = 'ai.tts_unavailable');
        }
      } catch (_) {
        if (!mounted) return;
        _session.onSpeakInterrupted();
        setState(() => _statusKey = 'ai.tts_unavailable');
      }
    }
  }

  Future<void> _interruptTts() async {
    if (_session.isSpeaking || _tts.enabled) {
      await _tts.stop();
      if (_session.phase == AiVoicePhase.speaking) {
        _session.onSpeakInterrupted();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> _ensureSpeech() async {
    if (_speechReady) return true;
    final ok = await _speech.initialize(
      onError: (_) {
        if (!mounted) return;
        if (_session.isListening) {
          _session.cancelListening();
          setState(() => _statusKey = 'ai.stt_unavailable');
        }
      },
      onStatus: (status) {
        if (!mounted) return;
        // Platform "done" / "notListening" — finalResult gelmezse idle’a dön
        if (status == 'done' || status == 'notListening') {
          if (_session.isListening && _partialTranscript.trim().isEmpty) {
            // Final callback bekleniyor olabilir; boş bırak
          }
        }
      },
    );
    _speechReady = ok;
    return ok;
  }

  Future<void> _startListening() async {
    final ok = await _ensureSpeech();
    if (!ok) {
      _session.cancelListening();
      setState(() => _statusKey = 'ai.stt_unavailable');
      return;
    }
    setState(() {
      _partialTranscript = '';
      _statusKey = null;
      _soundLevel = 0;
      _voiceFocused = false;
    });
    await _speech.listen(
      onSoundLevelChange: (level) {
        if (!mounted || !_session.isListening) return;
        final focused = AiSpeechFocus.isVoiceLevelUseful(level);
        if (focused != _voiceFocused || (level - _soundLevel).abs() > 2) {
          setState(() {
            _soundLevel = level;
            _voiceFocused = focused;
          });
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        // Ağ tanıma: gürültülü ortamda on-device’dan daha iyi odak
        onDevice: false,
        // Sürekli konuşma / dikte — kısa “confirmation” kelime kaybını azaltır
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
        localeId: AiSpeechLanguageDetector.sttLocaleForInput(
          preference: _speechLang,
          typedText: _textCtrl.text,
          appOrDeviceLang: _tts.fallbackLang,
        ),
        listenFor: const Duration(seconds: 60),
        // Düşünme boşluğu — erken kesmeyi azalt
        pauseFor: const Duration(seconds: 4),
      ),
      onResult: (r) {
        if (!mounted) return;
        // Sessizlikte gelen gürültü partial’larını gösterme
        if (!_voiceFocused &&
            !r.finalResult &&
            r.recognizedWords.trim().length < 3) {
          return;
        }
        final alts = r.alternates
            .map(
              (a) => (
                words: a.recognizedWords,
                confidence: a.confidence,
              ),
            )
            .toList();
        final best = AiSpeechFocus.pickBest(
          primary: r.recognizedWords,
          primaryConfidence: r.confidence,
          alternates: alts,
        );
        setState(() => _partialTranscript = best);
        if (r.finalResult) {
          if (!_session.isListening) return;
          if (!AiSpeechFocus.acceptFinal(
            text: best,
            confidence: r.confidence,
          )) {
            _session.cancelListening();
            setState(() {
              _partialTranscript = '';
              _statusKey = 'ai.stt_unclear';
            });
            return;
          }
          _send(best);
        }
      },
    );
  }

  Future<void> _stopListeningAndSend() async {
    await _speech.stop();
    final text = AiSpeechFocus.cleanTranscript(_partialTranscript);
    if (!AiSpeechFocus.acceptFinal(text: text, confidence: -1)) {
      _session.cancelListening();
      setState(() {
        _partialTranscript = '';
        _statusKey = text.isEmpty ? null : 'ai.stt_unclear';
      });
      return;
    }
    await _send(text);
  }

  /// Tap-to-talk / mic toggle + TTS interrupt
  Future<void> _onMicTap() async {
    final result = _session.pressMic();
    if (result.action == AiVoiceMicAction.ignored) return;

    if (result.stopTts) {
      await _tts.stop();
    }

    setState(() {});

    if (result.action == AiVoiceMicAction.stopListening) {
      await _stopListeningAndSend();
      return;
    }
    if (result.action == AiVoiceMicAction.startListening) {
      await _startListening();
    }
  }

  /// Pill basılı tut — başlat
  Future<void> _onPillHoldStart() async {
    if (_busy) return;
    if (_listening) return;
    final result = _session.pressMic();
    if (result.action != AiVoiceMicAction.startListening) return;
    if (result.stopTts) await _tts.stop();
    setState(() {});
    await _startListening();
  }

  /// Pill bırak — gönder
  Future<void> _onPillHoldEnd() async {
    if (!_listening) return;
    await _stopListeningAndSend();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _sendImage(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusKey = 'ai.request_failed');
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('ai.copied')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _resetChat() async {
    await _interruptTts();
    await _speech.stop();
    _textCtrl.clear();
    setState(() {
      _agent.reset();
      _session.reset();
      _msgTimes.clear();
      _statusKey = null;
      _dataNoteKey = null;
      _partialTranscript = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgs = _agent.history;
    final isEmpty = msgs.isEmpty &&
        !_listening &&
        _partialTranscript.isEmpty &&
        !_speaking;
    final bodyBg = FieldSalesDensTheme.bodyBackground(context);
    final muted = FieldSalesDensTheme.muted(context);
    final titleColor = FieldSalesDensTheme.title(context);

    return Scaffold(
      backgroundColor: bodyBg,
      appBar: FieldSalesDensAppBar(
        title: _t('ai.chat_title'),
        showCalculatorHome: false,
        actions: [
          AiSpeechLanguagePicker(
            value: _speechLang,
            compact: true,
            onChanged: _setSpeechLanguage,
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.add_comment_outlined,
            tooltip: _t('ai.new_chat'),
            onPressed: _resetChat,
          ),
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.settings_outlined,
            tooltip: _t('ai.settings_title'),
            onPressed: () {
              Navigator.pushNamed(context, AiSettingsScreen.routeName)
                  .then((_) => _loadTtsPref());
            },
          ),
        ],
        bottom: FieldSalesDensFilterBar(
          backgroundColor: FieldSalesDensTheme.surface(context),
          children: [
            AiTtsEnginePicker(
              cloudEnabled: _cloudTts,
              compact: true,
              enabled: _tts.enabled,
              onChanged: _setCloudTts,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_cloudTts && !_hasOpenAiKey)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _t('ai.tts_engine_openai_key_hint'),
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ),
            ),
          if (_statusKey != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _t(_statusKey!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          if (_dataNoteKey != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _t(_dataNoteKey!),
                    style: TextStyle(
                      fontSize: 11,
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_speaking)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                _t('ai.speaking'),
                style: TextStyle(
                  fontSize: 12,
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: isEmpty ? _buildEmptyGreeting() : _buildChatList(msgs),
          ),
          if (_busy)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: _primary,
            ),
          if (_listening || _speaking) _buildVoicePill(),
          AiChatComposer(
            controller: _textCtrl,
            focusNode: _textFocus,
            hintText: _t('ai.text_input_hint'),
            cameraTooltip: _t('ai.camera'),
            galleryTooltip: _t('ai.upload'),
            sendTooltip: _t('ai.send'),
            micTooltip: _t('ai.voice_input'),
            enabled: !_busy,
            listening: _listening,
            speaking: _speaking,
            voiceFocused: _voiceFocused,
            onSend: _submitTypedText,
            onMic: _onMicTap,
            onCamera: () => _pickImage(ImageSource.camera),
            onGallery: () => _pickImage(ImageSource.gallery),
            primary: _primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGreeting() {
    final orders = _t('ai.suggestion_recent_orders');
    final balance = _t('ai.suggestion_account_balance');
    final route = _t('ai.suggestion_today_route');

    return AiChatEmptyState(
      greeting: _t(
        'ai.ask_prompt',
        args: {'name': _greetingName},
      ),
      subtitle: _t('ai.chat_empty_subtitle'),
      suggestions: [
        AiChatSuggestion(
          label: orders,
          sendText: orders,
          icon: Icons.receipt_long_outlined,
        ),
        AiChatSuggestion(
          label: balance,
          sendText: balance,
          icon: Icons.account_balance_wallet_outlined,
        ),
        AiChatSuggestion(
          label: route,
          sendText: route,
          icon: Icons.route_outlined,
        ),
      ],
      onSuggestion: (text) {
        if (_busy) return;
        _send(text);
      },
      primary: _primary,
    );
  }

  Widget _buildChatList(List<AiChatMessage> msgs) {
    final showPartial = _listening && _partialTranscript.isNotEmpty;
    final count = msgs.length + (showPartial ? 1 : 0);

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      itemCount: count,
      itemBuilder: (context, i) {
          if (showPartial && i == count - 1) {
          return AiChatUserBubble(
            text: _partialTranscript,
            timeLabel: _fmtTime(DateTime.now()),
            isPartial: true,
            primary: _primary,
          );
        }
        final m = msgs[i];
        if (m.role == AiChatRole.user) {
          return AiChatUserBubble(
            text: m.content,
            hasImage: m.hasImage,
            imageLabel: _t('ai.camera'),
            timeLabel: _timeAt(i),
            primary: _primary,
          );
        }
        if (m.role == AiChatRole.assistant) {
          return _buildAssistantBubble(m.content, historyIndex: i);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAssistantBubble(String text, {required int historyIndex}) {
    final pdf = _agent.pdfAt(historyIndex);

    return AiChatAssistantBubble(
      text: text,
      timeLabel: _timeAt(historyIndex),
      footerLabel: _t('ai.ai_assistant'),
      primary: _primary,
      pdfSlot: pdf == null ? null : _buildPdfCard(pdf),
      actions: [
        _actionIcon(
          Icons.copy_outlined,
          _t('ai.copy'),
          () => _copyText(AiChatReplySanitizer.forDisplay(text)),
        ),
        _actionIcon(
          Icons.volume_up_outlined,
          _t('ai.tts_enabled'),
          () async {
            await _interruptTts();
            _session.beginSpeaking();
            setState(() {});
            final spoke = await _tts.speakIfEnabled(text);
            if (!spoke && mounted) {
              _session.onSpeakInterrupted();
              setState(() {});
            }
          },
        ),
        if (pdf != null)
          _actionIcon(
            Icons.picture_as_pdf_outlined,
            _t('ai.pdf_open'),
            () => _openPdf(pdf),
          ),
      ],
    );
  }

  Widget _buildPdfCard(AiChatReportPdfPayload pdf) {
    final border = FieldSalesDensTheme.border(context);
    final titleColor = FieldSalesDensTheme.title(context);
    final muted = FieldSalesDensTheme.muted(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.bodyBackground(context),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pdf.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                Text(
                  _t(
                    'ai.pdf_rows',
                    args: {'count': '${pdf.rowCount}'},
                  ),
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _openPdf(pdf),
            child: Text(
              _t('ai.pdf_open'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _sharePdf(pdf),
            child: Text(
              _t('ai.pdf_share'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(AiChatReportPdfPayload pdf) async {
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      ReportPdfViewerScreen.routeName,
      arguments: ReportPdfViewerArgs(
        bytes: pdf.bytes,
        title: pdf.title,
      ),
    );
  }

  Future<void> _sharePdf(AiChatReportPdfPayload pdf) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'ai_chat_${pdf.title.hashCode}.pdf');
      await File(path).writeAsBytes(pdf.bytes, flush: true);
      await Share.shareXFiles(
        [XFile(path)],
        subject: pdf.title,
        text: pdf.title,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusKey = 'ai.request_failed');
    }
  }

  Widget _actionIcon(IconData icon, String tip, VoidCallback onTap) {
    final muted = FieldSalesDensTheme.muted(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        iconSize: 16,
        color: muted,
        tooltip: tip,
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }

  /// Sesli durum — sese odak halkası + dalga
  Widget _buildVoicePill() {
    final surface = FieldSalesDensTheme.surface(context);
    final border = FieldSalesDensTheme.border(context);
    final muted = FieldSalesDensTheme.muted(context);
    final label = _listening
        ? (_voiceFocused
            ? _t('ai.listening_focus')
            : _t('ai.listening_noise'))
        : _t('ai.speaking');

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final active = _listening || _speaking;
        final focusBoost = _listening && _voiceFocused ? 0.12 : 0.0;
        final alpha =
            active ? 0.10 + _pulse.value * 0.08 + focusBoost : 0.05;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              key: const Key('ai_chat_voice_pill'),
              onTap: _busy ? null : _onMicTap,
              onLongPressStart: _busy
                  ? null
                  : (_) {
                      _onPillHoldStart();
                    },
              onLongPressEnd: (_) {
                _onPillHoldEnd();
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Color.lerp(surface, _primary, alpha),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: active
                        ? _primary.withValues(
                            alpha: _voiceFocused ? 0.7 : 0.4,
                          )
                        : border,
                    width: _voiceFocused ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (active)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final levelBoost = _voiceFocused
                              ? (_soundLevel.clamp(-20, 10) + 20) / 30
                              : 0.25;
                          final h = 6.0 +
                              ((i + 1) % 3) * 4 +
                              _pulse.value * 5 * levelBoost;
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 1.5,
                            ),
                            width: 3,
                            height: h.clamp(4, 22),
                            decoration: BoxDecoration(
                              color: _primary.withValues(
                                alpha: _voiceFocused ? 0.95 : 0.55,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    if (active) const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? _primary : muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
