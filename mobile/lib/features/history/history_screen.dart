import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final records = await HistoryService().getHistory();
    setState(() { _records = records; _isLoading = false; });
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Color _getStatusColor(String tumorType) {
    if (tumorType.toLowerCase().contains('no tumor')) return AppColors.success;
    if (tumorType.toLowerCase().contains('glioma')) return AppColors.danger;
    return AppColors.warning;
  }

  Future<void> _deleteRecord(ScanRecord record) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete Scan?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: Text('This action cannot be undone.', style: GoogleFonts.poppins()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.poppins())),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white))),
      ],
    ));
    if (confirm == true) {
      await HistoryService().deleteRecord(record.id);
      _loadHistory();
    }
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
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: isDark ? null : AppShadows.small),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
          ),
        ),
        title: Text('Scan History', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
        centerTitle: true,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
        : _records.isEmpty
          ? _buildEmptyState(textColor, subtextColor)
          : _buildHistoryList(isDark, cardColor, textColor, lightTextColor),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.history_rounded, size: 64, color: AppColors.primaryBlue)),
          const SizedBox(height: 24),
          Text('No Scans Yet', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Text('Your scan history will appear here', style: GoogleFonts.poppins(fontSize: 14, color: subtextColor)),
        ],
      ),
    );
  }

  Widget _buildHistoryList(bool isDark, Color cardColor, Color textColor, Color lightTextColor) {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _records.length,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (context, index) => _buildScanCard(_records[index], isDark, cardColor, textColor, lightTextColor),
      ),
    );
  }

  Widget _buildScanCard(ScanRecord record, bool isDark, Color cardColor, Color textColor, Color lightTextColor) {
    final statusColor = _getStatusColor(record.tumorType);
    final file = File(record.imagePath);
    
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteRecord(record),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: isDark ? null : AppShadows.small),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(color: isDark ? const Color(0xFF334155) : AppColors.background, child: Icon(Icons.image, size: 48, color: lightTextColor)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Brain MRI Scan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 4),
                            Text('${_formatDate(record.timestamp)} • ${_formatTime(record.timestamp)}', style: GoogleFonts.poppins(fontSize: 12, color: lightTextColor)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(record.tumorType, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    _buildStatChip(Icons.verified, '${(record.confidence * 100).toStringAsFixed(0)}%', AppColors.primaryBlue),
                    const SizedBox(width: 10),
                    _buildStatChip(Icons.warning_amber_rounded, '${record.risk} Risk', statusColor),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
