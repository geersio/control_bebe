import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/isar_service.dart';
import '../firebase/firebase_service.dart';
import '../providers/record_stream_providers.dart';
import '../providers/notification_prefs_provider.dart';
import '../providers/baby_profile_provider.dart';
import '../providers/session_reset.dart';
import '../services/next_feeding_notification_service.dart';
import '../widgets/splash_screen.dart';
import 'auth_service.dart';
import 'unauth_entry.dart';
import '../../features/auth/views/family_qr_join_screen.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/home/views/main_navigation.dart';
import '../../features/onboarding/providers/onboarding_draft_provider.dart';
import '../../features/onboarding/views/onboarding_flow_view.dart';
import '../../features/paywall/views/paywall_view.dart';
import '../../l10n/app_localizations.dart';

/// Raíz de autenticación: onboarding (nuevos), login, invitado QR o app.
/// Debe permanecer como primera ruta del [Navigator] para que [authStateChanges]
/// siga activo al cerrar sesión.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!FirebaseService.isAvailable) {
      return const AppInitializer();
    }
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.data == null) {
          // Primera instalación → onboarding.
          // Tras cerrar sesión → login (con "Crear perfil nuevo").
          final entry = ref.watch(unauthEntryProvider);
          return entry.when(
            loading: () => const SplashScreen(),
            error: (_, _) =>
                const OnboardingFlowView(alreadyAuthenticated: false),
            data: (dest) => dest == UnauthEntry.login
                ? const LoginView(asUnauthRoot: true)
                : const OnboardingFlowView(alreadyAuthenticated: false),
          );
        }
        final user = snapshot.data!;
        if (user.isAnonymous) {
          return const _AnonymousGuestGate();
        }
        return const AppInitializer();
      },
    );
  }
}

class _AnonymousGuestGate extends StatefulWidget {
  const _AnonymousGuestGate();

  @override
  State<_AnonymousGuestGate> createState() => _AnonymousGuestGateState();
}

class _AnonymousGuestGateState extends State<_AnonymousGuestGate> {
  Future<bool>? _familyCheck;

  @override
  void initState() {
    super.initState();
    _familyCheck = _userHasFamilyId();
  }

  Future<bool> _userHasFamilyId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final id = doc.data()?['familyId'] as String?;
    return id != null && id.isNotEmpty;
  }

  Future<void> _onQrScanned(String familyId) async {
    await IsarService.joinFamily(familyId);
    await IsarService.completeOnboarding();
    await IsarService.initialize();
    if (mounted) {
      setState(() {
        _familyCheck = _userHasFamilyId();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _familyCheck,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done && snap.data == true) {
          return const AppInitializer();
        }
        return FamilyQrJoinScreen(
          key: const ValueKey<String>('anonymous_guest_qr'),
          onScanned: _onQrScanned,
          onBack: () => AuthService.signOut(),
        );
      },
    );
  }
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isReady = false;
  bool _needsOnboarding = false;
  bool _committingDraft = false;
  bool _showPaywallAfterCommit = false;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // Asegura que un markPendingCommit reciente (email) ya está aplicado.
    await ref.read(onboardingDraftProvider.notifier).flushPersistence();
    if (!mounted) return;
    invalidateAuthSessionProviders(ref);
    final draft = ref.read(onboardingDraftProvider);
    if (draft.pendingCommit) {
      if (mounted) {
        setState(() {
          _committingDraft = true;
          _isReady = true;
        });
      }
      await _commitPendingDraft();
      return;
    }

    final needsOnboarding = await IsarService.needsOnboarding();
    if (!needsOnboarding) {
      // Un perfil remoto válido prevalece sobre cualquier borrador local antiguo.
      ref.read(onboardingDraftProvider.notifier).reset();
    }
    if (mounted) {
      resetRecordHistoryFirestoreDays(ref);
      ref.invalidate(weightRecordsForChartStreamProvider);
      ref.invalidate(diaperRecordsStreamProvider);
      ref.invalidate(feedingRecordsStreamProvider);
      ref.invalidate(notifyNextFeedingProvider);
      setState(() {
        _needsOnboarding = needsOnboarding;
        _isReady = true;
      });
      if (!needsOnboarding) {
        unawaited(NextFeedingNotificationService.syncFromStorage());
      }
    }
  }

  Future<void> _commitPendingDraft() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(onboardingDraftProvider.notifier)
          .commit(defaultName: l10n.onboardingFlowBabyDefaultName);
      if (!mounted) return;
      ref.invalidate(babyProfileProvider);
      if (!mounted) return;
      setState(() {
        _committingDraft = false;
        _needsOnboarding = false;
        _showPaywallAfterCommit = true;
      });
      unawaited(NextFeedingNotificationService.syncFromStorage());
      if (!mounted) return;
      await showAppPaywall(context);
      if (!mounted) return;
      setState(() => _showPaywallAfterCommit = false);
    } on ExistingBabyProfileException {
      // No entrar al perfil existente: volver al paso de cuenta del onboarding.
      final draft = ref.read(onboardingDraftProvider);
      ref.read(onboardingDraftProvider.notifier).clearPendingCommit();
      if (draft.step != 8) {
        ref.read(onboardingDraftProvider.notifier).setStep(8);
      }
      ref.read(onboardingExistingProfileAlertProvider.notifier).state = true;
      await ref.read(unauthEntryProvider.notifier).preferOnboardingKeepDraft();
      try {
        await AuthService.signOut();
      } catch (_) {}
      // AuthWrapper mostrará de nuevo OnboardingFlowView tras el signOut.
    } catch (e) {
      debugPrint('[auth_shell] commit onboarding draft: $e');
      if (!mounted) return;
      // Si falla el guardado, volver al onboarding autenticado.
      ref.read(onboardingDraftProvider.notifier).clearPendingCommit();
      setState(() {
        _committingDraft = false;
        _needsOnboarding = true;
        _isReady = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingFlowSaveFail('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const SplashScreen();
    }
    if (_committingDraft || _showPaywallAfterCommit) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_needsOnboarding) {
      return OnboardingFlowView(
        alreadyAuthenticated: true,
        onFinished: () async {
          unawaited(NextFeedingNotificationService.syncFromStorage());
          if (!mounted) return;
          setState(() => _needsOnboarding = false);
        },
      );
    }
    return const MainNavigation();
  }
}
