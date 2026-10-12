import 'dart:io';

import 'package:crypto/crypto.dart';

/// SHA-256 de [file] en hexadecimal minúscula.
///
/// Va por trozos para no cargar en memoria un APK entero.
Future<String> sha256OfFile(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();
