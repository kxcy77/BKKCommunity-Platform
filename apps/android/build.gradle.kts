plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.google.services) apply false
}

// Optional local workaround for cloud-synced folders that duplicate/offload
// generated files. Normal checkouts continue to use their own build folders.
val externalBuildRoot = providers.environmentVariable("BKK_BUILD_ROOT").orNull
if (!externalBuildRoot.isNullOrBlank()) {
    require(java.io.File(externalBuildRoot).isAbsolute) { "BKK_BUILD_ROOT must be an absolute path." }
    allprojects {
        val projectFolder = if (path == ":") "root" else path.trim(':').replace(':', '/')
        layout.buildDirectory.set(java.io.File(externalBuildRoot, projectFolder))
    }
}
