import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  ApiResult({required this.success, this.error, this.data});
}

class ApiService {
  // ============= DEPLOYMENT CONFIGURATION =============
  // 
  // RENDER CLOUD (Production - works from anywhere)
  static const String baseUrl = 'https://scanmybody-mobile-app.onrender.com/api/v1';
  //
  // LOCAL DEVELOPMENT (Testing - requires same WiFi)
  // static const String baseUrl = 'http://10.193.183.26:8000/api/v1';
  //
  // =====================================================

  Future<ApiResult> analyzeImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      var uri = Uri.parse("$baseUrl/analyze");

      var request = http.MultipartRequest("POST", uri);
      
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      );

      request.files.add(multipartFile);

      // Add timeout to prevent infinite loading
      var response = await request.send().timeout(
        const Duration(seconds: 120), // Increased timeout for cloud
        onTimeout: () {
          throw Exception('Request timed out. Server may be waking up (cold start). Try again.');
        },
      );
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return ApiResult(success: true, data: jsonDecode(responseBody));
      } else {
        try {
          var errorData = jsonDecode(responseBody);
          return ApiResult(success: false, error: errorData['detail'] ?? "Server Error");
        } catch (_) {
           return ApiResult(success: false, error: "Server Error: ${response.statusCode}");
        }
      }
    } catch (e) {
      return ApiResult(success: false, error: "Connection Error: $e");
    }
  }
}
