import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// OTPLESS: the deep-link scheme is "otpless.<app id in lowercase>". The demo
// reads the App ID from config/otpless_config.json (see scripts/configure.sh).
// In your own app you can hard-code it in AndroidManifest.xml instead.
val otplessAppId: String =
    rootProject.file("../config/otpless_config.json").takeIf { it.exists() }
        ?.let { (JsonSlurper().parse(it) as Map<*, *>)["appId"] as? String }
        ?: "YOUR_APP_ID"

android {
    namespace = "com.otpless.otpless_flutter_headless_demo"
    // OTPLESS SDK 3.x requires compileSdk 36+ and AGP 8.9.1+.
    compileSdk = maxOf(36, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.otpless.bigbasket_sna_demo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["otplessScheme"] = "otpless.${otplessAppId.lowercase()}"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
