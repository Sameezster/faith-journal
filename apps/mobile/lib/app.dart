import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class FaithJournalApp extends ConsumerWidget {
  const FaithJournalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Faith Journal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Allow scrolling on every input device. Default behavior only enables
      // touch + trackpad, which means a laptop emulator with a mouse can't
      // scroll. Explicitly include mouse + stylus so scrolling works
      // everywhere (Android phone, iOS, Chrome, macOS desktop).
      scrollBehavior: const _AllInputsScrollBehavior(),
      routerConfig: router,
    );
  }
}

class _AllInputsScrollBehavior extends MaterialScrollBehavior {
  const _AllInputsScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}
