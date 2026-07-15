import 'package:uuid/uuid.dart';
import '../../../../service/database_service.dart';
import '../model/ai_suggestion_model.dart';

class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  final _uuid = const Uuid();

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
