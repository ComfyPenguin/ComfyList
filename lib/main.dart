import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'shared/core/env/firebase_endpoints.dart';
import 'shared/data/local/app_database.dart';
import 'shared/data/local/database_provider.dart';
import 'shared/data/notifications/notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');

  final database = AppDatabase();

  // Inicialización best-effort: si las notificaciones fallan en una plataforma
  // (Linux desktop, p.ej.), la app sigue funcionando sin avisos.
  final notifications = NotificationsService();
  try {
    await notifications.init();
  } catch (e) {
    debugPrint('NotificationsService.init() falló: $e');
  }

  // Google Sign-In solo en Android (fase 1). En otras plataformas el botón
  // de Google está oculto, así que no necesitamos inicializar el SDK.
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: FirebaseEndpoints.googleSignInWebClientId,
      );
    } catch (e) {
      debugPrint('GoogleSignIn.initialize() falló: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const ComfyListApp(),
    ),
  );
}
