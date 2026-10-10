import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingProperty(propertyName: String, envName: String): String? {
    val fromFile = keystoreProperties.getProperty(propertyName)?.trim()?.ifEmpty { null }
    val fromEnv = System.getenv(envName)?.trim()?.ifEmpty { null }
    return fromFile ?: fromEnv
}

val releaseStoreFile = signingProperty("storeFile", "CARZON_UPLOAD_STORE_FILE")
val releaseStorePassword = signingProperty("storePassword", "CARZON_UPLOAD_STORE_PASSWORD")
val releaseKeyAlias = signingProperty("keyAlias", "CARZON_UPLOAD_KEY_ALIAS")
val releaseKeyPassword = signingProperty("keyPassword", "CARZON_UPLOAD_KEY_PASSWORD")
val hasReleaseSigning =
    releaseStoreFile != null &&
        releaseStorePassword != null &&
        releaseKeyAlias != null &&
        releaseKeyPassword != null

android {
    namespace = "com.carzon.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.carzon.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Debug keys are never used for release. Missing material fails
            // the release task graph below instead of producing a debug-signed APK.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

if (!hasReleaseSigning) {
    gradle.taskGraph.whenReady {
        val releaseRequested = allTasks.any { it.name.contains("Release") }
        if (releaseRequested) {
            throw GradleException(
                "Release signing is not configured. Add android/key.properties " +
                    "(see android/key.properties.example) or set " +
                    "CARZON_UPLOAD_STORE_FILE, CARZON_UPLOAD_STORE_PASSWORD, " +
                    "CARZON_UPLOAD_KEY_ALIAS, and CARZON_UPLOAD_KEY_PASSWORD. " +
                    "Release builds do not fall back to the debug keystore.",
            )
        }
    }
}

dependencies {
    // Required by flutter_local_notifications. Not a new product dependency.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// FlutterFire: only wire Google Services when a real `google-services.json`
// is present under `android/app/`. The plugin selects the client whose
// package_name matches applicationId (com.carzon.app).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
