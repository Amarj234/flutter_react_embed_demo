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
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

// React Native (flutter_react_embed README, "React Native engine" > Android).
// Does what React Native's settings plugin does: Flutter moves the root build
// directory to ../build, which is where the React Native app plugin reads
// autolinking.json.
includeBuild("../node_modules/@react-native/gradle-plugin")

val autolinkingConfig = providers.exec {
    commandLine("npx", "@react-native-community/cli", "config")
    workingDir = file("..")
}.standardOutput.asText.get()
file("../build/generated/autolinking/autolinking.json").apply {
    parentFile.mkdirs()
    writeText(autolinkingConfig)
}

// Include autolinked native libraries (same naming as React Native's settings plugin).
@Suppress("UNCHECKED_CAST")
val dependencies = (groovy.json.JsonSlurper().parseText(autolinkingConfig) as Map<String, Any?>)["dependencies"]
    as Map<String, Map<String, Any?>>? ?: emptyMap()
for ((name, dependency) in dependencies) {
    @Suppress("UNCHECKED_CAST")
    val android = (dependency["platforms"] as Map<String, Any?>?)?.get("android") as Map<String, Any?>?
    val sourceDir = android?.get("sourceDir") as String? ?: continue
    if (android["isPureCxxDependency"] == true) continue
    val path = ":" + name.replace(Regex("[~*!'()]+"), "_").replace(Regex("^@([\\w-.]+)/"), "$1_")
    include(path)
    project(path).projectDir = file(sourceDir)
}
