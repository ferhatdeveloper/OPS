import 'postgre_service.dart';

/// Legacy alias to avoid changing 50+ files during migration phase.
typedef SupabaseService = PostgreService;

class MockSupabase {
  static final instance = MockSupabase._();
  MockSupabase._();
  final dynamic client = null;
}
