import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/validation_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PASS':
        return Colors.green;
      case 'FAIL':
        return Colors.red;
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
        title: const Text('Validation Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ValidationProvider>(
        builder: (context, provider, _) {
          if (!provider.hasResult) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final summary = provider.lastResult!.summary;
          final parameters = provider.lastResult!.parameters;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compliance Score Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Color(int.parse('FF${summary.grade == 'EXCELLENT' ? '2ECC71' : summary.grade == 'GOOD' ? '3498DB' : summary.grade == 'NEEDS_ATTENTION' ? 'F39C12' : 'E74C3C'}', radix: 16)),
                          Color(int.parse('FF${summary.grade == 'EXCELLENT' ? '27AE60' : summary.grade == 'GOOD' ? '2980B9' : summary.grade == 'NEEDS_ATTENTION' ? 'D68910' : 'C0392B'}', radix: 16)),
                        ],
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
                            fontSize: 40,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              'PASS',
                              summary.pass_count.toString(),
                              Colors.green,
                            ),
                            _buildStatCard(
                              'FAIL',
                              summary.fail_count.toString(),
                              Colors.red,
                            ),
                            _buildStatCard(
                              'SKIP',
                              summary.skip_count.toString(),
                              Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Parameters breakdown
                const Text(
                  'Parameter Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: parameters.length,
                  itemBuilder: (context, index) {
                    final key = parameters.keys.toList()[index];
                    final param = parameters[key];
                    final status = param['status'] ?? 'UNKNOWN';
                    final statusColor = _getStatusColor(status);
                    final statusIcon = _getStatusIcon(status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor,
                          child: Text(
                            statusIcon,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          _getParameterName(key),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildParameterDetails(param),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement export/share functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
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

  Widget _buildStatCard(String label, String count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildParameterDetails(Map<String, dynamic> param) {
    final details = param['details'];
    final reason = param['reason'];

    if (reason != null) {
      return Text(reason);
    }

    if (details == null) {
      return const Text('No details available');
    }

    if (details is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...details.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDetailsValue(e.value),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    }

    return Text(details.toString());
  }

  String _formatDetailsValue(dynamic value) {
    if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
    } else if (value is List) {
      return value.join(', ');
    }
    return value.toString();
  }

  String _getParameterName(String key) {
    final names = {
      'sos': 'Parameter 1: SOS',
      'facing_oos': 'Parameter 2 & 7: Facing & OOS',
      'eye_level': 'Parameter 3B: Eye Level',
      'sequence': 'Parameter 3: Sequence',
      'price_tag': 'Parameter 4: Price Tag',
      'void': 'Parameter 5: Void',
      'posm': 'Parameter 6: POSM',
    };
    return names[key] ?? key;
  }
}
