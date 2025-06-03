// lib/services/background_service.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart'; // Quan trọng cho Firebase trong background
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';

// Import các service và model của bạn
// Đảm bảo đường dẫn import là chính xác dựa trên cấu trúc thư mục của bạn
import '../models/station.dart';
import './location_service.dart';
import './firebase_service.dart'; // File firebase_service.dart bạn đã có và cập nhật
import './station_data_service.dart';
import './notification_service.dart';

// Tên unique cho tác vụ nền (nên thay đổi cho ứng dụng của bạn)
const String dailyNotificationTask = "com.yourdomain.yourapp.dailyAqiNotificationTask"; // <<<< THAY ĐỔI CHO APP BẠN

// Hàm callback này phải được khai báo ở top-level hoặc là một static method.
// Nó sẽ được WorkManager gọi khi đến giờ thực thi tác vụ.
@pragma('vm:entry-point') // Đánh dấu cho Dart AOT compiler
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("[BackgroundService - $task] Task started.");

    if (task == dailyNotificationTask) {
      // QUAN TRỌNG: Khởi tạo Firebase trong background isolate.
      // Việc này cần thiết vì background isolate chạy tách biệt với main isolate.
      // Đảm bảo WidgetsFlutterBinding.ensureInitialized() đã được gọi ở hàm main() của app.
      await Firebase.initializeApp();
      print("[BackgroundService - $task] Firebase initialized for background task.");

      // Tạo instances của các service cần thiết
      final LocationService locationService = LocationService();
      final FirebaseService firebaseService = FirebaseService(); // Sử dụng class FirebaseService của bạn
      final StationDataService stationDataService = StationDataService();
      final NotificationService notificationService = NotificationService();

      try {
        // QUAN TRỌNG: Khởi tạo NotificationService cho background isolate
        // Điều này đảm bảo plugin được thiết lập đúng cách trong môi trường isolate riêng.
        await notificationService.initializeLocalNotifications();
        print("[BackgroundService - $task] NotificationService initialized for background task.");

        // 1. Lấy vị trí hiện tại của người dùng
        print("[BackgroundService - $task] Getting current location...");
        Position? userLocation = await locationService.getCurrentLocation();
        if (userLocation == null) {
          print("[BackgroundService - $task] Failed to get user location. Aborting task.");
          return Future.value(false); // Báo hiệu tác vụ thất bại
        }
        print("[BackgroundService - $task] User location: ${userLocation.latitude}, ${userLocation.longitude}");

        // 2. Lấy danh sách tất cả các trạm từ Firebase
        print("[BackgroundService - $task] Fetching all stations from Firebase...");
        List<Station> allStations = await firebaseService.getAllStations(); // Gọi hàm bạn đã tạo
        if (allStations.isEmpty) {
          print("[BackgroundService - $task] No stations found. Aborting task.");
          return Future.value(false);
        }
        print("[BackgroundService - $task] Fetched ${allStations.length} stations.");

        // 3. Tìm trạm gần nhất
        print("[BackgroundService - $task] Finding nearest station...");
        Station? nearestStation = stationDataService.findNearestStation(userLocation, allStations);
        if (nearestStation == null) {
          print("[BackgroundService - $task] Could not find nearest station. Aborting task.");
          return Future.value(false);
        }
        print("[BackgroundService - $task] Nearest station: ${nearestStation.viTri} (AQI: ${nearestStation.aqi})");

        // 4. Lấy mô tả AQI cho thông báo
        String aqiDescription = stationDataService.getAqiDescriptionForNotification(nearestStation.aqi);

        // 5. Hiển thị thông báo
        print("[BackgroundService - $task] Showing notification...");
        await notificationService.showAqiNotification(
          nearestStation.aqi,
          nearestStation.viTri, // Tên trạm
          aqiDescription,
        );
        print("[BackgroundService - $task] Notification shown successfully.");
        return Future.value(true); // Báo hiệu tác vụ thành công
      } catch (e, s) {
        print("[BackgroundService - $task] Error during background task: $e");
        print(s); // In stacktrace để debug
        return Future.value(false); // Báo hiệu tác vụ thất bại
      }
    }
    // Nếu task name không khớp
    print("[BackgroundService - $task] Unknown task. Returning true to avoid rescheduling error task.");
    return Future.value(true); // Trả về true cho các task không xác định để tránh lỗi
  });
}

class BackgroundTaskService {
  /// Khởi tạo WorkManager và đăng ký hàm callbackDispatcher.
  Future<void> initializeWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher, // Hàm callback top-level
      isInDebugMode: true, // Đặt là `false` khi release app.
      // Khi true, nó sẽ hiển thị thông báo hệ thống khi tác vụ chạy.
    );
    print("[BackgroundTaskService] WorkManager initialized.");
  }

  /// Tính toán độ trễ ban đầu để tác vụ chạy vào 7 giờ sáng tiếp theo.
  Duration _calculateInitialDelayTo7AM() {
    final DateTime now = DateTime.now();
    DateTime sevenAmToday = DateTime(now.year, now.month, now.day, 7, 0, 0); // 7:00:00 hôm nay
    DateTime scheduledTime;

    if (now.isAfter(sevenAmToday)) {
      // Nếu bây giờ đã qua 7h sáng, lên lịch cho 7h sáng ngày mai
      scheduledTime = sevenAmToday.add(const Duration(days: 1));
    } else {
      // Nếu bây giờ chưa đến 7h sáng, lên lịch cho 7h sáng hôm nay
      scheduledTime = sevenAmToday;
    }
    final Duration initialDelay = scheduledTime.difference(now);
    print("[BackgroundTaskService] Notification scheduled for: $scheduledTime (Delay: $initialDelay)");
    return initialDelay;
  }

  /// Lên lịch cho tác vụ thông báo chạy hàng ngày vào 7 giờ sáng.
  void scheduleDaily7AmNotification() {
    Workmanager().registerPeriodicTask(
      dailyNotificationTask, // Tên unique của tác vụ
      dailyNotificationTask, // Tên hiển thị của tác vụ (có thể giống unique name)
      frequency: const Duration(days: 1), // Chạy mỗi ngày một lần
      initialDelay: _calculateInitialDelayTo7AM(), // Độ trễ ban đầu để chạy vào 7h sáng
      constraints: Constraints(
        networkType: NetworkType.connected, // Yêu cầu có kết nối mạng
        // requiresBatteryNotLow: true, // (Tùy chọn) Yêu cầu pin không yếu
        // requiresCharging: false, // (Tùy chọn)
        // requiresDeviceIdle: false, // (Tùy chọn)
        // requiresStorageNotLow: true, // (Tùy chọn)
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace, // Thay thế tác vụ cũ nếu đã tồn tại
    );
    print("[BackgroundTaskService] Daily 7 AM AQI notification task scheduled with unique name: $dailyNotificationTask");
  }

  /// Hủy tất cả các tác vụ nền đã được lên lịch với unique name `dailyNotificationTask`.
  void cancelDailyNotifications() {
    Workmanager().cancelByUniqueName(dailyNotificationTask);
    print("[BackgroundTaskService] Canceled tasks with unique name: $dailyNotificationTask");
  }

  /// (Tùy chọn) Hủy tất cả các tác vụ của WorkManager
  void cancelAllTasks() {
    Workmanager().cancelAll();
    print("[BackgroundTaskService] All WorkManager tasks canceled.");
  }
}