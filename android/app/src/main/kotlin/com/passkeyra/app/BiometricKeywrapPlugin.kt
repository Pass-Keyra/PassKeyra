package com.passkeyra.app

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import android.util.Base64
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * BiometricKeywrapPlugin — Wrap/unwrap d'une clé de session via Keystore Android.
 *
 * Architecture (post-C3 revert) :
 * - Clé AES-256-GCM stockée dans le Keystore matériel (StrongBox best-effort)
 * - PAS de `setUserAuthenticationRequired(true)` : permet le face unlock (Class 1/2)
 *   sur tablettes et Pixel via `local_auth` côté Dart
 * - L'authentification biométrique est faite au niveau applicatif (BiometricPrompt
 *   via `local_auth.authenticate()`) AVANT d'appeler ce plugin. Une fois auth OK,
 *   wrap/unwrap se font sans nouveau prompt.
 *
 * Trade-off conscient : la clé n'est pas cryptographiquement liée à STRONG biometric,
 * mais le modèle correspond à celui de Bitwarden/1Password et permet le face unlock
 * sur tous les appareils.
 */
class BiometricKeywrapPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "biometric_keywrap")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "wrapKeyMaterial" -> {
                    val plaintextBase64 = call.argument<String>("plaintextBase64")
                    if (plaintextBase64.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "plaintextBase64 manquant", null)
                        return
                    }
                    val plaintext = Base64.decode(plaintextBase64, Base64.NO_WRAP)
                    val wrapped = wrap(plaintext)
                    result.success(Base64.encodeToString(wrapped, Base64.NO_WRAP))
                }

                "unwrapKeyMaterial" -> {
                    val wrappedBase64 = call.argument<String>("wrappedBase64")
                    if (wrappedBase64.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "wrappedBase64 manquant", null)
                        return
                    }
                    val wrapped = Base64.decode(wrappedBase64, Base64.NO_WRAP)
                    val plaintext = unwrap(wrapped)
                    result.success(Base64.encodeToString(plaintext, Base64.NO_WRAP))
                }

                "clearWrappingKey" -> {
                    clearKey(KEY_ALIAS)
                    // Nettoyage des anciens alias (V2 issu de C3, désormais inutilisé)
                    clearKey(KEY_ALIAS_V2_LEGACY)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("HW_WRAP_ERROR", e.message, null)
        }
    }

    private fun wrap(plaintext: ByteArray): ByteArray {
        val key = getOrCreateWrappingKey()
        val cipher = Cipher.getInstance(CIPHER_TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val ciphertext = cipher.doFinal(plaintext)
        val iv = cipher.iv

        // Format: [1 byte version][1 byte ivLen][iv][ciphertext]
        val out = ByteArray(2 + iv.size + ciphertext.size)
        out[0] = FORMAT_VERSION
        out[1] = iv.size.toByte()
        System.arraycopy(iv, 0, out, 2, iv.size)
        System.arraycopy(ciphertext, 0, out, 2 + iv.size, ciphertext.size)
        return out
    }

    private fun unwrap(wrapped: ByteArray): ByteArray {
        require(wrapped.size > 3) { "Blob enveloppé invalide" }
        require(wrapped[0] == FORMAT_VERSION) { "Version de blob inconnue" }
        val ivLen = wrapped[1].toInt() and 0xFF
        require(ivLen in 12..16) { "Longueur IV invalide" }
        require(wrapped.size > 2 + ivLen) { "Blob enveloppé incomplet" }

        val iv = wrapped.copyOfRange(2, 2 + ivLen)
        val ciphertext = wrapped.copyOfRange(2 + ivLen, wrapped.size)

        val key = getOrCreateWrappingKey()
        val cipher = Cipher.getInstance(CIPHER_TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv))
        return cipher.doFinal(ciphertext)
    }

    private fun getOrCreateWrappingKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existing = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
        if (existing != null) return existing

        // Tentative avec StrongBox si disponible (Pixel 3+, Samsung S20+).
        // setIsStrongBoxBacked(true) ne throw PAS immédiatement : l'erreur
        // arrive au moment de generateKey() via StrongBoxUnavailableException.
        // On retry sans StrongBox dans ce cas (cas typique : tablettes Samsung A,
        // appareils mid-range, anciens Pixel).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                return generateKey(useStrongBox = true)
            } catch (_: StrongBoxUnavailableException) {
                // Fallback : génération sans StrongBox.
            } catch (_: Exception) {
                // Fallback : autre erreur StrongBox-related.
            }
        }

        return generateKey(useStrongBox = false)
    }

    private fun generateKey(useStrongBox: Boolean): SecretKey {
        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        val specBuilder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(AES_KEY_SIZE_BITS)
            // Clé non exportable stockée dans Android Keystore.
            // L'auth biométrique utilisateur est gérée au niveau applicatif via local_auth
            // (qui accepte WEAK et CONVENIENCE biometric, contrairement au CryptoObject).
            .setUserAuthenticationRequired(false)

        if (useStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            specBuilder.setIsStrongBoxBacked(true)
        }

        keyGenerator.init(specBuilder.build())
        return keyGenerator.generateKey()
    }

    private fun clearKey(alias: String) {
        try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
            if (keyStore.containsAlias(alias)) {
                keyStore.deleteEntry(alias)
            }
        } catch (_: Exception) {
            // Best-effort.
        }
    }

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "passkeyra_biometric_wrap_key_v1"

        // Alias C3 (jamais utilisé en production stable, présent uniquement
        // sur les devices de test ayant essayé C3). Nettoyé via clearWrappingKey().
        private const val KEY_ALIAS_V2_LEGACY = "passkeyra_biometric_wrap_key_v2"

        private const val CIPHER_TRANSFORMATION = "AES/GCM/NoPadding"
        private const val AES_KEY_SIZE_BITS = 256
        private const val GCM_TAG_LENGTH_BITS = 128
        private const val FORMAT_VERSION: Byte = 1
    }
}
