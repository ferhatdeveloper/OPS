import 'package:uuid/uuid.dart';
import '../../../../service/database_service.dart';
import '../model/extra_ops_model.dart';
import '../../../../service/notification_service.dart';

class ExtraOpsService {
  static final ExtraOpsService _instance = ExtraOpsService._internal();
  factory ExtraOpsService() => _instance;
  ExtraOpsService._internal();

  final _uuid = const Uuid();

  Future<void> saveWastageLog(WastageLogModel log) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    await db.insert('wastage_logs', log.toMap());
    
    // Decrease from vehicle stock
    // In a real implementation, we would fetch the current vehicle ID
    await db.execute(
      'UPDATE vehicle_stocks SET quantity = quantity - ? WHERE product_id = ?',
      [log.quantity, log.productId]
    );

    // Check for critical stock threshold
    final stock = await db.query(
      'vehicle_stocks', 
      where: 'product_id = ?', 
      whereArgs: [log.productId]
    );
    
    if (stock.isNotEmpty) {
      final qty = (stock.first['quantity'] as num).toDouble();
      if (qty < 5) {
        NotificationService().showNotification(
          id: 700,
          title: '⚠️ Kritik Stok Uyarısı',
          body: 'Ürün (ID: \${log.productId}) stoğu kritik seviyeye düştü: \${qty.toInt()} adet.',
        );
      }
    }
  }

  Future<List<VisitTaskModel>> getTasksByCustomer(String customerId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    final result = await db.query('visit_tasks', where: 'customer_id = ?', whereArgs: [customerId]);
    return result.map((m) => VisitTaskModel.fromMap(m)).toList();
  }

  Future<void> completeTask(String taskId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    await db.update('visit_tasks', {'is_completed': 1}, where: 'id = ?', whereArgs: [taskId]);
  }

  Future<void> seedMockTasks(String customerId) async {
    final tasks = await getTasksByCustomer(customerId);
    if (tasks.isNotEmpty) return;

    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final mocks = [
      {'id': _uuid.v4(), 'customer_id': customerId, 'title': 'Yeni Sözleşme Tanıtımı', 'description': '2026 yılı yenileme şartlarını görüş.', 'is_completed': 0},
      {'id': _uuid.v4(), 'customer_id': customerId, 'title': 'Rack Yerleşimi', 'description': 'Teşhir standının yerini kontrol et.', 'is_completed': 0},
    ];

    for (var m in mocks) {
      await db.insert('visit_tasks', m);
    }
  }
}
