// Dosya Adı: social_media_image_service.dart
// Açıklama: Ürün sosyal medya — AI metin + görsel + yerel kaydet/paylaş
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/ai/ai_chat_message.dart';
import '../../../../core/ai/ai_completion.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../../../../core/ai/ai_image.dart';
import '../../../../core/ai/ai_use_case.dart';
import '../model/social_image_size_preset.dart';
import 'social_media_prompt_builder.dart';

/// {@template social_media_image_service}
/// AiGateway üzerinden reklam metni + görsel; key yoksa no-op.
///
/// Kullanım örneği:
/// ```dart
/// final svc = SocialMediaImageService();
/// final draft = await svc.draftAdCopy(input);
/// ```
/// {@endtemplate}
class SocialMediaImageService {
  /// [_gateway]: AI gateway
  final AiGateway _gateway;

  /// [_shareXFiles]: Test inject paylaşım
  final Future<void> Function(List<XFile> files, {String? text})? _shareXFiles;

  /// [_docsDir]: Test inject dizin
  final Future<Directory> Function()? _docsDir;

  /// {@macro social_media_image_service}
  SocialMediaImageService({
    AiGateway? gateway,
    Future<void> Function(List<XFile> files, {String? text})? shareXFiles,
    Future<Directory> Function()? docsDir,
  })  : _gateway = gateway ?? AiGateway(),
        _shareXFiles = shareXFiles,
        _docsDir = docsDir;

  /// {@template social_media_image_service_draft}
  /// AI ile reklam metni; key yoksa seed metin.
  ///
  /// Dönüş değeri:
  /// - [String]: Düzenlenebilir metin
  /// {@endtemplate}
  Future<String> draftAdCopy(SocialMediaPromptInput input) async {
    final seed = SocialMediaPromptBuilder.seedAdCopy(
      productName: input.productName,
      priceText: input.priceText,
      unit: input.unit,
      currency: input.currency,
    );
    final result = await _gateway.completeFor(
      AiUseCase.socialMediaImage,
      AiCompletionRequest(
        messages: [
          AiChatMessage.system(SocialMediaPromptBuilder.copySystemPrompt()),
          AiChatMessage.user(
            SocialMediaPromptBuilder.buildCopyUserPrompt(input),
          ),
        ],
        temperature: 0.7,
        maxTokens: 200,
      ),
    );
    if (!result.isOk) return seed;
    final text = result.text!.trim();
    return text.isEmpty ? seed : text;
  }

  /// {@template social_media_image_service_generate}
  /// Onaylı metin + preset ile görsel üret.
  ///
  /// Dönüş değeri:
  /// - [AiImageResult]: ok / noKey / unsupported / error
  /// {@endtemplate}
  Future<AiImageResult> generateImage(SocialMediaPromptInput input) {
    final prompt = SocialMediaPromptBuilder.buildImagePrompt(input);
    final url = input.productImageUrl.trim();
    return _gateway.generateImageFor(
      AiUseCase.socialMediaImage,
      AiImageRequest(
        prompt: prompt,
        width: input.preset.width,
        height: input.preset.height,
        productImageUrl: url.isEmpty ? null : url,
      ),
    );
  }

  /// {@template social_media_image_service_save}
  /// Uygulama belgelerine PNG kaydet (galeri yerine offline-safe).
  ///
  /// Dönüş değeri:
  /// - [File]: Kaydedilen dosya
  /// {@endtemplate}
  Future<File> saveLocally({
    required Uint8List bytes,
    required String productName,
    SocialImageSizePreset preset = SocialImageSizePreset.instagramSquare,
  }) async {
    final dir = _docsDir != null
        ? await _docsDir!()
        : await getApplicationDocumentsDirectory();
    final socialDir = Directory('${dir.path}/ai_social');
    if (!await socialDir.exists()) {
      await socialDir.create(recursive: true);
    }
    final safe = productName
        .trim()
        .replaceAll(RegExp(r'[^\w\-]+'), '_')
        .toLowerCase();
    final name = safe.isEmpty ? 'product' : safe;
    final file = File(
      '${socialDir.path}/${name}_${preset.storageKey}_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// {@template social_media_image_service_share}
  /// share_plus ile görsel paylaş.
  /// {@endtemplate}
  Future<void> shareImage({
    required Uint8List bytes,
    required String fileName,
    String? text,
  }) async {
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    final x = XFile(file.path, mimeType: 'image/png', name: fileName);
    if (_shareXFiles != null) {
      await _shareXFiles!([x], text: text);
      return;
    }
    await Share.shareXFiles([x], text: text);
  }
}
