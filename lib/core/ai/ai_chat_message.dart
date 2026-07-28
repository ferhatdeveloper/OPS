// Dosya Adı: ai_chat_message.dart
// Açıklama: Ortak AI sohbet mesajı modeli (metin + opsiyonel vision görüntü)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template ai_chat_role}
/// Mesaj rolü (OpenAI uyumlu).
/// {@endtemplate}
enum AiChatRole {
  /// Sistem talimatı
  system,

  /// Kullanıcı
  user,

  /// Asistan
  assistant,
}

/// {@template ai_chat_message}
/// Sağlayıcıdan bağımsız sohbet mesajı.
/// Opsiyonel [imageBase64] vision için; **asla loglanmaz**.
///
/// Kullanım örneği:
/// ```dart
/// AiChatMessage.user('Merhaba');
/// ```
/// {@endtemplate}
class AiChatMessage {
  /// [role]: Rol
  final AiChatRole role;

  /// [content]: Metin içerik
  final String content;

  /// [imageBase64]: Opsiyonel görüntü (base64, data-URL prefix yok)
  final String? imageBase64;

  /// [imageMimeType]: Görüntü MIME (varsayılan image/jpeg)
  final String? imageMimeType;

  /// {@macro ai_chat_message}
  const AiChatMessage({
    required this.role,
    required this.content,
    this.imageBase64,
    this.imageMimeType,
  });

  /// Kullanıcı mesajı kısayolu
  factory AiChatMessage.user(String content) =>
      AiChatMessage(role: AiChatRole.user, content: content);

  /// Asistan mesajı kısayolu
  factory AiChatMessage.assistant(String content) =>
      AiChatMessage(role: AiChatRole.assistant, content: content);

  /// Sistem mesajı kısayolu
  factory AiChatMessage.system(String content) =>
      AiChatMessage(role: AiChatRole.system, content: content);

  /// Vision kullanıcı mesajı (görüntü log’a yazılmaz)
  factory AiChatMessage.userWithImage({
    required String content,
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
  }) =>
      AiChatMessage(
        role: AiChatRole.user,
        content: content,
        imageBase64: imageBase64,
        imageMimeType: imageMimeType,
      );

  /// Görüntü var mı
  bool get hasImage =>
      imageBase64 != null && imageBase64!.trim().isNotEmpty;

  /// OpenAI / OpenRouter JSON rol adı
  String get openAiRoleName {
    switch (role) {
      case AiChatRole.system:
        return 'system';
      case AiChatRole.user:
        return 'user';
      case AiChatRole.assistant:
        return 'assistant';
    }
  }

  /// Wire map (metin-only; test / basit builder)
  Map<String, String> toOpenAiMap() => {
        'role': openAiRoleName,
        'content': content,
      };

  /// Multimodal OpenAI content (vision)
  Map<String, dynamic> toOpenAiMultimodalMap() {
    if (!hasImage) return toOpenAiMap();
    final mime = (imageMimeType ?? 'image/jpeg').trim();
    final b64 = imageBase64!.trim();
    return {
      'role': openAiRoleName,
      'content': [
        {'type': 'text', 'text': content},
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:$mime;base64,$b64',
          },
        },
      ],
    };
  }
}
