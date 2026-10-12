import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_updates_provider.dart';
import 'update_available_dialog.dart';

/// Abre el aviso de versión nueva.
///
/// Vive dentro del shell, que es quien tiene un [Navigator] donde montarlo, y
/// no pinta nada: solo escucha. El provider decide cuándo toca —una vez por
/// build y arranque—, así que aquí no hay que acordarse de nada.
class UpdateAvailableWatcher extends ConsumerWidget {
  const UpdateAvailableWatcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(updatePromptProvider, (_, next) {
      if (next == null) return;
      ref.read(updatePromptProvider.notifier).consume();
      unawaited(UpdateAvailableDialog.show(context, next));
    });

    return const SizedBox.shrink();
  }
}
