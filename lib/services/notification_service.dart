// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../models/station.dart';
// import '../models/AQIUtils.dart';
// import 'firebase_service.dart';
//
// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();
//
//   final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
//
//   Future<void> init() async {
//     tz.initializeTimeZones();
//
//     const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//       requestSoundPermission: true,
//       requestBadgePermission: true,
//       requestAlertPermission: true,
//     );
//
//     const InitializationSettings settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _notifications.initialize(settings);
//   }
//
//   Future<bool> requestPermissions() async {
//     if (await Permission.notification.isDenied) {
//       final status = await Permission.notification.request();
//       return status == PermissionStatus.granted;
//     }
//     return true;
//   }
//
//   Future<void> scheduleDailyNotification() async {
//     await _notifications.cancelAll();
//
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'daily_aqi_channel',
//       'Thông báo chất lượng không khí hàng ngày',
//       channelDescription: 'Thông báo chỉ số AQI hàng ngày vào lúc 7:00 sáng',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );
//
//     await _notifications.zonedSchedule(
//       0,
//       'Chất lượng không khí hôm nay',
//       await _getAQIMessage(),
//       _nextInstanceOf7AM(),
//       notificationDetails,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );
//   }
//
//   tz.TZDateTime _nextInstanceOf7AM() {
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7);
//
//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(const Duration(days: 1));
//     }
//
//     return scheduledDate;
//   }
//
//   Future<String> _getAQIMessage() async {
//     try {
//       // Lấy vị trí hiện tại
//       Position? position = await _getCurrentPosition();
//       if (position == null) {
//         return 'Không thể xác định vị trí để lấy thông tin chất lượng không khí.';
//       }
//
//       // Tìm trạm gần nhất (bạn cần implement hàm này trong FirebaseService)
//       Station? nearestStation = await FirebaseService.instance.getNearestStation(
//           position.latitude,
//           position.longitude
//       );
//
//       if (nearestStation == null) {
//         return 'Không tìm thấy trạm đo gần bạn.';
//       }
//
//       int aqi = nearestStation.aqi;
//       return _getAQINotificationMessage(aqi);
//     } catch (e) {
//       return 'Không thể lấy thông tin chất lượng không khí.';
//     }
//   }
//
//   Future<Position?> _getCurrentPosition() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) return null;
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) return null;
//       }
//
//       if (permission == LocationPermission.deniedForever) return null;
//
//       return await Geolocator.getCurrentPosition();
//     } catch (e) {
//       return null;
//     }
//   }
//
//   String _getAQINotificationMessage(int aqi) {
//     if (aqi <= 50) {
//       return 'Chất lượng không khí hôm nay tốt. Hãy tận hưởng các hoạt động ngoài trời!';
//     } else if (aqi <= 100) {
//       return 'Chất lượng không khí hôm nay trung bình. Các nhóm nhạy cảm nên giảm hoạt động ngoài trời.';
//     } else if (aqi <= 150) {
//       return 'Chất lượng không khí hôm nay không tốt cho nhóm nhạy cảm. Hạn chế hoạt động ngoài trời.';
//     } else if (aqi <= 200) {
//       return 'Chất lượng không khí hôm nay có hại cho sức khỏe. Mọi người nên hạn chế hoạt động ngoài trời!';
//     } else if (aqi <= 300) {
//       return 'Chất lượng không khí hôm nay rất có hại cho sức khỏe. Mọi người nên ở trong nhà!';
//     } else {
//       return 'Chất lượng không khí hôm nay cực kỳ có hại. Mọi người nên ở trong nhà và bật máy lọc không khí!';
//     }
//   }
//
//   Future<void> cancelDailyNotification() async {
//     await _notifications.cancel(0);
//   }
// }

// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest_all.dart' as tz; // Cần cho scheduled notifications với timezone
// import 'package:timezone/timezone.dart' as tz; // Cần cho scheduled notifications với timezone

class NotificationService {
  // Tạo một instance của plugin thông báo
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Khởi tạo cài đặt cho plugin thông báo.
  /// Cần được gọi ở hàm main() của ứng dụng.
  Future<void> initializeLocalNotifications() async {
    // Cài đặt cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Sử dụng icon mặc định của app bạn

    // Cài đặt cho iOS (bạn có thể cần cấu hình thêm quyền trong Info.plist)
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Callback cũ cho iOS < 10
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Khởi tạo plugin với các cài đặt trên
    // và callback khi người dùng nhấn vào thông báo (khi app đang chạy hoặc ở background)
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );

    // (Tùy chọn) Cấu hình timezone nếu bạn dự định lên lịch thông báo chính xác theo timezone
    // _configureLocalTimeZone();

    // Xin quyền hiển thị thông báo trên Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    // (Tùy chọn) Xin quyền cho phép thông báo chính xác (cần cho một số loại lịch trình)
    // await androidImplementation?.requestExactAlarmsPermission();
  }

  // (Tùy chọn) Hàm cấu hình timezone
  // Future<void> _configureLocalTimeZone() async {
  //   tz.initializeTimeZones();
  //   final String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
  //   tz.setLocalLocation(tz.getLocation(currentTimeZone));
  // }

  /// Hiển thị một thông báo AQI.
  ///
  /// [aqi]: Chỉ số AQI.
  /// [stationName]: Tên của trạm đo.
  /// [aqiDescription]: Mô tả về mức độ AQI.
  Future<void> showAqiNotification(int aqi, String stationName, String aqiDescription) async {
    // Định nghĩa chi tiết cho thông báo trên Android
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'daily_aqi_channel_id_001', // ID của kênh thông báo (quan trọng)
      'Thông báo AQI Hàng Ngày', // Tên của kênh (hiển thị trong cài đặt app)
      channelDescription: 'Kênh này dùng để gửi thông báo về chỉ số AQI hàng ngày.', // Mô tả kênh
      importance: Importance.max, // Mức độ ưu tiên cao nhất
      priority: Priority.high,    // Ưu tiên cao
      icon: '@mipmap/ic_launcher', // Icon nhỏ cho thông báo (tùy chọn, có thể là null)
      // sound: RawResourceAndroidNotificationSound('notification_sound'), // Nếu có âm thanh tùy chỉnh
      // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Icon lớn (tùy chọn)
      ticker: 'AQI Alert', // Text hiển thị trên thanh trạng thái khi thông báo đến (ít dùng)
    );

    // Định nghĩa chi tiết cho thông báo trên iOS
    const DarwinNotificationDetails darwinNotificationDetails =
    DarwinNotificationDetails(
      // sound: 'default', // Âm thanh mặc định
      // badgeNumber: 1, // Số hiển thị trên icon app (tùy chọn)
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Tổng hợp chi tiết thông báo cho các nền tảng
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Nội dung thông báo
    String title = 'Cập nhật Chất lượng Không khí';
    String body = 'Trạm $stationName: AQI $aqi - $aqiDescription.';

    // Hiển thị thông báo
    await flutterLocalNotificationsPlugin.show(
      0, // ID của thông báo (nếu gửi nhiều thông báo, ID này nên khác nhau hoặc =0 để ghi đè)
      title,
      body,
      notificationDetails,
      payload: 'payload_data_khi_click_noti_station_${stationName.replaceAll(" ", "_")}', // Dữ liệu tùy chọn khi người dùng nhấn vào thông báo
    );
    print("[NotificationService] Đã yêu cầu hiển thị thông báo cho trạm $stationName.");
  }
}

// Callback khi người dùng nhấn vào thông báo (khi app đang ở foreground/background nhưng không terminated)
// Hàm này phải được khai báo ở top-level hoặc là một static method.
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    print('[NotificationService] Foreground/Background CLICK. Payload: $payload');
    // Xử lý payload, ví dụ điều hướng đến màn hình chi tiết của trạm
    // MyApp.navigatorKey.currentState?.pushNamed('/stationDetail', arguments: payload);
  }
  // ... xử lý hành động khác ...
}

// Callback khi người dùng nhấn vào thông báo (khi app bị terminated và được mở lại từ thông báo)
// Hàm này phải được khai báo ở top-level hoặc là một static method và được đánh dấu @pragma('vm:entry-point').
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
  final String? payload = notificationResponse.payload;
  print('[NotificationService] Terminated CLICK. Payload: $payload');
  // Xử lý payload
  // Lưu ý: Ở đây bạn không thể thực hiện các tác vụ UI phức tạp trực tiếp.
  // Có thể lưu payload vào SharedPreferences để xử lý khi app khởi động hoàn toàn.
}

// // Callback cho iOS < 10 (ít dùng)
// void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
//   // Xử lý thông báo
//   print('[NotificationService] iOS < 10 onDidReceiveLocalNotification. Payload: $payload');
// }