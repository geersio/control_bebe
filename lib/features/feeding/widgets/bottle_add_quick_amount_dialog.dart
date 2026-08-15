import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../core/models/measurement_units.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/widgets/app_toast.dart';

/// Diálogo para añadir un atajo de cantidad. El [TextEditingController] vive
/// en este State y solo se libera en [dispose], tras cerrar la ruta.
class BottleAddQuickAmountDialog extends StatefulWidget {
  const BottleAddQuickAmountDialog({
    super.key,
    required this.prefs,
    required this.existingAmountsMl,
  });

  final MeasurementPrefs prefs;
  final List<int> existingAmountsMl;

  @override
  State<BottleAddQuickAmountDialog> createState() =>
      _BottleAddQuickAmountDialogState();
}

class _BottleAddQuickAmountDialogState extends State<BottleAddQuickAmountDialog> {
  final _input = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final ml = parseVolumeInputToMl(_input.text, widget.prefs);
    if (ml == null || ml <= 0 || ml > kMaxReasonableVolumeMl) {
      FocusManager.instance.primaryFocus?.unfocus();
      AppToast.show(context, message: l10n.bottleValidatorInvalid);
      return;
    }
    if (findMatchingQuickAmountMl(ml, widget.existingAmountsMl) != null) {
      FocusManager.instance.primaryFocus?.unfocus();
      AppToast.show(context, message: l10n.bottleQuickAmountDuplicate);
      return;
    }
    _submitting = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(ml);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.bottleQuickAmountAddTitle),
      content: TextField(
        controller: _input,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        autofocus: true,
        decoration: InputDecoration(
          hintText: bottleVolumeHint(widget.prefs, l10n),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
