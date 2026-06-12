pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Official sources FIRST for plugin lookups — the Aliyun
        // mirrors don't carry every Gradle plugin marker, e.g.
        // `com.google.gms.google-services` 404s on the mirror but
        // resolves fine from gradlePluginPortal().
        gradlePluginPortal()
        google()
        mavenCentral()
        // Aliyun fallbacks for regular library JARs (Firebase Android
        // SDK etc.) — Gradle uses these only after the official sources
        // succeed for plugin lookups but fail for transitive deps.
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // Pinned to 2.1.0 — Kotlin 2.2.x is too new for some plugins
    // (sentry_flutter 8.9 fails to compile against it).
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // id "com.android.application" version "8.1.0" apply false
    //id "org.jetbrains.kotlin.android" version "1.9.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
