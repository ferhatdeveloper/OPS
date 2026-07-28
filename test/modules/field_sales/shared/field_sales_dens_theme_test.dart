// Dosya Adı: field_sales_dens_theme_test.dart
// Açıklama: Dens tema kontrast — light/dark title ve muted assert
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_theme.dart';

void main() {
  testWidgets('FieldSalesDensTheme — light başlık slate, muted gri',
      (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            onSurface: Color(0xFF1A1A1A),
            onSurfaceVariant: Color(0xFF5C5C5C),
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F3F5),
        ),
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      FieldSalesDensTheme.title(captured),
      FieldSalesDensTheme.lightTitle,
    );
    expect(
      FieldSalesDensTheme.bodyBackground(captured),
      FieldSalesDensTheme.lightBodyBg,
    );
    expect(FieldSalesDensTheme.surface(captured), Colors.white);
  });

  testWidgets('FieldSalesDensTheme — dark onSurface / scaffold',
      (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            onSurface: Colors.white,
            onSurfaceVariant: Color(0xFFB3B3B3),
            surface: Color(0xFF1E1E1E),
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(FieldSalesDensTheme.title(captured), Colors.white);
    expect(
      FieldSalesDensTheme.muted(captured),
      const Color(0xFFB3B3B3),
    );
    expect(
      FieldSalesDensTheme.bodyBackground(captured),
      const Color(0xFF121212),
    );
    expect(
      FieldSalesDensTheme.surface(captured),
      const Color(0xFF1E1E1E),
    );
  });
}
