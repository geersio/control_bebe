import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../providers/premium_provider.dart';

/// Widget invisible que propaga el estado premium del usuario al documento de
/// familia cada vez que RevenueCat emite un [CustomerInfo] nuevo.
///
/// Se monta una vez dentro del árbol autenticado (ver [MainNavigation]).
class PremiumFamilySync extends ConsumerWidget {
  const PremiumFamilySync({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<CustomerInfo?>>(customerInfoProvider, (_, next) {
      final info = next.valueOrNull;
      if (info != null) {
        syncFamilyPremium(info);
      }
    });
    return const SizedBox.shrink();
  }
}
