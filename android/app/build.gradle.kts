import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin pour Firebase (doit être après les plugins Android et Kotlin)
    id("com.google.gms.google-services")
}

// Charger les propriétés du keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.passkeyra.app"
    compileSdk = 36  // Requis par les plugins Flutter récents
    // ndkVersion = "27.0.12077973" // Utilise automatiquement la version NDK installée (29)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.passkeyra.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // Aligné sur compileSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // MultiDex requis pour Firebase (nombreuses méthodes)
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { File(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Google Play Services pour AdMob
    // CORRECTION: Nécessaire pour que AdMob fonctionne dans l'AAB de production
    implementation("com.google.android.gms:play-services-ads:23.0.0")
    // Biométrie native (BiometricPrompt + CryptoObject) pour C3
    // Permet de lier la clé Keystore à l'authentification biométrique forte.
    implementation("androidx.biometric:biometric:1.1.0")
}
