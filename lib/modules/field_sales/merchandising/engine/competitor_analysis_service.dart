import '../../../../service/database_service.dart';
import '../model/competitor_model.dart';
import 'package:uuid/uuid.dart';

class CompetitorAnalysisService {
  static final CompetitorAnalysisService _instance = CompetitorAnalysisService._internal();
  factory CompetitorAnalysisService() => _instance;
  CompetitorAnalysisService._internal();

  final _uuid = const Uuid();

  Future<List<CompetitorProductModel>> getCompetitorProducts() async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final result = await db.query('competitor_products');
    return result.map((m) => CompetitorProductModel.fromMap(m)).toList();
  }

  Future<void> saveObservation(CompetitorObservationModel observation) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    await db.insert('competitor_observations', observation.toMap());
  }

  Future<List<CompetitorObservationModel>> getObservationsByVisit(String visitId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final result = await db.query(
      'competitor_observations',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'created_at DESC',
    );
    return result.map((m) => CompetitorObservationModel.fromMap(m)).toList();
  }

  /// Seeds some mock competitor products for testing if the table is empty
  Future<void> seedMockProducts() async {
    final products = await getCompetitorProducts();
    if (products.isNotEmpty) return;

    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    final mocks = [
      {'id': _uuid.v4(), 'name': 'Rakip Kola 330ml', 'brand': 'CocaCola', 'category': 'İçecek', 'price_reference': 25.0},
      {'id': _uuid.v4(), 'name': 'Rakip Bisküvi 100g', 'brand': 'Ülker', 'category': 'Gıda', 'price_reference': 15.0},
      {'id': _uuid.v4(), 'name': 'Rakip Deterjan 5kg', 'brand': 'Ariel', 'category': 'Temizlik', 'price_reference': 120.0},
    ];

    for (var m in mocks) {
      await db.insert('competitor_products', m);
    }
  }
}
