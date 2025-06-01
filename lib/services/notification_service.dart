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