package za.co.bkkcommunity.app.data.remote

import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.runBlocking
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import za.co.bkkcommunity.app.BuildConfig
import za.co.bkkcommunity.app.data.SessionStore
import java.util.concurrent.TimeUnit

object ApiClient {
    fun create(sessionStore: SessionStore): BkkApi {
        val logging = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BASIC else HttpLoggingInterceptor.Level.NONE
        }
        val client = OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .writeTimeout(15, TimeUnit.SECONDS)
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .header("Accept", "application/json")
                    .header("Content-Type", "application/json")
                    .apply { sessionStore.token()?.let { header("Authorization", "Bearer $it") } }
                    .build()
                chain.proceed(request)
            }
            .addInterceptor { chain ->
                val response = chain.proceed(chain.request())
                val path = chain.request().url.encodedPath
                val isAuthEntryPoint = path.contains("/auth/login") ||
                    path.contains("/auth/register") ||
                    path.contains("/auth/forgot-password") ||
                    path.contains("/auth/reset-password")
                if (response.code == 401 && !isAuthEntryPoint && sessionStore.token() != null) {
                    runBlocking { sessionStore.clear() }
                }
                response
            }
            .addInterceptor(logging)
            .build()
        val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(client)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
            .create(BkkApi::class.java)
    }
}
