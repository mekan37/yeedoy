import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystoreFile = keystorePropertiesFile.exists()
val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (hasReleaseKeystoreFile) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun readReleaseSigningValue(envKey: String, keyPropertiesName: String): String? {
    val fromEnv = System.getenv(envKey)?.trim().orEmpty()
    if (fromEnv.isNotEmpty()) return fromEnv
    val fromFile = keystoreProperties.getProperty(keyPropertiesName)?.trim().orEmpty()
    if (fromFile.isNotEmpty()) return fromFile
    return null
}

val releaseStoreFilePath = readReleaseSigningValue("ANDROID_RELEASE_STORE_FILE", "storeFile")
val releaseStorePassword = readReleaseSigningValue("ANDROID_RELEASE_STORE_PASSWORD", "storePassword")
val releaseKeyAlias = readReleaseSigningValue("ANDROID_RELEASE_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = readReleaseSigningValue("ANDROID_RELEASE_KEY_PASSWORD", "keyPassword")

val hasReleaseSigningConfig =
    !releaseStoreFilePath.isNullOrEmpty() &&
    !releaseStorePassword.isNullOrEmpty() &&
    !releaseKeyAlias.isNullOrEmpty() &&
    !releaseKeyPassword.isNullOrEmpty()

android {
    namespace = "com.yeedoy.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.yeedoy.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            val storeFilePath = releaseStoreFilePath.orEmpty()
            if (storeFilePath.isEmpty()) {
                throw GradleException(
                    "Release signing configured but 'storeFile' bos.",
                )
            }
            // Resolve relative to the Gradle root project (android/), matching
            // the documented convention in key.properties.example and the CI
            // keystore decode step — NOT the app module directory (android/app/).
            val resolvedStoreFile = rootProject.file(storeFilePath)
            if (!resolvedStoreFile.exists()) {
                // Keystore file absent: block release builds, not debug.
                // Debug builds fall back to the auto-generated Android debug key.
                if (isReleaseTaskRequested) {
                    throw GradleException(
                        "Release signing storeFile bulunamadi: $storeFilePath",
                    )
                }
            } else {
                create("release") {
                    storeFile = resolvedStoreFile
                    storePassword = releaseStorePassword
                    keyAlias = releaseKeyAlias
                    keyPassword = releaseKeyPassword
                }
            }
        }
    }

    buildTypes {
        release {
            if (isReleaseTaskRequested && !hasReleaseSigningConfig) {
                throw GradleException(
                    "Release signing not configured. android/key.properties kullanin ya da ANDROID_RELEASE_STORE_FILE / ANDROID_RELEASE_STORE_PASSWORD / ANDROID_RELEASE_KEY_ALIAS / ANDROID_RELEASE_KEY_PASSWORD env'lerini tanimlayin.",
                )
            }
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig != null) {
                signingConfig = releaseSigningConfig
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
}
