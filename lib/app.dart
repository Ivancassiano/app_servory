import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ServoryApp extends ConsumerWidget {
  const ServoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ServiceLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Só pt-BR por ora (spec §25 pede pt/it/en/es no não-funcional; isso é
      // trabalho de tradução via flutter_localizations/ARB quando o produto
      // tiver esse material — não bloqueia a fundação).
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
