// Dosya Adı: invoice_scan_store.dart
// Açıklama: Resim→Fatura dens state (OCR + eşleme + onay bayrakları)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:typed_data';

import '../../../../core/ai/ai_completion.dart';
import '../../products/model/product_catalog_row.dart';
import '../engine/invoice_ocr_analyzer.dart';
import '../model/invoice_ocr_line.dart';
import '../model/invoice_ocr_result.dart';
import '../model/invoice_scan_doc_type.dart';
import 'invoice_ocr_pending_queue.dart';

/// {@template invoice_scan_phase}
/// Ekran aşaması.
/// {@endtemplate}
enum InvoiceScanPhase {
  /// Fotoğraf bekleniyor
  idle,

  /// OCR çalışıyor
  analyzing,

  /// Doğrulama listesi
  review,

  /// Fatura kaydı
  saving,
}

/// {@template invoice_scan_state}
/// Dens fatura tarama durumu.
/// {@endtemplate}
class InvoiceScanState {
  /// [phase]
  final InvoiceScanPhase phase;

  /// [docType]
  final InvoiceScanDocType docType;

  /// [thumb]: Önizleme (loglanmaz)
  final Uint8List? thumb;

  /// [draft]
  final InvoiceOcrDraft? draft;

  /// [lineMatches]
  final List<InvoiceOcrLineMatch> lineMatches;

  /// [customerMatch]
  final InvoiceOcrCustomerMatch customerMatch;

  /// [statusKey]: l10n
  final String? statusKey;

  /// [userConfirmed]: Onay zorunlu
  final bool userConfirmed;

  /// [pendingQueued]: Offline kuyruğa alındı
  final bool pendingQueued;

  /// {@macro invoice_scan_state}
  const InvoiceScanState({
    this.phase = InvoiceScanPhase.idle,
    this.docType = InvoiceScanDocType.sales,
    this.thumb,
    this.draft,
    this.lineMatches = const [],
    this.customerMatch = const InvoiceOcrCustomerMatch(),
    this.statusKey,
    this.userConfirmed = false,
    this.pendingQueued = false,
  });

  InvoiceScanState copyWith({
    InvoiceScanPhase? phase,
    InvoiceScanDocType? docType,
    Uint8List? thumb,
    bool clearThumb = false,
    InvoiceOcrDraft? draft,
    bool clearDraft = false,
    List<InvoiceOcrLineMatch>? lineMatches,
    InvoiceOcrCustomerMatch? customerMatch,
    String? statusKey,
    bool clearStatus = false,
    bool? userConfirmed,
    bool? pendingQueued,
  }) {
    return InvoiceScanState(
      phase: phase ?? this.phase,
      docType: docType ?? this.docType,
      thumb: clearThumb ? null : (thumb ?? this.thumb),
      draft: clearDraft ? null : (draft ?? this.draft),
      lineMatches: lineMatches ?? this.lineMatches,
      customerMatch: customerMatch ?? this.customerMatch,
      statusKey: clearStatus ? null : (statusKey ?? this.statusKey),
      userConfirmed: userConfirmed ?? this.userConfirmed,
      pendingQueued: pendingQueued ?? this.pendingQueued,
    );
  }
}

/// {@template invoice_scan_store}
/// OCR + fuzzy + offline kuyruk (Riverpod dışı testable).
/// {@endtemplate}
class InvoiceScanStore {
  final InvoiceOcrAnalyzer analyzer;
  final InvoiceOcrPendingQueue pendingQueue;

  InvoiceScanState _state = const InvoiceScanState();

  /// {@macro invoice_scan_store}
  InvoiceScanStore({
    InvoiceOcrAnalyzer? analyzer,
    InvoiceOcrPendingQueue? pendingQueue,
  })  : analyzer = analyzer ?? InvoiceOcrAnalyzer(),
        pendingQueue = pendingQueue ?? InvoiceOcrPendingQueue();

  InvoiceScanState get state => _state;

  void setDocType(InvoiceScanDocType type) {
    _state = _state.copyWith(docType: type, userConfirmed: false);
  }

  void setCustomerMatch(InvoiceOcrCustomerMatch match) {
    _state = _state.copyWith(customerMatch: match, userConfirmed: false);
  }

  void updateLine(int index, InvoiceOcrLine line) {
    if (index < 0 || index >= _state.lineMatches.length) return;
    final next = List<InvoiceOcrLineMatch>.from(_state.lineMatches);
    next[index] = next[index].copyWith(
      line: line.copyWith(manualOverride: true),
    );
    _state = _state.copyWith(
      lineMatches: next,
      userConfirmed: false,
      draft: _state.draft?.copyWith(
        lines: next.map((e) => e.line).toList(),
      ),
    );
  }

  void markConfirmed() {
    _state = _state.copyWith(userConfirmed: true);
  }

  void resetReview() {
    _state = _state.copyWith(
      phase: InvoiceScanPhase.idle,
      clearDraft: true,
      lineMatches: const [],
      customerMatch: const InvoiceOcrCustomerMatch(),
      userConfirmed: false,
      clearStatus: true,
      pendingQueued: false,
    );
  }

  /// Analiz + eşleme; key yoksa kuyruk
  Future<InvoiceScanState> analyzeBytes({
    required Uint8List bytes,
    required String imageBase64,
    required List<ProductCatalogRow> catalog,
    required List<Map<String, dynamic>> customers,
    String imageMimeType = 'image/jpeg',
  }) async {
    _state = _state.copyWith(
      phase: InvoiceScanPhase.analyzing,
      thumb: bytes,
      clearStatus: true,
      userConfirmed: false,
      pendingQueued: false,
      clearDraft: true,
      lineMatches: const [],
    );
    final result = await analyzer.analyzeImage(
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
      docType: _state.docType,
    );
    if (result.status == AiCompletionStatus.noKey) {
      await pendingQueue.enqueue(bytes: bytes, docType: _state.docType);
      _state = _state.copyWith(
        phase: InvoiceScanPhase.idle,
        statusKey: 'ai.no_api_key',
        pendingQueued: true,
      );
      return _state;
    }
    if (!result.isOk || result.draft == null) {
      if (result.status == AiCompletionStatus.error ||
          result.status == AiCompletionStatus.cancelled) {
        await pendingQueue.enqueue(bytes: bytes, docType: _state.docType);
        _state = _state.copyWith(
          phase: InvoiceScanPhase.idle,
          statusKey: result.l10nKey ?? 'ai.request_failed',
          pendingQueued: true,
        );
        return _state;
      }
      _state = _state.copyWith(
        phase: InvoiceScanPhase.idle,
        statusKey: result.l10nKey ?? 'field_sales.ai_invoice_scan.err_parse',
      );
      return _state;
    }
    final draft = result.draft!;
    final matches = analyzer.matchProducts(
      lines: draft.lines,
      catalog: catalog,
    );
    final cust = analyzer.matchCustomer(
      partyName: draft.partyName,
      partyCode: draft.partyCode,
      customers: customers,
    );
    _state = _state.copyWith(
      phase: InvoiceScanPhase.review,
      draft: draft,
      lineMatches: matches,
      customerMatch: cust,
      clearStatus: true,
    );
    return _state;
  }

  void setPhase(InvoiceScanPhase phase) {
    _state = _state.copyWith(phase: phase);
  }

  void setStatusKey(String? key) {
    if (key == null) {
      _state = _state.copyWith(clearStatus: true);
    } else {
      _state = _state.copyWith(statusKey: key);
    }
  }
}
