# Visit Voice Intelligence + AI Chat PDF — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** (A) AI chat içinde dinamik/MBT rapor sonucu PDF önizleme + dens aç/paylaş; (B) ziyaret check-in süresince arka plan ses kaydı, diarization hint, dil algısı, transcript, duygu analizi ve kullanıcı onaylı ziyaret durumu — offline-first.

**Architecture:** Chat: `FieldSalesChatAgent` → PostgREST propose+run → `MbtReportActionService.buildPdfBytes` → chat dens PDF kartı / `ReportPdfViewerScreen`. Visit: `ai_visit_intelligence/` + `record` + FGS bildirim; SQLite `visit_audio_segments` / `visit_transcripts`; AiGateway use-case `visitTranscriptAnalyze` / `emotionDetect` / `diarizeHint`; net yoksa analiz kuyruğu; silent write yalnız draft.

**Tech Stack:** Flutter, Riverpod, sqflite, speech_to_text, record, flutter_background_service, pdf/printing, AiGateway, dens UI, l10n.

**Commit:** yok (bilinçli)

---

## Keşif özeti (mevcut)

| Bileşen | Durum |
|---------|--------|
| Check-in | `VisitProvider.checkIn` → `visits` Open |
| `audio_recording_path` | Kolon + STT helper stub (`record` yoktu) |
| STT | `VisitSpeechToTextStore` + form bar (oturum bazlı) |
| PDF | `MbtReportActionService` + `/field-sales/report-pdf` |
| AI chat | `/field-sales/ai-chat` Gemini UI; rapor PDF yok |
| FGS | Konum için `flutter_background_service` (microphone type yok) |

---

## A) AI chat PDF

### Task A1: PDF builder + mesaj eki
- Create: `lib/core/ai/features/ai_chat_report_pdf_builder.dart`
- Modify: `field_sales_chat_agent.dart` — rapor niyeti → propose+run+PDF
- Modify: `ai_voice_chat_screen.dart` — dens PDF kartı (aç / paylaş); viewer push
- Reuse: `ReportPdfViewerScreen`, `share_plus` / Mbt share yolu
- Test: builder column map (unit)

### Task A2: l10n
- `ai.pdf_open`, `ai.pdf_share`, `ai.pdf_ready`, `ai.report_from_chat_*`

---

## B) Visit voice intelligence

### Task B1: Şema
- `SqlQuerys`: `visit_audio_segments`, `visit_transcripts`
- Kolonlar: speaker_label, start_ms, end_ms, text, lang, emotion, ONAY, is_synced, draft flags
- `DatabaseService.ensureVisitVoiceIntelligenceSchema`
- visits: `voice_consent_at`, `emotion_summary`, `ai_status_draft` (opsiyonel ALTER)

### Task B2: AiUseCase + gateway
- `visitTranscriptAnalyze`, `emotionDetect`, `diarizeHint`
- Servis: parse JSON (emotion enum, speaker segments) — PII log yok

### Task B3: Kayıt + kuyruk
- pubspec: `record`
- `VisitVoiceRecordingStore` — izin + KVKK onay → dosya yolu (`VisitSpeechAudioHelper` genişlet)
- Android: `FOREGROUND_SERVICE_MICROPHONE` + bildirim l10n
- Offline: `visit_transcript_queue` status pending → AI net olunca işle

### Task B4: UI dens (ui-no-touch)
- `VisitVoiceIntelligenceBanner` — visit_form_screen üstü dens chip/banner
- Consent dialog (KVKK kısa)
- Duygu dens SnackBar / chip; durum önerisi → kullanıcı onaylı notes/ONAY

### Task B5: Test + l10n + canvas
- Unit: emotion parse, transcript model
- `tr.json` + translation_sync
- `OPS-paralel-is-durum.canvas.tsx` güncelle

---

## Riskler

| Risk | Not |
|------|-----|
| Diarization kalitesi | Lokal segment + AI “Speaker 1/2” hint; kimlik kesin değil |
| Arka plan OS | iOS/Android arka plan mic kısıtı; FGS + kullanıcı görünür bildirim zorunlu |
| STT+record çatışması | Aynı anda ASR ve file record platforma göre kırılgan — öncelik file record + batch STT/AI |
| KVKK | Ses/PII log yok; onay olmadan kayıt yok |

---

## Route / giriş

| Route / giriş | Açıklama |
|---------------|----------|
| `/field-sales/ai-chat` | PDF kartı + viewer |
| `/field-sales/report-pdf` | Tam ekran viewer (mevcut) |
| Visit form (check-in sonrası) | Voice banner + consent |
| Check-out | Kayıt stop + transcript kuyruk + draft özet |

---

## Doğrulama

```bash
flutter test test/core/ai/ai_chat_report_pdf_builder_test.dart
flutter test test/modules/field_sales/ai_visit_intelligence/
dart run .agents/skills/automatic-translation/scripts/translation_sync.dart
```
