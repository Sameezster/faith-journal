import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faith_journal/core/theme/app_theme.dart';
import 'package:faith_journal/core/theme/tokens.dart';

void main() {
  group('AppTheme', () {
    test('light theme builds with brand tokens', () {
      final theme = AppTheme.light();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, FjColors.gold500);
      expect(theme.scaffoldBackgroundColor, FjColors.cream50);
    });

    testWidgets('Material widgets render with the theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Text('hello')),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
