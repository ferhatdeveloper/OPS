import '../../../../service/database_service.dart';
import '../../stock/model/unit_set_model.dart';

class UnitConversionService {
  static Future<List<UnitSetLineModel>> getUnitsForProduct(String? unitSetId) async {
    if (unitSetId == null) return [];
    
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      
      final results = await db.query(
        'unit_set_lines',
        where: 'unit_set_id = ?',
        whereArgs: [unitSetId],
        orderBy: 'is_main_unit DESC',
      );
      
      return results.map((r) => UnitSetLineModel.fromMap(r)).toList();
    } catch (e) {
      print('UnitConversionService Error: $e');
      return [];
    }
  }

  static double convertToMainUnit(double quantity, UnitSetLineModel line) {
    return quantity * line.conversionFactor;
  }

  static double convertFromMainUnit(double mainUnitQuantity, UnitSetLineModel targetLine) {
    if (targetLine.conversionFactor == 0) return mainUnitQuantity;
    return mainUnitQuantity / targetLine.conversionFactor;
  }
}
