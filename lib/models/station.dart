// lib/models/station.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'AQIUtils.dart';

class Station {
  final String id;
  final String viTri;
  final double latitude;
  final double longitude;
  final double nongDoBuiMin;
  final double nhietDo;
  final double doAm;
  final DateTime? timestamp;

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

  // --- GETTERS ---

  String get formattedTempWithUnit {
    final formattedValue = NumberFormat("0.#").format(nhietDo);
    return '$formattedValue°C';
  }

  int get aqi => AQIUtils.calculateAQI(nongDoBuiMin);
  Color get aqiColor => AQIUtils.getAQIColor(aqi);

  String getAqiDescription(AppLocalizations l10n) =>
      AQIUtils.getAQIDescription(aqi, l10n);
  String getAqiMessage(AppLocalizations l10n) =>
      AQIUtils.getAQIMessage(aqi, l10n);

  String get aqiDescription => AQIUtils.getAQIDescription(aqi);
  String get aqiMessage => AQIUtils.getAQIMessage(aqi);

  // --- PRIVATE HELPER ---

  static double _parseAndDivide(dynamic value) {
    if (value == null) return 0.0;
    double numericValue = 0.0;
    if (value is num) {
      numericValue = value.toDouble();
    } else if (value is String) {
      numericValue = double.tryParse(value) ?? 0.0;
    }
    return numericValue / 100.0;
  }

  // --- STATIC METHODS & FACTORY CONSTRUCTORS ---

  // --- PHIÊN BẢN CÓ LOCALIZATION (ĐÃ THÊM LẠI) ---

  static Future<String> getPlaceNameFromCoordinatesLocalized(
      double latitude, double longitude, AppLocalizations l10n) async {
    try {
      if (latitude == 0.0 && longitude == 0.0) {
        return l10n.unknownLocation ?? "Vị trí không xác định";
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) place.subAdministrativeArea!,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea!,
        ];
        return addressParts.join(', ');
      }
      return l10n.addressNotFound ?? "Không tìm thấy địa chỉ";
    } catch (e) {
      return l10n.errorLocation ?? "Lỗi lấy vị trí";
    }
  }

  static Future<Station> fromFirebaseLocalized(
      Map<dynamic, dynamic> data, String thietBiId, AppLocalizations l10n) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;
    String fetchedViTri = await Station.getPlaceNameFromCoordinatesLocalized(lat, long, l10n);

    double latestPm25 = 0.0, latestTemp = 0.0, latestHumidity = 0.0;
    DateTime? latestTimestamp;
    int maxTimestamp = 0;

    data.forEach((key, value) {
      if (value is Map && value['time'] is int) {
        int currentTimestamp = value['time'];
        if (currentTimestamp > maxTimestamp) {
          maxTimestamp = currentTimestamp;
          latestPm25 = _parseAndDivide(value['pm25']);
          latestTemp = _parseAndDivide(value['temp']);
          latestHumidity = _parseAndDivide(value['humidity']);
          latestTimestamp = DateTime.fromMillisecondsSinceEpoch(currentTimestamp);
        }
      }
    });

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

  static Future<Station> fromMapLocalized(
      Map<String, dynamic> data, String documentId, AppLocalizations l10n) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;
    String fetchedViTri = await Station.getPlaceNameFromCoordinatesLocalized(lat, long, l10n);

    double pm25 = _parseAndDivide(data['pm25']);
    double temp = _parseAndDivide(data['temp']);
    double humidity = _parseAndDivide(data['humidity']);
    DateTime? timestamp = (data['time'] is int) ? DateTime.fromMillisecondsSinceEpoch(data['time']) : null;

    return Station._(
      id: documentId, viTri: fetchedViTri, nongDoBuiMin: pm25, nhietDo: temp,
      doAm: humidity, latitude: lat, longitude: long, timestamp: timestamp,
    );
  }

  // --- PHIÊN BẢN KHÔNG CÓ LOCALIZATION ---

  static Future<String> getPlaceNameFromCoordinates(double latitude, double longitude) async {
    try {
      if (latitude == 0.0 && longitude == 0.0) return "Vị trí không xác định";
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) place.subAdministrativeArea!,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea!,
        ];
        return addressParts.join(', ');
      }
      return "Không tìm thấy địa chỉ";
    } catch (e) {
      return "Lỗi lấy vị trí";
    }
  }

  static Future<Station> fromFirebase(Map<dynamic, dynamic> data, String thietBiId) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

    double latestPm25 = 0.0, latestTemp = 0.0, latestHumidity = 0.0;
    DateTime? latestTimestamp;
    int maxTimestamp = 0;

    data.forEach((key, value) {
      if (value is Map && value['time'] is int) {
        int currentTimestamp = value['time'];
        if (currentTimestamp > maxTimestamp) {
          maxTimestamp = currentTimestamp;
          latestPm25 = _parseAndDivide(value['pm25']);
          latestTemp = _parseAndDivide(value['temp']);
          latestHumidity = _parseAndDivide(value['humidity']);
          latestTimestamp = DateTime.fromMillisecondsSinceEpoch(currentTimestamp);
        }
      }
    });

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

  static Future<Station> fromMap(Map<String, dynamic> data, String documentId) async {
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double long = (data['long'] as num?)?.toDouble() ?? 0.0;
    String fetchedViTri = await Station.getPlaceNameFromCoordinates(lat, long);

    double pm25 = _parseAndDivide(data['pm25']);
    double temp = _parseAndDivide(data['temp']);
    double humidity = _parseAndDivide(data['humidity']);
    DateTime? timestamp = (data['time'] is int) ? DateTime.fromMillisecondsSinceEpoch(data['time']) : null;

    return Station._(
      id: documentId, viTri: fetchedViTri, nongDoBuiMin: pm25, nhietDo: temp,
      doAm: humidity, latitude: lat, longitude: long, timestamp: timestamp,
    );
  }

  // --- INSTANCE METHODS & OVERRIDES ---

  Map<String, dynamic> toMap() {
    return {
      'name': viTri, 'pm25': nongDoBuiMin, 'temp': nhietDo, 'humidity': doAm,
      'lat': latitude, 'long': longitude, 'time': timestamp?.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'Station(id: $id, viTri: $viTri, aqi: $aqi, pm25: $nongDoBuiMin, temp: $nhietDo, humidity: $doAm)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Station && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}