# Open in Android Studio

1. Open this `android` folder—the folder containing `settings.gradle.kts`.
2. Select Android Studio's embedded JDK when prompted.
3. Allow Gradle sync to finish; first sync needs internet access.
4. Start an Android API 26+ emulator or connect a device.
5. Run the `app` configuration.

Debug and release builds default to the verified Railway HTTPS API. To use a local service instead, set `BKK_DEBUG_API_BASE_URL=http://10.0.2.2:8000/api/v1/` in Gradle properties outside Git. Override release builds with `BKK_API_BASE_URL=https://.../api/v1/` only when intentionally targeting another verified environment.

Gradle supports the current Java 25 daemon criterion. Android/Kotlin bytecode stays on JVM 17 by design because that is the correct Android compilation target.

Firebase is optional at compile time. Add the authorised `google-services.json` to `app/` to test FCM; never commit it.
