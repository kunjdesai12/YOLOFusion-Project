import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'theme/app_theme.dart';
import 'image_detection_page.dart';
import 'video_page.dart';

class ObjectDetectionPage extends StatelessWidget {
  const ObjectDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Object Detection'),
          backgroundColor: AppTheme.primaryBlue,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Text(
                //   'Object Detection Dashboard',
                //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                //     fontSize: 28,
                //     fontWeight: FontWeight.w700,
                //     color: AppTheme.textDark,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // const Divider(color: AppTheme.primaryBlue, thickness: 2),
                // const SizedBox(height: 24),
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: Text(
                    'Leverage YOLOFusion\'s cutting-edge algorithms for efficient object detection and classification. Explore the options below to get started.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      _buildOptionCard(
                        context,
                        icon: Icons.image,
                        title: 'Image Detection',
                        description: 'Capture or upload images for precise object analysis.',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ImageDetectionPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildOptionCard(
                        context,
                        icon: Icons.video_library,
                        title: 'Video Detection',
                        description: 'Analyze preloaded videos with real-time detection.',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VideoPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required VoidCallback onPressed,
      }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}