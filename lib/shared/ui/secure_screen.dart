import 'package:flutter/widgets.dart';

import '../platform/screen_security.dart';

/// Activa el blindaje contra capturas mientras [child] esté en pantalla y lo
/// levanta al salir, para no dejar la app entera sin poder capturarse.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
