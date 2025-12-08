package com.example.qibla_ar_finder

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.qibla_ar_finder/ar"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startARView" -> {
                    val qiblaBearing = call.argument<Double>("qibla_bearing")?.toFloat() ?: 0f
                    startARView(qiblaBearing)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startARView(qiblaBearing: Float) {
        val intent = Intent(this, ARViewActivity::class.java)
        intent.putExtra("qibla_bearing", qiblaBearing)
        startActivity(intent)
    }
}
