import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/me/presentation/home_screen.dart';

/// Reconstruído a cada mudança de [sessionControllerProvider] — com só duas
/// rotas nesta fundação, refazer o `GoRouter` é mais simples que ligar um
/// `ChangeNotifier` à parte, e o efeito colateral (voltar pra raiz da pilha
/// de navegação) é exatamente o que se quer numa troca de sessão.
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      switch (session) {
        case SessionUnknown():
          return '/splash';
        case SessionUnauthenticated():
        case SessionAuthenticating():
          return loggingIn ? null : '/login';
        case SessionAuthenticated():
          return loggingIn || state.matchedLocation == '/splash' ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
