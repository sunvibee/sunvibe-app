plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sunvibee_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // ===== ADD THIS FOR DESUGARING =====
        isCoreLibraryDesugaringEnabled = true
        // ===================================
    }

    defaultConfig {
        applicationId = "com.example.sunvibee_app"
        minSdk = flutter.minSdkVersion // Ensure minSdk is at least 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // ===== ADD FOR MULTIDEX =====
        multiDexEnabled = true
        // =============================
    }

    buildTypes {
        release {
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

dependencies {
    // ===== ADD FOR DESUGARING =====
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // ================================
    
    // ===== ADD FOR MULTIDEX =====
    implementation("androidx.multidex:multidex:2.0.1")
    // ==============================
}
