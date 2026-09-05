package com.servory.servory

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (>= 2.x) exige uma FragmentActivity para exibir o BiometricPrompt;
// FlutterActivity padrão causa "no_fragment_activity" em runtime.
class MainActivity : FlutterFragmentActivity()
