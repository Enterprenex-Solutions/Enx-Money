package com.enxmoney.app.enx_money

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val DEVICE_CHANNEL = "com.enxmoney.app/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getModel" -> {
                    try {
                        val manufacturer = Build.MANUFACTURER?.replaceFirstChar { 
                            if (it.isLowerCase()) it.titlecase() else it.toString() 
                        } ?: ""
                        val model = Build.MODEL ?: ""
                        val fullModel = if (model.startsWith(manufacturer, ignoreCase = true)) {
                            model
                        } else {
                            "$manufacturer $model".trim()
                        }
                        result.success(if (fullModel.isNotEmpty()) fullModel else "Android Device")
                    } catch (e: Exception) {
                        result.success("Android Device")
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
