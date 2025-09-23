import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'pages/yolo_education_page.dart';
import 'app_state_manager.dart'; // Added import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  static const int _infiniteScrollCount = 10000;

  final List<String> _imagePaths = [
    'assets/image_0.jpg',
    'assets/image_1.jpg',
    'assets/image_2.jpg',
    'assets/image_3.jpg',
    'assets/image_4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = _infiniteScrollCount ~/ 2;
    _pageController = PageController(initialPage: _currentPage);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (AppStateManager().isAutoScrollEnabled && _pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOutCubicEmphasized,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentImageIndex = _currentPage % _imagePaths.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              'Welcome to YOLOFusion',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FadeInDown(
            duration: const Duration(milliseconds: 700),
            child: Text(
              'Learn About the Power of YOLO Models for Computer Vision',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeIn(
            duration: const Duration(milliseconds: 800),
            child: SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _infiniteScrollCount,
                itemBuilder: (context, index) {
                  final actualIndex = index % _imagePaths.length;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          _imagePaths[actualIndex],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          semanticLabel: 'Banner Image $actualIndex',
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.error,
                            size: 50,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.25),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                AppStateManager().isAutoScrollEnabled =
                                !AppStateManager().isAutoScrollEnabled;
                                if (!AppStateManager().isAutoScrollEnabled) {
                                  _autoScrollTimer?.cancel();
                                } else {
                                  _startAutoScroll();
                                }
                              });
                            },
                            child: Icon(
                              AppStateManager().isAutoScrollEnabled
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_imagePaths.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: currentImageIndex == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: currentImageIndex == index
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            child: _buildAboutYoloSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutYoloSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 32,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Discover YOLO Models',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'YOLO (You Only Look Once) is a revolutionary family of computer vision models designed for real-time object detection. Renowned for their speed and accuracy, YOLO models process images in a single pass, making them ideal for applications like autonomous driving, surveillance, and augmented reality.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Evolution of YOLO',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildTimelineItem(
              context,
              year: '2015',
              title: 'YOLOv1',
              description:
              'Introduced by Joseph Redmon, the first YOLO model revolutionized object detection with single-pass processing.',
            ),
            _buildTimelineItem(
              context,
              year: '2018',
              title: 'YOLOv3',
              description:
              'Improved accuracy and speed with multi-scale predictions and a more robust feature extractor.',
            ),
            _buildTimelineItem(
              context,
              year: '2020',
              title: 'YOLOv5',
              description:
              'Developed by Ultralytics, offering enhanced performance and ease of use for practical applications.',
            ),
            _buildTimelineItem(
              context,
              year: '2023',
              title: 'YOLOv8',
              description:
              'The latest iteration with state-of-the-art accuracy, speed, and support for diverse tasks like segmentation.',
            ),
            const SizedBox(height: 20),
            Text(
              'Key Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              context,
              'Real-Time Performance',
              'Processes images at high speeds (up to 60 FPS on modern GPUs), enabling seamless real-time applications.',
            ),
            _buildFeatureItem(
              context,
              'High Accuracy',
              'Achieves top-tier precision with minimal false positives using advanced backbone architectures like CSPDarknet.',
            ),
            _buildFeatureItem(
              context,
              'Versatility',
              'Supports over 80 object classes and extends to tasks like instance segmentation and pose estimation.',
            ),
            _buildFeatureItem(
              context,
              'Open-Source Ecosystem',
              'Backed by a vibrant community with extensive pre-trained models and tools for custom training.',
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const YoloEducationPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Explore YOLO Documentation',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, {
        required String year,
        required String title,
        required String description,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Column(
      children: [
      Container(
      width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: AppTheme.primaryBlue,
          shape: BoxShape.circle,
        ),
      ),
      Container(
        width: 2,
        height: 60,
        color: AppTheme.primaryBlue.withOpacity(0.3),
      ),
      ],
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    year,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryBlue,
    ),
    ),
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
    )],
    ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 10),
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