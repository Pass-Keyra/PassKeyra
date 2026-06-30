package com.passkeyra.app

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
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
 * BiometricKeywrapPlugin — Wrap/unwrap d'une cle de session via Keystore Android.
 *
 * Biometrie ADAPTATIVE :
 * - Class 3 (BIOMETRIC_STRONG) : cle Keystore avec setUserAuthenticationRequired(true),
 *   wrap/unwrap via BiometricPrompt + CryptoObject. Binding cryptographique materiel.
 * - Class 1/2 : cle Keystore sans auth requise (comme avant), l'auth biometrique
 *   est faite en amont cote applicatif via local_auth.
 *
 * Le plugin detecte la capacite de l'appareil via canUseStrongBiometric et expose
 * des methodes separees pour chaque chemin (wrapKeyMaterial vs wrapKeyMaterialStrong).
 */
class BiometricKeywrapPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: FragmentActivity? = null
    private var pendingResult: Result? = null

    // =========================================================================
    // FlutterPlugin lifecycle
    // =========================================================================

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "biometric_keywrap")
        channel.setMethodCallHandler(this)
        applicationContext = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    // =========================================================================
    // ActivityAware lifecycle (requis pour BiometricPrompt + CryptoObject)
    // =========================================================================

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // =========================================================================
    // MethodChannel dispatch
    // =========================================================================

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // --- Chemin faible (Class 1/2, inchange) ---
            "wrapKeyMaterial" -> {
                try {
                    val plaintextBase64 = call.argument<String>("plaintextBase64")
                    if (plaintextBase64.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "plaintextBase64 manquant", null)
                        return
                    }
                    val plaintext = Base64.decode(plaintextBase64, Base64.NO_WRAP)
                    val wrapped = wrap(plaintext)
                    result.success(Base64.encodeToString(wrapped, Base64.NO_WRAP))
                } catch (e: Exception) {
                    result.error("HW_WRAP_ERROR", e.message, null)
                }
            }

            "unwrapKeyMaterial" -> {
                try {
                    val wrappedBase64 = call.argument<String>("wrappedBase64")
                    if (wrappedBase64.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "wrappedBase64 manquant", null)
                        return
                    }
                    val wrapped = Base64.decode(wrappedBase64, Base64.NO_WRAP)
                    val plaintext = unwrap(wrapped)
                    result.success(Base64.encodeToString(plaintext, Base64.NO_WRAP))
                } catch (e: Exception) {
                    result.error("HW_WRAP_ERROR", e.message, null)
                }
            }

            // --- Detection capacite ---
            "canUseStrongBiometric" -> {
                try {
                    val ctx = activity?.applicationContext ?: applicationContext
                    if (ctx == null) {
                        result.success(false)
                        return
                    }
                    val biometricManager = BiometricManager.from(ctx)
                    val canAuth = biometricManager.canAuthenticate(
                        BiometricManager.Authenticators.BIOMETRIC_STRONG
                    )
                    result.success(canAuth == BiometricManager.BIOMETRIC_SUCCESS)
                } catch (e: Exception) {
                    result.success(false)
                }
            }

            // --- Chemin fort (Class 3, BiometricPrompt + CryptoObject) ---
            "wrapKeyMaterialStrong" -> handleWrapStrong(call, result)
            "unwrapKeyMaterialStrong" -> handleUnwrapStrong(call, result)

            // --- Nettoyage ---
            "clearWrappingKey" -> {
                clearKey(KEY_ALIAS)
                clearKey(KEY_ALIAS_V2_LEGACY)
                clearKey(KEY_ALIAS_STRONG)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // =========================================================================
    // Chemin faible (v1, inchange sauf backward compat v2-weak dans unwrap)
    // =========================================================================

    private fun wrap(plaintext: ByteArray): ByteArray {
        val key = getOrCreateWrappingKey()
        val cipher = Cipher.getInstance(CIPHER_TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val ciphertext = cipher.doFinal(plaintext)
        val iv = cipher.iv

        // Format v1: [VERSION=1 | IV_LEN | IV | CIPHERTEXT]
        val out = ByteArray(2 + iv.size + ciphertext.size)
        out[0] = FORMAT_VERSION
        out[1] = iv.size.toByte()
        System.arraycopy(iv, 0, out, 2, iv.size)
        System.arraycopy(ciphertext, 0, out, 2 + iv.size, ciphertext.size)
        return out
    }

    private fun unwrap(wrapped: ByteArray): ByteArray {
        require(wrapped.size > 3) { "Blob enveloppe invalide" }

        return when (wrapped[0]) {
            FORMAT_VERSION -> {
                // v1: [VERSION=1 | IV_LEN | IV | CIPHERTEXT]
                val ivLen = wrapped[1].toInt() and 0xFF
                require(ivLen in 12..16) { "Longueur IV invalide" }
                require(wrapped.size > 2 + ivLen) { "Blob enveloppe incomplet" }

                val iv = wrapped.copyOfRange(2, 2 + ivLen)
                val ciphertext = wrapped.copyOfRange(2 + ivLen, wrapped.size)

                val key = getOrCreateWrappingKey()
                val cipher = Cipher.getInstance(CIPHER_TRANSFORMATION)
                cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv))
                cipher.doFinal(ciphertext)
            }
            FORMAT_VERSION_2 -> {
                // v2: [VERSION=2 | MODE | IV_LEN | IV | CIPHERTEXT]
                val mode = wrapped[1]
                require(mode == MODE_WEAK) {
                    "Blob v2 strong ne peut pas etre unwrappe sans BiometricPrompt"
                }
                val ivLen = wrapped[2].toInt() and 0xFF
                require(ivLen in 12..16) { "Longueur IV invalide" }
                require(wrapped.size > 3 + ivLen) { "Blob enveloppe incomplet" }

                val iv = wrapped.copyOfRange(3, 3 + ivLen)
                val ciphertext = wrapped.copyOfRange(3 + ivLen, wrapped.size)

                val key = getOrCreateWrappingKey()
                val cipher = Cipher.getInstance(CIPHER_TRANSFORMATION)
                cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv))
                cipher.doFinal(ciphertext)
            }
            else -> throw IllegalArgumentException("Version de blob inconnue: ${wrapped[0]}")
        }
    }

    // =========================================================================
    // Chemin fort (v2-strong, BiometricPrompt + CryptoObject)
    // =========================================================================

    private fun handleWrapStrong(call: MethodCall, result: Result) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity non disponible", null)
            return
        }
        if (pendingResult != null) {
            result.error("BIOMETRIC_IN_PROGRESS", "Operation biometrique deja en cours", null)
            return
        }
        val plaintextBase64 = call.argument<String>("plaintextBase64")
        if (plaintextBase64.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENT", "plaintextBase64 manquant", null)
            return
        }

        val plaintext = Base64.decode(plaintextBase64, Base64.NO_WRAP)

        try {
            val key = getOrCreateStrongWrappingKey()
            val cipher = Cipher.getInstance(CIPHER_TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, key)

            pendingResult = result

            val prompt = BiometricPrompt(act, act.mainExecutor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(
                        authResult: BiometricPrompt.AuthenticationResult
                    ) {
                        try {
                            val authedCipher = authResult.cryptoObject?.cipher
                                ?: throw Exception("CryptoObject cipher null")
                            val ciphertext = authedCipher.doFinal(plaintext)
                            val iv = authedCipher.iv

                            // Format v2: [VERSION=2 | MODE=STRONG | IV_LEN | IV | CIPHERTEXT]
                            val out = ByteArray(3 + iv.size + ciphertext.size)
                            out[0] = FORMAT_VERSION_2
                            out[1] = MODE_STRONG
                            out[2] = iv.size.toByte()
                            System.arraycopy(iv, 0, out, 3, iv.size)
                            System.arraycopy(ciphertext, 0, out, 3 + iv.size, ciphertext.size)

                            pendingResult?.success(
                                Base64.encodeToString(out, Base64.NO_WRAP)
                            )
                        } catch (e: Exception) {
                            pendingResult?.error("HW_WRAP_ERROR", e.message, null)
                        } finally {
                            pendingResult = null
                        }
                    }

                    override fun onAuthenticationError(
                        errorCode: Int, errString: CharSequence
                    ) {
                        pendingResult?.error(
                            "BIOMETRIC_ERROR",
                            errString.toString(),
                            errorCode.toString()
                        )
                        pendingResult = null
                    }

                    override fun onAuthenticationFailed() {
                        // Non terminal : BiometricPrompt gere les retentatives en interne.
                    }
                }
            )

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle(call.argument<String>("promptTitle") ?: "PassKeyra")
                .setSubtitle(call.argument<String>("promptSubtitle") ?: "")
                .setNegativeButtonText(call.argument<String>("promptCancel") ?: "Annuler")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                .build()

            prompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
        } catch (e: Exception) {
            pendingResult?.error("HW_WRAP_ERROR", e.message, null)
            pendingResult = null
        }
    }

    private fun handleUnwrapStrong(call: MethodCall, result: Result) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity non disponible", null)
            return
        }
        if (pendingResult != null) {
            result.error("BIOMETRIC_IN_PROGRESS", "Operation biometrique deja en cours", null)
            return
        }
        val wrappedBase64 = call.argument<String>("wrappedBase64")
        if (wrappedBase64.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENT", "wrappedBase64 manquant", null)
            return
        }

        val wrapped = Base64.decode(wrappedBase64, Base64.NO_WRAP)

        // Validation du blob v2-strong
        require(wrapped.size > 3) { "Blob enveloppe invalide" }
        require(wrapped[0] == FORMAT_VERSION_2) { "Version de blob inattendue: ${wrapped[0]}" }
        require(wrapped[1] == MODE_STRONG) { "Mode strong attendu" }

        val ivLen = wrapped[2].toInt() and 0xFF
        require(ivLen in 12..16) { "Longueur IV invalide" }
        require(wrapped.size > 3 + ivLen) { "Blob enveloppe incomplet" }

        val iv = wrapped.copyOfRange(3, 3 + ivLen)
        val ciphertext = wrapped.copyOfRange(3 + ivLen, wrapped.size)

        try {
            val key = getOrCreateStrongWrappingKey()
            val cipher = Cipher.getInstance(CIPHER_TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv))

            pendingResult = result

            val prompt = BiometricPrompt(act, act.mainExecutor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(
                        authResult: BiometricPrompt.AuthenticationResult
                    ) {
                        try {
                            val authedCipher = authResult.cryptoObject?.cipher
                                ?: throw Exception("CryptoObject cipher null")
                            val plaintext = authedCipher.doFinal(ciphertext)
                            pendingResult?.success(
                                Base64.encodeToString(plaintext, Base64.NO_WRAP)
                            )
                        } catch (e: Exception) {
                            pendingResult?.error("HW_WRAP_ERROR", e.message, null)
                        } finally {
                            pendingResult = null
                        }
                    }

                    override fun onAuthenticationError(
                        errorCode: Int, errString: CharSequence
                    ) {
                        pendingResult?.error(
                            "BIOMETRIC_ERROR",
                            errString.toString(),
                            errorCode.toString()
                        )
                        pendingResult = null
                    }

                    override fun onAuthenticationFailed() {
                        // Non terminal.
                    }
                }
            )

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle(call.argument<String>("promptTitle") ?: "PassKeyra")
                .setSubtitle(call.argument<String>("promptSubtitle") ?: "")
                .setNegativeButtonText(call.argument<String>("promptCancel") ?: "Annuler")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                .build()

            prompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
        } catch (e: KeyPermanentlyInvalidatedException) {
            clearKey(KEY_ALIAS_STRONG)
            result.error(
                "KEY_INVALIDATED",
                "Cle invalidee suite a un changement d'empreinte biometrique",
                null
            )
        } catch (e: Exception) {
            pendingResult?.error("HW_WRAP_ERROR", e.message, null)
            pendingResult = null
        }
    }

    // =========================================================================
    // Gestion des cles Keystore
    // =========================================================================

    private fun getOrCreateWrappingKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existing = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
        if (existing != null) return existing

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                return generateKey(KEY_ALIAS, useStrongBox = true, requireAuth = false)
            } catch (_: StrongBoxUnavailableException) {
                // Fallback sans StrongBox.
            } catch (_: Exception) {
                // Fallback autre erreur StrongBox-related.
            }
        }

        return generateKey(KEY_ALIAS, useStrongBox = false, requireAuth = false)
    }

    private fun getOrCreateStrongWrappingKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existing = keyStore.getKey(KEY_ALIAS_STRONG, null) as? SecretKey
        if (existing != null) return existing

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                return generateKey(KEY_ALIAS_STRONG, useStrongBox = true, requireAuth = true)
            } catch (_: StrongBoxUnavailableException) {
                // Fallback sans StrongBox.
            } catch (_: Exception) {
                // Fallback autre erreur StrongBox-related.
            }
        }

        return generateKey(KEY_ALIAS_STRONG, useStrongBox = false, requireAuth = true)
    }

    private fun generateKey(
        alias: String,
        useStrongBox: Boolean,
        requireAuth: Boolean
    ): SecretKey {
        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        val specBuilder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(AES_KEY_SIZE_BITS)
            .setUserAuthenticationRequired(requireAuth)

        if (requireAuth) {
            // Invalidation de la cle si les empreintes changent.
            specBuilder.setInvalidatedByBiometricEnrollment(true)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // API 30+ : timeout 0 = chaque utilisation requiert auth,
                // AUTH_BIOMETRIC_STRONG = uniquement biometrie forte.
                specBuilder.setUserAuthenticationParameters(
                    0, KeyProperties.AUTH_BIOMETRIC_STRONG
                )
            } else {
                // API 23-29 : -1 = chaque utilisation requiert auth.
                @Suppress("DEPRECATION")
                specBuilder.setUserAuthenticationValidityDurationSeconds(-1)
            }
        }

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
        private const val KEY_ALIAS_STRONG = "passkeyra_biometric_wrap_key_strong"

        // Alias C3 (jamais utilise en production stable, present uniquement
        // sur les devices de test ayant essaye C3). Nettoye via clearWrappingKey().
        private const val KEY_ALIAS_V2_LEGACY = "passkeyra_biometric_wrap_key_v2"

        private const val CIPHER_TRANSFORMATION = "AES/GCM/NoPadding"
        private const val AES_KEY_SIZE_BITS = 256
        private const val GCM_TAG_LENGTH_BITS = 128

        private const val FORMAT_VERSION: Byte = 1
        private const val FORMAT_VERSION_2: Byte = 2
        private const val MODE_WEAK: Byte = 0
        private const val MODE_STRONG: Byte = 1
    }
}
