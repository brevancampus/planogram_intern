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
  @JsonKey(defaultValue: 0)
  final int photo_index;
  @JsonKey(defaultValue: 0)
  final int x_offset_applied;

  DetectionItem({
    required this.product_name,
    required this.confidence,
    required this.bbox,
    required this.class_name,
    this.photo_index = 0,
    this.x_offset_applied = 0,
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
  @JsonKey(defaultValue: [])
  final List<DetectionItem> detections;
  
  // Multi-photo metadata (optional)
  @JsonKey(defaultValue: 0)
  final int total_photos;
  @JsonKey(defaultValue: 0)
  final int photos_processed;
  @JsonKey(defaultValue: 0)
  final int photos_failed;
  @JsonKey(defaultValue: 0)
  final int total_detections;

  ValidationResponse({
    required this.status,
    required this.summary,
    required this.parameters,
    required this.timestamp,
    this.detections = const [],
    this.total_photos = 0,
    this.photos_processed = 0,
    this.photos_failed = 0,
    this.total_detections = 0,
  });

  factory ValidationResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ValidationResponseToJson(this);

  bool get isSuccess => status == 'success';
  bool get hasDetections => detections.isNotEmpty;
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

// ============================================================================
// DETECTION GROUPING MODELS (For UI Display)
// ============================================================================

class ProductDetectionInfo {
  final String productName;
  final int count;
  final List<DetectionItem> detections;
  
  const ProductDetectionInfo({
    required this.productName,
    required this.count,
    required this.detections,
  });
}

class RackLevel {
  final int rackIndex;
  final Map<String, ProductDetectionInfo> products; // productName -> ProductDetectionInfo
  
  RackLevel({
    required this.rackIndex,
    required this.products,
  });
  
  int get totalProducts => products.values.fold(0, (sum, p) => sum + p.count);
  
  List<String> get productNames => products.keys.toList();
}

class DetectionSummaryForUI {
  final List<RackLevel> racks;
  final Map<String, int> totalProductCount; // Global count per product
  
  DetectionSummaryForUI({
    required this.racks,
    required this.totalProductCount,
  });
  
  int get totalDetections => totalProductCount.values.fold(0, (sum, count) => sum + count);
  
  /// Parse detections from API response and group by row
  static DetectionSummaryForUI parseFromDetections(List<Map<String, dynamic>> detections) {
    final Map<int, Map<String, ProductDetectionInfo>> rackMap = {};
    final Map<String, int> globalProductCount = {};
    
    // Hardcoded valid products
    const validProducts = {'aqua', 'chitato', 'indomie', 'pepsodent', 'shampoo', 'tissue'};
    
    for (var detectionJson in detections) {
      final detection = DetectionItem.fromJson(detectionJson);
      
      // Skip if product not in valid list
      if (!validProducts.contains(detection.product_name.toLowerCase())) {
        continue;
      }
      
      // Calculate row index based on Y coordinate
      final rowIndex = _calculateRowIndex(detection.bbox.y1, detection.bbox.y2);
      
      // Ensure rack exists
      rackMap.putIfAbsent(rowIndex, () => {});
      
      // Update or create product entry
      final key = detection.product_name;
      if (rackMap[rowIndex]!.containsKey(key)) {
        final existing = rackMap[rowIndex]![key]!;
        rackMap[rowIndex]![key] = ProductDetectionInfo(
          productName: key,
          count: existing.count + 1,
          detections: [...existing.detections, detection],
        );
      } else {
        rackMap[rowIndex]![key] = ProductDetectionInfo(
          productName: key,
          count: 1,
          detections: [detection],
        );
      }
      
      // Update global count
      globalProductCount[key] = (globalProductCount[key] ?? 0) + 1;
    }
    
    // Convert to RackLevel list and sort by rack index
    final racks = rackMap.entries
        .map((e) => RackLevel(rackIndex: e.key, products: e.value))
        .toList()
        ..sort((a, b) => a.rackIndex.compareTo(b.rackIndex));
    
    return DetectionSummaryForUI(
      racks: racks,
      totalProductCount: globalProductCount,
    );
  }
  
  /// Calculate row index based on Y coordinate
  /// Assumes images are in standard YOLO format (relative coordinates or pixel-based)
  static int _calculateRowIndex(double y1, double y2) {
    final yCenter = (y1 + y2) / 2;
    
    // Assume typical shelf with 2-3 rows
    // Adjust thresholds based on actual image heights
    if (yCenter < 300) return 0;
    if (yCenter < 600) return 1;
    if (yCenter < 900) return 2;
    return 3;
  }
}
