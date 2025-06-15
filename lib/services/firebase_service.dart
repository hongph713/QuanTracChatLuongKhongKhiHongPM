// // lib/services/firebase_service.dart
// import 'dart:async';
// import 'package:firebase_database/firebase_database.dart'; // SỬ DỤNG CHO REALTIME DATABASE
// import '../models/station.dart'; // Đảm bảo đường dẫn này đúng
//
// class FirebaseService {
//   // Sửa thành DatabaseReference cho Realtime Database
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//
//   // Hàm này sẽ lấy thông tin của tất cả các trạm (trạng thái mới nhất)
//   // Dựa trên cấu trúc Firebase bạn cung cấp, mỗi trạm có lat, long tĩnh
//   // và một danh sách các data_points bên trong nó.
//   // Station model sẽ cần lấy thông tin mới nhất từ data_points.
//   Stream<List<Station>> getStationsStream() {
//     String stationsNodePath = 'cacThietBiQuanTrac';
//     print(
//         "[FirebaseService] Attempting to get stream from Realtime Database node: '$stationsNodePath'");
//
//     return _databaseRef
//         .child(stationsNodePath)
//         .onValue
//         .asyncMap((DatabaseEvent event) async {
//       print("[FirebaseService] Data event received from '$stationsNodePath'");
//       List<Station> stations = [];
//       if (event.snapshot.value != null) {
//         try {
//           final Map<dynamic, dynamic> allStationsData = event.snapshot
//               .value as Map<dynamic, dynamic>;
//           List<Future<Station>> futureStations = [];
//
//           allStationsData.forEach((stationId, stationData) {
//             if (stationData is Map) {
//               // Gọi Station.fromFirebase, hàm này cần được thiết kế để đọc
//               // lat/long từ stationData và dữ liệu mới nhất từ stationData['data_points']
//               // như chúng ta đã cập nhật trong station_model_dart_v4
//               futureStations.add(
//                   Station.fromFirebase(stationData as Map<dynamic, dynamic>,
//                       stationId.toString())
//               );
//             }
//           });
//
//           // Đợi tất cả các Station object (có thể bao gồm geocoding) được tạo
//           stations = await Future.wait(futureStations);
//           print("[FirebaseService] Parsed ${stations.length} stations.");
//         } catch (e, s) {
//           print("[FirebaseService] Error parsing stations data: $e");
//           print(s);
//           return <Station>[]; // Trả về danh sách rỗng khi có lỗi
//         }
//       } else {
//         print("[FirebaseService] No data found at node '$stationsNodePath'.");
//       }
//       return stations;
//     });
//   }
// }
// // Nếu bạn cần một hàm riêng để lấy lịch sử cho HistoryChartWidget
// // (Hàm này đã có trong HistoryChartWidget, chỉ để tham khảo cách lấy dữ liệu)
// // Stream<List<HistoricalDataPoint>> getStationHistoryStream(String stationId) {
// //   String historyPath = 'cacThietBiQuanTrac/$stationId/data_points';
// //   return _databaseRef.child(historyPath).orderByChild('time').onValue.map((event) {
// //     List<HistoricalDataPoint> history = [];
// //     if (event.snapshot.value != null) {
// //       final Map<dynamic, dynamic> dataPoints = event.snapshot.value as Map<dynamic, dynamic>;
// //       dataPoints.forEach((key, record) {
// //         if (record is Map) {
// //           try {
// //             final int? timestampMs = record['time'] as int?;
// //             final num? pm25Value = record['pm25'] as num?;
// //             if (timestampMs != null && pm25Value != null) {
// //               history.add(HistoricalDataPoint(
// //                 timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
// //                 value: pm25Value.toDouble(), // Hoặc tính AQI ở đây nếu cần
// //               ));
// //             }
// //           } catch (e) {
// //             print("Error parsing history point $key for $stationId: $e");
// //           }
// //         }
// //       });
// //       history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
// //     }
// //     return history;
// //   });
// // }

// import 'dart:async';
// import 'package:firebase_database/firebase_database.dart'; // SỬ DỤNG CHO REALTIME DATABASE
// import '../models/station.dart'; // Đảm bảo đường dẫn này đúng
//
// class FirebaseService {
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//   final String _stationsNodePath = 'cacThietBiQuanTrac'; // Định nghĩa đường dẫn nút trạm
//
//   // Giữ nguyên hàm stream hiện tại của bạn nếu cần
//   Stream<List<Station>> getStationsStream() {
//     print(
//         "[FirebaseService] Attempting to get stream from Realtime Database node: '$_stationsNodePath'");
//
//     return _databaseRef
//         .child(_stationsNodePath)
//         .onValue
//         .asyncMap((DatabaseEvent event) async {
//       print("[FirebaseService] Data event received from '$_stationsNodePath'");
//       List<Station> stations = [];
//       if (event.snapshot.value != null) {
//         try {
//           final Map<dynamic, dynamic> allStationsData =
//           event.snapshot.value as Map<dynamic, dynamic>;
//           List<Future<Station>> futureStations = [];
//
//           allStationsData.forEach((stationId, stationData) {
//             if (stationData is Map) {
//               // Sử dụng Station.fromFirebase như đã thảo luận,
//               // hàm này sẽ xử lý việc lấy dữ liệu mới nhất từ data_points
//               // và geocoding (phiên bản không localized cho background)
//               futureStations.add(Station.fromFirebase(
//                   stationData as Map<dynamic, dynamic>, stationId.toString()));
//             }
//           });
//
//           stations = await Future.wait(futureStations);
//           print("[FirebaseService] Stream: Parsed ${stations.length} stations.");
//         } catch (e, s) {
//           print("[FirebaseService] Stream: Error parsing stations data: $e");
//           print(s);
//           return <Station>[];
//         }
//       } else {
//         print("[FirebaseService] Stream: No data found at node '$_stationsNodePath'.");
//       }
//       return stations;
//     });
//   }
//
//   // *** BỔ SUNG HÀM NÀY CHO BACKGROUND SERVICE ***
//   // Hàm này sẽ lấy danh sách trạm một lần (không phải stream)
//   // Rất phù hợp để sử dụng trong background task
//   Future<List<Station>> getAllStations() async {
//     print(
//         "[FirebaseService] Attempting to fetch stations once from Realtime Database node: '$_stationsNodePath'");
//     List<Station> stations = [];
//     try {
//       final DataSnapshot snapshot = await _databaseRef.child(_stationsNodePath).get();
//
//       if (snapshot.exists && snapshot.value != null) {
//         final Map<dynamic, dynamic> allStationsData =
//         snapshot.value as Map<dynamic, dynamic>;
//         List<Future<Station>> futureStations = [];
//
//         allStationsData.forEach((stationId, stationData) {
//           if (stationData is Map) {
//             // Sử dụng Station.fromFirebase (phiên bản không localized)
//             // để đảm bảo hoạt động tốt trong background
//             futureStations.add(Station.fromFirebase(
//                 stationData as Map<dynamic, dynamic>, stationId.toString()));
//           }
//         });
//
//         // Đợi tất cả các đối tượng Station (bao gồm cả geocoding nếu có) được tạo
//         stations = await Future.wait(futureStations);
//         print("[FirebaseService] getAllStations: Successfully fetched and parsed ${stations.length} stations.");
//       } else {
//         print("[FirebaseService] getAllStations: No data found at node '$_stationsNodePath'.");
//       }
//     } catch (e, s) {
//       print("[FirebaseService] getAllStations: Error fetching stations data: $e");
//       print(s);
//       // Trả về danh sách rỗng hoặc ném lỗi tùy theo cách bạn muốn xử lý
//     }
//     return stations;
//   }
// }

// import 'dart:async';
// import 'package:firebase_database/firebase_database.dart';
// import '../models/station.dart'; // Đảm bảo đường dẫn model của bạn là chính xác
//
// class FirebaseService {
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//   final String _stationsNodePath = 'cacThietBiQuanTrac';
//
//   /// Lấy dữ liệu trạm dưới dạng Stream để cập nhật UI theo thời gian thực.
//   /// Hàm này phù hợp khi bạn muốn giao diện người dùng tự động thay đổi khi có dữ liệu mới trên Firebase.
//   Stream<List<Station>> getStationsStream() {
//     return _databaseRef.child(_stationsNodePath).onValue.asyncMap((event) async {
//       if (!event.snapshot.exists || event.snapshot.value == null) {
//         print("[FirebaseService - Stream] Không tìm thấy dữ liệu tại nút '$_stationsNodePath'.");
//         return [];
//       }
//
//       try {
//         final Map<dynamic, dynamic> allStationsData = event.snapshot.value as Map<dynamic, dynamic>;
//
//         // Sử dụng Future.wait để xử lý đồng thời việc tạo các đối tượng Station,
//         // bao gồm cả việc geocoding có thể mất thời gian.
//         final futureStations = allStationsData.entries.map((entry) {
//           final stationId = entry.key.toString();
//           final stationData = entry.value as Map<dynamic, dynamic>;
//           // Sử dụng phiên bản fromFirebase, hàm này cần xử lý việc lấy dữ liệu mới nhất
//           return Station.fromFirebase(stationData, stationId);
//         });
//
//         final stations = await Future.wait(futureStations);
//         print("[FirebaseService - Stream] Đã phân tích ${stations.length} trạm.");
//         return stations;
//       } catch (e, s) {
//         print("[FirebaseService - Stream] Lỗi khi phân tích dữ liệu trạm: $e");
//         print(s);
//         return [];
//       }
//     });
//   }
//
//   /// Lấy danh sách tất cả các trạm một lần duy nhất.
//   /// Hàm này là lựa chọn TỐT NHẤT cho tác vụ nền (background service)
//   /// vì nó không mở một stream liên tục, giúp tiết kiệm tài nguyên.
//   Future<List<Station>> getAllStations() async {
//     print("[FirebaseService - FetchOnce] Bắt đầu lấy dữ liệu trạm một lần.");
//     try {
//       final DataSnapshot snapshot = await _databaseRef.child(_stationsNodePath).get();
//
//       if (!snapshot.exists || snapshot.value == null) {
//         print("[FirebaseService - FetchOnce] Không tìm thấy dữ liệu tại nút '$_stationsNodePath'.");
//         return [];
//       }
//
//       final Map<dynamic, dynamic> allStationsData = snapshot.value as Map<dynamic, dynamic>;
//
//       final futureStations = allStationsData.entries.map((entry) {
//         final stationId = entry.key.toString();
//         final stationData = entry.value as Map<dynamic, dynamic>;
//         // Sử dụng phiên bản fromFirebase (không có l10n) để đảm bảo hoạt động trong background
//         return Station.fromFirebase(stationData, stationId);
//       });
//
//       final stations = await Future.wait(futureStations);
//       print("[FirebaseService - FetchOnce] Đã lấy và phân tích thành công ${stations.length} trạm.");
//       return stations;
//
//     } catch (e, s) {
//       print("[FirebaseService - FetchOnce] Lỗi khi lấy dữ liệu trạm: $e");
//       print(s);
//       return [];
//     }
//   }
// }
//

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/station.dart'; // Đảm bảo đường dẫn model của bạn là chính xác

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final String _stationsNodePath = 'cacThietBiQuanTrac';

  /// Lấy dữ liệu trạm dưới dạng Stream để cập nhật UI theo thời gian thực.
  /// Giờ đây nó cũng có thể nhận mã ngôn ngữ.
  Stream<List<Station>> getStationsStream({String lang = 'vi'}) {
    return _databaseRef.child(_stationsNodePath).onValue.asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        print("[FirebaseService - Stream] Không tìm thấy dữ liệu tại nút '$_stationsNodePath'.");
        return [];
      }

      try {
        final Map<dynamic, dynamic> allStationsData = event.snapshot.value as Map<dynamic, dynamic>;

        final futureStations = allStationsData.entries.map((entry) {
          final stationId = entry.key.toString();
          final stationData = entry.value as Map<dynamic, dynamic>;
          // Truyền `lang` vào hàm fromFirebase để xử lý geocoding nếu cần
          return Station.fromFirebase(stationData, stationId, lang: lang);
        });

        final stations = await Future.wait(futureStations);
        print("[FirebaseService - Stream] Đã phân tích ${stations.length} trạm.");
        return stations;
      } catch (e, s) {
        print("[FirebaseService - Stream] Lỗi khi phân tích dữ liệu trạm: $e");
        print(s);
        return [];
      }
    });
  }

  /// <<< CẬP NHẬT TẠI ĐÂY >>>
  /// Lấy danh sách tất cả các trạm một lần duy nhất.
  /// Hàm này đã được cập nhật để nhận tham số `lang`.
  Future<List<Station>> getAllStations({String lang = 'vi'}) async {
    print("[FirebaseService - FetchOnce] Bắt đầu lấy dữ liệu trạm một lần với ngôn ngữ: '$lang'");
    try {
      final DataSnapshot snapshot = await _databaseRef.child(_stationsNodePath).get();

      if (!snapshot.exists || snapshot.value == null) {
        print("[FirebaseService - FetchOnce] Không tìm thấy dữ liệu tại nút '$_stationsNodePath'.");
        return [];
      }

      final Map<dynamic, dynamic> allStationsData = snapshot.value as Map<dynamic, dynamic>;

      final futureStations = allStationsData.entries.map((entry) {
        final stationId = entry.key.toString();
        final stationData = entry.value as Map<dynamic, dynamic>;
        // Truyền `lang` vào hàm fromFirebase để đảm bảo hoạt động trong background
        return Station.fromFirebase(stationData, stationId, lang: lang);
      });

      final stations = await Future.wait(futureStations);
      print("[FirebaseService - FetchOnce] Đã lấy và phân tích thành công ${stations.length} trạm.");
      return stations;

    } catch (e, s) {
      print("[FirebaseService - FetchOnce] Lỗi khi lấy dữ liệu trạm: $e");
      print(s);
      return [];
    }
  }
}
