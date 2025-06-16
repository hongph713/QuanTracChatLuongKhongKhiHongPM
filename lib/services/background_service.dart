// lib/services/background_service.dart

// import 'package:firebase_core/firebase_core.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:geolocator/geolocator.dart';
//
// import '../models/station.dart';
// import 'location_service.dart';
// import 'firebase_service.dart';
// import 'station_data_service.dart';
// import 'notification_service.dart';
//
// const inexactPeriodicTask = "inexactPeriodicAirQualityTask";
//
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     if (task == inexactPeriodicTask) {
//       print("[Background Task] Bắt đầu chạy tác vụ định kỳ không chính xác.");
//       await Firebase.initializeApp();
//
//       final locationService = LocationService();
//       final firebaseService = FirebaseService();
//       final stationDataService = StationDataService();
//       final notificationService = NotificationService();
//       await notificationService.initialize(); // Gọi hàm initialize() đã sửa
//
//       try {
//         final userPos = await locationService.getSavedPosition();
//         if (userPos == null) return true;
//
//         final stations = await firebaseService.getAllStations();
//         if (stations.isEmpty) return true;
//
//         final nearestStation = stationDataService.findNearestStation(userPos, stations);
//         if (nearestStation == null) return true;
//
//         // =================================================================
//         // <<< SỬA LỖI TẠI ĐÂY >>>
//         // Đổi tên hàm cho khớp với file notification_service.dart
//         await notificationService.showAqiNotification(
//           stationName: nearestStation.viTri,
//           aqi: nearestStation.aqi,
//           aqiMessage: nearestStation.aqiMessage,
//           payload: nearestStation.id,
//         );
//         // =================================================================
//
//         print("[Background Task] Đã gửi thông báo thành công.");
//         return true;
//       } catch (e) {
//         print("[Background Task] Lỗi: $e");
//         return false;
//       }
//     }
//     return true;
//   });
// }

// import 'package:firebase_core/firebase_core.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../models/station.dart';
// import 'location_service.dart';
// import 'firebase_service.dart';
// import 'station_data_service.dart';
// import 'notification_service.dart';
// import '../models/AQIUtils.dart';
//
// const inexactPeriodicTask = "inexactPeriodicAirQualityTask";
//
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     if (task == inexactPeriodicTask) {
//       print("[Background Task] Bắt đầu chạy tác vụ.");
//       await Firebase.initializeApp();
//
//       try {
//         // 1. ĐỌC NGÔN NGỮ ĐÃ LƯU
//         final prefs = await SharedPreferences.getInstance();
//         final lang = prefs.getString('language_code_preference') ?? 'vi';
//         print("[Background Task] Ngôn ngữ lựa chọn: '$lang'");
//
//         final locationService = LocationService();
//         final firebaseService = FirebaseService();
//         final stationDataService = StationDataService();
//         final notificationService = NotificationService();
//         await notificationService.initialize();
//
//
//         final userPos = await locationService.getSavedPosition();
//         if (userPos == null) return true;
//
//         // 3. TẠO TIÊU ĐỀ VÀ NỘI DUNG THÔNG BÁO VỚI ĐÚNG NGÔN NGỮ
//         final String notificationBody = AQIUtils.getAQINoti(nearestStation.aqi, lang: lang);
//         final String notificationTitle = lang == 'en'
//             ? 'Air quality update for today!'
//             : 'Cập nhật chất lượng không khí hôm nay!';
//
//         // 4. GỬI THÔNG BÁO VỚI NỘI DUNG ĐÃ ĐƯỢC DỊCH
//         await notificationService.showAqiNotification(
//           title: notificationTitle,
//           body: notificationBody,
//           //payload: nearestStation.id,
//         );
//
//         print("[Background Task] Đã gửi thông báo bằng ngôn ngữ '$lang'.");
//         return true;
//       } catch (e) {
//         print("[Background Task] Lỗi: $e");
//         return false;
//       }
//     }
//     return true;
//   });
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';
import '../models/AQIUtils.dart'; // <<< THÊM IMPORT NÀY
import 'location_service.dart';
import 'firebase_service.dart';
import 'station_data_service.dart';
import 'notification_service.dart';

const inexactPeriodicTask = "inexactPeriodicAirQualityTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == inexactPeriodicTask) {
      print("[Background Task] Bắt đầu chạy tác vụ.");
      await Firebase.initializeApp();

      try {
        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('language_code_preference') ?? 'vi';

        final locationService = LocationService();
        final firebaseService = FirebaseService();
        final stationDataService = StationDataService();
        final notificationService = NotificationService();
        await notificationService.initialize();

        final userPos = await locationService.getSavedPosition();
        if (userPos == null) return true;

        final stations = await firebaseService.getAllStations(lang: 'vi');
        if (stations.isEmpty) return true;

        // <<< SỬA LỖI TẠI ĐÂY: THÊM LẠI DÒNG CODE TÌM TRẠM GẦN NHẤT >>>
        final nearestStation = stationDataService.findNearestStation(userPos, stations);
        // Kiểm tra nếu không tìm thấy trạm nào
        if (nearestStation == null) return true;

        // Giờ bạn có thể sử dụng biến `nearestStation` mà không bị lỗi
        final String notificationBody = AQIUtils.getAQINoti(nearestStation.aqi, lang: lang);
        final String notificationTitle = lang == 'en'
            ? 'Air quality update for today!'
            : 'Cập nhật chất lượng không khí hôm nay!';

        await notificationService.showAqiNotification(
          title: notificationTitle,
          body: notificationBody,
          payload: nearestStation.id,
        );

        print("[Background Task] Đã gửi thông báo bằng ngôn ngữ '$lang'.");
        return true;
      } catch (e) {
        print("[Background Task] Lỗi: $e");
        return false;
      }
    }
    return true;
  });
}


// Class BackgroundTaskService giữ nguyên, không cần thay đổi
class BackgroundTaskService {
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  Future<void> registerInexactPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      inexactPeriodicTask,
      inexactPeriodicTask,
      frequency: const Duration(hours: 12),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    print("Đã lên lịch tác vụ định kỳ không chính xác.");
  }

  // Future<void> registerInexactPeriodicTask() async {
  //   // TẠM THỜI DÙNG TÁC VỤ CHẠY MỘT LẦN ĐỂ TEST
  //   await Workmanager().registerOneOffTask(
  //     inexactPeriodicTask,     // Tên unique
  //     inexactPeriodicTask,     // Tên tác vụ
  //     initialDelay: const Duration(seconds: 10), // Chạy sau 30 giây
  //     constraints: Constraints(networkType: NetworkType.connected),
  //     existingWorkPolicy: ExistingWorkPolicy.replace,
  //   );
  //   print("ĐÃ LÊN LỊCH TÁC VỤ TEST (CHẠY MỘT LẦN SAU 30 GIÂY).");
  // }
  void cancelTask(String uniqueName) {
    Workmanager().cancelByUniqueName(uniqueName);
    print("[BackgroundTaskService] Đã hủy tác vụ với tên unique: $uniqueName");
  }
}