import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/validation_models.dart';
import '../providers/validation_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  // FMCG Color Palette
  static const Color fmcgGreen = Color(0xFF2ECC71);
  static const Color fmcgDarkGreen = Color(0xFF27AE60);
  static const Color fmcgRed = Color(0xFFE74C3C);
  static const Color fmcgOrange = Color(0xFFF39C12);
  static const Color fmcgLightGray = Color(0xFFF8F9FA);
  static const Color fmcgDarkGray = Color(0xFF2C3E50);

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PASS':
        return fmcgGreen;
      case 'FAIL':
        return fmcgRed;
      case 'SKIP':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PASS':
        return '✓';
      case 'FAIL':
        return '✗';
      case 'SKIP':
        return '⊘';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: fmcgGreen,
        title: const Text('Planogram Validation Result',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: fmcgLightGray,
      body: Consumer<ValidationProvider>(
        builder: (context, provider, _) {
          if (!provider.hasResult) {
            return const Center(
              child: CircularProgressIndicator(color: fmcgGreen),
            );
          }

          final result = provider.lastResult!;
          final summary = result.summary;
          final parameters = result.parameters;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====================================================
                // COMPLIANCE SCORE SUMMARY CARD
                // ====================================================
                _buildComplianceSummaryCard(summary),

                const SizedBox(height: 24),

                // ====================================================
                // DETECTION BREAKDOWN BY RACK LEVEL
                // ====================================================
                if (result.status == 'success') ...[
                  const Text(
                    'Detection Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fmcgDarkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetectionByRackLevel(context, result),
                  const SizedBox(height: 24),
                ],

                // ====================================================
                // PARAMETER BREAKDOWN
                // ====================================================
                const Text(
                  'Parameter Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: fmcgDarkGray,
                  ),
                ),
                const SizedBox(height: 12),
                _buildParameterBreakdown(context, parameters),

                const SizedBox(height: 24),

                // ====================================================
                // ACTION BUTTONS
                // ====================================================
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export feature coming soon'),
                              backgroundColor: fmcgGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: fmcgGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // BUILD COMPLIANCE SUMMARY CARD
  // ============================================================================
  Widget _buildComplianceSummaryCard(ComplianceSummary summary) {
    Color gradientStart = fmcgGreen;
    Color gradientEnd = fmcgDarkGreen;

    if (summary.grade.toUpperCase() == 'GOOD') {
      gradientStart = Colors.blue;
      gradientEnd = Colors.blue.shade900;
    } else if (summary.grade.toUpperCase().contains('ATTENTION')) {
      gradientStart = fmcgOrange;
      gradientEnd = Colors.orange.shade900;
    } else if (summary.grade.toUpperCase().contains('CRITICAL')) {
      gradientStart = fmcgRed;
      gradientEnd = Colors.red.shade900;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              summary.gradeEmoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              '${summary.compliance_score.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.grade,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip('PASS', summary.pass_count.toString(), fmcgGreen),
                _buildStatChip('FAIL', summary.fail_count.toString(), fmcgRed),
                _buildStatChip('SKIP', summary.skip_count.toString(), Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // BUILD DETECTION BY RACK LEVEL
  // ============================================================================
  Widget _buildDetectionByRackLevel(BuildContext context, ValidationResponse result) {
    // Check if we have detections from the response
    if (result.detections.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📌 No objects recognized with current confidence threshold',
                style: TextStyle(
                  fontSize: 14,
                  color: fmcgOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try: Adjust lighting, take clearer photos, or lower confidence threshold',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group detections by row/rack level
    final Map<int, List<DetectionItem>> detectionsByRack = {};
    
    for (final detection in result.detections) {
      // Use Y coordinate to estimate rack level
      final rackIndex = _estimateRackIndexFromCoords(detection.bbox.y1, detection.bbox.y2);
      detectionsByRack.putIfAbsent(rackIndex, () => []);
      detectionsByRack[rackIndex]!.add(detection);
    }

    // Sort racks by index
    final sortedRacks = detectionsByRack.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: sortedRacks.map((rackEntry) {
        final rackIndex = rackEntry.key;
        final detections = rackEntry.value;
        
        // Count products by name in this rack
        final productCounts = <String, int>{};
        for (final detection in detections) {
          final name = detection.product_name.toUpperCase();
          productCounts[name] = (productCounts[name] ?? 0) + 1;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              title: Text(
                'Rak Level ${rackIndex + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: fmcgDarkGray,
                ),
              ),
              subtitle: Text(
                '${productCounts.length} products, ${detections.length} units detected',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: productCounts.entries.map((entry) {
                      final productName = entry.key;
                      final count = entry.value;
                      
                      // Get the first detection for this product in this rack for details
                      final sampleDetection = detections
                          .firstWhere((d) => d.product_name.toUpperCase() == productName);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: fmcgLightGray,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: fmcgGreen,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name and count
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: fmcgDarkGray,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: fmcgGreen,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Confidence score
                              Text(
                                'Confidence: ${(sampleDetection.confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              
                              // Bounding box coordinates
                              Text(
                                'Coordinates: [${sampleDetection.bbox.x1.toStringAsFixed(0)}, '
                                '${sampleDetection.bbox.y1.toStringAsFixed(0)}, '
                                '${sampleDetection.bbox.x2.toStringAsFixed(0)}, '
                                '${sampleDetection.bbox.y2.toStringAsFixed(0)}]',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  int _estimateRackIndexFromCoords(double y1, double y2) {
    // Better rack estimation based on Y coordinates
    final yCenter = (y1 + y2) / 2;
    
    // Typical shelf layout with 3 rows
    // Adjust thresholds based on your image heights
    if (yCenter < 300) return 0;    // Top shelf
    if (yCenter < 600) return 1;    // Middle shelf
    if (yCenter < 900) return 2;    // Bottom shelf
    return 3;                       // Very bottom
  }

  // ============================================================================
  // BUILD PARAMETER BREAKDOWN
  // ============================================================================
  Widget _buildParameterBreakdown(BuildContext context, Map<String, dynamic> parameters) {
    final paramList = parameters.entries.toList();

    return Column(
      children: paramList.map((paramEntry) {
        final key = paramEntry.key;
        final param = paramEntry.value as Map<String, dynamic>;
        final status = param['status'] ?? 'UNKNOWN';
        final statusColor = _getStatusColor(status);
        final statusIcon = _getStatusIcon(status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: statusColor,
                radius: 20,
                child: Text(
                  statusIcon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Text(
                _getParameterName(key),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: fmcgDarkGray,
                ),
              ),
              subtitle: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildParameterDetails(param),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParameterDetails(Map<String, dynamic> param) {
    final details = param['details'] as Map<String, dynamic>?;
    final reason = param['reason'] as String?;

    if (reason != null && reason.isNotEmpty) {
      return Text(reason);
    }

    if (details == null || details.isEmpty) {
      return const Text('No details available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fmcgLightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: fmcgDarkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDetailsValue(entry.value),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDetailsValue(dynamic value) {
    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else if (value is List) {
      return value.join(', ');
    } else if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _getParameterName(String key) {
    final names = {
      'sos': '1️⃣ SOS (Share of Shelf)',
      'facing_oos': '2️⃣ Facing & OOS',
      'eye_level': '3️⃣B Eye Level',
      'sequence': '3️⃣ Sequence',
      'price_tag': '4️⃣ Price Tag',
      'void': '5️⃣ Void Detection',
      'posm': '6️⃣ POSM',
    };
    return names[key] ?? key;
  }
}
