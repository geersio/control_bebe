import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../home/views/main_navigation.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

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

  void _goToMain() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
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
    if (!_formKey.currentState!.validate()) return;

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

    await IsarService.saveBabyProfile(profile);
    await IsarService.completeOnboarding();
    _goToMain();
  }

  Future<void> _joinAndComplete(String familyId) async {
    await IsarService.joinFamily(familyId);
    await IsarService.completeOnboarding();
    _goToMain();
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == 'scan') {
      return _ScanBabyScreen(
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
        onBack: _createStep == 0
            ? () => setState(() => _mode = null)
            : () => setState(() => _createStep--),
      );
    }

    return _ChoiceScreen(
      onCreate: () => setState(() => _mode = 'create'),
      onScan: () => setState(() => _mode = 'scan'),
      canScan: FirebaseService.isAvailable,
    );
  }
}

class _ChoiceScreen extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onScan;
  final bool canScan;

  const _ChoiceScreen({
    required this.onCreate,
    required this.onScan,
    required this.canScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
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
              const SizedBox(height: 40),
              Icon(Icons.child_care, size: 64, color: AppTheme.primaryPink),
              const SizedBox(height: 16),
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
                  borderRadius: BorderRadius.circular(16),
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

class _ScanBabyScreen extends StatefulWidget {
  final Future<void> Function(String familyId) onScanned;
  final VoidCallback onBack;

  const _ScanBabyScreen({required this.onScanned, required this.onBack});

  @override
  State<_ScanBabyScreen> createState() => _ScanBabyScreenState();
}

class _ScanBabyScreenState extends State<_ScanBabyScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _processing = false;
  String? _error;

  /// Mensaje visible al usuario: resumen en español + detalle técnico para diagnosticar el fallo.
  static String _joinFailureDescription(Object error) {
    final technical = _technicalErrorText(error);
    final summary = _joinFailureSummary(error);
    if (technical == summary) return summary;
    return '$summary\n\nDetalle: $technical';
  }

  static String _joinFailureSummary(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permiso denegado en Firebase (reglas de Firestore o sesión).';
        case 'unavailable':
          return 'Firebase no está disponible. Revisa la conexión a internet.';
        case 'not-found':
        case 'not_found':
          return 'Recurso no encontrado en Firebase.';
        default:
          return 'Error de Firebase (${error.code}).';
      }
    }
    if (error is StateError) {
      final m = error.message;
      if (m.contains('no encontrada')) {
        return 'Familia no encontrada. Comprueba que el QR sea correcto.';
      }
      return 'Error al procesar el código del QR.';
    }
    if (error is UnsupportedError) {
      return 'Unirse por QR no está disponible (hace falta Firebase en este dispositivo).';
    }
    return 'No se pudo unir a la familia.';
  }

  static String _technicalErrorText(Object error) {
    if (error is FirebaseException) {
      final msg = error.message;
      if (msg != null && msg.isNotEmpty) return '${error.code}: $msg';
      return error.code;
    }
    return error.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await widget.onScanned(code);
    } catch (e, st) {
      debugPrint('[QR join] $e\n$st');
      if (mounted) {
        setState(() {
          _processing = false;
          _error = _joinFailureDescription(e);
        });
      }
    }
  }

  void _onDetectError(Object error, StackTrace stackTrace) {
    debugPrint('[QR decode] $error\n$stackTrace');
    if (!mounted) return;
    setState(() {
      _processing = false;
      _error =
          'Fallo al leer o decodificar el código.\n\nDetalle: ${error.toString()}';
    });
  }

  Widget _cameraErrorWidget(BuildContext context, MobileScannerException error) {
    final detail = error.errorDetails?.message;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                error.errorCode.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Código interno: ${error.errorCode.name}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Escanear código QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            onDetectError: _onDetectError,
            errorBuilder: _cameraErrorWidget,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: 40,
            left: AppTheme.screenEdgePadding,
            right: AppTheme.screenEdgePadding,
            child: Column(
              children: [
                Text(
                  'Apunta la cámara al código QR del bebé',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
                if (_processing) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ],
            ),
          ),
        ],
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
  final VoidCallback onComplete;
  final VoidCallback onBack;

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
  });

  void _onPrimaryPressed() {
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
    onComplete();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.child_care, size: 64, color: AppTheme.primaryPink),
                const SizedBox(height: 16),
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
                const SizedBox(height: 40),
                Expanded(child: _buildStepContent(context)),
                ElevatedButton(
                  onPressed: _onPrimaryPressed,
                  child: Text(step < 3 ? 'Siguiente' : 'Comenzar'),
                ),
                if (step > 0)
                  TextButton(
                    onPressed: onBack,
                    child: const Text('Atrás'),
                  ),
              ],
            ),
          ),
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
              decoration: const InputDecoration(
                hintText: 'Ej: María, Lucas...',
                prefixIcon: Icon(Icons.badge_outlined),
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
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 16),
                    Text(
                      '${birthDate.day}/${birthDate.month}/${birthDate.year}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
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
              decoration: const InputDecoration(
                hintText: 'Dejar vacío si no la conoces',
                prefixIcon: Icon(Icons.straighten_outlined),
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
          color: selected ? AppTheme.primaryBlue.withValues(alpha: 0.15) : Colors.white,
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
