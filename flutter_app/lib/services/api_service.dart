import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import '../models/validation_models.dart';

class ApiService {
  final String _baseUrl;
  final Dio _dio;
  final Logger _logger = Logger();

  ApiService({String baseUrl = 'http://10.218.158.207:8000'})
      : _baseUrl = baseUrl,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            contentType: Headers.jsonContentType,
            // Don't throw on 4xx/5xx - let us handle the response
            validateStatus: (status) => status != null && status < 600,
          ),
        );

  /// Health check endpoint
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      _logger.i('Health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Health check failed: $e');
      return false;
    }
  }

  /// Validate planogram dengan custom detections
  Future<ValidationResponse> validatePlanogram(
    List<DetectionItem> detections, {
    Map<String, dynamic>? planogramTarget,
  }) async {
    try {
      final request = ValidationRequest(
        detections: detections,
        planogram_target: planogramTarget,
      );

      final response = await _dio.post(
        '/api/validate',
        data: request.toJson(),
      );

      _logger.i('Validation response: ${response.statusCode}');
      final data = ValidationResponse.fromJson(response.data);
      return data;
    } catch (e) {
      _logger.e('Validation failed: $e');
      rethrow;
    }
  }

  /// Validate dengan dummy data (untuk testing)
  Future<ValidationResponse> validateWithDummy() async {
    try {
      final response = await _dio.post('/api/validate-with-dummy');
      _logger.i('Dummy validation response: ${response.statusCode}');
      final data = ValidationResponse.fromJson(response.data);
      return data;
    } catch (e) {
      _logger.e('Dummy validation failed: $e');
      rethrow;
    }
  }

  /// Get dummy YOLO detection data
  Future<Map<String, dynamic>> getDummyData() async {
    try {
      final response = await _dio.get('/api/dummy-data');
      _logger.i('Got dummy data: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('Get dummy data failed: $e');
      rethrow;
    }
  }

  /// Get default planogram target config
  Future<Map<String, dynamic>> getDefaultTarget() async {
    try {
      final response = await _dio.get('/api/default-target');
      _logger.i('Got default target: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('Get default target failed: $e');
      rethrow;
    }
  }

  /// Set base URL (untuk mengganti host)
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
    _logger.i('Base URL changed to: $url');
  }

  /// Get current base URL
  String getBaseUrl() => _baseUrl;

  /// Multi-Photo Audit: Upload multiple shelf photos dan validate combinasi
  Future<ValidationResponse> validateMultiple(
    List<File> imageFiles, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      _logger.i('Starting multi-photo audit with ${imageFiles.length} images');

      // Validate files exist
      for (int i = 0; i < imageFiles.length; i++) {
        if (!imageFiles[i].existsSync()) {
          throw Exception('File tidak ditemukan: ${imageFiles[i].path}');
        }
      }

      // Perbaikan: Gunakan List<MultipartFile> untuk FormData
      List<MultipartFile> multipartFileList = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final filename = file.path.split('/').last;
        
        _logger.i('Adding file ${i + 1}/${imageFiles.length}: $filename');

        // Tambahkan file ke list
        multipartFileList.add(
          MultipartFile.fromFileSync(
            file.path,
            filename: filename,
            // Tetap menggunakan contentType manual seperti permintaan awal
            contentType: DioMediaType.parse(_getContentType(filename)),
          ),
        );

        // Call progress callback
        onProgress?.call(i + 1, imageFiles.length);
      }

      // Build FormData dengan menambahkan files satu-satu
      // (Dio.FormData.fromMap tidak handle List<MultipartFile> dengan benar)
      final formData = FormData();
      for (var multipartFile in multipartFileList) {
        formData.files.add(MapEntry('files', multipartFile));
        _logger.i('✅ Added file: ${multipartFile.filename}');
      }

      _logger.i('🔍 FormData details:');
      _logger.i('   - Total files: ${formData.files.length}');
      _logger.i('   - Fields: ${formData.fields.map((f) => "${f.key}=${f.value}").toList()}');
      _logger.i('   - Files: ${formData.files.map((f) => "${f.key}:${f.value.filename}").toList()}');
      _logger.i('📤 Sending to /api/audit-multiple...');

      // Send POST request dengan FormData
      // Catatan: Jangan override contentType - biarkan Dio detect FormData secara otomatis
      final response = await _dio.post(
        '/api/audit-multiple',
        data: formData,
      );

      _logger.i('Multi-photo audit response: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        _logger.e('❌ Server error response: ${response.data}');
        throw Exception('Server returned ${response.statusCode}: ${response.data}');
      }
      
      final data = ValidationResponse.fromJson(response.data);
      return data;
    } catch (e) {
      _logger.e('Multi-photo audit failed: $e');
      rethrow;
    }
  }

  /// Helper: Detect content type dari file extension
  String _getContentType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Close connections
  void close() {
    _dio.close();
  }
}