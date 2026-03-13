import 'package:flutter/material.dart';
import '../models/validation_models.dart';
import '../services/api_service.dart';

class ValidationProvider extends ChangeNotifier {
  final ApiService _apiService;

  ValidationResponse? _lastResult;
  bool _isLoading = false;
  String? _error;
  List<DetectionItem> _currentDetections = [];

  ValidationProvider({required ApiService apiService})
      : _apiService = apiService;

  // Getters
  ValidationResponse? get lastResult => _lastResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DetectionItem> get currentDetections => _currentDetections;

  bool get hasResult => _lastResult != null;
  double get complianceScore => _lastResult?.summary.compliance_score ?? 0;
  String get gradeEmoji => _lastResult?.summary.gradeEmoji ?? '❓';
  String get grade => _lastResult?.summary.grade ?? 'UNKNOWN';

  // Validate dengan detections
  Future<void> validate(List<DetectionItem> detections) async {
    _isLoading = true;
    _error = null;
    _currentDetections = detections;
    notifyListeners();

    try {
      _lastResult = await _apiService.validatePlanogram(detections);
      _error = null;
    } catch (e) {
      _error = 'Validation failed: $e';
      _lastResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set result dari response (untuk multi-photo audit)
  void setLastResult(ValidationResponse response) {
    _lastResult = response;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Validate dengan dummy data
  Future<void> validateDummy() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lastResult = await _apiService.validateWithDummy();
      _error = null;
    } catch (e) {
      _error = 'Dummy validation failed: $e';
      _lastResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset state
  void reset() {
    _lastResult = null;
    _error = null;
    _currentDetections = [];
    _isLoading = false;
    notifyListeners();
  }

  // Get parameter result
  Map<String, dynamic>? getParameterResult(String paramKey) {
    return _lastResult?.parameters[paramKey];
  }

  // Get all pass parameters
  List<String> getPassParameters() {
    if (_lastResult == null) return [];
    return _lastResult!.parameters.entries
        .where((e) => e.value['status'] == 'PASS')
        .map((e) => e.key)
        .toList();
  }

  // Get all fail parameters
  List<String> getFailParameters() {
    if (_lastResult == null) return [];
    return _lastResult!.parameters.entries
        .where((e) => e.value['status'] == 'FAIL')
        .map((e) => e.key)
        .toList();
  }

  // Get all skip parameters
  List<String> getSkipParameters() {
    if (_lastResult == null) return [];
    return _lastResult!.parameters.entries
        .where((e) => e.value['status'] == 'SKIP')
        .map((e) => e.key)
        .toList();
  }
}
