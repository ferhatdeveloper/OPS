import 'package:uuid/uuid.dart';
import '../../../../core/ai/features/order_ai_recommendation_bridge.dart';
import '../../../../service/database_service.dart';
import '../model/ai_suggestion_model.dart';

class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  final _uuid = const Uuid();

  /// Opsiyonel AI gateway köprüsü (key yoksa yerel reason kalır)
  OrderAiRecommendationBridge? _bridge;

  /// Test / DI
  void bindAiBridge(OrderAiRecommendationBridge bridge) {
    _bridge = bridge;
  }

  Future<AISuggestionModel?> getSuggestion(String customerId, String productId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final result = await db.query(
      'ai_suggestions',
      where: 'customer_id = ? AND product_id = ?',
      whereArgs: [customerId, productId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return AISuggestionModel.fromMap(result.first);
    }
    return null;
  }

  /// Yerel suggestion + opsiyonel gateway reason enrich (offline-safe)
  Future<AISuggestionModel?> getSuggestionEnriched({
    required String customerId,
    required String productId,
    String customerLabel = '',
    String productLabel = '',
  }) async {
    final local = await getSuggestion(customerId, productId);
    if (local == null) return null;
    final bridge = _bridge ?? OrderAiRecommendationBridge();
    final enriched = await bridge.enrichReason(
      customerLabel: customerLabel.isEmpty ? customerId : customerLabel,
      productLabel: productLabel.isEmpty ? productId : productLabel,
      suggestedQty: local.suggestedQty,
      localReason: local.reason,
    );
    if (enriched == null || enriched == local.reason) return local;
    return AISuggestionModel(
      id: local.id,
      customerId: local.customerId,
      productId: local.productId,
      suggestedQty: local.suggestedQty,
      reason: enriched,
      confidence: local.confidence,
      updatedAt: local.updatedAt,
    );
  }

  /// Seeds mock suggestions for testing
  Future<void> seedMockSuggestions(String customerId, List<String> productIds) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    for (var pid in productIds) {
      final exists = await db.query('ai_suggestions', where: 'customer_id = ? AND product_id = ?', whereArgs: [customerId, pid]);
      if (exists.isEmpty) {
        final suggestion = AISuggestionModel(
          id: _uuid.v4(),
          customerId: customerId,
          productId: pid,
          suggestedQty: (10 + (pid.hashCode % 50)).toDouble(), // Deterministic random-looking qty
          reason: 'Aylık ortalama tüketim ve mevsimsellik bazlı öneri.',
          confidence: 0.85,
          updatedAt: DateTime.now(),
        );
        await db.insert('ai_suggestions', suggestion.toMap());
      }
    }
  }
}
