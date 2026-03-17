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
  bool _isMale = true;
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 30));

  /// null = pantalla de elección, 'create' = crear bebé, 'scan' = escanear
  String? _mode;
  int _createStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final profile = BabyProfile(
      name: _nameController.text.trim(),
      isMale: _isMale,
      birthDate: _birthDate,
      createdAt: DateTime.now(),
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
          padding: const EdgeInsets.all(24),
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          final msg = e.toString();
          _error = msg.contains('no encontrada') || msg.contains('not found')
              ? 'Familia no encontrada. Comprueba que el QR sea correcto.'
              : 'No se pudo unir a la familia. Inténtalo de nuevo.';
        });
      }
    }
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
            left: 24,
            right: 24,
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
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
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
    required this.isMale,
    required this.birthDate,
    required this.step,
    required this.onStepChanged,
    required this.onIsMaleChanged,
    required this.onBirthDateChanged,
    required this.onComplete,
    required this.onBack,
  });

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
                  onPressed: step < 2 ? () => onStepChanged(step + 1) : onComplete,
                  child: Text(step < 2 ? 'Siguiente' : 'Comenzar'),
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
              validator: (v) => v == null || v.trim().isEmpty ? 'Introduce el nombre' : null,
              textCapitalization: TextCapitalization.words,
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
