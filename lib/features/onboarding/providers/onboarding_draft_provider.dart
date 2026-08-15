import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/isar_service.dart';
import '../../../core/db/storage_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../../core/models/baby_sex.dart';
import '../../../core/models/height_record.dart';
import '../../../core/models/weight_record.dart';
import '../../../core/providers/baby_profile_provider.dart';
import '../../../core/providers/notification_prefs_provider.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/services/next_feeding_notification_service.dart';
import '../../../core/utils/baby_age_calendar.dart';
import '../models/onboarding_draft.dart';
import '../utils/feeding_interval_for_age.dart';

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
      OnboardingDraftNotifier.new,
    );

const _onboardingDraftStorageKey = 'onboarding_draft_v1';
OnboardingDraft? _persistedInitialDraft;
Future<void> _draftWriteQueue = Future<void>.value();

class ExistingBabyProfileException implements Exception {
  const ExistingBabyProfileException();
}

/// Tras rechazar un commit porque la cuenta ya tiene perfil: mostrar diálogo.
final onboardingExistingProfileAlertProvider = StateProvider<bool>(
  (ref) => false,
);

/// Restaura el borrador antes de crear el [ProviderScope].
Future<void> initializeOnboardingDraftPersistence() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_onboardingDraftStorageKey);
  if (raw == null || raw.isEmpty) return;
  try {
    _persistedInitialDraft = OnboardingDraft.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  } catch (_) {
    await prefs.remove(_onboardingDraftStorageKey);
  }
}

void _persistDraft(OnboardingDraft draft) {
  _persistedInitialDraft = draft;
  final encoded = jsonEncode(draft.toJson());
  _draftWriteQueue = _draftWriteQueue.catchError((_) {}).then((_) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardingDraftStorageKey, encoded);
  });
}

void _removePersistedDraft() {
  _persistedInitialDraft = null;
  _draftWriteQueue = _draftWriteQueue.catchError((_) {}).then((_) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingDraftStorageKey);
  });
}

class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  Future<void>? _commitInFlight;

  @override
  OnboardingDraft build() =>
      _persistedInitialDraft ?? OnboardingDraft.initial();

  void _setState(OnboardingDraft value) {
    state = value;
    _persistDraft(value);
  }

  /// Espera a que el JSON del borrador quede escrito en SharedPreferences.
  /// Necesario antes del login email: AuthWrapper puede reconstruir la app
  /// en cuanto hay sesión y el commit debe ver pendingCommit persistido.
  Future<void> flushPersistence() async {
    await _draftWriteQueue.catchError((_) {});
  }

  void reset() {
    state = OnboardingDraft.initial();
    _removePersistedDraft();
  }

  void setStep(int step) => _setState(state.copyWith(step: step));

  void setHasBorn(bool value) {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    _setState(state.copyWith(hasBorn: value, birthDate: date));
  }

  /// Elige nacido/embarazo y avanza al paso de nombre en un solo update.
  void selectHasBornAndContinue(bool value) {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    _setState(state.copyWith(hasBorn: value, birthDate: date, step: 1));
  }

  void setName(String name) =>
      _setState(state.copyWith(name: BabyProfile.sanitizeName(name)));

  void setSex(BabySex sex) => _setState(state.copyWith(sex: sex));

  /// Elige sexo y avanza al paso de fecha en un solo update.
  void selectSexAndContinue(BabySex sex) {
    _setState(state.copyWith(sex: sex, step: 3));
  }

  void setBirthDate(DateTime date) =>
      _setState(state.copyWith(birthDate: date));

  void setWeightKg(double? kg) =>
      _setState(state.copyWith(weightKg: kg, clearWeight: kg == null));

  void setHeightCm(double? cm) =>
      _setState(state.copyWith(heightCm: cm, clearHeight: cm == null));

  void setWantNotifications(bool value) =>
      _setState(state.copyWith(wantNotifications: value));

  void markPendingCommit() => _setState(state.copyWith(pendingCommit: true));

  void clearPendingCommit() => _setState(state.copyWith(pendingCommit: false));

  /// Persiste perfil, medidas y preferencias tras autenticarse.
  /// Seguro ante llamadas concurrentes (email + AppInitializer).
  Future<void> commit({String defaultName = 'Baby'}) async {
    final existing = _commitInFlight;
    if (existing != null) {
      await existing;
      return;
    }
    final done = _commitOnce(defaultName: defaultName);
    _commitInFlight = done;
    try {
      await done;
    } finally {
      if (identical(_commitInFlight, done)) {
        _commitInFlight = null;
      }
    }
  }

  Future<void> _commitOnce({required String defaultName}) async {
    // Snapshot antes de cualquier await: el registro email puede competir con
    // AppInitializer y no debe ver un state ya reseteado a medias.
    final draft = state;
    if (!draft.pendingCommit && !draft.hasName && draft.step < 1) {
      // Nada que guardar (p. ej. segundo caller tras reset exitoso).
      return;
    }

    final name = draft.hasName ? draft.displayName : defaultName;
    final ageMonths = BabyAgeCalendar.fractionalMonthsAt(
      draft.birthDate,
      DateTime.now(),
    );
    final interval = feedingIntervalPresetForAgeMonths(ageMonths);

    final profile = BabyProfile(
      name: BabyProfile.sanitizeName(name),
      isMale: draft.sex?.isMaleFlag,
      birthDate: draft.birthDate,
      createdAt: DateTime.now(),
      heightCm: draft.heightCm,
      expectedFeedingIntervalMinutes: interval,
    );

    // Evita reutilizar familyId de una sesión anterior tras borrar/crear cuenta.
    storage.clearRemoteSessionCache();
    await IsarService.initialize();
    final created = await IsarService.createBabyProfileIfAbsent(profile);
    if (!created) throw const ExistingBabyProfileException();

    final now = DateTime.now();
    if (draft.weightKg != null && draft.weightKg! > 0) {
      await IsarService.addWeightRecord(
        WeightRecord(weightKg: draft.weightKg!, dateTime: now),
      );
    }
    if (draft.heightCm != null && draft.heightCm! > 0) {
      await IsarService.addHeightRecord(
        HeightRecord(heightCm: draft.heightCm!, dateTime: now),
      );
    }

    unawaited(IsarService.completeOnboarding());

    final wantNotify = draft.wantNotifications == true;
    unawaited(ref.read(notifyNextFeedingProvider.notifier).set(wantNotify));
    if (wantNotify) {
      unawaited(NextFeedingNotificationService.syncFromStorage());
    }

    ref.invalidate(familyIdProvider);
    ref.invalidate(babyProfileProvider);
    reset();
  }
}
