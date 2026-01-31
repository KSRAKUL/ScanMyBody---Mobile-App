import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../services/history_service.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final Uint8List originalImageBytes;

  const ResultScreen({
    super.key,
    required this.data,
    required this.originalImageBytes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _savedToHistory = false;
  bool _showHeatmap = true;
  Uint8List? _heatmapBytes;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _saveToHistory();
    _cacheHeatmap();
  }
  
  void _cacheHeatmap() {
    final gradcam = widget.data['gradcam'];
    if (gradcam != null && gradcam['heatmap_base64'] != null) {
      try { _heatmapBytes = base64Decode(gradcam['heatmap_base64']); } catch (_) {}
    }
  }
  
  Future<void> _saveToHistory() async {
    if (_savedToHistory) return;
    _savedToHistory = true;
    try {
      final c = widget.data['classification'];
      await HistoryService().addScan(
        imageBytes: widget.originalImageBytes,
        tumorType: _formatTumorType(c['type'].toString()),
        confidence: c['confidence'],
        risk: c['risk'],
        xaiData: widget.data['xai'] ?? {},
      );
    } catch (_) {}
  }

  @override
  void dispose() { _animationController.dispose(); super.dispose(); }

  String _formatTumorType(String type) {
    final t = type.toLowerCase();
    if (t.contains('glioma')) return 'Glioma';
    if (t.contains('meningioma')) return 'Meningioma';
    if (t.contains('pituitary')) return 'Pituitary Adenoma';
    if (t.contains('notumor') || t.contains('no tumor')) return 'No Tumor Detected';
    return type;
  }

  Color _getStatusColor(String type, String risk) {
    if (type.toLowerCase().contains('no tumor')) return AppColors.success;
    if (risk == 'High') return AppColors.danger;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final classification = widget.data['classification'];
    final xai = widget.data['xai'] ?? {};
    final gradcam = widget.data['gradcam'] ?? {};
    
    final tumorType = _formatTumorType(classification['type'].toString());
    final confidence = (classification['confidence'] * 100).toStringAsFixed(0);
    final risk = classification['risk'];
    final isHealthy = tumorType.toLowerCase().contains('no tumor');
    final statusColor = _getStatusColor(tumorType, risk);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _animationController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildDiagnosisCard(tumorType, confidence, risk, statusColor, isHealthy),
                    const SizedBox(height: 20),
                    _buildImageSection(gradcam, isHealthy),
                    const SizedBox(height: 20),
                    if (!isHealthy) ...[_buildAIExplanationCard(tumorType, xai), const SizedBox(height: 20)],
                    _buildRecommendationsCard(tumorType, isHealthy),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 60, floating: true, pinned: true,
      backgroundColor: AppColors.background, elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.small),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
        ),
      ),
      title: Text('Analysis Report', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      centerTitle: true,
      actions: [
        _buildAppBarBtn(Icons.share_outlined, AppColors.primaryBlue, _isSharing, _shareReport),
        const SizedBox(width: 8),
        _buildAppBarBtn(Icons.save_alt_outlined, AppColors.success, _isSaving, _saveToGallery),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildAppBarBtn(IconData icon, Color color, bool loading, VoidCallback onTap) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.small),
        child: loading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color)) : Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildDiagnosisCard(String type, String confidence, String risk, Color color, bool isHealthy) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.medium),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: color, size: 44)),
        const SizedBox(height: 20),
        Text('DIAGNOSIS', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(type, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('$risk Risk', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: color))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('AI Confidence', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              Text('$confidence%', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: widget.data['classification']['confidence'], backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue), minHeight: 10)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildImageSection(Map<String, dynamic> gradcam, bool isHealthy) {
    final hasHeatmap = _heatmapBytes != null && !isHealthy;
    final tumorLocation = gradcam['tumor_location'] ?? 'Location analysis unavailable';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.medium),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medical_information_rounded, color: AppColors.primaryBlue, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text('MRI Analysis', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600))),
          if (hasHeatmap) _buildToggleBtn(),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.black,
              child: Stack(fit: StackFit.expand, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showHeatmap && hasHeatmap
                    ? Image.memory(_heatmapBytes!, key: const ValueKey('heatmap'), fit: BoxFit.contain)
                    : Image.memory(widget.originalImageBytes, key: const ValueKey('original'), fit: BoxFit.contain),
                ),
                Positioned(top: 12, right: 12, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _showHeatmap && hasHeatmap ? Colors.red : Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_showHeatmap && hasHeatmap ? 'Heatmap' : 'Original', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                )),
              ]),
            ),
          ),
        ),
        if (hasHeatmap) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withOpacity(0.2))),
            child: Row(children: [const Icon(Icons.location_on_rounded, color: AppColors.warning, size: 20), const SizedBox(width: 12), Expanded(child: Text(tumorLocation, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.4)))]),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildLegend(const Color(0xFF0000FF), 'Low'), _buildLegend(const Color(0xFF00FFFF), 'Mild'),
            _buildLegend(const Color(0xFFFFFF00), 'High'), _buildLegend(const Color(0xFFFF0000), 'Critical'),
          ]),
        ],
      ]),
    );
  }

  Widget _buildToggleBtn() {
    return GestureDetector(
      onTap: () => setState(() => _showHeatmap = !_showHeatmap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_showHeatmap ? Icons.thermostat : Icons.image, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(_showHeatmap ? 'Heatmap' : 'Original', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
        ]),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 4), Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight))]));

  Widget _buildAIExplanationCard(String tumorType, Map<String, dynamic> xai) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.medium),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.psychology_rounded, color: AppColors.info, size: 22)),
          const SizedBox(width: 12),
          Text('AI Explanation', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 20),
        _buildExplanation('What is $tumorType?', xai['description'] ?? _getDesc(tumorType), Icons.help_outline_rounded, AppColors.primaryBlue),
        const SizedBox(height: 16),
        _buildExplanation('Key Characteristics', xai['characteristics'] ?? _getChars(tumorType), Icons.format_list_bulleted_rounded, AppColors.warning),
      ]),
    );
  }

  Widget _buildExplanation(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: color))]),
        const SizedBox(height: 12),
        Text(content, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
      ]),
    );
  }

  Widget _buildRecommendationsCard(String tumorType, bool isHealthy) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: isHealthy ? AppColors.successGradient : LinearGradient(colors: [AppColors.warning, AppColors.danger.withOpacity(0.8)]), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Text('Recommendations', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
        const SizedBox(height: 16),
        Text(isHealthy ? 'Your brain scan appears normal. Continue with regular health checkups.' : 'Please consult a qualified neurologist or oncologist. This AI screening is not a substitute for professional medical advice.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.95), height: 1.5)),
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveToGallery,
        icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.photo_library_rounded),
        label: Text(_isSaving ? 'Saving...' : 'Save to Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      )),
      const SizedBox(width: 16),
      Expanded(child: OutlinedButton.icon(
        onPressed: _isSharing ? null : _shareReport,
        icon: const Icon(Icons.share_rounded),
        label: Text('Share', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryBlue, side: const BorderSide(color: AppColors.primaryBlue, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      )),
    ]);
  }

  String _getDesc(String type) {
    if (type.contains('Glioma')) return 'Gliomas are primary brain tumors from glial cells. Most common malignant brain tumors.';
    if (type.contains('Meningioma')) return 'Meningiomas arise from the meninges. Most are benign and slow-growing.';
    if (type.contains('Pituitary')) return 'Pituitary adenomas develop in the pituitary gland. Most are benign.';
    return 'No abnormalities detected. Brain structures appear normal.';
  }

  String _getChars(String type) {
    if (type.contains('Glioma')) return '• Irregular borders\n• Cerebral hemispheres\n• May cause edema\n• Grades I-IV';
    if (type.contains('Meningioma')) return '• Well-defined borders\n• Brain outer surface\n• Dural tail sign\n• Slow-growing';
    if (type.contains('Pituitary')) return '• Sella turcica region\n• Hormone effects\n• Vision impact possible\n• Treatable';
    return '• Normal tissue\n• No lesions\n• Normal ventricles\n• No midline shift';
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    try {
      // Request permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }
      
      // Get Pictures directory
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Pictures/ScanMyBody');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      if (!await dir.exists()) await dir.create(recursive: true);
      
      final ts = DateTime.now().millisecondsSinceEpoch;
      
      // Save MRI
      final mriPath = '${dir.path}/MRI_$ts.png';
      await File(mriPath).writeAsBytes(widget.originalImageBytes);
      
      // Save heatmap if available
      if (_heatmapBytes != null) {
        final heatmapPath = '${dir.path}/Heatmap_$ts.png';
        await File(heatmapPath).writeAsBytes(_heatmapBytes!);
      }
      
      if (mounted) _showSnack('Saved to Pictures/ScanMyBody!', AppColors.success, Icons.check_circle);
    } catch (e) {
      // Fallback to app documents
      try {
        final dir = await getApplicationDocumentsDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch;
        await File('${dir.path}/MRI_$ts.png').writeAsBytes(widget.originalImageBytes);
        if (_heatmapBytes != null) await File('${dir.path}/Heatmap_$ts.png').writeAsBytes(_heatmapBytes!);
        if (mounted) _showSnack('Saved to app storage!', AppColors.success, Icons.check_circle);
      } catch (_) {
        if (mounted) _showSnack('Failed to save', AppColors.danger, Icons.error);
      }
    }
    
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _shareReport() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    
    try {
      final dir = await getTemporaryDirectory();
      final mriPath = '${dir.path}/ScanMyBody_MRI.png';
      await File(mriPath).writeAsBytes(widget.originalImageBytes);
      
      List<XFile> files = [XFile(mriPath)];
      if (_heatmapBytes != null) {
        final heatmapPath = '${dir.path}/ScanMyBody_Heatmap.png';
        await File(heatmapPath).writeAsBytes(_heatmapBytes!);
        files.add(XFile(heatmapPath));
      }
      
      await Share.shareXFiles(files, text: _genReport());
    } catch (e) {
      if (mounted) _showSnack('Failed to share', AppColors.danger, Icons.error);
    }
    
    if (mounted) setState(() => _isSharing = false);
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(msg, style: GoogleFonts.poppins()))]),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2),
    ));
  }

  String _genReport() {
    final c = widget.data['classification'];
    final type = _formatTumorType(c['type'].toString());
    final conf = (c['confidence'] * 100).toStringAsFixed(1);
    final loc = widget.data['gradcam']?['tumor_location'] ?? 'N/A';
    return '🧠 BRAIN TUMOR REPORT\n━━━━━━━━━━━━━━━━\n📋 $type\n📊 Confidence: $conf%\n⚠️ Risk: ${c['risk']}\n📍 Location: $loc\n\n${_getDesc(type)}\n\n⚠️ Consult a medical professional.\n\nGenerated by ScanMyBody AI';
  }
}
