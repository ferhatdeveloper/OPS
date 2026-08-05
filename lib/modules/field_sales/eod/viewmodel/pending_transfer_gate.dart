// Dosya Adı: pending_transfer_gate.dart
// Açıklama: Logo’ya aktarılmamış fatura — gün sonu / çıkış karar kapısı
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

/// {@template pending_transfer_action}
/// Bekleyen transfer kontrolünün tetiklendiği saha eylemi.
/// {@endtemplate}
enum PendingTransferAction {
  /// Gün sonu kapanış (DayCloseScreen)
  dayClose,

  /// Gün durumu — Tamamlandı? ile bitirme
  dayStatusComplete,

  /// Uygulama çıkışı
  logout,
}

/// {@template pending_transfer_verdict}
/// Kapı sonucu: serbest / uyar / engelle.
/// {@endtemplate}
enum PendingTransferVerdict {
  /// Bekleyen yok — devam
  allow,

  /// Uyarı — onay veya listeye git
  warn,

  /// Engelle — yalnızca liste / iptal (zorla yok)
  block,
}

/// {@template pending_transfer_decision}
/// Bekleyen fatura sayısı + l10n anahtarları + hedef rota.
///
/// Kullanım örneği:
/// ```dart
/// final d = PendingTransferGate.evaluate(
///   action: PendingTransferAction.dayClose,
///   pendingInvoiceCount: 2,
/// );
/// ```
/// {@endtemplate}
class PendingTransferDecision {
  /// [verdict]: allow / warn / block
  final PendingTransferVerdict verdict;

  /// [action]: Tetikleyen eylem
  final PendingTransferAction action;

  /// [pendingInvoiceCount]: logo_ref boş veya kuyrukta
  final int pendingInvoiceCount;

  /// [titleKey]: Dialog başlık l10n
  final String titleKey;

  /// [messageKey]: Dialog gövde l10n (`{count}`)
  final String messageKey;

  /// [forceProceedKey]: Uyarıda “yine de” aksiyonu (block’ta boş)
  final String? forceProceedKey;

  /// [openListKey]: Transfer listesine git
  final String openListKey;

  /// [listRoute]: Named route — fatura untransferred
  final String listRoute;

  /// {@macro pending_transfer_decision}
  const PendingTransferDecision({
    required this.verdict,
    required this.action,
    required this.pendingInvoiceCount,
    required this.titleKey,
    required this.messageKey,
    required this.openListKey,
    required this.listRoute,
    this.forceProceedKey,
  });

  /// Bekleyen yok veya allow
  bool get shouldInterrupt =>
      verdict == PendingTransferVerdict.warn ||
      verdict == PendingTransferVerdict.block;

  /// Zorla devam (yalnızca warn)
  bool get allowsForceProceed =>
      verdict == PendingTransferVerdict.warn &&
      (forceProceedKey ?? '').isNotEmpty;
}

/// {@template pending_transfer_gate}
/// Plasiyer: Logo’ya gitmemiş fatura varken gün sonu / çıkış kapısı.
///
/// Kaynak: `InvoiceUntransferredStore` (is_synced=0 ≡ logo_ref boş +
/// sync_queue entity=invoice). Saf Dart — UI yok.
///
/// Kullanım örneği:
/// ```dart
/// final d = PendingTransferGate.evaluate(
///   action: PendingTransferAction.logout,
///   pendingInvoiceCount: n,
/// );
/// if (d.shouldInterrupt) { /* dialog */ }
/// ```
/// {@endtemplate}
class PendingTransferGate {
  /// [invoicesUntransferredRoute]: Dens fatura kuyruk rotası
  static const String invoicesUntransferredRoute =
      '/field-sales/invoices-untransferred';

  /// [titleKey]: Ortak dialog başlığı
  static const String titleKey = 'field_sales.pending_transfer_title';

  /// [openListKey]: Listeye git
  static const String openListKey =
      'field_sales.pending_transfer_open_list';

  /// [messageDayCloseKey]: Gün sonu uyarı / engel
  static const String messageDayCloseKey =
      'field_sales.pending_transfer_day_close_message';

  /// [messageLogoutKey]: Çıkış uyarı
  static const String messageLogoutKey =
      'field_sales.pending_transfer_logout_message';

  /// [forceCloseKey]: Yine de günü kapat
  static const String forceCloseKey =
      'field_sales.pending_transfer_force_close';

  /// [forceLogoutKey]: Yine de çık
  static const String forceLogoutKey =
      'field_sales.pending_transfer_force_logout';

  /// [savedQueuedKey]: Hızlı kes sonrası net durum
  static const String savedQueuedKey =
      'field_sales.invoice_saved_queued';

  PendingTransferGate._();

  /// {@template pending_transfer_gate_policy}
  /// Eyleme göre varsayılan verdict (count > 0 iken).
  ///
  /// Tümü **warn**: dialog zorunlu; “yine de” ile devam veya listeye git.
  /// (Logo down iken sert block plasiyeri kilitlemez. `block` API hazır.)
  /// {@endtemplate}
  static PendingTransferVerdict policyFor(PendingTransferAction action) {
    switch (action) {
      case PendingTransferAction.dayClose:
      case PendingTransferAction.dayStatusComplete:
      case PendingTransferAction.logout:
        return PendingTransferVerdict.warn;
    }
  }

  /// {@template pending_transfer_gate_evaluate}
  /// Bekleyen sayıya göre karar üretir.
  ///
  /// Parametreler:
  /// - [action]: Gün sonu / çıkış
  /// - [pendingInvoiceCount]: Bekleyen fatura adedi (≥0)
  ///
  /// Dönüş değeri:
  /// - [PendingTransferDecision]: Dialog / akış için karar
  /// {@endtemplate}
  static PendingTransferDecision evaluate({
    required PendingTransferAction action,
    required int pendingInvoiceCount,
  }) {
    final count = pendingInvoiceCount < 0 ? 0 : pendingInvoiceCount;
    if (count == 0) {
      return PendingTransferDecision(
        verdict: PendingTransferVerdict.allow,
        action: action,
        pendingInvoiceCount: 0,
        titleKey: titleKey,
        messageKey: messageFor(action),
        openListKey: openListKey,
        listRoute: invoicesUntransferredRoute,
      );
    }

    final verdict = policyFor(action);
    return PendingTransferDecision(
      verdict: verdict,
      action: action,
      pendingInvoiceCount: count,
      titleKey: titleKey,
      messageKey: messageFor(action),
      openListKey: openListKey,
      listRoute: invoicesUntransferredRoute,
      forceProceedKey: verdict == PendingTransferVerdict.warn
          ? forceProceedKeyFor(action)
          : null,
    );
  }

  /// {@template pending_transfer_gate_message_for}
  /// Eylem → mesaj l10n anahtarı.
  /// {@endtemplate}
  static String messageFor(PendingTransferAction action) {
    switch (action) {
      case PendingTransferAction.dayClose:
      case PendingTransferAction.dayStatusComplete:
        return messageDayCloseKey;
      case PendingTransferAction.logout:
        return messageLogoutKey;
    }
  }

  /// {@template pending_transfer_gate_force_key}
  /// Uyarıda “yine de” aksiyon anahtarı.
  /// {@endtemplate}
  static String forceProceedKeyFor(PendingTransferAction action) {
    switch (action) {
      case PendingTransferAction.dayClose:
      case PendingTransferAction.dayStatusComplete:
        return forceCloseKey;
      case PendingTransferAction.logout:
        return forceLogoutKey;
    }
  }
}
