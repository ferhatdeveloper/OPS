// Dosya Adı: ai_use_case.dart
// Açıklama: AI özellik use-case kimlikleri + opsiyonel model override
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_use_case}
/// AI özellik kullanım senaryoları (gateway routing / model override).
///
/// Kullanım örneği:
/// ```dart
/// await gateway.completeFor(AiUseCase.reportInsight, request);
/// ```
/// {@endtemplate}
enum AiUseCase {
  /// MBT rapor sonucu kısa insight (P0)
  reportInsight,

  /// Yeni rapor önerisi / özet üretimi
  reportSuggestion,

  /// Sipariş miktar önerisi (recommendation bridge)
  orderRecommendation,

  /// Sipariş / talep tahmin insight (başka ajan UI yazar)
  demandForecastInsight,

  /// Müşteri ürün bitiş + depo tedarik / replenishment advice
  replenishmentAdvice,

  /// Plasiyer sesli / metin sohbet asistanı
  voiceAssistant,

  /// Doğal dil → PostgREST query spec önerisi (ham SQL yok)
  proposeReport,

  /// Raf / rakip fiyat vision + OCR
  visionAnalyze,

  /// Fatura / fiş görüntüsü OCR (ürün satırları + cari)
  invoiceOcr,

  /// Araç fotoğrafı → plaka / marka / tür / renk
  vehicleVision,

  /// Ürün sosyal medya reklam görseli + metin
  socialMediaImage,

  /// Ziyaret konuşma transcript analizi (özet + durum önerisi)
  visitTranscriptAnalyze,

  /// Ziyaret duygu / memnuniyet sınıflandırma
  emotionDetect,

  /// Konuşmacı ayrımı ipucu (Speaker 1/2 etiket)
  diarizeHint,

  /// Depo / WHMS ekran insight (emir, sayım, stok, transfer, rapor)
  whmsInsight,
}

/// {@template ai_use_case_x}
/// [AiUseCase] yardımcı uzantılar.
/// {@endtemplate}
extension AiUseCaseX on AiUseCase {
  /// Prefs / storage anahtar parçası
  String get storageKey {
    switch (this) {
      case AiUseCase.reportInsight:
        return 'report_insight';
      case AiUseCase.reportSuggestion:
        return 'report_suggestion';
      case AiUseCase.orderRecommendation:
        return 'order_recommendation';
      case AiUseCase.demandForecastInsight:
        return 'demand_forecast';
      case AiUseCase.replenishmentAdvice:
        return 'replenishment';
      case AiUseCase.voiceAssistant:
        return 'voice_assistant';
      case AiUseCase.proposeReport:
        return 'propose_report';
      case AiUseCase.visionAnalyze:
        return 'vision_analyze';
      case AiUseCase.invoiceOcr:
        return 'invoice_ocr';
      case AiUseCase.vehicleVision:
        return 'vehicle_vision';
      case AiUseCase.socialMediaImage:
        return 'social_media_image';
      case AiUseCase.visitTranscriptAnalyze:
        return 'visit_transcript_analyze';
      case AiUseCase.emotionDetect:
        return 'emotion_detect';
      case AiUseCase.diarizeHint:
        return 'diarize_hint';
      case AiUseCase.whmsInsight:
        return 'whms_insight';
    }
  }

  /// l10n: `ai.usecase_<storageKey>`
  String get labelKey => 'ai.usecase_$storageKey';

  /// Kısa sistem prompt kimliği (özellik adaptörleri doldurur)
  String get defaultSystemHintKey => 'ai.system_$storageKey';

  /// [storageKey] → enum
  static AiUseCase? tryParse(String? raw) {
    final k = (raw ?? '').trim().toLowerCase();
    if (k.isEmpty) return null;
    for (final u in AiUseCase.values) {
      if (u.storageKey == k) return u;
    }
    return null;
  }
}
