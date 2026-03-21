import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../auth/views/login_view.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final BabyProfile? initialBaby;
  final void Function(BabyProfile profile)? onProfileSaved;

  const SettingsPage({super.key, this.initialBaby, this.onProfileSaved});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  BabyProfile? _baby;

  @override
  void initState() {
    super.initState();
    _baby = widget.initialBaby;
  }

  Future<void> _editProfile() async {
    final baby = _baby ?? BabyProfile(
      name: '',
      isMale: true,
      birthDate: DateTime.now().subtract(const Duration(days: 30)),
    );
    final nameController = TextEditingController(text: baby.name);
    final heightController = TextEditingController(
      text: baby.heightCm == null
          ? ''
          : (baby.heightCm == baby.heightCm!.roundToDouble()
              ? '${baby.heightCm!.round()}'
              : '${baby.heightCm}'),
    );
    var isMale = baby.isMale;
    var birthDate = baby.birthDate;

    BabyProfile? result;
    try {
      result = await showModalBottomSheet<BabyProfile?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.dialogRadius)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Editar perfil del bebé',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text(
                  'Género',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _GenderChip(
                        label: 'Niño',
                        icon: Icons.male,
                        selected: isMale,
                        onTap: () => setModalState(() => isMale = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderChip(
                        label: 'Niña',
                        icon: Icons.female,
                        selected: !isMale,
                        onTap: () => setModalState(() => isMale = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Altura (cm)',
                    hintText: 'Opcional, ej. 58',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: birthDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                      lastDate: DateTime.now(),
                      locale: const Locale('es', 'ES'),
                    );
                    if (date != null) setModalState(() => birthDate = date);
                  },
                  borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.fieldBackground,
                      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                      border: Border.all(color: AppTheme.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('d MMM yyyy', 'es').format(birthDate),
                          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: AppTheme.textLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          final heightRaw = heightController.text.trim().replaceAll(',', '.');
                          double? heightCm;
                          if (heightRaw.isEmpty) {
                            heightCm = null;
                          } else {
                            heightCm = double.tryParse(heightRaw);
                            if (heightCm == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Altura inválida')),
                              );
                              return;
                            }
                            if (heightCm < 25 || heightCm > 120) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Altura debe estar entre 25 y 120 cm'),
                                ),
                              );
                              return;
                            }
                          }
                          final profile = baby.copyWith(
                            name: name,
                            isMale: isMale,
                            birthDate: birthDate,
                            heightCm: heightCm,
                            setHeightCm: true,
                          );
                          widget.onProfileSaved?.call(profile);
                          if (ctx.mounted) Navigator.pop(ctx, profile);
                          IsarService.saveBabyProfile(profile);
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    } finally {
      nameController.dispose();
      heightController.dispose();
    }
    if (result != null && mounted) setState(() => _baby = result);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AuthService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cerrar sesión: $e')),
          );
        }
        return;
      }
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenEdgePadding,
                16,
                AppTheme.screenEdgePadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsCard(
                    title: 'Perfil del Bebé',
                    leading: FaIcon(
                      FontAwesomeIcons.baby,
                      color: AppTheme.primaryPink,
                      size: 22,
                    ),
                    children: [
                      if (_baby != null) ...[
                        _ProfileRow(
                          label: 'Nombre',
                          value: _baby!.name,
                        ),
                        const SizedBox(height: 12),
                        _ProfileRow(
                          label: 'Fecha de nacimiento',
                          value: DateFormat('d MMM yyyy', 'es').format(_baby!.birthDate),
                        ),
                        const SizedBox(height: 12),
                        _ProfileRow(
                          label: 'Altura',
                          value: _baby!.heightCm != null
                              ? '${_baby!.heightCm == _baby!.heightCm!.roundToDouble() ? _baby!.heightCm!.round() : _baby!.heightCm} cm'
                              : '—',
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Sin perfil configurado',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _editProfile,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar perfil'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: AppTheme.primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'Compartir Familia',
                    leading: Icon(Icons.share, color: AppTheme.primaryBlue, size: 24),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Invita a otros miembros de la familia escaneando el código QR.',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const _ShowQRButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'Cerrar sesión',
                    titleColor: Theme.of(context).colorScheme.error,
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                      size: 24,
                    ),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: Icon(
                            Icons.logout,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          label: const Text('Cerrar sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.fieldBackground,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        border: Border.all(color: AppTheme.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowQRButton extends StatelessWidget {
  const _ShowQRButton();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: IsarService.getFamilyId(),
      builder: (context, snapshot) {
        final familyId = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (familyId == null || familyId.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Compartir familia solo disponible con Firebase.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
            ),
          );
        }
        return _QRButton(familyId: familyId);
      },
    );
  }
}

class _QRButton extends StatefulWidget {
  final String familyId;

  const _QRButton({required this.familyId});

  @override
  State<_QRButton> createState() => _QRButtonState();
}

class _QRButtonState extends State<_QRButton> {
  bool _showQR = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _showQR = !_showQR),
            icon: Icon(_showQR ? Icons.visibility_off : Icons.qr_code_2, size: 20),
            label: Text(_showQR ? 'Ocultar QR' : 'Mostrar QR para invitar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
              ),
            ),
          ),
        ),
        if (_showQR) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.fieldBorder),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: widget.familyId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppTheme.textDark,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Escanea para unirte a la familia',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget leading;
  final List<Widget> children;
  final Color? titleColor;

  const _SettingsCard({
    required this.title,
    required this.leading,
    required this.children,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final titleCol = titleColor ?? AppTheme.textDark;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Center(child: leading),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: titleCol,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue.withValues(alpha: 0.15) : AppTheme.fieldBackground,
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: selected ? AppTheme.primaryBlue : AppTheme.textLight),
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
