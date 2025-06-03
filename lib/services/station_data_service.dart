// lib/services/station_data_service.dart
import 'package:geolocator/geolocator.dart';
import '../models/station.dart'; // Đường dẫn đến file station.dart của bạn

class StationDataService {
  /// Tìm trạm gần nhất dựa trên vị trí người dùng và danh sách tất cả các trạm.
  ///
  /// [userLocation]: Vị trí hiện tại của người dùng.
  /// [allStations]: Danh sách tất cả các trạm đo.
  /// Trả về đối tượng `Station` gần nhất, hoặc `null` nếu không tìm thấy.
  Station? findNearestStation(Position userLocation, List<Station> allStations) {
    if (allStations.isEmpty) {
      print("[StationDataService] Danh sách trạm rỗng, không thể tìm trạm gần nhất.");
      return null;
    }

    Station? nearestStation;
    double? minDistance;

    for (var station in allStations) {
      // Đảm bảo trạm có tọa độ hợp lệ
      // (station.dart của bạn đã có xử lý giá trị mặc định 0.0, 0.0 nếu null,
      // nhưng bạn có thể thêm kiểm tra chặt chẽ hơn ở đây nếu muốn)
      // if (station.latitude == 0.0 && station.longitude == 0.0) {
      //   print("[StationDataService] Trạm ${station.id} có tọa độ không hợp lệ, bỏ qua.");
      //   continue;
      // }

      double distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        station.latitude,
        station.longitude,
      );

      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
        nearestStation = station;
      }
    }

    if (nearestStation != null) {
      print("[StationDataService] Trạm gần nhất tìm thấy: ${nearestStation.viTri} (ID: ${nearestStation.id}) với khoảng cách ${minDistance?.toStringAsFixed(2)} mét.");
    } else {
      print("[StationDataService] Không tìm thấy trạm nào gần vị trí người dùng.");
    }
    return nearestStation;
  }

  /// Cung cấp mô tả mức độ AQI cho nội dung thông báo.
  /// Hàm này đơn giản và không phụ thuộc vào `AppLocalizations` để dễ sử dụng trong background.
  ///
  /// [aqi]: Chỉ số AQI.
  /// Trả về một chuỗi mô tả mức độ AQI.
  String getAqiDescriptionForNotification(int aqi) {
    // Bạn có thể sử dụng lại logic từ AQIUtils.getAQIDescription nếu nó
    // có phiên bản không cần AppLocalizations, hoặc định nghĩa ở đây.
    // Ví dụ:
    if (aqi <= 50) return "Tốt";
    if (aqi <= 100) return "Trung bình";
    if (aqi <= 150) return "Kém";
    if (aqi <= 200) return "Xấu";
    if (aqi <= 300) return "Rất xấu";
    return "Nguy hại";
    // Hoặc, nếu AQIUtils.dart của bạn có hàm tương tự không cần l10n:
    // return AQIUtils.getAQIDescription(aqi); // Đảm bảo hàm này tồn tại và phù hợp
  }
}