import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'edit_dialog_fields.dart';

/// Contenedor de filas estilo lista (edición compacta).
class EditListCard extends StatelessWidget {
  final List<Widget> children;

  const EditListCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.fieldBackground,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        border: Border.all(color: AppTheme.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Fila táctil: icono + etiqueta + valor (p. ej. «Hoy, 08:00») + chevron.
class EditInstantRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;
  final Widget? leading;

  const EditInstantRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showDivider = true,
    this.leading,
  });

  /// Atajo: fila de instante con formato relativo Hoy/Ayer.
  factory EditInstantRow.dateTime({
    Key? key,
    required BuildContext context,
    required String label,
    required DateTime value,
    required VoidCallback onTap,
    IconData icon = Icons.access_time,
    bool showDivider = true,
    Widget? leading,
  }) {
    return EditInstantRow(
      key: key,
      icon: icon,
      label: label,
      value: formatRelativeDateTime(context, value),
      onTap: onTap,
      showDivider: showDivider,
      leading: leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  leading ?? Icon(icon, size: 22, color: AppTheme.textDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.palettePrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: AppTheme.textLight.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 48,
            color: AppTheme.fieldBorder,
          ),
      ],
    );
  }
}

/// Fila con switch a la derecha (p. ej. «Sigue durmiendo»).
class EditSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final Widget? leading;
  final bool showDivider;

  const EditSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.leading,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final leadingWidget =
        leading ??
        (icon != null
            ? Icon(icon, size: 22, color: AppTheme.textDark)
            : const SizedBox(width: 22));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Center(child: leadingWidget),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: AppTheme.palettePrimary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 48,
            color: AppTheme.fieldBorder,
          ),
      ],
    );
  }
}

/// Límite superior habitual para pickers de edición (mañana).
DateTime editPickerMaxDate([DateTime? now]) {
  final n = now ?? DateTime.now();
  return n.add(const Duration(days: 1));
}

/// Abre el datetime picker y devuelve el valor elegido.
Future<DateTime?> pickEditDateTime(
  BuildContext context, {
  required DateTime initial,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) {
  return showDateTimePickerSheet(
    context,
    initialDateTime: initial,
    minimumDate: minimumDate,
    maximumDate: maximumDate ?? editPickerMaxDate(),
  );
}

/// Si [end] ≤ [start], mantiene la hora de fin y la pasa al día siguiente.
DateTime ensureDateTimeAfter(DateTime start, DateTime end) {
  if (end.isAfter(start)) return end;
  var candidate = DateTime(
    start.year,
    start.month,
    start.day,
    end.hour,
    end.minute,
  );
  if (!candidate.isAfter(start)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}
