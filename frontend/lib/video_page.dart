import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _videoController;
  VideoPlayerController? _processedVideoController;
  List<dynamic> _videoResults = [];
  List<dynamic> _currentDetections = [];
  double videoWidth = 0.0;
  double videoHeight = 0.0;
  bool _isProcessing = false;

  final List<Color> boundingBoxColors = [
    Color(0xFFADD8E6),
    Color(0xFF90EE90),
    Color(0xFFFFFFE0),
    Color(0xFFFFDAB9),
    Color(0xFFFFC0CB),
    Color(0xFFE6E6FA),
    Color(0xFFAFEEEE),
    Color(0xFF98FB98),
    Color(0xFFFFE4B5),
    Color(0xFFFAFAD2),
    Color(0xFF87CEEB),
    Color(0xFF98FB98),
    Color(0xFFFFFACD),
    Color(0xFFFFB6C1),
    Color(0xFFE0FFFF),
  ];

  Color getColorForLabel(String label) {
    int hash = label.hashCode;
    return boundingBoxColors[hash.abs() % boundingBoxColors.length];
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _uploadVideo() async {
    debugPrint('Running on platform: ${Platform.operatingSystem}');
    final ImagePicker _picker = ImagePicker();
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint('Using image_picker for mobile');
        var status = await Permission.photos.request();
        if (Platform.isAndroid && !status.isGranted) {
          status = await Permission.videos.request();
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }
        if (status.isPermanentlyDenied) {
          debugPrint('Video library permission permanently denied');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video library access denied. Please enable in app settings.'),
              duration: Duration(seconds: 1),
            ),
          );
          await openAppSettings();
          return;
        }
        if (!status.isGranted) {
          debugPrint('Video library permission denied');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video library permission denied'), duration: Duration(seconds: 1)),
          );
          return;
        }
        debugPrint('Picking video from gallery...');
        XFile? video;
        try {
          video = await _picker.pickVideo(source: ImageSource.gallery);
        } on PlatformException catch (e) {
          debugPrint('PlatformException in pickVideo: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to access gallery: $e'), duration: Duration(seconds: 1)),
          );
          return;
        }
        if (video != null) {
          debugPrint('Initializing VideoPlayerController with video: ${video.path}');
          final File videoFile = File(video.path);
          _videoController?.dispose();
          _processedVideoController?.dispose();
          _videoController = VideoPlayerController.file(videoFile);
          _processedVideoController = VideoPlayerController.file(videoFile);
          debugPrint('Initializing VideoPlayerController...');
          try {
            await Future.wait([
              _videoController!.initialize(),
              _processedVideoController!.initialize(),
            ]);
            debugPrint('VideoPlayerController initialized successfully');
          } catch (e) {
            debugPrint('VideoPlayerController initialization failed: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to initialize video player: $e'), duration: Duration(seconds: 1)),
            );
            return;
          }
          videoWidth = _videoController!.value.size.width;
          videoHeight = _videoController!.value.size.height;
          _processedVideoController!.addListener(_updateCurrentDetections);
          setState(() {
            _isProcessing = true;
            _videoResults = []; // Clear previous results
            _currentDetections = []; // Clear current detections
          });
          await _processVideo(videoFile);
          setState(() {
            _isProcessing = false;
          });
        } else {
          debugPrint('No video selected');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No video selected'), duration: Duration(seconds: 1)),
          );
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        debugPrint('Using file_selector for desktop');
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'Videos',
          extensions: <String>['mp4', 'mov', 'avi', 'mkv', 'wmv'],
        );
        final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
        if (file != null) {
          final XFile video = XFile(file.path);
          debugPrint('Video file path: ${video.path}');
          final File videoFile = File(video.path);
          _videoController?.dispose();
          _processedVideoController?.dispose();
          _videoController = VideoPlayerController.file(videoFile);
          _processedVideoController = VideoPlayerController.file(videoFile);
          debugPrint('Initializing VideoPlayerController...');
          try {
            await Future.wait([
              _videoController!.initialize(),
              _processedVideoController!.initialize(),
            ]);
            debugPrint('VideoPlayerController initialized successfully');
          } catch (e) {
            debugPrint('VideoPlayerController initialization failed: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to initialize video player: $e'), duration: Duration(seconds: 1)),
            );
            return;
          }
          videoWidth = _videoController!.value.size.width;
          videoHeight = _videoController!.value.size.height;
          _processedVideoController!.addListener(_updateCurrentDetections);
          setState(() {
            _isProcessing = true;
            _videoResults = []; // Clear previous results
            _currentDetections = []; // Clear current detections
          });
          await _processVideo(videoFile);
          setState(() {
            _isProcessing = false;
          });
        } else {
          debugPrint('No file selected on desktop');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No video file selected'), duration: Duration(seconds: 1)),
          );
          return;
        }
      } else {
        debugPrint('Unsupported platform: ${Platform.operatingSystem}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video picking not supported on this platform'), duration: Duration(seconds: 1)),
        );
        return;
      }
    } catch (e) {
      debugPrint('Failed to pick video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e'), duration: Duration(seconds: 1)),
      );
      setState(() {
        _isProcessing = false;
      });
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
      final fps = 30.0;
      final currentFrame = (position.inMilliseconds / 1000 * fps).toInt();

      dynamic closestFrameData;
      int closestDiff = 99999999;
      for (var result in _videoResults) {
        final diff = (currentFrame - result['frame']).abs().toInt();
        if (diff < closestDiff) {
          closestDiff = diff;
          closestFrameData = result;
        }
      }

      if (closestFrameData != null && closestFrameData['detections'] != _currentDetections) {
        setState(() {
          _currentDetections = closestFrameData['detections'];
        });
      }
    }
  }

  void _controlBothControllers(Function(VideoPlayerController) action) {
    if (_videoController != null) action(_videoController!);
    if (_processedVideoController != null) action(_processedVideoController!);
  }

  Future<void> _processVideo(File video) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/process_video/object'));
      request.files.add(await http.MultipartFile.fromPath('file', video.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var result = await response.stream.bytesToString();
        var json = jsonDecode(result);
        setState(() {
          _videoResults = json['results'] ?? [];
        });
        debugPrint('Object Video Detection Results: $result');
      } else {
        debugPrint('Error: ${response.statusCode}');
        setState(() { _videoResults = []; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process video: HTTP ${response.statusCode}'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint('API Error: $e');
      setState(() { _videoResults = []; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Error: $e'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total bounding boxes
    int totalBB = _videoResults.fold(0, (sum, frame) => sum + (frame['detections'] as List).length);

    // Prepare data for the table
    List<DataRow> detectionRows = [];
    int displayedFrames = _videoResults.length > 10 ? 10 : _videoResults.length;
    for (int frameIndex = 0; frameIndex < displayedFrames; frameIndex++) {
      var frameData = _videoResults[frameIndex];
      var dets = frameData['detections'] as List;
      for (var det in dets) {
        detectionRows.add(DataRow(cells: [
          DataCell(Text('${frameData['frame']}')),
          DataCell(Text(det['label'])),
          DataCell(Text(det['conf'].toStringAsFixed(2))),
          DataCell(Text('(${det['x1']},${det['y1']})-(${det['x2']},${det['y2']})')),
        ]));
      }
    }

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Object Detection'),
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
                  'Video Detection',
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
                        _videoController == null
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
                            : Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                ),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else if (_processedVideoController != null && _videoResults.isNotEmpty) ...[
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
                                            border: Border.all(color: getColorForLabel(det['label']), width: 2),
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              color: getColorForLabel(det['label']).withOpacity(0.5),
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
                  const SizedBox(height: 32),
                  Text(
                    'Detection Results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total Bounding Boxes: $totalBB',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_videoResults.isEmpty)
                    const Text(
                      'No detections or processing...',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(
                          color: Colors.grey.withOpacity(0.5),
                          width: 1,
                        ),
                        columnSpacing: 16,
                        dataRowHeight: 48,
                        headingRowColor: MaterialStateColor.resolveWith((states) => AppTheme.primaryBlue.withOpacity(0.1)),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Frame',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Label',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Conf',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Box',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                        rows: detectionRows,
                      ),
                    ),
                ],
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