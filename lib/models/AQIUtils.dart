import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Lớp để lưu trữ thông tin khuyến nghị sức khỏe
class HealthRecommendation {
  final IconData iconData;
  final String text;
  final String? subText; // Ví dụ: "Mua một trình theo dõi"
  final Color iconColor; // Màu của icon sẽ theo màu AQI

  HealthRecommendation({
    required this.iconData,
    required this.text,
    this.subText,
    required this.iconColor,
  });
}

class AQIUtils {
// Tính chỉ số AQI dựa trên nồng độ bụi mịn PM2.5 (μg/m³)
  static int calculateAQI(double pm25) {
    const List<double> pm25Breakpoints = [0, 55, 155, 255, 355, 425, 605];
    const List<int> aqiBreakpoints = [0, 51, 101, 151, 201, 301, 500];

    int i = 0;
    while (i < pm25Breakpoints.length - 1) {
      if (pm25 < pm25Breakpoints[i + 1]) break;
      i++;
    }

    if (pm25 >= pm25Breakpoints[pm25Breakpoints.length - 1]) {
      return aqiBreakpoints[aqiBreakpoints.length - 1];
    }
    if (pm25 < pm25Breakpoints[0]) {
      return aqiBreakpoints[0];
    }

    double ih = aqiBreakpoints[i + 1].toDouble();
    double il = aqiBreakpoints[i].toDouble();
    double bph = pm25Breakpoints[i + 1];
    double bpl = pm25Breakpoints[i];

    if (bph == bpl) {
      return il.round();
    }

    double aqiValue = ((ih - il) / (bph - bpl)) * (pm25 - bpl) + il;
    return aqiValue.round();
  }

// Lấy màu dựa trên chỉ số AQI
  static Color getAQIColor(int aqi) {
    if (aqi <= 50) return Color(0xFF9CCC65);
    if (aqi <= 100) return Color(0xFFFFCA28);
    if (aqi <= 150) return Color(0xFFFF9843);
    if (aqi <= 200) return Color(0xFFEF5350);
    if (aqi <= 300) return Color(0xFFAB47BC);
    return Color(0xFF885A6C); // Màu nâu (SaddleBrown)
  }

  static Color getAQIColorBgr(int aqi) {
    if (aqi <= 50) return const Color(0xFFF0FFF0);
    if (aqi <= 100) return const Color(0xFFFFFFF0);
    if (aqi <= 150) return const Color(0xFFFFF7F0);
    if (aqi <= 200) return const Color(0xFFFEF2F2);
    if (aqi <= 300) return const Color(0xFFF5F0FA);
    return const Color(0xFFF9F5F2); // Màu nâu (SaddleBrown)
  }

// Lấy mô tả/phân loại mức độ AQI với localization
  static String getAQIDescription(int aqi, [AppLocalizations? l10n]) {
    if (l10n != null) {
      // Sử dụng localization nếu có
      if (aqi <= 50) return l10n.aqiGood;
      if (aqi <= 100) return l10n.aqiModerate;
      if (aqi <= 150) return l10n.aqiUnhealthyForSensitive;
      if (aqi <= 200) return l10n.aqiUnhealthy;
      if (aqi <= 300) return l10n.aqiVeryUnhealthy;
      return l10n.aqiHazardous;
    } else {
      // Fallback cho trường hợp không có localization
      if (aqi <= 50) return 'Tốt';
      if (aqi <= 100) return 'Trung bình';
      if (aqi <= 150) return 'Không lành mạnh cho nhóm nhạy cảm';
      if (aqi <= 200) return 'Không lành mạnh';
      if (aqi <= 300) return 'Rất không lành mạnh';
      return 'Nguy hiểm';
    }
  }

// Lấy thông điệp cảnh báo/khuyến nghị chung dựa trên AQI với localization
  static String getAQIMessage(int aqi, [AppLocalizations? l10n]) {
    if (l10n != null) {
      // Sử dụng localization nếu có
      if (aqi <= 50) return l10n.aqiMessageGood;
      if (aqi <= 100) return l10n.aqiMessageModerate;
      if (aqi <= 150) return l10n.aqiMessageUnhealthyForSensitive;
      if (aqi <= 200) return l10n.aqiMessageUnhealthy;
      if (aqi <= 300) return l10n.aqiMessageVeryUnhealthy;
      return l10n.aqiMessageHazardous;
    } else {
      // Fallback cho trường hợp không có localization
      if (aqi <= 50) return 'Chất lượng không khí hôm nay tốt!';
      if (aqi <= 100) return 'Chất lượng không khí trung bình. Nhóm nhạy cảm nên cẩn thận!';
      if (aqi <= 150) return 'Không tốt cho nhóm nhạy cảm. Hạn chế hoạt động ngoài trời!';
      if (aqi <= 200) return 'Có hại cho sức khỏe. Mọi người nên hạn chế hoạt động ngoài trời!';
      if (aqi <= 300) return 'Rất có hại cho sức khỏe. Mọi người nên ở trong nhà!';
      return 'Nguy hiểm. Mọi người nên ở trong nhà và bật máy lọc không khí!';
    }
  }

  static String getAQINoti(int aqi, {String lang = 'vi'}) {
    if (lang == 'en') {
      if (aqi <= 50) return "Today's air quality is good. Enjoy your outdoor activities!";
      if (aqi <= 100) return "Today's air quality is moderate. Sensitive groups should reduce outdoor activities!";
      if (aqi <= 150) return "Today's air quality is unhealthy for sensitive groups. Limit outdoor activities!";
      if (aqi <= 200) return "Today's air quality is unhealthy. Everyone should limit outdoor activities!";
      if (aqi <= 300) return "Today's air quality is very unhealthy. Everyone should stay indoors!";
      return "Today's air quality is hazardous. Everyone should stay indoors and turn on an air purifier!";
    }
    // Mặc định là Tiếng Việt
    if (aqi <= 50) return 'Chất lượng không khí hôm nay tốt.Hãy tận hưởng các hoạt động ngoài trời!';
    if (aqi <= 100) return 'Chất lượng không khí hôm nay trung bình. Các nhóm nhạy cảm nên giảm hoạt động ngoài trời!';
    if (aqi <= 150) return 'Chất lượng không khí hôm nay không tốt cho nhóm nhạy cảm. Hạn chế hoạt  ngoài trời!';
    if (aqi <= 200) return 'Chất lượng không khí hôm nay có hại cho sức khỏe. Mọi người nên hạn chế hoạt động ngoài trời!';
    if (aqi <= 300) return 'Chất lượng không khí hôm nay rất có hại cho sức khỏe. Mọi người nên ở trong nhà!';
    return 'Chất lượng không khí hôm nay cực kỳ có hại. Mọi người nên ở trong nhà và bật máy lọc không khí!';
  }

// HÀM ĐƯỢC THÊM LẠI để tương thích với StationInfoCard hiện tại
  static IconData getWarningIcon(int aqi) {
    if (aqi <= 50) return Icons.check_circle_outline_rounded;
    if (aqi <= 100) return Icons.info_outline_rounded;
    if (aqi <= 150) return Icons.warning_amber_rounded;
    if (aqi <= 200) return Icons.warning_amber_rounded;
    if (aqi <= 300) return Icons.report_problem_outlined;
    return Icons.gpp_bad_outlined;
  }

// Lấy Icon cảnh báo chính dựa trên AQI (có thể dùng hàm này hoặc getWarningIcon)
  static IconData getRecommendationIconData(int aqi) {
    // Logic này giống hệt getWarningIcon, bạn có thể chọn dùng một trong hai
    // Hoặc làm cho getWarningIcon gọi getRecommendationIconData
    if (aqi <= 50) return Icons.check_circle_outline_rounded; // Tốt
    if (aqi <= 100) return Icons.info_outline_rounded; // Trung bình
    if (aqi <= 150) return Icons.warning_amber_rounded; // Không lành mạnh cho nhóm nhạy cảm
    if (aqi <= 200) return Icons.warning_amber_rounded; // Không lành mạnh
    if (aqi <= 300) return Icons.report_problem_outlined; // Rất không lành mạnh
    return Icons.gpp_bad_outlined; // Nguy hiểm
  }

// HÀM MỚI: Lấy danh sách các khuyến nghị sức khỏe chi tiết với localization
  static List<HealthRecommendation> getHealthRecommendations(int aqi, [AppLocalizations? l10n]) {
    Color iconColor = getAQIColor(aqi);
    List<HealthRecommendation> recommendations = [];

    if (l10n != null) {
      // Sử dụng localization
      if (aqi <= 50) { // Tốt (Xanh lá)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: l10n.healthRecommendationGoodOutdoor, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: l10n.healthRecommendationGoodWindows, iconColor: iconColor),
        ]);
      } else if (aqi <= 100) { // Trung bình (Vàng)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: l10n.healthRecommendationModerateOutdoor, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: l10n.healthRecommendationModerateWindows, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: l10n.healthRecommendationModerateMask, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: l10n.healthRecommendationModerateAirPurifier, iconColor: iconColor),
        ]);
      } else if (aqi <= 150) { // Không tốt cho nhóm nhạy cảm (Cam)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: l10n.healthRecommendationUnhealthySensitiveOutdoor, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: l10n.healthRecommendationUnhealthySensitiveWindows, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: l10n.healthRecommendationUnhealthySensitiveMask, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: l10n.healthRecommendationUnhealthySensitiveAirPurifier, iconColor: iconColor),
        ]);
      } else if (aqi <= 200) { // Không tốt cho sức khỏe (Đỏ)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: l10n.healthRecommendationUnhealthyOutdoor, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: l10n.healthRecommendationUnhealthyWindows, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: l10n.healthRecommendationUnhealthyMask, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: l10n.healthRecommendationUnhealthyAirPurifier, iconColor: iconColor),
        ]);
      } else if (aqi <= 300) { // Rất không tốt (Tím)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: l10n.healthRecommendationVeryUnhealthyOutdoor, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: l10n.healthRecommendationVeryUnhealthyWindows, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: l10n.healthRecommendationVeryUnhealthyMask, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: l10n.healthRecommendationVeryUnhealthyAirPurifier, iconColor: iconColor),
        ]);
      } else { // Nguy hiểm (Nâu)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: l10n.healthRecommendationHazardousOutdoor, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: l10n.healthRecommendationHazardousWindows, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: l10n.healthRecommendationHazardousMask, iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: l10n.healthRecommendationHazardousAirPurifier, iconColor: iconColor),
        ]);
      }
    } else {
      // Fallback cho trường hợp không có localization
      if (aqi <= 50) { // Tốt (Xanh lá)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: 'Tận hưởng các hoạt động ngoài trời', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Mở cửa sổ để đưa không khí sạch và trong lành vào nhà', iconColor: iconColor),
        ]);
      } else if (aqi <= 100) { // Trung bình (Vàng)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: 'Các nhóm nhạy cảm nên giảm tập thể dục ngoài trời', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: 'Các nhóm nhạy cảm nên đeo khẩu trang khi ra ngoài', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: 'Các nhóm nhạy cảm nên khởi động máy lọc không khí', iconColor: iconColor),
        ]);
      } else if (aqi <= 150) { // Không tốt cho nhóm nhạy cảm (Cam)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: 'Giảm vận động ngoài trời', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: 'Các nhóm nhạy cảm nên đeo khẩu trang khi ra ngoài', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí', iconColor: iconColor),
        ]);
      } else if (aqi <= 200) { // Không tốt cho sức khỏe (Đỏ)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: 'Tránh tập thể dục ngoài trời', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng cửa sổ để tránh không khí bẩn bên ngoài', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: 'Đeo khẩu trang khi ra ngoài', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí', iconColor: iconColor),
        ]);
      } else if (aqi <= 300) { // Rất không tốt (Tím)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: 'Tránh mọi hoạt động ngoài trời', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng kín cửa sổ. Ở trong nhà.', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: 'Bắt buộc đeo khẩu trang chất lượng cao nếu phải ra ngoài', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí liên tục', iconColor: iconColor),
        ]);
      } else { // Nguy hiểm (Nâu)
        recommendations.addAll([
          HealthRecommendation(iconData: Icons.directions_bike, text: 'Tránh tuyệt đối mọi hoạt động ngoài trời. Ở trong nhà.', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.sensor_window_outlined, text: 'Đóng kín tất cả cửa sổ. Không ra ngoài nếu không cần thiết.', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.masks_outlined, text: 'Bắt buộc đeo khẩu trang N95/FFP2 nếu phải ra ngoài.', iconColor: iconColor),
          HealthRecommendation(iconData: Icons.air_outlined, text: 'Chạy máy lọc không khí ở mức cao nhất.', iconColor: iconColor),
        ]);
      }
    }
    return recommendations;
  }

// Tạo BitmapDescriptor cho marker với màu tương ứng với AQI
  static Future<BitmapDescriptor> getMarkerIconByAQI(int aqi) async {
    Color color = getAQIColor(aqi);
    return BitmapDescriptor.defaultMarkerWithHue(_getHueFromColor(color));
  }

// Chuyển đổi Color sang giá trị Hue cho BitmapDescriptor
  static double _getHueFromColor(Color color) {
    if (color == Color(0xFF9CCC65)) return BitmapDescriptor.hueGreen;
    if (color == Color(0xFFFFCA28)) return BitmapDescriptor.hueYellow;
    if (color == Color(0xFFFF9843)) return BitmapDescriptor.hueOrange;
    if (color == Color(0xFFEF5350)) return BitmapDescriptor.hueRed;
    if (color == Color(0xFFAB47BC)) return BitmapDescriptor.hueViolet;
    if (color == Color(0xFF885A6C)) return BitmapDescriptor.hueRose;
    return BitmapDescriptor.hueRed; // Mặc định
  }
}