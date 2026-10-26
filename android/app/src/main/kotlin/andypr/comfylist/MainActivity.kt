package andypr.comfylist

import android.app.DownloadManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
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

                "enqueueDownload" -> guarded(result) {
                    enqueueDownload(
                        url = call.argument<String>("url")!!,
                        fileName = call.argument<String>("fileName")!!,
                        title = call.argument<String>("title")!!,
                    )
                }

                "downloadStatus" -> guarded(result) {
                    downloadStatus(call.argument<Number>("id")!!.toLong())
                }

                "removeDownload" -> guarded(result) {
                    downloadManager.remove(call.argument<Number>("id")!!.toLong())
                    null
                }

                else -> result.notImplemented()
            }
        }
    }

    private val downloadManager by lazy { getSystemService(DownloadManager::class.java) }

    private inline fun guarded(result: MethodChannel.Result, block: () -> Any?) {
        try {
            result.success(block())
        } catch (e: Exception) {
            result.error("downloadFailed", e.message, null)
        }
    }

    // El APK lo baja el DownloadManager y no la app: Android corta la red a
    // las apps en segundo plano y la descarga moriría al salir de ComfyList.
    private fun enqueueDownload(url: String, fileName: String, title: String): Long {
        // Si la app murió a mitad, la descarga de esa URL sigue viva en el
        // sistema: se reengancha en vez de empezar otra. Las de versiones
        // anteriores se borran con su APK.
        downloadManager.query(DownloadManager.Query()).use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_ID))
                if (cursor.string(DownloadManager.COLUMN_URI) != url) {
                    downloadManager.remove(id)
                    continue
                }
                when (cursor.status()) {
                    DownloadManager.STATUS_FAILED -> downloadManager.remove(id)
                    DownloadManager.STATUS_SUCCESSFUL ->
                        if (cursor.localFile()?.exists() == true) return id else downloadManager.remove(id)
                    else -> return id
                }
            }
        }

        // Con el destino ocupado el DownloadManager renombra en vez de pisar.
        File(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), fileName).delete()
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(title)
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setDestinationInExternalFilesDir(this, Environment.DIRECTORY_DOWNLOADS, fileName)
        return downloadManager.enqueue(request)
    }

    private fun downloadStatus(id: Long): Map<String, Any?> {
        downloadManager.query(DownloadManager.Query().setFilterById(id)).use { cursor ->
            // Cancelada desde la notificación: ya no existe.
            if (!cursor.moveToFirst()) return mapOf("status" to "failed")
            return mapOf(
                "status" to when (cursor.status()) {
                    DownloadManager.STATUS_SUCCESSFUL -> "successful"
                    DownloadManager.STATUS_FAILED -> "failed"
                    else -> "running"
                },
                "received" to cursor.getLong(
                    cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR),
                ),
                "total" to cursor.getLong(
                    cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES),
                ),
                "reason" to cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON)),
                "path" to cursor.localFile()?.path,
            )
        }
    }

    private fun Cursor.string(column: String): String? = getString(getColumnIndexOrThrow(column))

    private fun Cursor.status(): Int = getInt(getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))

    private fun Cursor.localFile(): File? =
        string(DownloadManager.COLUMN_LOCAL_URI)?.let { Uri.parse(it).path }?.let(::File)

    private fun installApk(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("noFile", null, null)
            return
        }

        // Sin este permiso del sistema el instalador se cierra sin más: se abre
        // directamente su ajuste para ComfyList.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ),
            )
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
