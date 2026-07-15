import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/audit_model.dart';
import '../../../../service/database_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../../../../service/data_cache_service.dart';

class MerchandisingState {
  final List<AuditFormModel> availableForms;
  final bool isLoading;
  final String? error;

  MerchandisingState({
    this.availableForms = const [],
    this.isLoading = false,
    this.error,
  });

  MerchandisingState copyWith({
    List<AuditFormModel>? availableForms,
    bool? isLoading,
    String? error,
  }) {
    return MerchandisingState(
      availableForms: availableForms ?? this.availableForms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MerchandisingNotifier extends StateNotifier<MerchandisingState> {
  MerchandisingNotifier() : super(MerchandisingState()) {
    fetchForms();
  }

  Future<void> fetchForms() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      final forms = await DataCacheService().getOrFetch<List<AuditFormModel>>('audit_forms_list', () async {
        final formResults = await sqliteDb.query('audit_forms', where: 'is_active = 1');
        final fetchedForms = <AuditFormModel>[];

        for (var f in formResults) {
          final fieldResults = await sqliteDb.query(
            'audit_form_fields',
            where: 'form_id = ?',
            whereArgs: [f['id']],
            orderBy: 'sort_order',
          );
          final fields = fieldResults.map((fr) => AuditFormFieldModel.fromMap(fr)).toList();
          fetchedForms.add(AuditFormModel.fromMap(f, fields));
        }
        return fetchedForms;
      }, ttl: const Duration(minutes: 60));

      state = state.copyWith(availableForms: forms, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveAudit({
    required String visitId,
    required String formId,
    required Map<String, String> answers,
    Map<String, Map<String, dynamic>>? verificationData,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      final auditId = const Uuid().v4();
      
      await sqliteDb.transaction((txn) async {
        await txn.insert('visit_audits', {
          'id': auditId,
          'visit_id': visitId,
          'form_id': formId,
          'completed_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
        });

        for (var entry in answers.entries) {
          final vData = verificationData?[entry.key];
          await txn.insert('audit_answers', {
            'id': const Uuid().v4(),
            'audit_id': auditId,
            'field_id': entry.key,
            'answer_value': entry.value,
            'verification_data': vData != null ? jsonEncode(vData) : null,
          });
        }
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> validatePhotoLocation(Position position, String customerId) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      
      final customerResult = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
      if (customerResult.isEmpty) return {'verified': false, 'reason': 'Customer not found'};

      final custLat = (customerResult.first['latitude'] as num?)?.toDouble();
      final custLng = (customerResult.first['longitude'] as num?)?.toDouble();

      if (custLat == null || custLng == null) return {'verified': true, 'reason': 'No customer coordinates to verify against'};

      double distance = Geolocator.distanceBetween(position.latitude, position.longitude, custLat, custLng);

      return {
        'verified': distance <= 150, // 150m threshold for verification
        'distance': distance,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'verified': false, 'reason': e.toString()};
    }
  }
}

final merchandisingProvider = StateNotifierProvider<MerchandisingNotifier, MerchandisingState>((ref) {
  return MerchandisingNotifier();
});
