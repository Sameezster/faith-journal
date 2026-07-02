import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:faith_journal/core/theme/app_colors.dart';
import 'package:faith_journal/core/theme/app_theme.dart';

void main() {
  // Tests run offline — never fetch Google Fonts over the network.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppTheme', () {
    test('light theme builds with brand tokens', () {
      final theme = AppTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.gold);
      expect(theme.scaffoldBackgroundColor, AppColors.ivory);
    });

    testWidgets('Material widgets render with the theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('hello')),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
