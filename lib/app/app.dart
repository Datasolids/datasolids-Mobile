import 'package:datasolids_mobile/app/router.dart';
import 'package:datasolids_mobile/core/config/env.dart';
import 'package:datasolids_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class DatasolidsApp extends ConsumerWidget {
  const DatasolidsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: Env.instance.flavor.displayName,
      debugShowCheckedModeBanner: !Env.instance.flavor.isProduction,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      // l10n wiring (uncomment once locale arb files land):
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
