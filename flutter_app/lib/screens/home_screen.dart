import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/validation_provider.dart';
import '../models/validation_models.dart';
import 'result_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<DetectionItem> _detections = [];
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _productNameController;
  late TextEditingController _confidenceController;
  late TextEditingController _x1Controller;
  late TextEditingController _y1Controller;
  late TextEditingController _x2Controller;
  late TextEditingController _y2Controller;
  String _selectedClass = 'Product';

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _confidenceController = TextEditingController();
    _x1Controller = TextEditingController();
    _y1Controller = TextEditingController();
    _x2Controller = TextEditingController();
    _y2Controller = TextEditingController();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _confidenceController.dispose();
    _x1Controller.dispose();
    _y1Controller.dispose();
    _x2Controller.dispose();
    _y2Controller.dispose();
    super.dispose();
  }

  void _addDetection() {
    if (_formKey.currentState!.validate()) {
      final detection = DetectionItem(
        product_name: _productNameController.text,
        confidence: double.parse(_confidenceController.text),
        bbox: BBox(
          x1: double.parse(_x1Controller.text),
          y1: double.parse(_y1Controller.text),
          x2: double.parse(_x2Controller.text),
          y2: double.parse(_y2Controller.text),
        ),
        class_name: _selectedClass,
      );

      setState(() {
        _detections.add(detection);
      });

      // Clear form
      _productNameController.clear();
      _confidenceController.clear();
      _x1Controller.clear();
      _y1Controller.clear();
      _x2Controller.clear();
      _y2Controller.clear();
      _selectedClass = 'Product';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detection ditambahkan'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeDetection(int index) {
    setState(() {
      _detections.removeAt(index);
    });
  }

  void _validateDetections(BuildContext context) async {
    if (_detections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 detection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<ValidationProvider>();
    await provider.validate(_detections);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ResultScreen(),
        ),
      );
    }
  }

  void _loadDummyData(BuildContext context) async {
    final provider = context.read<ValidationProvider>();
    await provider.validateDummy();

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ResultScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planogram Validator'),
        elevation: 0,
        actions: [
          // Navigate to Scanner Screen
          Tooltip(
            message: 'Multi-Photo Audit',
            child: IconButton(
              icon: const Icon(Icons.photo_camera),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Planogram Validator',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Validasi kepatuhan planogram rak menggunakan YOLO detections',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadDummyData(context),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Test Dummy'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _detections.clear());
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form section
            const Text(
              'Add YOLO Detection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Product Name
                  TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(
                      hintText: 'Product name (e.g., Indomie, Aqua)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_basket),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Product name required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Confidence & Class selection
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _confidenceController,
                          decoration: const InputDecoration(
                            hintText: 'Confidence (0-1)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            final val = double.tryParse(value ?? '');
                            if (val == null || val < 0 || val > 1) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField(
                          initialValue: _selectedClass,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: ['Product', 'Price_Tag', 'POSM']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedClass = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bounding Box coordinates
                  const Text(
                    'Bounding Box (x1, y1, x2, y2)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _x1Controller,
                          decoration: const InputDecoration(
                            hintText: 'x1',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _y1Controller,
                          decoration: const InputDecoration(
                            hintText: 'y1',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _x2Controller,
                          decoration: const InputDecoration(
                            hintText: 'x2',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _y2Controller,
                          decoration: const InputDecoration(
                            hintText: 'y2',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addDetection,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Detection'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detections list
            if (_detections.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Added Detections (${_detections.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _detections.length,
                    itemBuilder: (context, index) {
                      final det = _detections[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: det.class_name == 'Product'
                                ? Colors.blue
                                : det.class_name == 'Price_Tag'
                                    ? Colors.orange
                                    : Colors.purple,
                            child: Text(
                              det.product_name[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(det.product_name),
                          subtitle: Text(
                            '${det.class_name} • Conf: ${(det.confidence * 100).toStringAsFixed(0)}%',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeDetection(index),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Validate button
            if (_detections.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: Consumer<ValidationProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => _validateDetections(context),
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(provider.isLoading
                          ? 'Validating...'
                          : 'Validate'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
