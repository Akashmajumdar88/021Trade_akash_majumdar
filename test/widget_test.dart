import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradeakashmajumdar/app/app.dart';
import 'package:tradeakashmajumdar/data/services/persistence_service.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TradingApp(),
      ),
    );

    // The market screen should be visible on launch.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
