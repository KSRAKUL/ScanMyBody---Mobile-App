import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();
  bool _notifications = true;
  bool _saveHistory = true;

  @override
  void initState() {
    super.initState();
    _themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
          ),
        ),
        title: Text('Settings', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferences', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: subtextColor)),
              const SizedBox(height: 12),
              _buildToggleSetting(Icons.notifications_outlined, 'Notifications', 'Get alerts for scan results', _notifications, (v) => setState(() => _notifications = v), cardColor, textColor, subtextColor),
              _buildToggleSetting(Icons.dark_mode_outlined, 'Dark Mode', 'Switch to dark theme', _themeNotifier.isDarkMode, (v) => _themeNotifier.setDarkMode(v), cardColor, textColor, subtextColor),
              _buildToggleSetting(Icons.history, 'Save History', 'Keep scan history locally', _saveHistory, (v) => setState(() => _saveHistory = v), cardColor, textColor, subtextColor),
              const SizedBox(height: 24),
              Text('About', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: subtextColor)),
              const SizedBox(height: 12),
              _buildInfoItem(Icons.info_outline, 'Version', '1.0.0', cardColor, textColor),
              _buildInfoItem(Icons.psychology, 'AI Model', 'Stacked Model', cardColor, textColor),
              _buildInfoItem(Icons.verified, 'Accuracy', '95%+', cardColor, textColor),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('This app is for screening only. Always consult a medical professional.',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSetting(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged, Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: subtextColor)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor))),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
        ],
      ),
    );
  }
}

