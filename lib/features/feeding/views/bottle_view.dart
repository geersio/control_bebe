import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/models/measurement_units.dart';
import '../../../core/providers/measurement_prefs_provider.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/models/enums.dart';
import '../models/bottle_quick_amounts_prefs.dart';
import '../widgets/bottle_add_quick_amount_dialog.dart';
import '../widgets/bottle_quick_amount_pills.dart';

class BottleView extends ConsumerStatefulWidget {
  const BottleView({super.key});

  @override
  ConsumerState<BottleView> createState() => _BottleViewState();
}

class _BottleViewState extends ConsumerState<BottleView> {
  final _controller = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  BottleQuickAmountsPrefs _quickAmounts = BottleQuickAmountsPrefs.empty;
  int? _selectedAmountMl;

  @override
  void initState() {
    super.initState();
    _loadQuickAmounts();
  }

  Future<void> _loadQuickAmounts() async {
    final stored = await BottleQuickAmountsPrefs.load();
    if (mounted) setState(() => _quickAmounts = stored);
  }

  List<int> get _amountsMl => _quickAmounts.displayAmountsMl();

  Future<BottleQuickAmountAddResult> _addCustomAmount(int ml) async {
    final current = await BottleQuickAmountsPrefs.load();
    if (current.containsAmount(ml)) {
      return BottleQuickAmountAddResult.alreadyExists;
    }
    if (current.customMl.length >= BottleQuickAmountsPrefs.maxCustomCount) {
      return BottleQuickAmountAddResult.maxReached;
    }
    final next = await current.addCustomAmount(ml);
    if (next == null) return BottleQuickAmountAddResult.alreadyExists;
    _quickAmounts = next;
    return BottleQuickAmountAddResult.saved;
  }

  Future<void> _removeQuickAmount(int ml) async {
    final next = await _quickAmounts.removeAmount(ml);
    if (!mounted) return;
    setState(() {
      _quickAmounts = next;
      if (_selectedAmountMl == ml) _selectedAmountMl = null;
    });
  }

  void _applyQuickAmount(int ml, MeasurementPrefs prefs) {
    final text = prefs.liquid == LiquidUnitMode.milliliters
        ? '$ml'
        : trimFlOzDisplay(mlToUsFlOzNum(ml));
    _controller.text = text;
    _selectedAmountMl = ml;
    _formKey.currentState?.validate();
  }

  void _applyAmountMl(int ml, MeasurementPrefs prefs) {
    final clamped = ml.clamp(0, kMaxReasonableVolumeMl);
    final text = prefs.liquid == LiquidUnitMode.milliliters
        ? (clamped == 0 ? '' : '$clamped')
        : (clamped == 0 ? '' : trimFlOzDisplay(mlToUsFlOzNum(clamped)));
    _controller.text = text;
    _syncSelectedFromField(prefs);
    _formKey.currentState?.validate();
  }

  void _adjustAmountByMl(int deltaMl, MeasurementPrefs prefs) {
    final currentMl = parseVolumeInputToMl(_controller.text, prefs) ?? 0;
    setState(() => _applyAmountMl(currentMl + deltaMl, prefs));
  }

  void _syncSelectedFromField(MeasurementPrefs prefs) {
    final match = _amountsMl.where(
      (ml) => isBottleQuickAmountSelected(ml, _controller.text, prefs),
    );
    _selectedAmountMl = match.isEmpty ? null : match.first;
  }

  void _onPillAmountTap(int ml, MeasurementPrefs prefs) {
    setState(() => _applyQuickAmount(ml, prefs));
  }

  Future<void> _openAddCustomShortcut() async {
    final prefs =
        ref.read(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();

    final addedMl = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BottleAddQuickAmountDialog(
        prefs: prefs,
        existingAmountsMl: _amountsMl,
      ),
    );

    if (!mounted || addedMl == null) return;

    final existing = _amountsMl;
    final matching = findMatchingQuickAmountMl(addedMl, existing);
    final result = matching != null
        ? BottleQuickAmountAddResult.alreadyExists
        : await _addCustomAmount(addedMl);
    final amountToApply = matching ?? addedMl;

    if (!mounted) return;

    // Tras cerrar la ruta del diálogo: un solo setState en el siguiente frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _applyQuickAmount(amountToApply, prefs);
      });
      final l10n = AppLocalizations.of(context)!;
      final message = switch (result) {
        BottleQuickAmountAddResult.saved => null,
        BottleQuickAmountAddResult.alreadyExists =>
          l10n.bottleQuickAmountDuplicate,
        BottleQuickAmountAddResult.maxReached =>
          l10n.bottleQuickAmountMaxCustom,
      };
      if (message != null) {
        AppToast.show(
          context,
          message: message,
          variant: result == BottleQuickAmountAddResult.maxReached
              ? AppToastVariant.warning
              : AppToastVariant.info,
        );
      }
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final prefs =
        ref.read(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final ml = parseVolumeInputToMl(_controller.text, prefs);
    if (ml == null || ml <= 0 || ml > kMaxReasonableVolumeMl) return;

    final record = FeedingRecord(
      type: FeedingType.bottle,
      dateTime: DateTime.now(),
      amountMl: ml,
    );
    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final liquidUnitLabel = prefs.liquid == LiquidUnitMode.milliliters
        ? l10n.unitMlLong
        : l10n.unitFlOzLong;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(l10n.bottleTitle),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.screenEdgePadding,
                      24,
                      AppTheme.screenEdgePadding,
                      16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 40).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BottleAmountStepperField(
                              controller: _controller,
                              focusNode: _amountFocusNode,
                              unitLabel: liquidUnitLabel,
                              hintText: '0',
                              onMinusTap: () => _adjustAmountByMl(-5, prefs),
                              onPlusTap: () => _adjustAmountByMl(5, prefs),
                              onChanged: (_) =>
                                  setState(() => _syncSelectedFromField(prefs)),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return l10n.bottleValidatorEmpty;
                                }
                                final parsed = parseVolumeInputToMl(v, prefs);
                                if (parsed == null ||
                                    parsed <= 0 ||
                                    parsed > kMaxReasonableVolumeMl) {
                                  return l10n.bottleValidatorInvalid;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Material(
              color: AppTheme.background,
              elevation: 8,
              shadowColor: Colors.black26,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.screenEdgePadding,
                    12,
                    AppTheme.screenEdgePadding,
                    12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.bottleQuickAmountsSectionTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BottleQuickAmountPills(
                        prefs: prefs,
                        amountsMl: _amountsMl,
                        selectedAmountMl: _selectedAmountMl,
                        addLabel: l10n.bottleQuickAmountAdd,
                        onAmountTap: (ml) => _onPillAmountTap(ml, prefs),
                        onAddTap: _openAddCustomShortcut,
                        onRemoveAmount: _removeQuickAmount,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: Text(l10n.commonSave),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottleAmountStepperField extends StatelessWidget {
  const _BottleAmountStepperField({
    required this.controller,
    required this.focusNode,
    required this.unitLabel,
    required this.hintText,
    required this.onMinusTap,
    required this.onPlusTap,
    required this.onChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String unitLabel;
  final String hintText;
  final VoidCallback onMinusTap;
  final VoidCallback onPlusTap;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.palettePrimary;
    final amountTextStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppTheme.textDark,
      letterSpacing: -1.5,
    );
    return Semantics(
      textField: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StepperRoundButton(
                  icon: Icons.remove_rounded,
                  onTap: onMinusTap,
                  color: accent,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    onChanged: onChanged,
                    onTapOutside: (_) => focusNode.unfocus(),
                    style: amountTextStyle,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: amountTextStyle?.copyWith(
                        color: AppTheme.textLight.withValues(alpha: 0.65),
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      errorMaxLines: 2,
                    ),
                    validator: validator,
                  ),
                ),
                const SizedBox(width: 24),
                _StepperRoundButton(
                  icon: Icons.add_rounded,
                  onTap: onPlusTap,
                  color: accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unitLabel.toUpperCase(),
            style: GoogleFonts.nunitoSans(
              textStyle: Theme.of(context).textTheme.titleMedium,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperRoundButton extends StatelessWidget {
  const _StepperRoundButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon, color: color, size: 40),
        ),
      ),
    );
  }
}
