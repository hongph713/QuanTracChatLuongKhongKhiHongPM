// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/station.dart'; // Đảm bảo đường dẫn này đúng
//
// class FirebaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Stream<List<Station>> getStationsStream() {
//     return _firestore.collection('cacThietBiQuanTrac')
//         .snapshots()
//         .asyncMap((snapshot) async { // Thay .map bằng .asyncMap và thêm async
//       try {
//         // Tạo danh sách các Future<Station>
//         List<Future<Station>> futureStations = snapshot.docs
//             .map((doc) => Station.fromMap(doc.data() as Map<String, dynamic>, doc.id)) // Thêm cast (as Map<String, dynamic>) nếu cần
//             .toList();
//
//         // Đợi tất cả các Future hoàn thành
//         List<Station> stations = await Future.wait(futureStations);
//         return stations;
//       } catch (e) {
//         print('Lỗi parse dữ liệu hoặc lấy địa chỉ trạm: $e');
//         return []; // Trả về danh sách rỗng khi có lỗi
//       }
//     });
//   }
// }


// lib/services/firebase_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart'; // SỬ DỤNG CHO REALTIME DATABASE
import '../models/station.dart'; // Đảm bảo đường dẫn này đúng

class FirebaseService {
  // Sửa thành DatabaseReference cho Realtime Database
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Hàm này sẽ lấy thông tin của tất cả các trạm (trạng thái mới nhất)
  // Dựa trên cấu trúc Firebase bạn cung cấp, mỗi trạm có lat, long tĩnh
  // và một danh sách các data_points bên trong nó.
  // Station model sẽ cần lấy thông tin mới nhất từ data_points.
  Stream<List<Station>> getStationsStream() {
    String stationsNodePath = 'cacThietBiQuanTrac';
    print(
        "[FirebaseService] Attempting to get stream from Realtime Database node: '$stationsNodePath'");

    return _databaseRef
        .child(stationsNodePath)
        .onValue
        .asyncMap((DatabaseEvent event) async {
      print("[FirebaseService] Data event received from '$stationsNodePath'");
      List<Station> stations = [];
      if (event.snapshot.value != null) {
        try {
          final Map<dynamic, dynamic> allStationsData = event.snapshot
              .value as Map<dynamic, dynamic>;
          List<Future<Station>> futureStations = [];

          allStationsData.forEach((stationId, stationData) {
            if (stationData is Map) {
              // Gọi Station.fromFirebase, hàm này cần được thiết kế để đọc
              // lat/long từ stationData và dữ liệu mới nhất từ stationData['data_points']
              // như chúng ta đã cập nhật trong station_model_dart_v4
              futureStations.add(
                  Station.fromFirebase(stationData as Map<dynamic, dynamic>,
                      stationId.toString())
              );
            }
          });

          // Đợi tất cả các Station object (có thể bao gồm geocoding) được tạo
          stations = await Future.wait(futureStations);
          print("[FirebaseService] Parsed ${stations.length} stations.");
        } catch (e, s) {
          print("[FirebaseService] Error parsing stations data: $e");
          print(s);
          return <Station>[]; // Trả về danh sách rỗng khi có lỗi
        }
      } else {
        print("[FirebaseService] No data found at node '$stationsNodePath'.");
      }
      return stations;
    });
  }
}
// Nếu bạn cần một hàm riêng để lấy lịch sử cho HistoryChartWidget
// (Hàm này đã có trong HistoryChartWidget, chỉ để tham khảo cách lấy dữ liệu)
// Stream<List<HistoricalDataPoint>> getStationHistoryStream(String stationId) {
//   String historyPath = 'cacThietBiQuanTrac/$stationId/data_points';
//   return _databaseRef.child(historyPath).orderByChild('time').onValue.map((event) {
//     List<HistoricalDataPoint> history = [];
//     if (event.snapshot.value != null) {
//       final Map<dynamic, dynamic> dataPoints = event.snapshot.value as Map<dynamic, dynamic>;
//       dataPoints.forEach((key, record) {
//         if (record is Map) {
//           try {
//             final int? timestampMs = record['time'] as int?;
//             final num? pm25Value = record['pm25'] as num?;
//             if (timestampMs != null && pm25Value != null) {
//               history.add(HistoricalDataPoint(
//                 timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
//                 value: pm25Value.toDouble(), // Hoặc tính AQI ở đây nếu cần
//               ));
//             }
//           } catch (e) {
//             print("Error parsing history point $key for $stationId: $e");
//           }
//         }
//       });
//       history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//     }
//     return history;
//   });
// }


// import 'package:firebase_database/firebase_database.dart';
// import 'package:geolocator/geolocator.dart';
// import '../models/station.dart';
// import 'dart:math';
//
// class FirebaseService {
//   static final FirebaseService _instance = FirebaseService._internal();
//   factory FirebaseService() => _instance;
//   FirebaseService._internal();
//
//   static FirebaseService get instance => _instance;
//
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//
//   Future<Station?> getNearestStation(double userLat, double userLng) async {
//     try {
//       final snapshot = await _databaseRef.child('cacThietBiQuanTrac').once();
//
//       if (snapshot.snapshot.value == null) return null;
//
//       final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
//       Station? nearestStation;
//       double minDistance = double.infinity;
//
//       for (var entry in data.entries) {
//         try {
//           String key = entry.key;
//           var value = entry.value;
//
//           if (value['lat'] == null || value['long'] == null) continue;
//
//           Station station = await Station.fromFirebase(value, key);
//
//           double distance = _calculateDistance(
//               userLat, userLng,
//               station.latitude, station.longitude
//           );
//
//           if (distance < minDistance) {
//             minDistance = distance;
//             nearestStation = station;
//           }
//         } catch (e) {
//           print('Error processing station: $e');
//           continue;
//         }
//       }
//
//       return nearestStation;
//     } catch (e) {
//       print('Error getting nearest station: $e');
//       return null;
//     }
//   }
//
//   double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
//     const double earthRadius = 6371; // km
//
//     double dLat = _degreesToRadians(lat2 - lat1);
//     double dLng = _degreesToRadians(lng2 - lng1);
//
//     double a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
//             sin(dLng / 2) * sin(dLng / 2);
//
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//
//     return earthRadius * c;
//   }
//
//   double _degreesToRadians(double degrees) {
//     return degrees * (pi / 180);
//   }
// }
