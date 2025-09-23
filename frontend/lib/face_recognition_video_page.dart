import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'config.dart';

class FaceRecognitionVideoPage extends StatefulWidget {
  const FaceRecognitionVideoPage({super.key});

  @override
  _FaceRecognitionVideoPageState createState() => _FaceRecognitionVideoPageState();
}

class _FaceRecognitionVideoPageState extends State<FaceRecognitionVideoPage> {
  VideoPlayerController? _videoController;
  VideoPlayerController? _processedVideoController;
  List<dynamic> _videoResults = [];
  List<dynamic> _currentDetections = [];
  double videoWidth = 0.0;
  double videoHeight = 0.0;
  final double assumedFps = 30.0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _uploadVideo() async {
    final ImagePicker _picker = ImagePicker();
    try {
      debugPrint('Requesting video library permissions...');
      Map<Permission, PermissionStatus> statuses;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        if (sdkInt >= 33) {
          statuses = await [Permission.videos, Permission.photos].request();
        } else if (sdkInt >= 30) {
          statuses = await [Permission.videos, Permission.storage].request();
        } else {
          statuses = await [Permission.storage].request();
        }
      } else {
        statuses = await [Permission.photos].request();
      }

      if (statuses.values.any((status) => status.isPermanentlyDenied)) {
        debugPrint('Video library permission permanently denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video library access denied. Please enable in app settings.'),
            duration: Duration(seconds: 3),
          ),
        );
        await openAppSettings();
        return;
      }

      if (statuses.values.every((status) => status.isGranted)) {
        debugPrint('Picking video from gallery...');
        XFile? video;
        try {
          video = await _picker.pickVideo(source: ImageSource.gallery);
        } on PlatformException catch (e) {
          debugPrint('PlatformException in pickVideo: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to access gallery: $e'), duration: Duration(seconds: 3)),
          );
          return;
        }
        if (video != null) {
          final File videoFile = File(video.path);
          _videoController?.dispose();
          _processedVideoController?.dispose();
          _videoController = VideoPlayerController.file(videoFile);
          _processedVideoController = VideoPlayerController.file(videoFile);
          await Future.wait([
            _videoController!.initialize(),
            _processedVideoController!.initialize(),
          ]);
          videoWidth = _videoController!.value.size.width;
          videoHeight = _videoController!.value.size.height;
          _processedVideoController!.addListener(_updateCurrentDetections);
          setState(() {});
          _processFaceVideo(videoFile);
        } else {
          debugPrint('No video selected');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No video selected'), duration: Duration(seconds: 3)),
          );
        }
      } else {
        debugPrint('Video library permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video library permission denied'), duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      debugPrint('Failed to pick video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e'), duration: Duration(seconds: 3)),
      );
    }
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Upload Your Video'),
            onTap: () {
              Navigator.pop(context);
              _uploadVideo();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _processedVideoController?.removeListener(_updateCurrentDetections);
    _videoController?.dispose();
    _processedVideoController?.dispose();
    super.dispose();
  }

  void _updateCurrentDetections() {
    if (_processedVideoController != null && _processedVideoController!.value.isPlaying) {
      final position = _processedVideoController!.value.position;
      final currentFrame = (position.inMilliseconds / 1000 * assumedFps).toInt();
      final frameData = _videoResults.firstWhere(
            (result) => result['frame'] == currentFrame,
        orElse: () => null,
      );
      if (frameData != null && frameData['detections'] != _currentDetections) {
        setState(() {
          _currentDetections = frameData['detections'];
        });
      }
    }
  }

  void _controlBothControllers(Function(VideoPlayerController) action) {
    if (_videoController != null) action(_videoController!);
    if (_processedVideoController != null) action(_processedVideoController!);
  }

  Future<void> _processFaceVideo(File video) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/process_video/face'));
      request.files.add(await http.MultipartFile.fromPath('file', video.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var result = await response.stream.bytesToString();
        var json = jsonDecode(result);
        setState(() {
          _videoResults = json['results'] ?? [];
        });
        debugPrint('Face Video Recognition Results: $result');
      } else {
        debugPrint('Error: ${response.statusCode}');
        setState(() { _videoResults = []; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process video: HTTP ${response.statusCode}'), duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      debugPrint('API Error: $e');
      setState(() { _videoResults = []; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Error: $e'), duration: Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Face Recognition'),
          backgroundColor: AppTheme.primaryBlue,
          elevation: 0,
          centerTitle: true,
        ),
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Video Recognition',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: AppTheme.primaryBlue, thickness: 2),
                const SizedBox(height: 24),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Video',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _videoController == null
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_camera_front,
                                    size: 60,
                                    color: AppTheme.primaryBlue.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Add a video using the "+" button',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                                : VideoPlayer(_videoController!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_videoController != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filled(
                                icon: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _controlBothControllers((controller) {
                                      controller.value.isPlaying
                                          ? controller.pause()
                                          : controller.play();
                                    });
                                  });
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton.filled(
                                icon: const Icon(Icons.replay),
                                onPressed: () {
                                  _controlBothControllers((controller) {
                                    controller.seekTo(Duration.zero);
                                    controller.play();
                                  });
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                if (_processedVideoController != null) ...[
                  const SizedBox(height: 32),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Processed Video with Detections',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: _processedVideoController!.value.aspectRatio,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final scaleX = constraints.maxWidth / videoWidth;
                                  final scaleY = constraints.maxHeight / videoHeight;
                                  final scale = scaleX < scaleY ? scaleX : scaleY;
                                  final offsetX = (constraints.maxWidth - videoWidth * scale) / 2;
                                  final offsetY = (constraints.maxHeight - videoHeight * scale) / 2;
                                  return Stack(
                                    children: [
                                      VideoPlayer(_processedVideoController!),
                                      ..._currentDetections.map((det) => Positioned(
                                        left: offsetX + det['x1'] * scale,
                                        top: offsetY + det['y1'] * scale,
                                        width: (det['x2'] - det['x1']) * scale,
                                        height: (det['y2'] - det['y1']) * scale,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.red, width: 2),
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              color: Colors.red.withOpacity(0.5),
                                              padding: const EdgeInsets.all(2),
                                              child: Text(
                                                '${det['label']} ${det['conf'].toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recognition Results',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.pastelBlue,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: _videoResults.isEmpty
                              ? const Text(
                            'No detections or processing...',
                            style: TextStyle(fontSize: 16, height: 1.5),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _videoResults.length > 10 ? 10 : _videoResults.length,
                            itemBuilder: (context, frameIndex) {
                              var frameData = _videoResults[frameIndex];
                              var dets = frameData['detections'] as List;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Frame ${frameData['frame']}:'),
                                  ...dets.map((det) => Text(
                                    '  Label: ${det['label']}, Conf: ${det['conf'].toStringAsFixed(2)}, Box: (${det['x1']},${det['y1']})-(${det['x2']},${det['y2']})',
                                    style: const TextStyle(fontSize: 16, height: 1.5),
                                  )),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _videoController == null
            ? FloatingActionButton(
          onPressed: _showActionSheet,
          backgroundColor: AppTheme.primaryBlue,
          child: const Icon(Icons.add),
        )
            : null,
      ),
    );
  }
}