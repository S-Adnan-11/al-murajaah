import java.util.Properties
import java.security.KeyStore
import java.security.MessageDigest

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Dedicated production signer approved before the first public release.
// The legacy debug-origin key remains private for existing test installations.
val productionSigningFile = rootProject.file("production/key.properties")
val productionSigning = Properties()
if (productionSigningFile.isFile) {
    productionSigningFile.inputStream().use { productionSigning.load(it) }
    val store = KeyStore.getInstance("JKS")
    val password = productionSigning.getProperty("storePassword").toCharArray()
    file(productionSigning.getProperty("storeFile")).inputStream().use { store.load(it, password) }
    val certificate = store.getCertificate(productionSigning.getProperty("keyAlias"))
    val fingerprint = MessageDigest.getInstance("SHA-256").digest(certificate.encoded)
        .joinToString("") { "%02x".format(it) }
    check(fingerprint == "acac6c5bc482ea7c9246fd233fc59efe707b65779c40b17f9d663b3937f0737d") {
        "Production signer differs from the approved certificate. Do not substitute another key."
    }
} else {
    check(gradle.startParameter.taskNames.none { it.contains("release", ignoreCase = true) }) {
        "Release signing requires private android/production/key.properties and the preserved production key."
    }
}

android {
    namespace = "dev.almurajaah.al_murajaah"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Established installed identity; retain for data-preserving updates.
        applicationId = "dev.almurajaah.al_murajaah.diagnostic"
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

    signingConfigs {
        if (productionSigningFile.isFile) {
            create("productionRelease") {
                storeFile = file(productionSigning.getProperty("storeFile"))
                storePassword = productionSigning.getProperty("storePassword")
                keyAlias = productionSigning.getProperty("keyAlias")
                keyPassword = productionSigning.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("productionRelease")
            isMinifyEnabled = true
            isShrinkResources = true
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
