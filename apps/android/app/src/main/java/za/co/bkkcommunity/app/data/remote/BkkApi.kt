package za.co.bkkcommunity.app.data.remote

import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query

interface BkkApi {
    @POST("auth/register") suspend fun register(@Body request: RegisterRequest): ApiEnvelope<AuthDto>
    @POST("auth/login") suspend fun login(@Body request: LoginRequest): ApiEnvelope<AuthDto>
    @POST("auth/forgot-password") suspend fun forgotPassword(@Body request: ForgotPasswordRequest): ApiEnvelope<Map<String, String>>
    @POST("auth/reset-password") suspend fun resetPassword(@Body request: ResetPasswordRequest): ApiEnvelope<Map<String, String>>
    @DELETE("auth/session") suspend fun logout(@Header("Authorization") authorization: String? = null)

    @GET("me") suspend fun me(): ApiEnvelope<MemberDto>
    @PATCH("me") suspend fun updateProfile(@Body request: ProfileRequest): ApiEnvelope<MemberDto>
    @DELETE("me") suspend fun deleteAccount()
    @PATCH("me/notification-preferences")
    suspend fun updatePreferences(@Body request: PreferencesRequest): ApiEnvelope<MemberDto>
    @GET("me/attendance") suspend fun attendanceHistory(): ApiEnvelope<List<EventDto>>

    @GET("events") suspend fun events(@Query("category") category: String? = null): ApiEnvelope<List<EventDto>>
    @GET("events/{id}") suspend fun event(@Path("id") id: Long): ApiEnvelope<EventDto>
    @PUT("events/{id}/attendance")
    suspend fun setAttendance(@Path("id") id: Long, @Body request: AttendanceRequest): ApiEnvelope<AttendanceDto>

    @GET("discounts") suspend fun discounts(@Query("category") category: String? = null): ApiEnvelope<List<DiscountDto>>
    @GET("discounts/{id}") suspend fun discount(@Path("id") id: Long): ApiEnvelope<DiscountDto>
    @GET("local-services") suspend fun localServices(@Query("type") type: String? = null): ApiEnvelope<List<LocalServiceDto>>
    @POST("contact") suspend fun contact(@Body request: ContactRequest): ApiEnvelope<ContactResult>
    @PUT("devices/fcm-token") suspend fun registerDevice(@Body request: DeviceRequest): ApiEnvelope<Map<String, Boolean>>
}
