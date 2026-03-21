import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../auth/views/family_qr_join_screen.dart';

class OnboardingView extends ConsumerStatefulWidget {
  /// Si no es null, se llama al terminar (perfil creado o unión por QR). Evita reemplazar la raíz del [Navigator].
  final Future<void> Function()? onFinished;

  const OnboardingView({super.key, this.onFinished});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  bool _isMale = true;
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 30));

  /// null = pantalla de elección, 'create' = crear bebé, 'scan' = escanear
  String? _mode;
  int _createStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _notifyFinished() async {
    if (!mounted) return;
    if (widget.onFinished != null) {
      await widget.onFinished!();
    }
  }

  Future<void> _completeCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        setState(() => _createStep = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Introduce el nombre del bebé')),
        );
      }
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Revisa la talla: número entre 25 y 130 cm, o deja el campo vacío',
            ),
          ),
        );
      }
      return;
    }

    double? heightCm;
    final heightText = _heightController.text.trim();
    if (heightText.isNotEmpty) {
      heightCm = double.tryParse(heightText.replaceAll(',', '.'));
    }

    final profile = BabyProfile(
      name: name,
      isMale: _isMale,
      birthDate: _birthDate,
      createdAt: DateTime.now(),
      heightCm: heightCm,
    );

    try {
      await IsarService.saveBabyProfile(profile);
      await IsarService.completeOnboarding();
      if (!mounted) return;
      await _notifyFinished();
    } on FirebaseException catch (e) {
      debugPrint('[onboarding] guardar perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'permission-denied'
                  ? 'Sin permiso en Firebase (reglas o sesión). Revisa Firestore.'
                  : 'No se pudo guardar (${e.code}). Revisa conexión y Firebase.',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[onboarding] guardar perfil: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    }
  }

  Future<void> _joinAndComplete(String familyId) async {
    await IsarService.joinFamily(familyId);
    await IsarService.completeOnboarding();
    await _notifyFinished();
  }

  Future<void> _confirmExitToLogin() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: const Text('¿Salir?'),
        content: const Text(
          'Cerrarás sesión y volverás a la pantalla de inicio de sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Salir',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == 'scan') {
      return FamilyQrJoinScreen(
        onScanned: _joinAndComplete,
        onBack: () => setState(() => _mode = null),
      );
    }

    if (_mode == 'create') {
      return _CreateBabyScreen(
        formKey: _formKey,
        nameController: _nameController,
        heightController: _heightController,
        isMale: _isMale,
        birthDate: _birthDate,
        step: _createStep,
        onStepChanged: (s) => setState(() => _createStep = s),
        onIsMaleChanged: (v) => setState(() => _isMale = v),
        onBirthDateChanged: (d) => setState(() => _birthDate = d),
        onComplete: _completeCreate,
        onExitToLogin: _confirmExitToLogin,
        onBack: _createStep == 0
            ? () => setState(() => _mode = null)
            : () => setState(() => _createStep--),
      );
    }

    return _ChoiceScreen(
      onCreate: () => setState(() => _mode = 'create'),
      onScan: () => setState(() => _mode = 'scan'),
      canScan: FirebaseService.isAvailable,
      onExitToLogin: _confirmExitToLogin,
    );
  }
}

class _ChoiceScreen extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onScan;
  final VoidCallback onExitToLogin;
  final bool canScan;

  const _ChoiceScreen({
    required this.onCreate,
    required this.onScan,
    required this.onExitToLogin,
    required this.canScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenEdgePadding,
            24,
            AppTheme.screenEdgePadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bienvenido a MiBebé Diario',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Cómo quieres empezar?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      const SizedBox(height: 40),
                      _ChoiceCard(
                        icon: Icons.add_circle_outline,
                        iconColor: AppTheme.primaryBlue,
                        title: 'Crear bebé',
                        subtitle: 'Configura un nuevo perfil desde cero',
                        onTap: onCreate,
                      ),
                      const SizedBox(height: 16),
                      _ChoiceCard(
                        icon: Icons.qr_code_scanner,
                        iconColor: AppTheme.primaryGreen,
                        title: 'Escanear bebé',
                        subtitle: canScan
                            ? 'Únete a un bebé ya creado escaneando su código QR'
                            : 'Requiere Firebase para compartir',
                        onTap: canScan ? onScan : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onExitToLogin,
                icon: Icon(Icons.logout, size: 20, color: AppTheme.textLight),
                label: Text(
                  'Salir y volver al inicio de sesión',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: enabled ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                ),
                child: Icon(icon, color: enabled ? iconColor : AppTheme.textLight, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: enabled ? AppTheme.textDark : AppTheme.textLight,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLight,
                          ),
                    ),
                  ],
                ),
              ),
              if (enabled) Icon(Icons.chevron_right, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateBabyScreen extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController heightController;
  final bool isMale;
  final DateTime birthDate;
  final int step;
  final void Function(int) onStepChanged;
  final void Function(bool) onIsMaleChanged;
  final void Function(DateTime) onBirthDateChanged;
  final Future<void> Function() onComplete;
  final VoidCallback onBack;
  final Future<void> Function() onExitToLogin;

  const _CreateBabyScreen({
    required this.formKey,
    required this.nameController,
    required this.heightController,
    required this.isMale,
    required this.birthDate,
    required this.step,
    required this.onStepChanged,
    required this.onIsMaleChanged,
    required this.onBirthDateChanged,
    required this.onComplete,
    required this.onBack,
    required this.onExitToLogin,
  });

  Future<void> _onPrimaryPressed() async {
    if (step == 0) {
      if (formKey.currentState?.validate() ?? false) {
        onStepChanged(1);
      }
      return;
    }
    if (step < 3) {
      onStepChanged(step + 1);
      return;
    }
    await onComplete();
  }

  static String? _optionalHeightCmValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return 'Introduce un número válido (ej: 52,5)';
    if (n < 25 || n > 130) return 'Altura habitual entre 25 y 130 cm';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('Configurar bebé'),
        actions: [
          TextButton(
            onPressed: () => onExitToLogin(),
            child: Text(
              'Salir',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenEdgePadding,
                  8,
                  AppTheme.screenEdgePadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryPink.withValues(alpha: 0.15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.baby,
                            color: AppTheme.primaryPink,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Crear perfil del bebé',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configura los datos de tu bebé',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLight,
                          ),
                    ),
                    const SizedBox(height: 32),
                    _buildStepContent(context),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenEdgePadding,
                  0,
                  AppTheme.screenEdgePadding,
                  AppTheme.screenEdgePadding,
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _onPrimaryPressed(),
                    child: Text(
                      step < 3 ? 'Siguiente' : 'Comenzar',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre del bebé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Ej: María, Lucas...',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  color: AppTheme.textLight,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Género',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GenderOption(
                    label: 'Niño',
                    icon: Icons.boy,
                    selected: isMale,
                    onTap: () => onIsMaleChanged(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _GenderOption(
                    label: 'Niña',
                    icon: Icons.girl,
                    selected: !isMale,
                    onTap: () => onIsMaleChanged(false),
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha de nacimiento',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: birthDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                  lastDate: DateTime.now(),
                  locale: const Locale('es', 'ES'),
                );
                if (date != null) onBirthDateChanged(date);
              },
              borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.fieldBackground,
                  borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                  border: Border.all(color: AppTheme.fieldBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppTheme.textLight),
                    const SizedBox(width: 16),
                    Text(
                      '${birthDate.day}/${birthDate.month}/${birthDate.year}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textDark,
                          ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se usa para calcular percentiles OMS (0-12 meses)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Talla / altura',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Opcional. La altura actual en centímetros (aparece en el perfil).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Dejar vacío si no la conoces',
                prefixIcon: Icon(
                  Icons.straighten_outlined,
                  color: AppTheme.textLight,
                ),
                suffixText: 'cm',
              ),
              validator: _optionalHeightCmValidator,
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.15)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: selected ? AppTheme.primaryBlue : AppTheme.textLight),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primaryBlue : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
