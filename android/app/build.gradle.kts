plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.datn_20242"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Giữ lại dòng này

    // XÓA HOẶC COMMENT OUT DÒNG DƯỚI ĐÂY:
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString() // Đảm bảo có .toString() ở đây nếu JavaVersion.VERSION_11 không tự ép kiểu
    }

    defaultConfig {
        applicationId = "com.example.datn_20242"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

//plugins {
//    id("com.android.application")
//    // START: FlutterFire Configuration
//    id("com.google.gms.google-services")
//    // END: FlutterFire Configuration
//    id("kotlin-android")
//    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//    id("dev.flutter.flutter-gradle-plugin")
//}
//
//android {
//    namespace = "com.example.datn_20242"
//    compileSdk = 34  // Cố định thay vì flutter.compileSdkVersion
//    ndkVersion = "25.1.8937393"  // Phiên bản NDK ổn định hơn
//
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_1_8  // Đổi về Java 8
//        targetCompatibility = JavaVersion.VERSION_1_8
//    }
//
//    kotlinOptions {
//        jvmTarget = "1.8"  // Đổi về Java 8
//    }
//
//    defaultConfig {
//        applicationId = "com.example.datn_20242"
//        minSdk = 21  // Cố định minSdk
//        targetSdk = 34  // Cố định targetSdk
//        versionCode = 1
//        versionName = "1.0"
//        multiDexEnabled = true  // Thêm dòng này
//    }
//
//    buildTypes {
//        release {
//            signingConfig = signingConfigs.getByName("debug")
//        }
//    }
//}
//
//flutter {
//    source = "../.."
//}
//
//dependencies {
//    implementation("androidx.multidex:multidex:2.0.1")  // Thêm MultiDex
//}