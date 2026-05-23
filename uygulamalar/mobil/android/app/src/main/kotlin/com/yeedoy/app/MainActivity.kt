package com.yeedoy.app

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import java.util.ArrayDeque

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val pendingPayloads = ArrayDeque<Map<String, Any?>>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DEBUG_PUSH_CHANNEL)
            .setStreamHandler(this)
        debugLog("configureFlutterEngine action=${intent?.action}")
        deliverDebugPushIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        debugLog("onNewIntent action=${intent.action} extras=${intent.extras?.keySet()?.joinToString()}")
        deliverDebugPushIntent(intent)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        debugLog("onListen pending=${pendingPayloads.size}")
        while (pendingPayloads.isNotEmpty()) {
            eventSink?.success(pendingPayloads.removeFirst())
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun deliverDebugPushIntent(intent: Intent?) {
        val payload = extractDebugPushPayload(intent) ?: return
        debugLog("deliverDebugPushIntent payload=$payload sinkReady=${eventSink != null}")
        if (eventSink == null) {
            pendingPayloads.addLast(payload)
            return
        }
        eventSink?.success(payload)
    }

    private fun extractDebugPushPayload(intent: Intent?): Map<String, Any?>? {
        intent ?: return null
        val isDebugPushIntent =
            intent.action == DEBUG_PUSH_ACTION ||
                intent.getBooleanExtra(EXTRA_DEBUG_PUSH, false)
        if (!isDebugPushIntent) return null

        val extras = intent.extras ?: return null
        val payload = linkedMapOf<String, Any?>()
        for (key in extras.keySet()) {
            if (key == EXTRA_DEBUG_PUSH) continue
            payload[key] = normalizeExtraValue(extras.get(key))
        }
        if (payload.isEmpty()) return null

        if (intent.action == DEBUG_PUSH_ACTION) {
            intent.action = null
        }
        intent.removeExtra(EXTRA_DEBUG_PUSH)
        return payload
    }

    private fun normalizeExtraValue(value: Any?): Any? {
        return when (value) {
            null,
            is String,
            is Boolean,
            is Int,
            is Long,
            is Double -> value
            is Float -> value.toDouble()
            else -> value.toString()
        }
    }

    private fun debugLog(message: String) {
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) {
            Log.d(TAG, message)
        }
    }

    companion object {
        private const val TAG = "YeedoyDebugPush"
        private const val DEBUG_PUSH_CHANNEL = "com.yeedoy.app/debug_push_payload"
        private const val DEBUG_PUSH_ACTION = "com.yeedoy.app.DEBUG_PUSH"
        private const val EXTRA_DEBUG_PUSH = "yeedoy_debug_push"
    }
}
