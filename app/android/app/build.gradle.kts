import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pienoamico.pienoamico"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    val keystorePropsFile = rootProject.file("key.properties")
    val keystoreProps = Properties()
    if (keystorePropsFile.exists()) {
        keystorePropsFile.inputStream().use { stream -> keystoreProps.load(stream) }
    }

    signingConfigs {
        create("release") {
            keyAlias     = keystoreProps.getProperty("keyAlias", "")
            keyPassword  = keystoreProps.getProperty("keyPassword", "")
            storePassword = keystoreProps.getProperty("storePassword", "")
            val storeFilePath = keystoreProps.getProperty("storeFile")
            storeFile = if (storeFilePath != null) file(storeFilePath) else null
        }
    }

    defaultConfig {
        applicationId = "com.pienoamico.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropsFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
