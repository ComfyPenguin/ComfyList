import 'dart:io';

import 'package:crypto/crypto.dart';

/// SHA-256 de [file] en hexadecimal minúscula.
///
/// Va por trozos para no cargar en memoria un APK entero.
Future<String> sha256OfFile(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

/// El `digest` que publica GitHub de un asset llega como `sha256:2151b604…`.
/// Cualquier otro algoritmo devuelve `null`, porque solo se sabe comprobar ese.
String? sha256FromDigest(String? digest) {
  const prefix = 'sha256:';
  if (digest == null || !digest.startsWith(prefix)) return null;
  final hex = digest.substring(prefix.length).trim().toLowerCase();
  return hex.isEmpty ? null : hex;
}
