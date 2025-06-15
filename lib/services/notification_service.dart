// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// //
// // class NotificationService {
// //   // Singleton pattern của bạn đã rất tốt, giữ nguyên
// //   static final NotificationService _instance = NotificationService._internal();
// //   factory NotificationService() => _instance;
// //   NotificationService._internal();
// //
// //   final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
// //
// //   /// Khởi tạo dịch vụ thông báo.
// //   /// Cần được gọi ở cả main isolate và background isolate.
// //   Future<void> initialize() async {
// //     const AndroidInitializationSettings initializationSettingsAndroid =
// //     AndroidInitializationSettings('@mipmap/ic_launcher'); // Sử dụng icon mặc định của app
// //
// //     const InitializationSettings initializationSettings = InitializationSettings(
// //       android: initializationSettingsAndroid,
// //       // iOS: Thêm cấu hình nếu cần
// //     );
// //
// //     await _plugin.initialize(initializationSettings);
// //   }
// //
// //   /// Hiển thị thông báo AQI định kỳ.
// //   /// Tên hàm và tham số được đặt lại cho rõ ràng hơn.
// //   Future<void> showAqiNotification({
// //     required String stationName,
// //     required int aqi,
// //     required String aqiMessage,
// //   }) async {
// //     final String title = 'AQI tại $stationName: $aqi';
// //
// //     final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
// //       'periodic_aqi_channel_v1', // ID của channel
// //       'Cập nhật AQI định kỳ', // Tên channel hiển thị trong cài đặt của điện thoại
// //       channelDescription: 'Kênh thông báo chỉ số chất lượng không khí định kỳ.',
// //
// //       // Tinh chỉnh nhỏ: Vì đây là thông báo định kỳ không khẩn cấp,
// //       // ta nên dùng mức độ quan trọng và ưu tiên mặc định để không làm phiền người dùng.
// //       importance: Importance.max, // <<< TĂNG LÊN MỨC CAO NHẤT
// //       priority: Priority.high,
// //
// //       // Các thuộc tính khác bạn có thể muốn thêm
// //       // styleInformation: BigTextStyleInformation(aqiMessage), // Hiển thị nội dung dài hơn
// //     );
// //
// //     final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
// //
// //     // Sử dụng một ID cố định cho loại thông báo này để thông báo mới sẽ
// //     // cập nhật/thay thế thông báo cũ, tránh làm đầy thanh thông báo của người dùng.
// //     const int notificationId = 123;
// //
// //     await _plugin.show(notificationId, title, aqiMessage, platformDetails);
// //   }
// // }
// //
//
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'dart:math';
// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();
//
//   final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
//
//   // Cập nhật hàm initialize để nhận một hàm callback TÙY CHỌN
//   Future<void> initialize({Function(NotificationResponse)? onDidReceiveNotificationResponse}) async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
//
//     await _plugin.initialize(
//       initializationSettings,
//       // Đây là hàm sẽ được gọi khi người dùng bấm vào thông báo
//       onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
//     );
//   }
//
//   // Cập nhật hàm showAqiNotification để nhận thêm `payload`
//   Future<void> showAqiNotification({
//     required String stationName,
//     required int aqi,
//     required String aqiMessage,
//     String? payload, // Thêm payload (ID của trạm)
//   }) async {
//     final String title = 'Cập nhật chất lượng không khí hôm nay!';
//
//     final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'periodic_aqi_channel_v2', // Dùng ID mới để đảm bảo cài đặt được cập nhật
//       'Cập nhật AQI định kỳ',
//       channelDescription: 'Kênh thông báo chỉ số chất lượng không khí định kỳ.',
//       importance: Importance.max,
//       priority: Priority.high,
//       fullScreenIntent: true,
//     );
//
//     final NotificationDetails platformDetails =
//     NotificationDetails(android: androidDetails);
//
//     final int notificationId = Random().nextInt(100000);
//
//     await _plugin.show(
//       notificationId,
//       title,
//       aqiMessage,
//       platformDetails,
//       payload: payload, // Gửi payload cùng với thông báo
//     );
//   }
// }

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize({Function(NotificationResponse)? onDidReceiveNotificationResponse}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  // Hàm này giờ sẽ nhận title và body đã được dịch
  Future<void> showAqiNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'periodic_aqi_channel_v3', // Đổi ID để đảm bảo cài đặt mới được áp dụng
      'Cập nhật AQI định kỳ',
      channelDescription: 'Kênh thông báo chỉ số chất lượng không khí định kỳ.',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );

    final NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    final int notificationId = Random().nextInt(100000);

    await _plugin.show(
      notificationId,
      title, // Hiển thị tiêu đề đã được dịch
      body,  // Hiển thị nội dung đã được dịch
      platformDetails,
      payload: payload,
    );
  }
}

