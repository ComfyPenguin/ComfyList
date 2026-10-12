package andypr.comfylist

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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

        // El comprobador de actualizaciones baja el APK y lo manda al instalador
        // del sistema. Android no instala nada en silencio: esto abre el diálogo
        // y el toque final lo da quien usa la app. El APK va por un content://
        // del FileProvider, que es lo único que el instalador acepta desde
        // Android 7.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "comfy_list/updates",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> installApk(call.argument<String>("path"), result)

                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("noFile", null, null)
            return
        }

        // Sin este permiso del sistema el instalador se cierra sin más: mejor
        // decirlo antes de intentarlo.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            result.error("unknownSources", null, null)
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                File(path),
            )
            startActivity(
                Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                },
            )
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("noActivity", null, null)
        } catch (e: IllegalArgumentException) {
            // El fichero ya no está donde se bajó.
            result.error("noFile", null, null)
        }
    }
}
