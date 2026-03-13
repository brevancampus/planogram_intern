// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BBox _$BBoxFromJson(Map<String, dynamic> json) => BBox(
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
    );

Map<String, dynamic> _$BBoxToJson(BBox instance) => <String, dynamic>{
      'x1': instance.x1,
      'y1': instance.y1,
      'x2': instance.x2,
      'y2': instance.y2,
    };

DetectionItem _$DetectionItemFromJson(Map<String, dynamic> json) =>
    DetectionItem(
      product_name: json['product_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      bbox: BBox.fromJson(json['bbox'] as Map<String, dynamic>),
      class_name: json['class_name'] as String,
    );

Map<String, dynamic> _$DetectionItemToJson(DetectionItem instance) =>
    <String, dynamic>{
      'product_name': instance.product_name,
      'confidence': instance.confidence,
      'bbox': instance.bbox,
      'class_name': instance.class_name,
    };

ValidationRequest _$ValidationRequestFromJson(Map<String, dynamic> json) =>
    ValidationRequest(
      detections: (json['detections'] as List<dynamic>)
          .map((e) => DetectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      planogram_target: json['planogram_target'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ValidationRequestToJson(ValidationRequest instance) =>
    <String, dynamic>{
      'detections': instance.detections,
      'planogram_target': instance.planogram_target,
    };

ComplianceSummary _$ComplianceSummaryFromJson(Map<String, dynamic> json) =>
    ComplianceSummary(
      pass_count: (json['pass_count'] as num).toInt(),
      fail_count: (json['fail_count'] as num).toInt(),
      skip_count: (json['skip_count'] as num).toInt(),
      total_params: (json['total_params'] as num).toInt(),
      compliance_score: (json['compliance_score'] as num).toDouble(),
      grade: json['grade'] as String,
    );

Map<String, dynamic> _$ComplianceSummaryToJson(ComplianceSummary instance) =>
    <String, dynamic>{
      'pass_count': instance.pass_count,
      'fail_count': instance.fail_count,
      'skip_count': instance.skip_count,
      'total_params': instance.total_params,
      'compliance_score': instance.compliance_score,
      'grade': instance.grade,
    };

ValidationResponse _$ValidationResponseFromJson(Map<String, dynamic> json) =>
    ValidationResponse(
      status: json['status'] as String,
      summary:
          ComplianceSummary.fromJson(json['summary'] as Map<String, dynamic>),
      parameters: json['parameters'] as Map<String, dynamic>,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$ValidationResponseToJson(ValidationResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'summary': instance.summary,
      'parameters': instance.parameters,
      'timestamp': instance.timestamp,
    };

ParameterDetail _$ParameterDetailFromJson(Map<String, dynamic> json) =>
    ParameterDetail(
      status: json['status'] as String,
      parameter: json['parameter'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ParameterDetailToJson(ParameterDetail instance) =>
    <String, dynamic>{
      'status': instance.status,
      'parameter': instance.parameter,
      'details': instance.details,
    };
