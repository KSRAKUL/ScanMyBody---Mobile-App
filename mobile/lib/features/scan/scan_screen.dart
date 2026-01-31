import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../results/result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  final ApiService _apiService = ApiService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() { _selectedImage = image; _imageBytes = bytes; });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() => _isAnalyzing = true);
    final result = await _apiService.analyzeImage(_selectedImage!);
    setState(() => _isAnalyzing = false);
    
    if (result.success && mounted) {
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => ResultScreen(data: result.data!, originalImageBytes: _imageBytes!),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    } else if (mounted) {
      _showError(result.error ?? 'Analysis failed');
    }
  }

  void _showError(String message) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 28),
        const SizedBox(width: 12),
        Text('Error', style: GoogleFonts.poppins(color: AppColors.danger, fontSize: 18, fontWeight: FontWeight.w600)),
      ]),
      content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: GoogleFonts.poppins(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)))],
    ));
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
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
          ),
        ),
        title: Text('Brain MRI Scan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text('AI', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildImageArea(isDark, cardColor, textColor, subtextColor)),
              const SizedBox(height: 20),
              if (_selectedImage == null) _buildUploadOptions() else _buildAnalyzeSection(isDark),
              const SizedBox(height: 16),
              _buildInfoCard(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea(bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _selectedImage != null ? AppColors.primaryBlue : (isDark ? Colors.white24 : AppColors.textLight.withOpacity(0.2 + (_pulseController.value * 0.1))),
              width: 2,
            ),
            boxShadow: isDark ? null : [BoxShadow(color: _selectedImage != null ? AppColors.primaryBlue.withOpacity(0.1) : Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _imageBytes != null
                ? Stack(fit: StackFit.expand, children: [Image.memory(_imageBytes!, fit: BoxFit.cover), if (_isAnalyzing) _buildAnalyzingOverlay()])
                : _buildEmptyState(textColor, subtextColor),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtextColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryBlue.withOpacity(0.1), AppColors.primaryLight.withOpacity(0.05)]), shape: BoxShape.circle),
          child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primaryBlue, size: 48),
        ),
        const SizedBox(height: 24),
        Text('Upload Brain MRI', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 8),
        Text('Select an image to analyze with AI', style: GoogleFonts.poppins(fontSize: 14, color: subtextColor)),
      ],
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))),
          const SizedBox(height: 24),
          Text('Analyzing MRI...', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('AI is processing your scan', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUploadOptions() {
    return Row(children: [
      Expanded(child: _buildUploadCard(Icons.photo_library_rounded, 'Gallery', () => _pickImage(ImageSource.gallery))),
      const SizedBox(width: 14),
      Expanded(child: _buildUploadCard(Icons.camera_alt_rounded, 'Camera', () => _pickImage(ImageSource.camera))),
    ]);
  }

  Widget _buildUploadCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
        child: Column(children: [Icon(icon, color: Colors.white, size: 32), const SizedBox(height: 10), Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]),
      ),
    );
  }

  Widget _buildAnalyzeSection(bool isDark) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isAnalyzing ? null : _analyzeImage,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.psychology, size: 24, color: Colors.white),
            const SizedBox(width: 10),
            Text('Analyze with AI', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => setState(() { _selectedImage = null; _imageBytes = null; }),
        child: Text('Choose Different Image', style: GoogleFonts.poppins(color: AppColors.primaryBlue, fontWeight: FontWeight.w500)),
      ),
    ]);
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1))),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text('Upload T1 or T2 weighted brain MRI for best results', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryBlue))),
      ]),
    );
  }
}
