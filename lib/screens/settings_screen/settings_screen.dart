import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:datn_20242/services/locale_provider.dart'; // Đường dẫn đến file locale_provider.dart

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedTheme = 'light';
  bool notificationsEnabled = true;

  final List<Map<String, String>> languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  ];

  final List<Map<String, dynamic>> themes = [
    {'code': 'light', 'name': 'light', 'icon': Icons.wb_sunny},
    {'code': 'dark', 'name': 'dark', 'icon': Icons.nightlight_round},
    {'code': 'system', 'name': 'system', 'icon': Icons.settings},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          l10n?.settingsTitle ?? 'Cài đặt',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Giao diện Section
            _buildSectionTitle(l10n?.interfaceSectionTitle ?? 'Giao diện'),
            const SizedBox(height: 12),
            _buildLanguageItem(),
            const SizedBox(height: 12),
            _buildThemeItem(),

            const SizedBox(height: 32),

            // Thông báo Section
            _buildSectionTitle(l10n?.notificationsSectionTitle ?? 'Thông báo'),
            const SizedBox(height: 12),
            _buildNotificationItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLanguageItem() {
    final l10n = AppLocalizations.of(context);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLanguage = languages.firstWhere(
              (lang) => lang['code'] == languageProvider.currentLocale.languageCode,
        );

        // Lấy tên ngôn ngữ theo localization
        String getLanguageName(String languageCode) {
          if (languageCode == 'vi') {
            return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
          } else {
            return l10n?.englishLanguage ?? 'English';
          }
        }

        return _buildSettingItem(
          icon: Icons.language,
          iconColor: Colors.blue,
          title: l10n?.languageSettingTitle ?? 'Ngôn ngữ',
          subtitle: getLanguageName(languageProvider.currentLocale.languageCode),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLanguage['flag']!,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          onTap: () => _showLanguageModal(),
        );
      },
    );
  }

  Widget _buildThemeItem() {
    final l10n = AppLocalizations.of(context);
    final currentTheme = themes.firstWhere(
          (theme) => theme['code'] == selectedTheme,
    );

    // Lấy tên theme theo ngôn ngữ hiện tại
    String getThemeName(String themeCode) {
      switch (themeCode) {
        case 'light':
          return l10n?.lightTheme ?? 'Sáng';
        case 'dark':
          return l10n?.darkTheme ?? 'Tối';
        case 'system':
          return l10n?.systemTheme ?? 'Theo hệ thống';
        default:
          return l10n?.lightTheme ?? 'Sáng';
      }
    }

    return _buildSettingItem(
      icon: Icons.palette,
      iconColor: Colors.purple,
      title: l10n?.themeSettingTitle ?? 'Chủ đề',
      subtitle: getThemeName(selectedTheme),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              currentTheme['icon'],
              size: 16,
              color: _getThemeIconColor(selectedTheme),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: () => _showThemeModal(),
    );
  }

  Color _getThemeIconColor(String themeCode) {
    switch (themeCode) {
      case 'light':
        return Colors.orange;
      case 'dark':
        return Colors.blue[700]!;
      case 'system':
        return Colors.grey[600]!;
      default:
        return Colors.orange;
    }
  }

  Widget _buildNotificationItem() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.dailyNotificationsTitle ?? 'Thông báo hàng ngày (7:00)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  notificationsEnabled
                      ? (l10n?.notificationsOn ?? 'Đang bật')
                      : (l10n?.notificationsOff ?? 'Đang tắt'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildToggleSwitch(),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: () {
        setState(() {
          notificationsEnabled = !notificationsEnabled;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: notificationsEnabled ? Colors.blue : Colors.grey[300],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: notificationsEnabled
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageModal() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.chooseLanguageModalTitle ?? 'Chọn ngôn ngữ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...languages.map((language) => _buildLanguageOption(language)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(Map<String, String> language) {
    final l10n = AppLocalizations.of(context);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isSelected = languageProvider.isCurrentLanguage(language['code']!);

        // Lấy tên ngôn ngữ theo localization
        String getLanguageName(String languageCode) {
          if (languageCode == 'vi') {
            return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
          } else {
            return l10n?.englishLanguage ?? 'English';
          }
        }

        return GestureDetector(
          onTap: () async {
            // Thay đổi ngôn ngữ
            await languageProvider.changeLanguage(language['code']!);

            if (mounted) {
              Navigator.pop(context);

              // Hiển thị thông báo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      language['code'] == 'vi'
                          ? 'Đã chuyển sang Tiếng Việt'
                          : 'Changed to English'
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.blue[200]!)
                  : null,
            ),
            child: Row(
              children: [
                Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getLanguageName(language['code']!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.blue, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeModal() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.chooseThemeModalTitle ?? 'Chọn chủ đề',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...themes.map((theme) => _buildThemeOption(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(Map<String, dynamic> theme) {
    final l10n = AppLocalizations.of(context);
    final isSelected = selectedTheme == theme['code'];

    // Lấy tên theme theo ngôn ngữ
    String getThemeName(String themeCode) {
      switch (themeCode) {
        case 'light':
          return l10n?.lightTheme ?? 'Sáng';
        case 'dark':
          return l10n?.darkTheme ?? 'Tối';
        case 'system':
          return l10n?.systemTheme ?? 'Theo hệ thống';
        default:
          return l10n?.lightTheme ?? 'Sáng';
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTheme = theme['code']!;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blue[200]!)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getThemeBackgroundColor(theme['code']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                theme['icon'],
                size: 16,
                color: _getThemeIconColor(theme['code']),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getThemeName(theme['code']),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }

  Color _getThemeBackgroundColor(String themeCode) {
    switch (themeCode) {
      case 'light':
        return Colors.yellow[100]!;
      case 'dark':
        return Colors.grey[800]!;
      case 'system':
        return Colors.blue[100]!;
      default:
        return Colors.yellow[100]!;
    }
  }
}