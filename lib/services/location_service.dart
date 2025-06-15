// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const String _latKey = 'user_latitude';
  static const String _lonKey = 'user_longitude';

  Future<bool> requestPermission() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }

  // Lấy vị trí hiện tại và lưu vào SharedPreferences
  Future<void> getCurrentPositionAndSave() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lonKey, position.longitude);
      print('Đã lưu vị trí lần cuối: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Lỗi khi lấy và lưu vị trí: $e');
    }
  }

  // Lấy vị trí đã lưu (dùng cho tác vụ nền)
  Future<Position?> getSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lon = prefs.getDouble(_lonKey);

    if (lat != null && lon != null) {
      return Position(
        latitude: lat, longitude: lon, timestamp: DateTime.now(), accuracy: 0,
        altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );
    }
    return null;
  }
}