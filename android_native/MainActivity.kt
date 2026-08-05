package app.kitsunebyte

/**
 * Drop-in MainActivity for Termux RUN_COMMAND integration.
 *
 * After `flutter create .` in the project root:
 *  1. Replace android/app/src/main/kotlin/.../MainActivity.kt with this file
 *     (adjust package name to match your applicationId).
 *  2. Add to AndroidManifest.xml inside <application>:
 *       <queries>
 *         <package android:name="com.termux" />
 *       </queries>
 *  3. Request the user enable:
 *       Termux → Settings → "Allow external apps" / RUN_COMMAND permission
 *
 * Channel: kitsune_byte/termux
 * Methods: isTermuxInstalled, runCommand
 */

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "kitsune_byte/termux"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTermuxInstalled" -> {
                        result.success(isPackageInstalled("com.termux"))
                    }
                    "runCommand" -> {
                        val path = call.argument<String>("path")
                        val args = call.argument<List<String>>("arguments") ?: emptyList()
                        val workdir = call.argument<String>("workdir")
                        val background = call.argument<Boolean>("background") ?: true
                        if (path.isNullOrBlank()) {
                            result.error("bad_args", "path required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent().apply {
                                setClassName(
                                    "com.termux",
                                    "com.termux.app.RunCommandService"
                                )
                                action = "com.termux.RUN_COMMAND"
                                putExtra("com.termux.RUN_COMMAND_PATH", path)
                                putExtra(
                                    "com.termux.RUN_COMMAND_ARGUMENTS",
                                    args.toTypedArray()
                                )
                                if (workdir != null) {
                                    putExtra("com.termux.RUN_COMMAND_WORKDIR", workdir)
                                }
                                putExtra("com.termux.RUN_COMMAND_BACKGROUND", background)
                                putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
                            }
                            startService(intent)
                            result.success(
                                mapOf(
                                    "ok" to true,
                                    "dispatched" to true,
                                    "note" to "Termux RUN_COMMAND dispatched (async; no stdout capture yet)"
                                )
                            )
                        } catch (e: Exception) {
                            result.success(
                                mapOf("ok" to false, "error" to (e.message ?: "intent failed"))
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isPackageInstalled(pkg: String): Boolean {
        return try {
            packageManager.getPackageInfo(pkg, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }
}
