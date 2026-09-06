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
import '../../features/companies/presentation/company_detail_screen.dart';
import '../../features/companies/presentation/company_list_screen.dart';
import '../../features/equipments/presentation/equipment_detail_screen.dart';
import '../../features/equipments/presentation/equipment_list_screen.dart';
import '../../features/labels/presentation/label_batch_detail_screen.dart';
import '../../features/labels/presentation/label_batch_list_screen.dart';
import '../../features/labels/presentation/label_template_edit_screen.dart';
import '../../features/labels/presentation/label_template_list_screen.dart';
import '../../features/locations/presentation/location_detail_screen.dart';
import '../../features/locations/presentation/location_list_screen.dart';
import '../../features/me/presentation/home_screen.dart';
import '../../features/reference/data/type_catalog_repository.dart';
import '../../features/reference/presentation/type_catalog_screen.dart';
import '../../features/service_orders/presentation/service_order_detail_screen.dart';
import '../../features/service_orders/presentation/service_order_list_screen.dart';
import '../../features/service_orders/presentation/service_order_report_screen.dart';
import '../connectivity/connectivity_provider.dart';
import '../providers.dart';

/// Spec §18.3: uma sessão offline vale por 7 dias desde a última vez que o
/// aparelho confirmou com o servidor (login ou refresh bem-sucedido).
const offlineSessionTtl = Duration(days: 7);

const _gatedRoutes = {'/login', '/splash', '/unlock', '/offline-expired'};

/// Instância única de `GoRouter`: sessão, conectividade e trava de app — as 3
/// coisas que decidem pra onde redirecionar — chegam pelo `refreshListenable`,
/// que faz o `redirect` rodar de novo sem recriar o router. Recriar o router a
/// cada mudança de estado desmontava a árvore de navegação inteira e junto com
/// ela o estado das telas (ex.: a mensagem de erro do login sumia no frame
/// seguinte a um 401).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  void bump(Object? _, Object? _) => refresh.value++;
  ref.listen(sessionControllerProvider, bump);
  ref.listen(isOnlineProvider, bump);
  ref.listen(appLockControllerProvider, bump);

  final store = ref.read(secureStoreProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final session = ref.read(sessionControllerProvider);
      final online = ref.read(isOnlineProvider).value;
      final unlocked = ref.read(appLockControllerProvider);

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
        path: '/companies',
        builder: (_, _) => const CompanyListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                CompanyDetailScreen(companyId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/label-batches',
        builder: (_, _) => const LabelBatchListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                LabelBatchDetailScreen(batchId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/type-catalog',
        builder: (_, state) => TypeCatalogScreen(
          initial: state.uri.queryParameters['kind'] == 'service-order'
              ? TypeCatalog.serviceOrderType
              : TypeCatalog.equipmentType,
        ),
      ),
      GoRoute(
        path: '/label-templates',
        builder: (_, _) => const LabelTemplateListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => LabelTemplateEditScreen(
              templateId: state.pathParameters['id']!,
            ),
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
            routes: [
              GoRoute(
                path: 'report',
                builder: (_, state) => ServiceOrderReportScreen(
                  serviceOrderId: state.pathParameters['id']!,
                ),
              ),
            ],
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
