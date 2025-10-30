package com.example.warehouse_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URL
import com.zebra.sdk.comm.BluetoothConnection
import com.zebra.sdk.comm.Connection
import com.zebra.sdk.comm.ConnectionException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "zebra_print"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "printPdfFromUrl" -> {
                    val btAddress = call.argument<String>("btAddress")
                    val url = call.argument<String>("url")
                    if (btAddress.isNullOrBlank() || url.isNullOrBlank()) {
                        result.error("ARG", "Missing btAddress or url", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val bytes = URL(url).openStream().use { it.readBytes() }
                            val conn: Connection = BluetoothConnection(btAddress)
                            conn.open()
                            try {
                                conn.write(bytes)
                            } finally {
                                conn.close()
                            }
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("PRINT", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }
}
