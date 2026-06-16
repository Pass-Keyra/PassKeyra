package com.passkeyra.app

import android.content.ClipData
import android.content.ClipDescription
import android.content.Context
import android.os.Build
import android.os.PersistableBundle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SecureClipboardPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "secure_clipboard")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "copySecure" -> {
                val text = call.argument<String>("text") ?: ""
                val sensitive = call.argument<Boolean>("sensitive") ?: false
                copySecure(text, sensitive, result)
            }
            "clearClipboard" -> {
                clearClipboard(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun copySecure(text: String, sensitive: Boolean, result: Result) {
        try {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager

            if (sensitive) {
                // Création du ClipData avec label vide pour réduire la visibilité
                val clip = ClipData.newPlainText("", text)

                // Android 13+ (API 33+) : Utiliser EXTRA_IS_SENSITIVE pour masquer complètement
                // le contenu dans la bulle de preview du clipboard
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    // Marquer le contenu comme sensible
                    clip.description.extras = PersistableBundle().apply {
                        putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                    }
                }
                // Note : Pour Android 12 et inférieur, le label vide réduit mais ne masque pas
                // complètement la preview. Il n'existe pas d'API standard pour cela.

                clipboard.setPrimaryClip(clip)
            } else {
                // Contenu non sensible
                clipboard.setPrimaryClip(ClipData.newPlainText("PassKeyra", text))
            }

            result.success("Copie réussie")
        } catch (e: Exception) {
            result.error("COPY_ERROR", "Erreur lors de la copie: ${e.message}", null)
        }
    }

    private fun clearClipboard(result: Result) {
        try {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
            result.success("Presse-papier effacé")
        } catch (e: Exception) {
            result.error("CLEAR_ERROR", "Erreur lors de l'effacement: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}


