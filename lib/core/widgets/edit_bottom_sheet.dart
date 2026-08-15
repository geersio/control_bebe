import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/edit_dialog_theme.dart';

double _editSheetBottomPadding(BuildContext context) {
  final vi = MediaQuery.viewInsetsOf(context).bottom;
  return vi + AppTheme.extraBottomSpacing;
}

/// Bottom sheet reutilizable para formularios de edición.
class EditBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const EditBottomSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.dialogRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: _editSheetBottomPadding(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: EditDialogTheme.contentPadding,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EditDialogTheme.contentPadding,
                  child: child,
                ),
              ),
              Padding(
                padding: EditDialogTheme.bottomPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onCancel,
                        child: Text(l10n.commonCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: EditDialogTheme.saveButtonStyle,
                        onPressed: onSave,
                        child: Text(l10n.commonSave),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
