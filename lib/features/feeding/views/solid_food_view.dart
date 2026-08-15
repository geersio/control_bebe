import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/solid_food_display.dart';

class SolidFoodView extends ConsumerStatefulWidget {
  const SolidFoodView({super.key});

  @override
  ConsumerState<SolidFoodView> createState() => _SolidFoodViewState();
}

class _SolidFoodViewState extends ConsumerState<SolidFoodView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  SolidQuantityUnit _unit = SolidQuantityUnit.grams;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onUnitSelectionChanged(Set<SolidQuantityUnit> selection) {
    final nu = selection.first;
    if (nu == _unit) return;
    setState(() {
      _unit = nu;
      if (nu == SolidQuantityUnit.units) {
        final raw = _quantityController.text.trim();
        if (raw.contains(',') || raw.contains('.')) {
          final g = tryParseSolidQuantity(raw, SolidQuantityUnit.grams);
          if (g != null) {
            _quantityController.text = g.round().toString();
          } else {
            _quantityController.clear();
          }
        }
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final q = tryParseSolidQuantity(_quantityController.text, _unit);
    if (q == null || !q.isFinite) return;
    final record = FeedingRecord(
      type: FeedingType.solidFood,
      dateTime: DateTime.now(),
      solidName: name,
      solidQuantity: q,
      solidUnit: _unit,
    );
    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          title: Text(l10n.solidFoodTitle),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenEdgePadding,
                  24,
                  AppTheme.screenEdgePadding,
                  16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.solidFoodNameLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: l10n.solidFoodNameHint,
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.solidFoodValidatorNameEmpty;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.solidFoodQuantityLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: _unit == SolidQuantityUnit.grams,
                          signed: false,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          if (_unit == SolidQuantityUnit.grams)
                            SolidGramsQuantityInputFormatter()
                          else
                            SolidUnitsQuantityInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: _unit == SolidQuantityUnit.grams
                              ? l10n.solidFoodQuantityHintGrams
                              : l10n.solidFoodQuantityHintUnits,
                        ),
                        validator: (v) =>
                            validateSolidQuantityInput(v, _unit, l10n),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<SolidQuantityUnit>(
                        segments: [
                          ButtonSegment(
                            value: SolidQuantityUnit.grams,
                            label: Text(l10n.solidFoodUnitGrams),
                          ),
                          ButtonSegment(
                            value: SolidQuantityUnit.units,
                            label: Text(l10n.solidFoodUnitUnits),
                          ),
                        ],
                        selected: {_unit},
                        onSelectionChanged: _onUnitSelectionChanged,
                      ),
                    ],
                  ),
                ),
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(l10n.commonSave),
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
}
