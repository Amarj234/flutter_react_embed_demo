plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.amarj234.react_embed_demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.amarj234.react_embed_demo"
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

// React Native (flutter_react_embed README, "React Native engine" > Android).
apply(plugin = "com.facebook.react")
val react = extensions.getByName("react")
fun <T : Any> reactProperty(name: String): T {
    @Suppress("UNCHECKED_CAST")
    return react.withGroovyBuilder { getProperty(name) } as T
}
reactProperty<DirectoryProperty>("root").set(rootProject.file(".."))
// The bundle ships as a Flutter asset, so React Native never bundles it itself.
reactProperty<ListProperty<String>>("debuggableVariants").set(listOf("debug", "profile", "release"))
react.withGroovyBuilder { "autolinkLibrariesWithApp"() }

dependencies {
    "implementation"("com.facebook.react:react-android") // version pinned by the plugin
    "implementation"("com.facebook.react:hermes-android")
}
