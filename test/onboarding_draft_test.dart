import 'package:control_bebe/core/models/baby_sex.dart';
import 'package:control_bebe/features/onboarding/models/onboarding_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializa y restaura todo el borrador del onboarding', () {
    final original = OnboardingDraft(
      step: 8,
      hasBorn: true,
      name: 'Luna',
      sex: BabySex.female,
      birthDate: DateTime(2025, 11, 3),
      weightKg: 7.4,
      heightCm: 66.5,
      wantNotifications: true,
      pendingCommit: true,
    );

    final restored = OnboardingDraft.fromJson(original.toJson());

    expect(restored.step, original.step);
    expect(restored.hasBorn, original.hasBorn);
    expect(restored.name, original.name);
    expect(restored.sex, original.sex);
    expect(restored.birthDate, original.birthDate);
    expect(restored.weightKg, original.weightKg);
    expect(restored.heightCm, original.heightCm);
    expect(restored.wantNotifications, original.wantNotifications);
    expect(restored.pendingCommit, original.pendingCommit);
  });

  test('ignora valores desconocidos y aplica valores seguros', () {
    final restored = OnboardingDraft.fromJson({
      'step': 3,
      'sex': 'unknown',
      'birthDateMs': DateTime(2026, 1, 2).millisecondsSinceEpoch,
    });

    expect(restored.step, 3);
    expect(restored.sex, isNull);
    expect(restored.name, isEmpty);
    expect(restored.pendingCommit, isFalse);
  });
}
