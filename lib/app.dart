import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/appointments/presentation/providers/appointment_reminders_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/trash/presentation/providers/trash_provider.dart';
import 'features/updates/presentation/providers/app_updates_provider.dart';
import 'routing/app_router.dart';
import 'shared/core/lifecycle/app_lifecycle_controller.dart';
import 'shared/core/theme/app_theme.dart';

class ComfyListApp extends ConsumerWidget {
  const ComfyListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    ref.watch(appLifecycleControllerProvider);
    ref.watch(appointmentRemindersProvider);
    ref.watch(trashPurgeProvider);
    ref.watch(appUpdatesProvider);

    return MaterialApp.router(
      title: 'Comfy List',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Al hacer tap fuera de un campo de texto, quitamos el foco para
        // ocultar el teclado. `translucent` deja pasar los taps de los demás
        // widgets (botones, scroll) y solo captura los del fondo.
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
    );
  }
}
