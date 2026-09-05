import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` quando alguma interface de rede está ativa. Não garante internet
/// de verdade (proxy cativo, wifi sem sinal) — é só o sinal usado para
/// decidir se vale tentar chamar a API; uma falha real ainda vira
/// `ApiException` tratada normalmente pelo `AuthInterceptor`.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasConnection(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasConnection);
});

bool _hasConnection(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);
