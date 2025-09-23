import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'theme/app_theme.dart';
import 'object_detection_page.dart';
import 'face_recognition_page.dart';
import 'activity_analysis_page.dart';  // Add this import for the new page

class DetectionSystemsPage extends StatelessWidget {
  const DetectionSystemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              'Detection Systems',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInDown(
            duration: const Duration(milliseconds: 700),
            child: Text(
              'Discover cutting-edge vision-based detection technologies',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 32),
// First Row: Smart Object Recognition and Advanced Face Analysis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
// SMART OBJECT RECOGNITION CARD
              Expanded(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ObjectDetectionPage(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/image_object.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.65),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Object Detection',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
// ADVANCED FACE ANALYSIS CARD
              Expanded(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 900),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FaceRecognitionPage(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/image_face.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
// color: const Color(0xFF1C2E44).withOpacity(0.75),
                              color: AppTheme.primaryBlue.withOpacity(0.65),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Face Recognition',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
// Second Row: Human Activity Intelligence and AgriVision: Plant Health Detection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
// HUMAN ACTIVITY INTELLIGENCE CARD
              Expanded(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivityAnalysisPage(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/image_activity.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.65), // Deep teal for human activity
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Activity Analysis',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
// AGRIVISION: PLANT HEALTH DETECTION CARD
              Expanded(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1100),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ComingSoonPage(
                              featureName: 'AgriVision: Plant Health Detection',
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/image_plant1.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.65),// Forest green for plant health
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Plant Health Detection',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ComingSoonPage extends StatelessWidget {
  final String featureName;

  const ComingSoonPage({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          featureName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.pastelBlue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Text(
                '$featureName is under development.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A90C1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Detection Systems',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}