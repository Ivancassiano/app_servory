import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/app_lock_controller.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/offline_expired_screen.dart';
import '../../features/auth/presentation/accept_invite_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/unlock_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/companies/presentation/company_detail_screen.dart';
import '../../features/companies/presentation/company_list_screen.dart';
import '../../features/labels/presentation/label_batch_detail_screen.dart';
import '../../features/labels/presentation/label_batch_list_screen.dart';
import '../../features/labels/presentation/label_template_edit_screen.dart';
import '../../features/labels/presentation/label_template_list_screen.dart';
import '../../features/labels/presentation/qr_label_print_screen.dart';
import '../../features/items/presentation/item_detail_screen.dart';
import '../../features/items/presentation/item_fields_screen.dart';
import '../../features/items/presentation/item_list_screen.dart';
import '../../features/locations/presentation/location_detail_screen.dart';
import '../../features/locations/presentation/location_list_screen.dart';
import '../../features/me/presentation/home_screen.dart';
import '../../features/me/presentation/person_screen.dart';
import '../../features/members/presentation/members_screen.dart';
import '../../features/me/presentation/settings_screen.dart';
import '../../features/reference/data/type_catalog_repository.dart';
import '../../features/reference/presentation/type_catalog_screen.dart';
import '../../features/service_orders/presentation/service_order_detail_screen.dart';
import '../../features/service_orders/presentation/service_order_list_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/service_orders/presentation/service_order_item_screen.dart';
import '../../features/service_orders/presentation/service_order_report_screen.dart';
import '../connectivity/connectivity_provider.dart';
import '../providers.dart';
import '../widgets/splash_screen.dart';

/// Spec §18.3: uma sessão offline vale por 7 dias desde a última vez que o
/// aparelho confirmou com o servidor (login ou refresh bem-sucedido).
const offlineSessionTtl = Duration(days: 7);

const _gatedRoutes = {
  '/login',
  '/register',
  '/verify-email',
  '/accept-invite',
  '/splash',
  '/unlock',
  '/offline-expired',
};

/// Telas do fluxo de entrada acessíveis sem sessão (login, auto-cadastro,
/// confirmação de e-mail e aceitar convite). Fora dessas, quem não está
/// logado vai pro /login.
const _authFlowRoutes = {
  '/login',
  '/register',
  '/verify-email',
  '/accept-invite',
};

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
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/accept-invite',
        builder: (_, _) => const AcceptInviteScreen(),
      ),
      GoRoute(path: '/unlock', builder: (_, _) => const UnlockScreen()),
      GoRoute(
        path: '/offline-expired',
        builder: (_, _) => const OfflineExpiredScreen(),
      ),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/me/person', builder: (_, _) => const PersonScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/users', builder: (_, _) => const MembersScreen()),
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
        path: '/items',
        builder: (_, state) => ItemListScreen(
          clientId: state.uri.queryParameters['clientId'],
          locationId: state.uri.queryParameters['locationId'],
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => ItemDetailScreen(
              itemId: state.pathParameters['id']!,
              presetClientId: state.uri.queryParameters['clientId'],
              presetLocationId: state.uri.queryParameters['locationId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/locations',
        builder: (_, state) => LocationListScreen(
          clientId: state.uri.queryParameters['clientId'],
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => LocationDetailScreen(
              locationId: state.pathParameters['id']!,
              presetClientId: state.uri.queryParameters['clientId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/item-fields',
        builder: (_, _) => const ItemFieldsScreen(),
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
          kind: switch (state.uri.queryParameters['kind']) {
            'service-order' => TypeCatalog.serviceOrderType,
            'task' => TypeCatalog.taskType,
            _ => TypeCatalog.itemType,
          },
        ),
      ),
      GoRoute(
        path: '/qr-label',
        builder: (_, state) => QrLabelPrintScreen(
          publicCode: state.uri.queryParameters['code'] ?? '',
          title: state.uri.queryParameters['title'],
          subtitle: state.uri.queryParameters['subtitle'],
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
        builder: (_, state) => ServiceOrderListScreen(
          clientId: state.uri.queryParameters['clientId'],
          itemId: state.uri.queryParameters['itemId'],
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final q = state.uri.queryParameters;
              final ids = (q['presetItemIds'] ?? '')
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList();
              return ServiceOrderDetailScreen(
                serviceOrderId: state.pathParameters['id']!,
                presetClientId: q['presetClientId'],
                presetItemIds: ids,
                fromTaskId: q['fromTaskId'],
              );
            },
            routes: [
              GoRoute(
                path: 'report',
                builder: (_, state) => ServiceOrderReportScreen(
                  serviceOrderId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'items/:itemId',
                builder: (_, state) => ServiceOrderItemScreen(
                  serviceOrderId: state.pathParameters['id']!,
                  itemId: state.pathParameters['itemId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/tasks',
        builder: (_, state) => TaskListScreen(
          clientId: state.uri.queryParameters['clientId'],
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => TaskDetailScreen(
              taskId: state.pathParameters['id']!,
              presetClientId: state.uri.queryParameters['clientId'],
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
      return _authFlowRoutes.contains(currentLocation) ? null : '/login';

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
