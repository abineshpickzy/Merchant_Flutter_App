plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bayfay.merchant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    val appConstantsFile = File(project.rootDir, "../lib/core/constants/app_constants.dart")
    val googleMapsApiKey = if (appConstantsFile.exists()) {
        Regex("""googleMapsApiKey\s*=\s*['"]([^'"]+)['"]""")
            .find(appConstantsFile.readText())
            ?.groupValues
            ?.get(1) ?: ""
    } else {
        ""
    }

    defaultConfig {
        applicationId = "com.bayfay.merchantdev"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }

    buildFeatures {
        buildConfig = true
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            resValue("string", "app_name", "Merchant-Dev")
            buildConfigField("String", "SERVER_URL", "\"https://store-devapi.bayfay.com/merchant/\"")
            buildConfigField("int", "payment_environment", "2")
        }

        create("qa") {
            dimension = "environment"
            resValue("string", "app_name", "Merchant-Qa")
            buildConfigField("String", "SERVER_URL", "\"https://qa-api.bayfay.com/merchant/\"")
            buildConfigField("int", "payment_environment", "2")
        }

        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Merchant")
            buildConfigField("String", "SERVER_URL", "\"https://store-api.bayfay.com/merchant/\"")
            buildConfigField("int", "payment_environment", "0")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.google.android.material:material:1.12.0")
}

flutter {
    source = "../.."
}
