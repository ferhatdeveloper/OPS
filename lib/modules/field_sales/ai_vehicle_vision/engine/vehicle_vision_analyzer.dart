// Dosya Adı: vehicle_vision_analyzer.dart
// Açıklama: AiGateway.vehicleVision → VehicleVisionResult
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import '../../../../core/ai/ai_completion.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../model/vehicle_vision_result.dart';

/// {@template vehicle_vision_analyze_result}
/// Vision araç analiz sonucu.
/// {@endtemplate}
class VehicleVisionAnalyzeResult {
  /// [status]
  final AiCompletionStatus status;

  /// [vehicle]
  final VehicleVisionResult? vehicle;

  /// [l10nKey]
  final String? l10nKey;

  /// {@macro vehicle_vision_analyze_result}
  const VehicleVisionAnalyzeResult({
    required this.status,
    this.vehicle,
    this.l10nKey,
  });

  bool get isOk =>
      status == AiCompletionStatus.ok &&
      vehicle != null &&
      vehicle!.hasContent;
}

/// {@template vehicle_vision_analyzer}
/// Fotoğraf → araç alanları; görüntü loglanmaz.
/// {@endtemplate}
class VehicleVisionAnalyzer {
  final AiGateway _gateway;

  /// {@macro vehicle_vision_analyzer}
  VehicleVisionAnalyzer({AiGateway? gateway})
      : _gateway = gateway ?? AiGateway();

  /// Vision çağrısı
  Future<VehicleVisionAnalyzeResult> analyzeImage({
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
    String? hint,
  }) async {
    final settings = await _gateway.loadSettings();
    if (!settings.hasActiveKey) {
      return const VehicleVisionAnalyzeResult(
        status: AiCompletionStatus.noKey,
        l10nKey: 'ai.no_api_key',
      );
    }
    final r = await _gateway.vehicleVision(
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
      userHint: hint,
    );
    if (!r.isOk) {
      return VehicleVisionAnalyzeResult(
        status: r.status,
        l10nKey: r.l10nKey ?? 'ai.request_failed',
      );
    }
    final vehicle = parseVehicleJson(r.text!);
    if (vehicle == null || !vehicle.hasContent) {
      return const VehicleVisionAnalyzeResult(
        status: AiCompletionStatus.error,
        l10nKey: 'field_sales.ai_vehicle_vision.err_parse',
      );
    }
    return VehicleVisionAnalyzeResult(
      status: AiCompletionStatus.ok,
      vehicle: vehicle,
    );
  }

  /// JSON → araç (unit test)
  static VehicleVisionResult? parseVehicleJson(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    String body = trimmed;
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(trimmed);
    if (m != null) {
      body = m.group(1)!.trim();
    } else {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        body = trimmed.substring(start, end + 1);
      }
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      return VehicleVisionResult.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }
}
