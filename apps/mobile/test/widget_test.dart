// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:darb_mobile/core/providers/app_state.dart';
import 'package:darb_mobile/main.dart';

void main() {
  testWidgets('DARB App smoke test', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const DarbApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    appState.dispose();
    await tester.pumpAndSettle();
  });
}
