import 'package:json_annotation/json_annotation.dart';

part 'validation_models.g.dart';

// ============================================================================
// DETECTION MODELS
// ============================================================================

@JsonSerializable()
class BBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  BBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory BBox.fromJson(Map<String, dynamic> json) => _$BBoxFromJson(json);
  Map<String, dynamic> toJson() => _$BBoxToJson(this);
}

@JsonSerializable()
class DetectionItem {
  final String product_name;
  final double confidence;
  final BBox bbox;
  final String class_name;

  DetectionItem({
    required this.product_name,
    required this.confidence,
    required this.bbox,
    required this.class_name,
  });

  factory DetectionItem.fromJson(Map<String, dynamic> json) =>
      _$DetectionItemFromJson(json);
  Map<String, dynamic> toJson() => _$DetectionItemToJson(this);
}

@JsonSerializable()
class ValidationRequest {
  final List<DetectionItem> detections;
  final Map<String, dynamic>? planogram_target;

  ValidationRequest({
    required this.detections,
    this.planogram_target,
  });

  factory ValidationRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ValidationRequestToJson(this);
}

// ============================================================================
// RESPONSE MODELS
// ============================================================================

@JsonSerializable()
class ComplianceSummary {
  final int pass_count;
  final int fail_count;
  final int skip_count;
  final int total_params;
  final double compliance_score;
  final String grade;

  ComplianceSummary({
    required this.pass_count,
    required this.fail_count,
    required this.skip_count,
    required this.total_params,
    required this.compliance_score,
    required this.grade,
  });

  factory ComplianceSummary.fromJson(Map<String, dynamic> json) =>
      _$ComplianceSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ComplianceSummaryToJson(this);

  // Helper getter untuk warna berdasarkan grade
  String get gradeColor {
    switch (grade.toUpperCase()) {
      case 'EXCELLENT':
        return '2ECC71'; // Green
      case 'GOOD':
        return '3498DB'; // Blue
      case 'NEEDS_ATTENTION':
        return 'F39C12'; // Orange
      case 'CRITICAL':
        return 'E74C3C'; // Red
      default:
        return '95A5A6'; // Gray
    }
  }

  String get gradeEmoji {
    switch (grade.toUpperCase()) {
      case 'EXCELLENT':
        return '🎉';
      case 'GOOD':
        return '✅';
      case 'NEEDS_ATTENTION':
        return '⚠️';
      case 'CRITICAL':
        return '❌';
      default:
        return '❓';
    }
  }
}

@JsonSerializable()
class ValidationResponse {
  final String status;
  final ComplianceSummary summary;
  final Map<String, dynamic> parameters;
  final String timestamp;

  ValidationResponse({
    required this.status,
    required this.summary,
    required this.parameters,
    required this.timestamp,
  });

  factory ValidationResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ValidationResponseToJson(this);

  bool get isSuccess => status == 'success';
}

// ============================================================================
// PARAMETER DETAIL MODELS
// ============================================================================

@JsonSerializable()
class ParameterDetail {
  final String status;
  final String? parameter;
  final Map<String, dynamic>? details;

  ParameterDetail({
    required this.status,
    this.parameter,
    this.details,
  });

  factory ParameterDetail.fromJson(Map<String, dynamic> json) =>
      _$ParameterDetailFromJson(json);
  Map<String, dynamic> toJson() => _$ParameterDetailToJson(this);
}
