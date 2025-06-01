import 'package:flutter/material.dart';
// Đảm bảo các đường dẫn import này chính xác với cấu trúc project của bạn
import '../../../models/station.dart';
import '../../../models/AQIUtils.dart'; // Sử dụng file AQIUtils của bạn
import '../../station_detail_screen/station_detail_screen.dart'; // Import màn hình chi tiết

class StationInfoCard extends StatelessWidget {
  final Station station;

  const StationInfoCard({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sử dụng station.aqi trực tiếp nếu model Station đã có sẵn
    final int aqi = station.aqi;

    // Gọi các hàm từ AQIUtils
    final Color aqiColor = AQIUtils.getAQIColor(aqi);
    final Color aqiColorBgr = AQIUtils.getAQIColorBgr(aqi);
    final String aqiMessage = AQIUtils.getAQIMessage(aqi); // Hàm này cần được thêm vào AQIUtils.dart
    final String aqiCategory = AQIUtils.getAQIDescription(aqi); // Sử dụng getAQIDescription từ file của bạn

    return GestureDetector(
      onTap: () {
        print("StationInfoCard tapped, navigating to detail for ${station.viTri}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StationDetailScreen(station: station),
          ),
        );
      },
      child: Card(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: aqiColorBgr,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Icon(Icons.location_on, color: Colors.black54, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      station.viTri,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                aqi.toString(),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: aqiColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                aqiCategory, // Sử dụng aqiCategory từ AQIUtils.getAQIDescription
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: aqiColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoItem(
                    icon: Icons.thermostat_outlined,
                    value: '${station.nhietDo.toStringAsFixed(1)}°C',
                    label: 'Nhiệt độ',
                  ),
                  _buildInfoItem(
                    icon: Icons.water_drop_outlined,
                    value: '${station.doAm.toStringAsFixed(0)}%',
                    label: 'Độ ẩm',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: aqiColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Icon(
                        AQIUtils.getWarningIcon(aqi), // Hàm này cần được thêm vào AQIUtils.dart
                        color: Colors.black,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          aqiMessage,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueGrey[700], size: 26),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
