// lib/models/station.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'AQIUtils.dart';

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

// Computed properties
  int get aqi => AQIUtils.calculateAQI(nongDoBuiMin);
  Color get aqiColor => AQIUtils.getAQIColor(aqi);

// Getter với localization
  String getAqiDescription(AppLocalizations l10n) =>
      AQIUtils.getAQIDescription(aqi, l10n);
  String getAqiMessage(AppLocalizations l10n) =>
      AQIUtils.getAQIMessage(aqi, l10n);

// Getter fallback (không localized)
  String get aqiDescription => AQIUtils.getAQIDescription(aqi);
  String get aqiMessage => AQIUtils.getAQIMessage(aqi);

// Phương thức static để lấy tên địa điểm từ tọa độ với localization
  static Future<String> getPlaceNameFromCoordinatesLocalized(
      double latitude,
      double longitude,
      AppLocalizations l10n
      ) async {
    try {
      if (latitude == 0.0 && longitude == 0.0) {
        return l10n.unknownLocation ?? "Vị trí không xác định (tọa độ mặc định)";
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
          return "${l10n.location ?? "Vị trí"} (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
        }
        return addressParts.join(", ");
      }
      return "${l10n.addressNotFound ?? "Không tìm thấy địa chỉ"} (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
    } catch (e) {
      print("${l10n.errorGettingLocation ?? "Lỗi khi lấy tên địa điểm từ tọa độ"}: $e");
      return "${l10n.errorLocation ?? "Lỗi lấy vị trí"} (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
    }
  }

// Phương thức static để lấy tên địa điểm từ tọa độ (fallback - không localized)
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

// Helper method để xử lý data_points chung
  static Map<String, dynamic> _processDataPoints(Map<dynamic, dynamic> dataPoints, String stationId) {
    double latestPm25 = 0.0;
    double latestTemp = 0.0;
    double latestHumidity = 0.0;
    DateTime? latestTimestamp;
    int maxTimestamp = 0;

    dataPoints.forEach((pushId, record) {
      if (record is Map) {
        dynamic timeValue = record['time'];
        int currentTimestamp = 0;

        if (timeValue is int) {
          currentTimestamp = timeValue;
        } else if (timeValue is Map && timeValue['.sv'] == 'timestamp') {
          // Bỏ qua placeholder timestamp khi xác định dữ liệu mới nhất cho Station object
          print("[Station._processDataPoints] Server timestamp placeholder found for $stationId, pushId $pushId. Ignoring for latest data determination.");
          return;
        } else {
          print("[Station._processDataPoints] Invalid or missing time value for $stationId, pushId $pushId. Record: $record");
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

    return {
      'pm25': latestPm25,
      'temp': latestTemp,
      'humidity': latestHumidity,
      'timestamp': latestTimestamp,
    };
  }

// Static async method để tạo Station từ dữ liệu Firebase với localization
  static Future<Station> fromFirebaseLocalized(
      Map<dynamic, dynamic> data,
      String thietBiId,
      AppLocalizations l10n
      ) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;

    // Lấy địa chỉ từ tọa độ với localization
    String fetchedViTri = await Station.getPlaceNameFromCoordinatesLocalized(lat, long, l10n);

    double latestPm25 = 0.0;
    double latestTemp = 0.0;
    double latestHumidity = 0.0;
    DateTime? latestTimestamp;

    if (data['data_points'] != null && data['data_points'] is Map) {
      Map<dynamic, dynamic> dataPoints = data['data_points'] as Map<dynamic, dynamic>;
      var processedData = _processDataPoints(dataPoints, thietBiId);

      latestPm25 = processedData['pm25'];
      latestTemp = processedData['temp'];
      latestHumidity = processedData['humidity'];
      latestTimestamp = processedData['timestamp'];
    } else {
      print("[Station.fromFirebaseLocalized] 'data_points' node is missing or not a Map for station $thietBiId.");
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

// Static async method để tạo Station từ dữ liệu Firebase (fallback - không localized)
  static Future<Station> fromFirebase(Map<dynamic, dynamic> data, String thietBiId) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;

    // Lấy địa chỉ từ tọa độ
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

    double latestPm25 = 0.0;
    double latestTemp = 0.0;
    double latestHumidity = 0.0;
    DateTime? latestTimestamp;

    if (data['data_points'] != null && data['data_points'] is Map) {
      Map<dynamic, dynamic> dataPoints = data['data_points'] as Map<dynamic, dynamic>;
      var processedData = _processDataPoints(dataPoints, thietBiId);

      latestPm25 = processedData['pm25'];
      latestTemp = processedData['temp'];
      latestHumidity = processedData['humidity'];
      latestTimestamp = processedData['timestamp'];
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

// Factory constructor để tạo Station từ Firestore snapshot với localization
  static Future<Station> fromMapLocalized(
      Map<String, dynamic> data,
      String documentId,
      AppLocalizations l10n
      ) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;
    String fetchedViTri = await Station.getPlaceNameFromCoordinatesLocalized(lat, long, l10n);

    double pm25 = (data['pm25'] as num?)?.toDouble() ?? 0.0;
    double temp = (data['temp'] as num?)?.toDouble() ?? 0.0;
    double humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
    DateTime? timestamp;

    if (data['time'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(data['time']);
    }

    return Station._(
      id: documentId,
      viTri: fetchedViTri,
      nongDoBuiMin: pm25,
      nhietDo: temp,
      doAm: humidity,
      latitude: lat,
      longitude: long,
      timestamp: timestamp,
    );
  }

// Factory constructor để tạo Station từ Firestore snapshot (fallback)
  static Future<Station> fromMap(Map<String, dynamic> data, String documentId) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

    double pm25 = (data['pm25'] as num?)?.toDouble() ?? 0.0;
    double temp = (data['temp'] as num?)?.toDouble() ?? 0.0;
    double humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
    DateTime? timestamp;

    if (data['time'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(data['time']);
    }

    return Station._(
      id: documentId,
      viTri: fetchedViTri,
      nongDoBuiMin: pm25,
      nhietDo: temp,
      doAm: humidity,
      latitude: lat,
      longitude: long,
      timestamp: timestamp,
    );
  }

// Static async method để tạo Station từ JSON với localization
  static Future<Station> fromJsonLocalized(
      Map<String, dynamic> json,
      String thietBiId,
      AppLocalizations l10n
      ) async {
    double lat = (json['lat'] ?? 0).toDouble();
    double long = (json['long'] ?? 0).toDouble();
    String fetchedViTri = await Station.getPlaceNameFromCoordinatesLocalized(lat, long, l10n);

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
      timestamp: timestamp,
    );
  }

// Static async method để tạo Station từ JSON (fallback)
  static Future<Station> fromJson(Map<String, dynamic> json, String thietBiId) async {
    double lat = (json['lat'] ?? 0).toDouble();
    double long = (json['long'] ?? 0).toDouble();
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

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
      timestamp: timestamp,
    );
  }

// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'name': viTri,
      'pm25': nongDoBuiMin,
      'temp': nhietDo,
      'humidity': doAm,
      'lat': latitude,
      'long': longitude,
      'time': timestamp?.millisecondsSinceEpoch,
    };
  }

// Override toString for debugging
  @override
  String toString() {
    return 'Station(id: $id, viTri: $viTri, aqi: $aqi, pm25: $nongDoBuiMin, temp: $nhietDo, humidity: $doAm)';
  }

// Override equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Station && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}