import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/app_lock_controller.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/offline_expired_screen.dart';
import '../../features/auth/presentation/unlock_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/equipments/presentation/equipment_detail_screen.dart';
import '../../features/equipments/presentation/equipment_list_screen.dart';
import '../../features/locations/presentation/location_detail_screen.dart';
import '../../features/locations/presentation/location_list_screen.dart';
import '../../features/me/presentation/home_screen.dart';
import '../../features/service_orders/presentation/service_order_detail_screen.dart';
import '../../features/service_orders/presentation/service_order_list_screen.dart';
import '../connectivity/connectivity_provider.dart';
import '../providers.dart';

/// Spec §18.3: uma sessão offline vale por 7 dias desde a última vez que o
/// aparelho confirmou com o servidor (login ou refresh bem-sucedido).
const offlineSessionTtl = Duration(days: 7);

const _gatedRoutes = {'/login', '/splash', '/unlock', '/offline-expired'};

/// Reconstruído a cada mudança de sessão, conectividade ou trava de app —
/// as 3 coisas que decidem pra onde redirecionar. Simples o bastante com
/// esse número de rotas; um `ChangeNotifier` só compensaria com uma árvore
/// de navegação muito maior.
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final online = ref.watch(isOnlineProvider).value;
  final unlocked = ref.watch(appLockControllerProvider);
  final store = ref.watch(secureStoreProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      bool? expired;
      if (session is SessionAuthenticated && online == false) {
        final lastValidation = await store.readLastOnlineValidation();
        expired =
            lastValidation == null ||
            DateTime.now().difference(lastValidation) > offlineSessionTtl;
      }
      return decideRedirect(
        session: session,
        online: online,
        unlocked: unlocked,
        offlineSessionExpired: expired,
        currentLocation: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/unlock', builder: (_, _) => const UnlockScreen()),
      GoRoute(
        path: '/offline-expired',
        builder: (_, _) => const OfflineExpiredScreen(),
      ),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/clients',
        builder: (_, _) => const ClientListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                ClientDetailScreen(clientId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/locations',
        builder: (_, _) => const LocationListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                LocationDetailScreen(locationId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/equipments',
        builder: (_, _) => const EquipmentListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                EquipmentDetailScreen(equipmentId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/service-orders',
        builder: (_, _) => const ServiceOrderListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => ServiceOrderDetailScreen(
              serviceOrderId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
});

/// Lógica de decisão pura (sem I/O), separada do closure do `GoRouter` só
/// para dar pra testar sem widget/DB/secure storage de verdade —
/// [offlineSessionExpired] já vem calculado (`null` quando não se aplica:
/// sessão desconhecida/não-autenticada, ou online).
@visibleForTesting
String? decideRedirect({
  required SessionState session,
  required bool? online,
  required bool unlocked,
  required bool? offlineSessionExpired,
  required String currentLocation,
}) {
  switch (session) {
    case SessionUnknown():
      return currentLocation == '/splash' ? null : '/splash';

    case SessionUnauthenticated():
    case SessionAuthenticating():
      return currentLocation == '/login' ? null : '/login';

    case SessionAuthenticated():
      // `online == null` enquanto o stream de conectividade ainda não
      // emitiu o primeiro valor — trata como online pra não mostrar um
      // "unlock" de mentira no primeiro frame.
      if (online != false) {
        return _gatedRoutes.contains(currentLocation) ? '/' : null;
      }
      if (offlineSessionExpired ?? true) {
        return currentLocation == '/offline-expired'
            ? null
            : '/offline-expired';
      }
      if (!unlocked) {
        return currentLocation == '/unlock' ? null : '/unlock';
      }
      return _gatedRoutes.contains(currentLocation) ? '/' : null;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
