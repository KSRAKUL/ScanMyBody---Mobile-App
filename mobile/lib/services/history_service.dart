import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ScanRecord {
  final String id;
  final DateTime timestamp;
  final String tumorType;
  final double confidence;
  final String risk;
  final String imagePath;
  final Map<String, dynamic> xaiData;

  ScanRecord({
    required this.id,
    required this.timestamp,
    required this.tumorType,
    required this.confidence,
    required this.risk,
    required this.imagePath,
    required this.xaiData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'tumorType': tumorType,
    'confidence': confidence,
    'risk': risk,
    'imagePath': imagePath,
    'xaiData': xaiData,
  };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    tumorType: json['tumorType'],
    confidence: json['confidence'],
    risk: json['risk'],
    imagePath: json['imagePath'],
    xaiData: json['xaiData'] ?? {},
  );
}

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  List<ScanRecord> _records = [];
  bool _isLoaded = false;

  Future<Directory> get _storageDir async {
    final dir = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${dir.path}/scan_history');
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return historyDir;
  }

  Future<String> get _historyFilePath async {
    final dir = await _storageDir;
    return '${dir.path}/history.json';
  }

  Future<void> loadHistory() async {
    if (_isLoaded) return;
    
    try {
      final filePath = await _historyFilePath;
      final file = File(filePath);
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        _records = jsonList.map((json) => ScanRecord.fromJson(json)).toList();
        _records.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
      }
      _isLoaded = true;
    } catch (e) {
      _records = [];
      _isLoaded = true;
    }
  }

  Future<void> _saveHistory() async {
    try {
      final filePath = await _historyFilePath;
      final file = File(filePath);
      final jsonList = _records.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      // Silent fail
    }
  }

  Future<ScanRecord> addScan({
    required Uint8List imageBytes,
    required String tumorType,
    required double confidence,
    required String risk,
    required Map<String, dynamic> xaiData,
  }) async {
    await loadHistory();
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dir = await _storageDir;
    final imagePath = '${dir.path}/scan_$id.png';
    
    // Save image
    await File(imagePath).writeAsBytes(imageBytes);
    
    final record = ScanRecord(
      id: id,
      timestamp: DateTime.now(),
      tumorType: tumorType,
      confidence: confidence,
      risk: risk,
      imagePath: imagePath,
      xaiData: xaiData,
    );
    
    _records.insert(0, record);
    await _saveHistory();
    
    return record;
  }

  Future<List<ScanRecord>> getHistory() async {
    await loadHistory();
    return List.from(_records);
  }

  Future<void> deleteRecord(String id) async {
    await loadHistory();
    
    final record = _records.firstWhere((r) => r.id == id, orElse: () => throw Exception('Not found'));
    
    // Delete image file
    try {
      await File(record.imagePath).delete();
    } catch (_) {}
    
    _records.removeWhere((r) => r.id == id);
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    await loadHistory();
    
    for (final record in _records) {
      try {
        await File(record.imagePath).delete();
      } catch (_) {}
    }
    
    _records.clear();
    await _saveHistory();
  }
}
