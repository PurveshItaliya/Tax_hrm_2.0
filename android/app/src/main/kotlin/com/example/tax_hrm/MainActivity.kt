package com.hrmnewapp.taxhrm
import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "punch_widget/open"
    private var methodChannel: MethodChannel? = null
    private val TAG = "TaxHrmMainActivity"

    override fun getInitialRoute(): String {
        Log.d(TAG, "getInitialRoute called. intent action: ${intent?.action}")
        if (intent?.action == "PUNCH_WIDGET_TAP") {
            Log.d(TAG, "getInitialRoute: returning /punch_widget")
            return "/punch_widget"
        }
        val route = super.getInitialRoute() ?: "/"
        Log.d(TAG, "getInitialRoute: returning $route")
        return route
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine called")
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "move_to_background") {
                finishAndRemoveTask()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called with action: ${intent.action}")
        setIntent(intent) // Important: update the intent so onResume sees the new intent
        handleIntent(intent, "onNewIntent")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume called with action: ${intent?.action}")
        handleIntent(intent, "onResume")
    }

    private fun handleIntent(intent: Intent?, source: String) {
        Log.d(TAG, "handleIntent called from $source with action: ${intent?.action}")
        if (intent?.action == "PUNCH_WIDGET_TAP") {
            Log.d(TAG, "handleIntent: Invoking open_punch on methodChannel")
            methodChannel?.invokeMethod("open_punch", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d(TAG, "MethodChannel open_punch success")
                }
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "MethodChannel open_punch error: $errorCode, $errorMessage")
                }
                override fun notImplemented() {
                    Log.e(TAG, "MethodChannel open_punch not implemented")
                }
            })
            // Clear the action so it's not triggered again on resume/configuration change
            intent.action = ""
            Log.d(TAG, "handleIntent: intent.action cleared")
        }
    }
}