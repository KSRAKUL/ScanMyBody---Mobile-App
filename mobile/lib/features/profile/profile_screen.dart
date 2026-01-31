import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/history_service.dart';
import '../../services/user_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Patient';
  int _scanCount = 0;
  List<ScanRecord> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await UserPreferences().loadUserName();
    final records = await HistoryService().getHistory();
    setState(() {
      _userName = UserPreferences().userName;
      _scanCount = records.length;
      _notifications = records.take(5).toList();
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _userName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter your name as per Aadhar',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await UserPreferences().setUserName(newName);
      setState(() => _userName = newName);
    }
  }

  void _showNotifications() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Scan Notifications', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
            ),
            Expanded(
              child: _notifications.isEmpty
                ? Center(child: Text('No notifications yet', style: GoogleFonts.poppins(color: isDark ? Colors.white54 : AppColors.textLight)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final record = _notifications[index];
                      final hasTumor = !record.tumorType.toLowerCase().contains('no tumor');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasTumor ? AppColors.danger.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: hasTumor ? AppColors.danger.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(hasTumor ? Icons.warning_rounded : Icons.check_circle_rounded, color: hasTumor ? AppColors.danger : AppColors.success, size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hasTumor ? 'Tumor Detected' : 'No Tumor Detected', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: hasTumor ? AppColors.danger : AppColors.success)),
                                  const SizedBox(height: 4),
                                  Text(hasTumor ? '${record.tumorType} - Please consult a doctor' : 'You are safe! No abnormalities found', style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacy() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
              Text('Privacy & Medical Standards', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 20),
              _privacySection('Data Protection', 'Your medical data is encrypted and stored securely on your device. We do not share your MRI scans with third parties.', Icons.security, isDark),
              _privacySection('Medical Disclaimer', 'This app is for screening purposes only. Always consult a qualified healthcare provider for diagnosis.', Icons.medical_services, isDark),
              _privacySection('HIPAA Compliance', 'We follow HIPAA guidelines to ensure the privacy and security of your health information.', Icons.verified_user, isDark),
              _privacySection('Consent', 'By using this app, you consent to AI-based analysis of your MRI images. You may delete your data at any time.', Icons.handshake, isDark),
              _privacySection('Accuracy Notice', 'AI predictions may not be 100% accurate. A negative result does not guarantee absence of disease.', Icons.info, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacySection(String title, String content, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(content, style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            Text('Help & Support', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 20),
            Text('We are here to help you with any questions or issues. Our team is dedicated to providing you with the best support experience.', style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.email_rounded, color: AppColors.primaryBlue, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email Support', style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                        Text('ksrakul27@gmail.com', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'ksrakul27@gmail.com'));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email copied!', style: GoogleFonts.poppins()), backgroundColor: AppColors.success));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.copy, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Response within 24-48 hours', style: GoogleFonts.poppins(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textLight)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 12),
              Text('ScanMyBody', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              Text('Version 1.0.0', style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textLight)),
              const SizedBox(height: 14),
              Text('AI-powered brain tumor detection using deep learning. Our Stacked Model provides accurate predictions for early screening.', style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _aboutChip('95%+', 'Accuracy', AppColors.success),
                  const SizedBox(width: 12),
                  _aboutChip('AI', 'Powered', AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  _aboutChip('Fast', 'Analysis', AppColors.warning),
                ],
              ),
              const SizedBox(height: 14),
              Text('© 2026 ScanMyBody', style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white54 : AppColors.textLight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color)),
        ],
      ),
    );
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
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
          ),
        ),
        title: Text('Profile', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Column(
                  children: [
                    Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 40)),
                    const SizedBox(height: 16),
                    Text(_userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Brain Tumor Screening', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_scanCount', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Total Scans', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Menu Items
              _buildMenuItem(Icons.person_outline, 'Edit Profile', 'Change your name', _editName, cardColor, textColor, subtextColor),
              _buildMenuItem(Icons.notifications_outlined, 'Notifications', 'View scan alerts', _showNotifications, cardColor, textColor, subtextColor),
              _buildMenuItem(Icons.security_outlined, 'Privacy', 'Medical standards', _showPrivacy, cardColor, textColor, subtextColor),
              _buildMenuItem(Icons.help_outline, 'Help & Support', 'Contact us', _showHelp, cardColor, textColor, subtextColor),
              _buildMenuItem(Icons.info_outline, 'About', 'App information', _showAbout, cardColor, textColor, subtextColor),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap, Color cardColor, Color textColor, Color subtextColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryBlue, size: 22)),
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
            Icon(Icons.arrow_forward_ios, color: subtextColor, size: 16),
          ],
        ),
      ),
    );
  }
}

