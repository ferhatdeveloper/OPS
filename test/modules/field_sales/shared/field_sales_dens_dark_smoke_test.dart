// Dosya Adı: field_sales_dens_dark_smoke_test.dart
// Açıklama: Dark ThemeMode dens filter / scaffold yüzey smoke
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_app_bar.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_filter_bar.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_theme.dart';

void main() {
  testWidgets('Dark ThemeMode — Scaffold body dens, chip surface',
      (tester) async {
    const scaffoldBg = Color(0xFF121212);
    const surface = Color(0xFF1E1E1E);

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            onSurface: Colors.white,
            onSurfaceVariant: Color(0xFFB3B3B3),
            surface: surface,
          ),
          scaffoldBackgroundColor: scaffoldBg,
        ),
        home: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor:
                  FieldSalesDensTheme.bodyBackground(context),
              appBar: FieldSalesDensAppBar(
                title: 'Dark Smoke',
                bottom: FieldSalesDensFilterBar(
                  children: [
                    FieldSalesDensChipRow(
                      items: [
                        FieldSalesDensChipItem(
                          label: 'A',
                          selected: true,
                          onTap: () {},
                        ),
                        FieldSalesDensChipItem(
                          label: 'B',
                          selected: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              body: const SizedBox.shrink(),
            );
          },
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, scaffoldBg);

    final materials = tester.widgetList<Material>(find.byType(Material));
    final chipSurfaces = materials
        .where((m) => m.color == surface)
        .toList();
    expect(chipSurfaces, isNotEmpty);

    final filterBar = tester.widgetList<Material>(find.byType(Material)).where(
          (m) => m.color == scaffoldBg,
        );
    expect(filterBar, isNotEmpty);
  });

  testWidgets('Light ThemeMode — body F8F9FD, chip white surface',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF2F3F5),
        ),
        home: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor:
                  FieldSalesDensTheme.bodyBackground(context),
              body: FieldSalesDensChip(
                label: 'X',
                selected: false,
                onTap: () {},
              ),
            );
          },
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, FieldSalesDensTheme.lightBodyBg);

    final chipMaterial = tester
        .widgetList<Material>(find.byType(Material))
        .firstWhere((m) => m.color == Colors.white);
    expect(chipMaterial.color, Colors.white);
  });
}
