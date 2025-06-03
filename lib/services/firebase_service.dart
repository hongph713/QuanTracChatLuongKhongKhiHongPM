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

import 'dart:async';
import 'package:firebase_database/firebase_database.dart'; // SỬ DỤNG CHO REALTIME DATABASE
import '../models/station.dart'; // Đảm bảo đường dẫn này đúng

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final String _stationsNodePath = 'cacThietBiQuanTrac'; // Định nghĩa đường dẫn nút trạm

  // Giữ nguyên hàm stream hiện tại của bạn nếu cần
  Stream<List<Station>> getStationsStream() {
    print(
        "[FirebaseService] Attempting to get stream from Realtime Database node: '$_stationsNodePath'");

    return _databaseRef
        .child(_stationsNodePath)
        .onValue
        .asyncMap((DatabaseEvent event) async {
      print("[FirebaseService] Data event received from '$_stationsNodePath'");
      List<Station> stations = [];
      if (event.snapshot.value != null) {
        try {
          final Map<dynamic, dynamic> allStationsData =
          event.snapshot.value as Map<dynamic, dynamic>;
          List<Future<Station>> futureStations = [];

          allStationsData.forEach((stationId, stationData) {
            if (stationData is Map) {
              // Sử dụng Station.fromFirebase như đã thảo luận,
              // hàm này sẽ xử lý việc lấy dữ liệu mới nhất từ data_points
              // và geocoding (phiên bản không localized cho background)
              futureStations.add(Station.fromFirebase(
                  stationData as Map<dynamic, dynamic>, stationId.toString()));
            }
          });

          stations = await Future.wait(futureStations);
          print("[FirebaseService] Stream: Parsed ${stations.length} stations.");
        } catch (e, s) {
          print("[FirebaseService] Stream: Error parsing stations data: $e");
          print(s);
          return <Station>[];
        }
      } else {
        print("[FirebaseService] Stream: No data found at node '$_stationsNodePath'.");
      }
      return stations;
    });
  }

  // *** BỔ SUNG HÀM NÀY CHO BACKGROUND SERVICE ***
  // Hàm này sẽ lấy danh sách trạm một lần (không phải stream)
  // Rất phù hợp để sử dụng trong background task
  Future<List<Station>> getAllStations() async {
    print(
        "[FirebaseService] Attempting to fetch stations once from Realtime Database node: '$_stationsNodePath'");
    List<Station> stations = [];
    try {
      final DataSnapshot snapshot = await _databaseRef.child(_stationsNodePath).get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> allStationsData =
        snapshot.value as Map<dynamic, dynamic>;
        List<Future<Station>> futureStations = [];

        allStationsData.forEach((stationId, stationData) {
          if (stationData is Map) {
            // Sử dụng Station.fromFirebase (phiên bản không localized)
            // để đảm bảo hoạt động tốt trong background
            futureStations.add(Station.fromFirebase(
                stationData as Map<dynamic, dynamic>, stationId.toString()));
          }
        });

        // Đợi tất cả các đối tượng Station (bao gồm cả geocoding nếu có) được tạo
        stations = await Future.wait(futureStations);
        print("[FirebaseService] getAllStations: Successfully fetched and parsed ${stations.length} stations.");
      } else {
        print("[FirebaseService] getAllStations: No data found at node '$_stationsNodePath'.");
      }
    } catch (e, s) {
      print("[FirebaseService] getAllStations: Error fetching stations data: $e");
      print(s);
      // Trả về danh sách rỗng hoặc ném lỗi tùy theo cách bạn muốn xử lý
    }
    return stations;
  }
}

