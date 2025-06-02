import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../models/station.dart';
import '../../../models/AQIUtils.dart';
import '../../station_detail_screen/station_detail_screen.dart';

class StationInfoCard extends StatelessWidget {
  final Station station;

  const StationInfoCard({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // Fallback nếu localization chưa sẵn sàng
      return _buildFallbackCard(context);
    }

    final int aqi = station.aqi;

    // Sử dụng các method localized từ Station model
    final Color aqiColor = station.aqiColor;
    final Color aqiColorBgr = AQIUtils.getAQIColorBgr(aqi);
    final String aqiMessage = station.getAqiMessage(l10n);
    final String aqiCategory = station.getAqiDescription(l10n);

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
                aqiCategory,
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
                    context: context,
                    icon: Icons.thermostat_outlined,
                    value: '${station.nhietDo.toStringAsFixed(1)}°C',
                    label: l10n.temperature ?? 'Nhiệt độ',
                  ),
                  _buildInfoItem(
                    context: context,
                    icon: Icons.water_drop_outlined,
                    value: '${station.doAm.toStringAsFixed(0)}%',
                    label: l10n.humidity ?? 'Độ ẩm',
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
                        AQIUtils.getWarningIcon(aqi),
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

  Widget _buildFallbackCard(BuildContext context) {
    // Fallback card khi localization chưa sẵn sàng
    final int aqi = station.aqi;
    final Color aqiColor = station.aqiColor;
    final Color aqiColorBgr = AQIUtils.getAQIColorBgr(aqi);
    final String aqiMessage = station.aqiMessage; // Fallback không localized
    final String aqiCategory = station.aqiDescription; // Fallback không localized

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
                aqiCategory,
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
                    context: context,
                    icon: Icons.thermostat_outlined,
                    value: '${station.nhietDo.toStringAsFixed(1)}°C',
                    label: 'Nhiệt độ', // Fallback tiếng Việt
                  ),
                  _buildInfoItem(
                    context: context,
                    icon: Icons.water_drop_outlined,
                    value: '${station.doAm.toStringAsFixed(0)}%',
                    label: 'Độ ẩm', // Fallback tiếng Việt
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
                        AQIUtils.getWarningIcon(aqi),
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

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueGrey[700], size: 26),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}