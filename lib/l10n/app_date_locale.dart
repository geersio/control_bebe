import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Código de idioma para [DateFormat] e intl (p. ej. "es", "en").
String dateFormatLanguageCode(BuildContext context) {
  final loc = Localizations.localeOf(context);
  return loc.languageCode;
}

DateTime _civilDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Etiqueta corta de instante: «Hoy, 08:00», «Ayer, 22:21» o «11 ago, 22:21».
String formatRelativeDateTime(
  BuildContext context,
  DateTime value, {
  DateTime? now,
}) {
  final l10n = AppLocalizations.of(context)!;
  final dateCode = dateFormatLanguageCode(context);
  final ref = now ?? DateTime.now();
  final today = _civilDay(ref);
  final yesterday = today.subtract(const Duration(days: 1));
  final day = _civilDay(value);
  final time = DateFormat('HH:mm', dateCode).format(value);
  if (day == today) return '${l10n.today}, $time';
  if (day == yesterday) return '${l10n.yesterday}, $time';
  return '${DateFormat('d MMM', dateCode).format(value)}, $time';
}
