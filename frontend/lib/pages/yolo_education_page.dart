import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'theme/app_theme.dart';
import 'quiz_page.dart'; // Import the new QuizPage

class YoloEducationPage extends StatefulWidget {
  const YoloEducationPage({super.key});

  @override
  _YoloEducationPageState createState() => _YoloEducationPageState();
}

class _YoloEducationPageState extends State<YoloEducationPage> {
  final List<bool> _expandedStates = [false, false, false, false, false, false];
  final List<bool> _moduleViewed = [false, false, false, false, false, false];
  int _viewedModules = 0;

  @override
  void initState() {
    super.initState();
    if (_expandedStates.length != _moduleViewed.length) {
      throw Exception('Mismatch in module state arrays');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'YOLO Model Education',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Deep Dive into YOLO Models',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeInDown(
              duration: const Duration(milliseconds: 700),
              child: Text(
                'A comprehensive journey from the basics of object detection to deploying YOLO models in production.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Learning Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modules Viewed: $_viewedModules/6 (${(_viewedModules / 6 * 100).toStringAsFixed(0)}%)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _viewedModules > 0 ? _viewedModules / 6 : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildModuleCard(
              context,
              index: 0,
              title: 'Module 1: Introduction to YOLO and Object Detection',
              description:
              'Learn the fundamentals of object detection and how YOLO (You Only Look Once) revolutionized the field with its single-pass approach, making it fast and efficient for real-time applications.',
              extendedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'What is Object Detection?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Object detection involves identifying and locating objects in images or videos. YOLO models process the entire image in one forward pass, predicting bounding boxes and class probabilities simultaneously.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildKeyPointItem(
                    context,
                    'Why YOLO?',
                    'Unlike traditional two-stage detectors (e.g., Faster R-CNN), YOLO’s single-stage design offers unmatched speed, ideal for real-time systems like surveillance and robotics.',
                  ),
                  _buildKeyPointItem(
                    context,
                    'Evolution Overview',
                    'From YOLOv1 (2015) to YOLOv8 (2023), the family has grown in accuracy, speed, and versatility.',
                  ),
                ],
              ),
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              index: 1,
              title: 'Module 2: YOLO Architecture Deep Dive',
              description:
              'Explore the core architecture of YOLO models, including the backbone (e.g., CSPDarknet), neck (e.g., PANet), and head for bounding box prediction, enabling real-time performance.',
              extendedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'YOLO Architecture Diagram',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/yolo_architecture.png',
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading asset: $error');
                        return const Icon(
                          Icons.error,
                          size: 50,
                          color: AppTheme.errorColor,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The backbone extracts features, the neck aggregates them across scales, and the head predicts bounding boxes and class probabilities.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              icon: Icons.architecture,
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              index: 2,
              title: 'Module 3: Training YOLO Models',
              description:
              'Learn to train YOLO models with custom datasets using frameworks like PyTorch or Ultralytics, leveraging transfer learning and data augmentation for high accuracy.',
              extendedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Sample YOLOv8 Training Code',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '# Install Ultralytics\n'
                          'pip install ultralytics\n\n'
                          '# Train YOLOv8 model\n'
                          'from ultralytics import YOLO\n'
                          'model = YOLO("yolov8n.pt")\n'
                          'model.train(data="custom_dataset.yaml", epochs=100, imgsz=640)',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use pre-trained weights for transfer learning and adjust hyperparameters like image size and epochs for optimal performance.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              icon: Icons.model_training,
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              index: 3,
              title: 'Module 4: Advanced Applications',
              description:
              'Discover advanced YOLO applications like instance segmentation, pose estimation, and multi-object tracking, supported by YOLOv8’s enhanced modules.',
              extendedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Professional Use Cases',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUseCaseItem(
                    context,
                    'Autonomous Vehicles',
                    'Real-time detection of pedestrians, vehicles, and road signs for safe navigation.',
                  ),
                  _buildUseCaseItem(
                    context,
                    'Smart Cities',
                    'Traffic monitoring and crowd analysis for urban planning and safety.',
                  ),
                  _buildUseCaseItem(
                    context,
                    'Industrial Automation',
                    'Quality control and defect detection in manufacturing processes.',
                  ),
                ],
              ),
              icon: Icons.apps,
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              index: 4,
              title: 'Module 5: Performance Optimization',
              description:
              'Master techniques like model pruning, quantization, and TensorRT integration to deploy YOLO models on resource-constrained devices.',
              extendedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Optimization Metrics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetricItem(
                    context,
                    'FPS',
                    'Frames per second for real-time performance.',
                  ),
                  _buildMetricItem(
                    context,
                    'Latency',
                    'Time taken for a single inference pass.',
                  ),
                  _buildMetricItem(
                    context,
                    'IoU',
                    'Intersection over Union for bounding box accuracy.',
                  ),
                ],
              ),
              icon: Icons.speed,
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              index: 5,
              title: 'Module 6: Deploying YOLO in Production',
              description:
              'Learn strategies for deploying YOLO models in production environments, including cloud, edge, and hybrid setups for scalable applications.',
              extendedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Deployment Strategies',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUseCaseItem(
                    context,
                    'Cloud Deployment',
                    'Use AWS, Azure, or GCP for scalable inference with high availability.',
                  ),
                  _buildUseCaseItem(
                    context,
                    'Edge Deployment',
                    'Optimize models for edge devices like NVIDIA Jetson or Raspberry Pi using ONNX or TensorRT.',
                  ),
                  _buildUseCaseItem(
                    context,
                    'Hybrid Systems',
                    'Combine cloud and edge for low-latency, high-throughput applications.',
                  ),
                ],
              ),
              icon: Icons.cloud_upload,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Quiz',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
      BuildContext context, {
        required int index,
        required String title,
        required String description,
        required Widget extendedContent,
        required IconData icon,
      }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.pastelBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _expandedStates[index]
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppTheme.primaryBlue,
                    ),
                    onPressed: () {
                      if (index >= 0 && index < _expandedStates.length) {
                        setState(() {
                          _expandedStates[index] = !_expandedStates[index];
                          if (_expandedStates[index] && !_moduleViewed[index]) {
                            _moduleViewed[index] = true;
                            _viewedModules = _moduleViewed.where((viewed) => viewed).length;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _expandedStates[index]
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: extendedContent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPointItem(
      BuildContext context,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseCaseItem(
      BuildContext context,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      BuildContext context,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}