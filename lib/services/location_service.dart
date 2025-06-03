// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Lấy vị trí hiện tại của người dùng.
  ///
  /// Trả về một đối tượng `Position` nếu thành công.
  /// Ném ra một `Future.error` với thông báo lỗi nếu:
  /// - Dịch vụ vị trí bị tắt.
  /// - Quyền truy cập vị trí bị từ chối.
  /// - Quyền truy cập vị trí bị từ chối vĩnh viễn.
  /// Trả về `null` nếu có lỗi không mong muốn khác khi lấy vị trí.
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có được bật không.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Dịch vụ vị trí không được bật, không thể tiếp tục
      // truy cập vị trí hoặc yêu cầu người dùng bật dịch vụ vị trí.
      print("[LocationService] Dịch vụ vị trí bị tắt.");
      return Future.error('Dịch vụ vị trí bị tắt.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Quyền bị từ chối, lần sau người dùng có thể thử lại
        // (ví dụ, bằng cách hiển thị lại yêu cầu quyền).
        print("[LocationService] Quyền truy cập vị trí bị từ chối.");
        return Future.error('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Quyền bị từ chối vĩnh viễn, xử lý phù hợp.
      // Hướng dẫn người dùng vào cài đặt ứng dụng để cấp quyền.
      print("[LocationService] Quyền truy cập vị trí bị từ chối vĩnh viễn.");
      return Future.error(
          'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt ứng dụng.');
    }

    // Khi quyền đã được cấp (hoặc được cấp trước đó),
    // chúng ta có thể truy cập vị trí của thiết bị.
    try {
      print("[LocationService] Đang lấy vị trí hiện tại...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Có thể điều chỉnh độ chính xác
        // timeLimit: Duration(seconds: 10) // Có thể đặt giới hạn thời gian
      );
      print("[LocationService] Vị trí lấy được: ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      print("[LocationService] Lỗi không mong muốn khi lấy vị trí: $e");
      // Trả về null hoặc ném lỗi tùy theo cách bạn muốn xử lý ở nơi gọi
      return null;
    }
  }
}