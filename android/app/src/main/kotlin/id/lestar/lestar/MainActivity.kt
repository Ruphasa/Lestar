package id.lestar.lestar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "id.lestar/screen_brightness",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "set" -> {
                    val value = call.argument<Double>("value")?.toFloat() ?: 1.0f
                    val attributes = window.attributes
                    attributes.screenBrightness = value.coerceIn(0.0f, 1.0f)
                    window.attributes = attributes
                    result.success(null)
                }
                "reset" -> {
                    val attributes = window.attributes
                    attributes.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    window.attributes = attributes
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
