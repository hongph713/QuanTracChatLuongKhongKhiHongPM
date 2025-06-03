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
//    compileSdk = flutter.compileSdkVersion
//    ndkVersion = "27.0.12077973" // Giữ lại dòng này
//
//    // XÓA HOẶC COMMENT OUT DÒNG DƯỚI ĐÂY:
//    // ndkVersion = flutter.ndkVersion
//
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_11
//        targetCompatibility = JavaVersion.VERSION_11
//    }
//
//    kotlinOptions {
//        jvmTarget = JavaVersion.VERSION_11.toString() // Đảm bảo có .toString() ở đây nếu JavaVersion.VERSION_11 không tự ép kiểu
//    }
//
//    defaultConfig {
//        applicationId = "com.example.datn_20242"
//        minSdk = flutter.minSdkVersion
//        targetSdk = flutter.targetSdkVersion
//        versionCode = flutter.versionCode
//        versionName = flutter.versionName
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

    compileOptions {
        // <<< START: CẬP NHẬT CHO KOTLIN SCRIPT >>>
        isCoreLibraryDesugaringEnabled = true // Sử dụng "isCoreLibraryDesugaringEnabled = true"
        // <<< END: CẬP NHẬT CHO KOTLIN SCRIPT >>>

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.datn_20242"
        minSdk = flutter.minSdkVersion // Đảm bảo minSdkVersion >= 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // multiDexEnabled = true // Thường không cần với desugaring, nhưng để lại nếu bạn đã bật trước đó
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Cấu hình cho release build
            // isMinifyEnabled = false
            // isShrinkResources = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            // isCoreLibraryDesugaringEnabled = true // Thường không cần đặt lại ở đây nếu đã có ở compileOptions
        }
    }
    // Thêm dòng này nếu chưa có, để đảm bảo các tùy chọn packaging được áp dụng đúng
    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ... các dependencies khác của bạn ...

    // <<< START: CẬP NHẬT CHO KOTLIN SCRIPT >>>
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Sử dụng dấu ngoặc đơn ()
    // <<< END: CẬP NHẬT CHO KOTLIN SCRIPT >>>

    // implementation("androidx.multidex:multidex:2.0.1") // Nếu bạn bật multiDexEnabled
}