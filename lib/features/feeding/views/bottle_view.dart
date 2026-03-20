import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/models/enums.dart';

class BottleView extends ConsumerStatefulWidget {
  const BottleView({super.key});

  @override
  ConsumerState<BottleView> createState() => _BottleViewState();
}

class _BottleViewState extends ConsumerState<BottleView> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ml = int.tryParse(_controller.text.trim());
    if (ml == null || ml <= 0) return;

    await IsarService.addFeedingRecord(FeedingRecord(
      type: FeedingType.bottle,
      dateTime: DateTime.now(),
      amountMl: ml,
    ));

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Biberón'),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenEdgePadding,
              24,
              AppTheme.screenEdgePadding,
              24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                'Cantidad (ml)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Ej: 120',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Introduce la cantidad';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Cantidad inválida';
                  return null;
                },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
