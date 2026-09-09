import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/router/app_router.dart';
import 'package:servory/features/auth/application/session_controller.dart';

void main() {
  const authenticated = SessionAuthenticated(
    userId: 'u1',
    organizationId: 'org1',
  );

  String? redirect({
    required SessionState session,
    bool? online,
    bool unlocked = false,
    bool? expired,
    String from = '/',
  }) {
    return decideRedirect(
      session: session,
      online: online,
      unlocked: unlocked,
      offlineSessionExpired: expired,
      currentLocation: from,
    );
  }

  test('sessão desconhecida sempre vai pro splash', () {
    expect(redirect(session: const SessionUnknown(), from: '/'), '/splash');
    expect(redirect(session: const SessionUnknown(), from: '/splash'), isNull);
  });

  test('sem sessão vai pro login', () {
    expect(
      redirect(session: const SessionUnauthenticated(), from: '/'),
      '/login',
    );
    expect(
      redirect(session: const SessionUnauthenticated(), from: '/login'),
      isNull,
    );
  });

  test('sem sessão: /register, /verify-email e /accept-invite são acessíveis', () {
    expect(
      redirect(session: const SessionUnauthenticated(), from: '/register'),
      isNull,
    );
    expect(
      redirect(session: const SessionAuthenticating(), from: '/verify-email'),
      isNull,
    );
    expect(
      redirect(session: const SessionUnauthenticated(), from: '/accept-invite'),
      isNull,
    );
    // uma rota qualquer fora do fluxo de entrada ainda joga pro login
    expect(
      redirect(session: const SessionUnauthenticated(), from: '/clients'),
      '/login',
    );
  });

  test('autenticado sai de /register e /verify-email', () {
    expect(
      redirect(session: authenticated, online: true, from: '/register'),
      '/',
    );
    expect(
      redirect(session: authenticated, online: true, from: '/verify-email'),
      '/',
    );
  });

  test('autenticado e online: acessa tudo, sai das telas de gate', () {
    expect(redirect(session: authenticated, online: true, from: '/login'), '/');
    expect(
      redirect(session: authenticated, online: true, from: '/unlock'),
      '/',
    );
    expect(
      redirect(session: authenticated, online: true, from: '/clients'),
      isNull,
    );
  });

  test(
    'autenticado, online desconhecido ainda (stream não emitiu): trata como online',
    () {
      expect(
        redirect(session: authenticated, online: null, from: '/clients'),
        isNull,
      );
    },
  );

  test('autenticado, offline, sessão expirada: força tela de expirada', () {
    expect(
      redirect(session: authenticated, online: false, expired: true, from: '/'),
      '/offline-expired',
    );
    expect(
      redirect(
        session: authenticated,
        online: false,
        expired: true,
        from: '/offline-expired',
      ),
      isNull,
    );
  });

  test(
    'autenticado, offline, dentro do prazo, ainda não destravou: força unlock',
    () {
      expect(
        redirect(
          session: authenticated,
          online: false,
          expired: false,
          unlocked: false,
          from: '/',
        ),
        '/unlock',
      );
      expect(
        redirect(
          session: authenticated,
          online: false,
          expired: false,
          unlocked: false,
          from: '/unlock',
        ),
        isNull,
      );
    },
  );

  test(
    'autenticado, offline, dentro do prazo, já destravou: acessa normalmente',
    () {
      expect(
        redirect(
          session: authenticated,
          online: false,
          expired: false,
          unlocked: true,
          from: '/clients',
        ),
        isNull,
      );
      expect(
        redirect(
          session: authenticated,
          online: false,
          expired: false,
          unlocked: true,
          from: '/unlock',
        ),
        '/',
      );
    },
  );
}
