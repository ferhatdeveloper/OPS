import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/sync/view/pending_transfers_screen.dart';

void main() {
  testWidgets('K‑Period selector updates list titles', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PendingTransfersScreen()));
    // Verify segmented control is present with K1 selected by default
    expect(find.text('K1'), findsOneWidget);
    // Tap on K2 segment
    await tester.tap(find.text('K2'));
    await tester.pumpAndSettle();
    // Verify that list items now contain "K2"
    expect(find.textContaining('K2'), findsWidgets);
  });
}
