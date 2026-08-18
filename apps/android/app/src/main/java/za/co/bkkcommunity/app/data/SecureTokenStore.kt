package za.co.bkkcommunity.app.data

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal class SecureTokenStore(context: Context) {
    private val preferences = context.getSharedPreferences("secure_session", Context.MODE_PRIVATE)

    fun read(): String? = runCatching {
        val encoded = preferences.getString(TOKEN, null) ?: return null
        val payload = Base64.decode(encoded, Base64.NO_WRAP)
        require(payload.size > IV_BYTES)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(TAG_BITS, payload.copyOfRange(0, IV_BYTES)))
        String(cipher.doFinal(payload.copyOfRange(IV_BYTES, payload.size)), Charsets.UTF_8)
    }.getOrElse {
        clear()
        null
    }

    fun write(token: String) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.doFinal(token.toByteArray(Charsets.UTF_8))
        val payload = cipher.iv + encrypted
        preferences.edit().putString(TOKEN, Base64.encodeToString(payload, Base64.NO_WRAP)).apply()
    }

    fun clear() {
        preferences.edit().clear().apply()
    }

    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }

        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE).run {
            init(
                KeyGenParameterSpec.Builder(
                    KEY_ALIAS,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setRandomizedEncryptionRequired(true)
                    .build()
            )
            generateKey()
        }
    }

    private companion object {
        const val KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "bkk_auth_token_v1"
        const val TOKEN = "encrypted_access_token"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_BYTES = 12
        const val TAG_BITS = 128
    }
}
