// lib/models/station.dart
import 'dart:ui'; // Bạn có import dart:ui, có thể là cho Color
import 'package:flutter/material.dart'; // Thêm Material để dùng Color nếu dart:ui không đủ
import 'package:geocoding/geocoding.dart';
import 'AQIUtils.dart'; // Đảm bảo bạn đã import AQIUtils

class Station {
  final String id; // Document ID/Key từ Firebase (ví dụ: "id_1_caugiay")
  final String viTri; // Tên/vị trí của trạm, lấy từ geocoding
  final double latitude;
  final double longitude;
  final double nongDoBuiMin; // PM2.5 của bản ghi mới nhất
  final double nhietDo;      // Nhiệt độ của bản ghi mới nhất
  final double doAm;         // Độ ẩm của bản ghi mới nhất
  final DateTime? timestamp; // Thời gian của bản ghi đo mới nhất

  // Constructor private, chỉ được gọi từ các factory methods
  Station._({
    required this.id,
    required this.viTri,
    required this.latitude,
    required this.longitude,
    required this.nongDoBuiMin,
    required this.nhietDo,
    required this.doAm,
    this.timestamp,
  });

  int get aqi => AQIUtils.calculateAQI(nongDoBuiMin);
  Color get aqiColor => AQIUtils.getAQIColor(aqi); // Giả sử AQIUtils có hàm này
  String get aqiDescription => AQIUtils.getAQIDescription(aqi);

  // Phương thức static để lấy tên địa điểm từ tọa độ (giữ nguyên từ code của bạn)
  static Future<String> getPlaceNameFromCoordinates(double latitude, double longitude) async {
    try {
      if (latitude == 0.0 && longitude == 0.0) {
        return "Vị trí không xác định (tọa độ mặc định)";
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];
        if (place.name != null && place.name!.isNotEmpty && place.name != place.street) {
          addressParts.add(place.name!);
        }
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (addressParts.isEmpty && place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (addressParts.isEmpty) {
          return "Vị trí (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
        }
        return addressParts.join(", ");
      }
      return "Không tìm thấy địa chỉ (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
    } catch (e) {
      print("Lỗi khi lấy tên địa điểm từ tọa độ: $e");
      return "Lỗi lấy vị trí (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
    }
  }

  // Static async method để tạo Station từ dữ liệu Firebase (Realtime Database)
  // data ở đây là Map của một trạm cụ thể, ví dụ: data của "id_1_caugiay"
  static Future<Station> fromFirebase(Map<dynamic, dynamic> data, String thietBiId) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;

    // Lấy địa chỉ từ tọa độ
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

    double latestPm25 = 0.0;
    double latestTemp = 0.0;
    double latestHumidity = 0.0;
    DateTime? latestTimestamp;
    int maxTimestamp = 0;

    if (data['data_points'] != null && data['data_points'] is Map) {
      Map<dynamic, dynamic> dataPoints = data['data_points'] as Map<dynamic, dynamic>;

      dataPoints.forEach((pushId, record) {
        if (record is Map) {
          dynamic timeValue = record['time'];
          int currentTimestamp = 0;

          if (timeValue is int) {
            currentTimestamp = timeValue;
          } else if (timeValue is Map && timeValue['.sv'] == 'timestamp') {
            // Bỏ qua placeholder timestamp khi xác định dữ liệu mới nhất cho Station object
            print("[Station.fromFirebase] Server timestamp placeholder found for $thietBiId, pushId $pushId. Ignoring for latest data determination.");
            return;
          } else {
            print("[Station.fromFirebase] Invalid or missing time value for $thietBiId, pushId $pushId. Record: $record");
            return;
          }

          if (currentTimestamp > maxTimestamp) {
            maxTimestamp = currentTimestamp;
            latestPm25 = (record['pm25'] as num?)?.toDouble() ?? 0.0;
            latestTemp = (record['temp'] as num?)?.toDouble() ?? 0.0;
            latestHumidity = (record['humidity'] as num?)?.toDouble() ?? 0.0;
            latestTimestamp = DateTime.fromMillisecondsSinceEpoch(currentTimestamp);
          }
        }
      });
    } else {
      print("[Station.fromFirebase] 'data_points' node is missing or not a Map for station $thietBiId.");
    }

    return Station._(
      id: thietBiId,
      viTri: fetchedViTri,
      latitude: lat,
      longitude: long,
      nongDoBuiMin: latestPm25,
      nhietDo: latestTemp,
      doAm: latestHumidity,
      timestamp: latestTimestamp,
    );
  }

  // Factory constructor để tạo Station từ Firestore snapshot (giữ lại từ code của bạn)
  // Lưu ý: Firestore thường dùng Map<String, dynamic>
  static Future<Station> fromMap(Map<String, dynamic> data, String documentId) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

    // Logic đọc data_points tương tự như fromFirebase nếu cấu trúc Firestore giống
    // Hoặc nếu Firestore chỉ lưu dữ liệu mới nhất ở cấp document:
    double pm25 = (data['pm25'] as num?)?.toDouble() ?? 0.0; // Giả sử pm25 ở cấp document
    double temp = (data['temp'] as num?)?.toDouble() ?? 0.0;
    double humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
    DateTime? timestamp;
    if (data['time'] is int) { // Giả sử time ở cấp document và là int
      timestamp = DateTime.fromMillisecondsSinceEpoch(data['time']);
    } //else if (data['time'] is Timestamp) { // Firestore Timestamp object
      //timestamp = (data['time'] as Timestamp).toDate();
    //}


    // NẾU Firestore của bạn cũng có cấu trúc data_points bên trong document,
    // bạn cần lặp qua data_points tương tự như hàm fromFirebase.
    // Ví dụ (cần điều chỉnh cho phù hợp với cấu trúc Firestore của bạn):
    // if (data['data_points'] != null && data['data_points'] is Map) {
    //   Map<String, dynamic> dataPoints = data['data_points'] as Map<String, dynamic>;
    //   // ... logic tìm bản ghi mới nhất trong data_points ...
    // }


    return Station._(
      id: documentId,
      viTri: fetchedViTri,
      nongDoBuiMin: pm25, // Sử dụng giá trị đã đọc
      nhietDo: temp,     // Sử dụng giá trị đã đọc
      doAm: humidity,    // Sử dụng giá trị đã đọc
      latitude: lat,
      longitude: long,
      timestamp: timestamp, // Sử dụng giá trị đã đọc
    );
  }

  // Static async method để tạo Station từ JSON (giữ lại từ code của bạn)
  static Future<Station> fromJson(Map<String, dynamic> json, String thietBiId) async {
    double lat = (json['lat'] ?? 0).toDouble();
    double long = (json['long'] ?? 0).toDouble();
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

    // Logic đọc data_points tương tự như fromFirebase nếu JSON có cấu trúc đó
    // Hoặc nếu JSON chỉ lưu dữ liệu mới nhất:
    double pm25 = (json['pm25'] ?? 0).toDouble();
    double temp = (json['temp'] ?? 0).toDouble();
    double humidity = (json['humidity'] ?? 0).toDouble();
    DateTime? timestamp;
    if (json['time'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['time']);
    }


    return Station._(
        id: thietBiId,
        viTri: fetchedViTri,
        doAm: humidity,
        nhietDo: temp,
        nongDoBuiMin: pm25,
        latitude: lat,
        longitude: long,
        timestamp: timestamp
    );
  }


  Map<String, dynamic> toMap() {
    return {
      // 'name' trong toMap giờ sẽ là địa chỉ đã được geocode (viTri).
      // Nếu bạn muốn lưu một 'name' gốc hoặc khác, bạn cần một trường riêng.
      'name': viTri, // Hoặc bạn có thể muốn lưu một trường name gốc nếu có
      'pm25': nongDoBuiMin,
      'temp': nhietDo,
      'humidity': doAm,
      'lat': latitude,
      'long': longitude,
      'time': timestamp?.millisecondsSinceEpoch, // Lưu timestamp nếu có
      // Không lưu trực tiếp data_points ở đây, vì đây là model cho một Station (trạng thái mới nhất)
    };
  }
}

