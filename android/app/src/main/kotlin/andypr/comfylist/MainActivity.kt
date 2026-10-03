package andypr.comfylist

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Las pantallas de acceso piden blindar la pantalla: sin capturas y sin
        // miniatura en el conmutador de apps mientras se escribe la contraseña.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "comfy_list/screen_security",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    if (call.argument<Boolean>("secure") == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
