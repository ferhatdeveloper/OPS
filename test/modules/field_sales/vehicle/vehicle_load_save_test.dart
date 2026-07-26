// Dosya Adı: vehicle_load_save_test.dart
// Açıklama: Araç yükleme dens Kaydet → loadStockIntoVehicle wiring
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/product_model.dart';
import 'package:exfin_ops/modules/field_sales/vehicle/view/vehicle_load_screen.dart';
import 'package:exfin_ops/modules/field_sales/vehicles/model/vehicle_model.dart';
import 'package:exfin_ops/modules/field_sales/vehicles/viewmodel/vehicle_provider.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

/// Kaydet çağrılarını kaydeden test harness.
class _RecordingVehicleNotifier extends VehicleNotifier {
  _RecordingVehicleNotifier() : super();

  /// [lastItems]: Son loadStockIntoVehicle parametresi
  List<Map<String, dynamic>>? lastItems;

  /// [callCount]: Kaç kez çağrıldığı
  int callCount = 0;

  /// [nextResult]: Dönüş değeri
  bool nextResult = true;

  @override
  Future<void> loadInitialData() async {
    final vehicle = VehicleModel(id: 'veh-test', plate: '34 TEST 01');
    state = VehicleState(
      vehicles: [vehicle],
      selectedVehicle: vehicle,
    );
  }

  @override
  Future<bool> loadStockIntoVehicle({
    required List<Map<String, dynamic>> items,
  }) async {
    callCount++;
    lastItems = List<Map<String, dynamic>>.from(items);
    return nextResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('VehicleLoadScreen dens Kaydet', () {
    late _RecordingVehicleNotifier harness;

    Future<ProductModel?> fakeCatalogPicker(BuildContext context) async {
      return ProductModel(
        id: 'prod-catalog-1',
        code: 'SKU-CAT-1',
        name: 'Katalog Ürün',
        unit: 'Adet',
      );
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      harness = _RecordingVehicleNotifier();
      await pumpStubWithL10n(
        tester,
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith((ref) => harness),
          ],
          child: VehicleLoadScreen(productPicker: fakeCatalogPicker),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('Kaydet butonu görünür (common.save)', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Kaydet'), findsOneWidget);
    });

    testWidgets('satır yokken Kaydet provider çağırmaz', (tester) async {
      await pumpScreen(tester);
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('ink_sparkle')) {
          return;
        }
        previousOnError?.call(details);
      };
      try {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kaydet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      } finally {
        FlutterError.onError = previousOnError;
      }
      expect(harness.callCount, 0);
      expect(find.text('En az bir satır ekleyin.'), findsOneWidget);
    });

    testWidgets(
        'katalog seçip Kaydet → loadStockIntoVehicle (productId)',
        (tester) async {
      await pumpScreen(tester);

      expect(
        tester.widget<VehicleLoadScreen>(find.byType(VehicleLoadScreen))
            .productPicker,
        isNotNull,
      );

      final addBtn = find.widgetWithText(TextButton, 'Satır Ekle');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dens üst alan yüksekliği yüzünden satır ListView offstage olabilir.
      expect(
        find.text('Katalog Ürün', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('SKU-CAT-1', skipOffstage: false),
        findsOneWidget,
      );

      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('ink_sparkle')) {
          return;
        }
        previousOnError?.call(details);
      };
      try {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kaydet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      } finally {
        FlutterError.onError = previousOnError;
      }

      expect(harness.callCount, 1);
      expect(harness.lastItems, isNotNull);
      expect(harness.lastItems!, isNotEmpty);
      expect(harness.lastItems!.first['productId'], 'prod-catalog-1');
      expect(
        (harness.lastItems!.first['quantity'] as num).toDouble(),
        greaterThan(0),
      );
    });
  });
}
