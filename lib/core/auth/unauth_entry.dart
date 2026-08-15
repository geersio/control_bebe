import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/providers/onboarding_draft_provider.dart';

/// Destino cuando no hay sesión Firebase.
enum UnauthEntry { onboarding, login }

const _kPreferLoginKey = 'unauth_prefer_login';

/// Tras cerrar sesión preferimos login; en primera instalación, onboarding.
final unauthEntryProvider =
    AsyncNotifierProvider<UnauthEntryNotifier, UnauthEntry>(
      UnauthEntryNotifier.new,
    );

class UnauthEntryNotifier extends AsyncNotifier<UnauthEntry> {
  @override
  Future<UnauthEntry> build() async {
    final sp = await SharedPreferences.getInstance();
    final preferLogin = sp.getBool(_kPreferLoginKey) ?? false;
    return preferLogin ? UnauthEntry.login : UnauthEntry.onboarding;
  }

  Future<void> markLoginPreferred() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPreferLoginKey, true);
    state = const AsyncData(UnauthEntry.login);
  }

  /// Vuelve al onboarding sin borrar el borrador (p. ej. cuenta ya tiene perfil).
  Future<void> preferOnboardingKeepDraft() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPreferLoginKey, false);
    state = const AsyncData(UnauthEntry.onboarding);
  }

  Future<void> startNewProfile() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPreferLoginKey, false);
    ref.read(onboardingDraftProvider.notifier).reset();
    state = const AsyncData(UnauthEntry.onboarding);
  }
}
