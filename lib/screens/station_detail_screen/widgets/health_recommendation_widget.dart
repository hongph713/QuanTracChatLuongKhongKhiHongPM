// lib/screens/station_detail_screen/widgets/health_recommendation_widget.dart
import 'package:flutter/material.dart';
// TODO: Đảm bảo đường dẫn import này đúng
import '../../../models/AQIUtils.dart'; // Cần hàm để lấy danh sách khuyến nghị

// Định nghĩa một class hoặc cấu trúc dữ liệu cho khuyến nghị
class HealthRecommendation {
  final IconData iconData;
  final String text;
  final String? subText; // Ví dụ: "Mua một trình theo dõi"

  HealthRecommendation({required this.iconData, required this.text, this.subText});
}

class HealthRecommendationWidget extends StatelessWidget {
  final int aqi;

  const HealthRecommendationWidget({Key? key, required this.aqi}) : super(key: key);

  // Hàm này sẽ lấy danh sách khuyến nghị dựa trên AQI
  // Bạn cần triển khai logic này, có thể trong AQIUtils.dart
  List<HealthRecommendation> _getRecommendations(int currentAqi) {
    // Đây là dữ liệu mẫu, bạn cần thay thế bằng logic thực tế dựa trên các hình ảnh bạn cung cấp
    // và map với các khoảng AQI.
    Color recommendationColor = AQIUtils.getAQIColor(currentAqi);

    if (currentAqi <= 50) { // Tốt (Xanh lá)
      return [
        HealthRecommendation(iconData: Icons.directions_bike, text: 'Tận hưởng các hoạt động ngoài trời'),
        HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Mở cửa sổ để đưa không khí sạch và trong lành vào nhà'),
      ];
    } else if (currentAqi <= 100) { // Trung bình (Vàng)
      return [
        HealthRecommendation(iconData: Icons.directions_bike, text: 'Các nhóm nhạy cảm nên giảm tập thể dục ngoài trời'),
        HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài'),
        HealthRecommendation(iconData: Icons.masks_outlined, text: 'Các nhóm nhạy cảm nên đeo khẩu trang khi ra ngoài'),
        HealthRecommendation(iconData: Icons.air_outlined, text: 'Các nhóm nhạy cảm nên khởi động máy lọc không khí'),
      ];
    } else if (currentAqi <= 150) { // Không tốt cho nhóm nhạy cảm (Cam)
      return [
        HealthRecommendation(iconData: Icons.directions_bike, text: 'Giảm vận động ngoài trời'),
        HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài'),
        HealthRecommendation(iconData: Icons.masks_outlined, text: 'Các nhóm nhạy cảm nên đeo khẩu trang khi ra ngoài'),
        HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí'),
      ];
    } else if (currentAqi <= 200) { // Không tốt cho sức khỏe (Đỏ)
      return [
        HealthRecommendation(iconData: Icons.directions_bike, text: 'Tránh tập thể dục ngoài trời'),
        HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài'),
        HealthRecommendation(iconData: Icons.masks_outlined, text: 'Đeo khẩu trang khi ra ngoài'),
        HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí'),
      ];
    } else if (currentAqi <= 300) { // Rất không tốt (Tím)
      return [
        HealthRecommendation(iconData: Icons.directions_bike, text: 'Tránh tập thể dục ngoài trời'),
        HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài'),
        HealthRecommendation(iconData: Icons.masks_outlined, text: 'Đeo khẩu trang khi ra ngoài'),
        HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí'),
      ];
    } else { // Nguy hiểm (Nâu)
      return [
        HealthRecommendation(iconData: Icons.cancel_outlined, text: 'Tránh tập thể dục ngoài trời'),
        HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài'),
        HealthRecommendation(iconData: Icons.masks_outlined, text: 'Đeo khẩu trang khi ra ngoài'),
        HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí'),
      ];
    }
    // Bạn cần hoàn thiện logic này dựa trên 6 mức độ AQI và các hình ảnh khuyến nghị bạn đã cung cấp.
  }


  @override
  Widget build(BuildContext context) {
    List<HealthRecommendation> recommendations = _getRecommendations(aqi);
    Color iconColor = AQIUtils.getAQIColor(aqi);

    if (recommendations.isEmpty) {
      return const SizedBox.shrink(); // Không hiển thị gì nếu không có khuyến nghị
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recommendations.map((rec) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rec.iconData, color: iconColor, size: 36.0),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.text,
                          style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                        ),
                        if (rec.subText != null && rec.subText!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              rec.subText!,
                              style: TextStyle(fontSize: 13.0, color: Colors.blue[700], fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
