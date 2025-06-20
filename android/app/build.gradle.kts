plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")      // Flutter plugin last
}

android {
    namespace = "com.example.splittrack"

    /* ---------- SDK / NDK ----------- */
    compileSdk  = flutter.compileSdkVersion
    ndkVersion  = "27.0.12077973"                // keep NDK 27

    /* ---------- Java & desugaring --- */
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true    // must stay true
    }

    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    defaultConfig {
        applicationId = "com.example.splittrack"
        minSdk      = flutter.minSdkVersion
        targetSdk   = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }

dependencies {
    /* ---------- desugaring lib (bump to ≥ 2.1.4) ---------- */
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // 🔺 version bump

    /* (Other plugin-generated deps follow automatically) */
}
