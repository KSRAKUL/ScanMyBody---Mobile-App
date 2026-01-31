import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/history_service.dart';
import '../../services/user_preferences.dart';
import '../scan/scan_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  int _currentIndex = 0;
  List<ScanRecord> _recentScans = [];
  String _userName = 'Patient';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    await UserPreferences().loadUserName();
    final records = await HistoryService().getHistory();
    setState(() {
      _userName = UserPreferences().userName;
      _recentScans = records.take(3).toList();
    });
  }



  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, animation, __) => screen,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    )).then((_) => _loadData());
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final lightTextColor = isDark ? Colors.white54 : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildHeader(isDark, cardColor, textColor, subtextColor),
                  const SizedBox(height: 28),
                  _buildBrainScanCard(),
                  const SizedBox(height: 28),
                  _buildQuickActions(isDark, cardColor, textColor, subtextColor),
                  const SizedBox(height: 28),
                  _buildRecentScans(isDark, cardColor, textColor, lightTextColor, subtextColor),
                  const SizedBox(height: 100),
                ]),
              )),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark, cardColor, lightTextColor),
    );
  }

  Widget _buildHeader(bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateTo(const ProfileScreen()),
          child: Hero(
            tag: 'avatar',
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.colored),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome Back 👋', style: GoogleFonts.poppins(fontSize: 13, color: subtextColor)),
              const SizedBox(height: 2),
              Text(_userName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _navigateTo(const SettingsScreen()),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), boxShadow: isDark ? null : AppShadows.small),
            child: Icon(Icons.settings_outlined, color: subtextColor, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildBrainScanCard() {
    return GestureDetector(
      onTap: () => _navigateTo(const ScanScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.colored),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text('AI Powered', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text('Brain Tumor\nDetection', style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.15)),
                  const SizedBox(height: 10),
                  Text('Upload MRI for instant AI analysis', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Start Scan', style: GoogleFonts.poppins(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue, size: 18),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Hero(
              tag: 'brain_logo',
              child: Container(
                width: 95, height: 95,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _buildActionCard(Icons.document_scanner_rounded, 'New\nScan', AppColors.primaryBlue, () => _navigateTo(const ScanScreen()), isDark, cardColor, textColor)),
          const SizedBox(width: 14),
          Expanded(child: _buildActionCard(Icons.history_rounded, 'Scan\nHistory', AppColors.success, () => _navigateTo(const HistoryScreen()), isDark, cardColor, textColor)),
          const SizedBox(width: 14),
          Expanded(child: _buildActionCard(Icons.description_rounded, 'My\nReports', AppColors.warning, () => _navigateTo(const HistoryScreen()), isDark, cardColor, textColor)),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll, Color textColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        GestureDetector(
          onTap: onSeeAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('See All', style: GoogleFonts.poppins(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap, bool isDark, Color cardColor, Color textColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: isDark ? null : AppShadows.small),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: textColor, height: 1.3), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildRecentScans(bool isDark, Color cardColor, Color textColor, Color lightTextColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Scans', () => _navigateTo(const HistoryScreen()), textColor, subtextColor),
        const SizedBox(height: 14),
        if (_recentScans.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: isDark ? null : AppShadows.small),
            child: Center(
              child: Column(children: [
                Icon(Icons.history_rounded, size: 48, color: lightTextColor),
                const SizedBox(height: 12),
                Text('No scans yet', style: GoogleFonts.poppins(fontSize: 14, color: lightTextColor)),
                const SizedBox(height: 4),
                Text('Your scan history will appear here', style: GoogleFonts.poppins(fontSize: 12, color: lightTextColor)),
              ]),
            ),
          )
        else
          ..._recentScans.map((record) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildScanCard(record, isDark, cardColor, textColor, lightTextColor),
          )),
      ],
    );
  }

  Widget _buildScanCard(ScanRecord record, bool isDark, Color cardColor, Color textColor, Color lightTextColor) {
    final statusColor = record.tumorType.toLowerCase().contains('no tumor') ? AppColors.success : (record.tumorType.toLowerCase().contains('glioma') ? AppColors.danger : AppColors.warning);
    
    return GestureDetector(
      onTap: () => _navigateTo(const HistoryScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: isDark ? null : AppShadows.small),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : AppColors.background, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.medical_information_rounded, color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brain MRI Scan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 4),
                  Text('${_formatDate(record.timestamp)} • ${_formatTime(record.timestamp)}', style: GoogleFonts.poppins(fontSize: 12, color: lightTextColor)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(record.tumorType, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, Color cardColor, Color lightTextColor) {
    return Container(
      decoration: BoxDecoration(color: cardColor, boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0, lightTextColor),
              _buildNavItem(Icons.document_scanner_rounded, 'Scan', 1, lightTextColor),
              _buildNavItem(Icons.history_rounded, 'History', 2, lightTextColor),
              _buildNavItem(Icons.person_rounded, 'Profile', 3, lightTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color lightTextColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 1) _navigateTo(const ScanScreen());
        if (index == 2) _navigateTo(const HistoryScreen());
        if (index == 3) _navigateTo(const ProfileScreen());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? AppColors.primaryBlue : lightTextColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppColors.primaryBlue : lightTextColor)),
        ]),
      ),
    );
  }
}

