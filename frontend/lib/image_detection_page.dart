import 'package:flutter/material.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class ImageDetectionPage extends StatefulWidget {
  const ImageDetectionPage({super.key});

  @override
  _ImageDetectionPageState createState() => _ImageDetectionPageState();
}

class _ImageDetectionPageState extends State<ImageDetectionPage> {
  int? _cameraId;
  File? _selectedImage;
  bool _isCameraActive = false;
  bool _isProcessing = false;
  List<dynamic> _detections = [];
  double imageWidth = 0.0;
  double imageHeight = 0.0;
  List<CameraDescription> _cameras = [];
  bool _initialized = false;
  int _selectedCameraIndex = 0; // Default to first camera (usually back)

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
    _fetchCameras();
  }

  Future<void> _fetchCameras() async {
    int retryCount = 0;
    const maxRetries = 3;
    while (retryCount < maxRetries) {
      try {
        debugPrint('Platform: ${Platform.operatingSystem}');
        debugPrint('Attempting to fetch available cameras... (Attempt ${retryCount + 1}/$maxRetries)');
        debugPrint('CameraPlatform instance: ${CameraPlatform.instance.runtimeType}');
        _cameras = await CameraPlatform.instance.availableCameras();
        debugPrint('Number of cameras found: ${_cameras.length}');
        if (_cameras.isEmpty) {
          debugPrint('No cameras detected on this device.');
          String message = Platform.isWindows
              ? 'No cameras detected. Please check if a webcam is connected, drivers are installed, and Windows Media Features are enabled (Control Panel > Programs > Turn Windows features on or off > Media Features).'
              : 'No cameras available on this device.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: Duration(seconds: 3)),
          );
        } else {
          debugPrint('Cameras detected:');
          for (var camera in _cameras) {
            debugPrint(' - Camera: ${camera.name}, Lens Direction: ${camera.lensDirection}');
          }
          // On mobile, set default to back camera
          if (Platform.isAndroid || Platform.isIOS) {
            _selectedCameraIndex = _cameras.indexWhere((cam) => cam.lensDirection == CameraLensDirection.back);
            if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
          }
        }
        if (mounted) {
          setState(() {});
        }
        return;
      } on PlatformException catch (e) {
        debugPrint('PlatformException in _fetchCameras: code=${e.code}, message=${e.message}, details=${e.details}');
        String message = Platform.isWindows
            ? 'Camera error: ${e.message}. Ensure webcam is connected, drivers are updated, camera permissions are granted in Windows Settings > Privacy > Camera, and Media Features are enabled.'
            : 'Failed to fetch cameras: ${e.message}';
        if (e.code == 'channel-error' && Platform.isWindows) {
          message = 'Camera communication error: ${e.message}. Try restarting the app, updating webcam drivers, or enabling Windows Media Features (Control Panel > Programs > Turn Windows features on or off > Media Features).';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: Duration(seconds: 3)),
        );
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
          debugPrint('Retrying camera fetch...');
        }
      } catch (e) {
        debugPrint('Unexpected error in _fetchCameras: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected camera error: $e'), duration: Duration(seconds: 3)),
        );
        return;
      }
    }
    if (retryCount == maxRetries) {
      debugPrint('Max retries reached for fetching cameras.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch cameras after multiple attempts. Please check system setup and restart the app.'), duration: Duration(seconds: 3)),
      );
    }
  }

  Future<void> _disposeCamera() async {
    if (_initialized && _cameraId != null) {
      try {
        debugPrint('Disposing camera with ID: $_cameraId');
        await CameraPlatform.instance.dispose(_cameraId!);
        debugPrint('Camera disposed successfully');
        setState(() {
          _initialized = false;
          _cameraId = null;
        });
      } catch (e) {
        debugPrint('Failed to dispose camera: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dispose camera: $e'), duration: Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _startCamera() async {
    if (_cameras.isEmpty) {
      debugPrint('No cameras available to start.');
      String message = Platform.isWindows
          ? 'No cameras available. Please check webcam connection, drivers, and Windows Media Features.'
          : 'No cameras available.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 3)),
      );
      setState(() {
        _isCameraActive = false;
      });
      return;
    }
    try {
      debugPrint('Requesting camera permission...');
      var status = await Permission.camera.request();
      debugPrint('Camera permission status: $status');
      if (!status.isGranted) {
        debugPrint('Camera permission denied.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied'), duration: Duration(seconds: 3)),
        );
        setState(() {
          _isCameraActive = false;
        });
        return;
      }
      await _disposeCamera();
      final CameraDescription camera = _cameras[_selectedCameraIndex];
      debugPrint('Creating camera with settings for: ${camera.name}');
      _cameraId = await CameraPlatform.instance.createCameraWithSettings(
        camera,
        const MediaSettings(resolutionPreset: ResolutionPreset.high),
      );
      debugPrint('Initializing camera with ID: $_cameraId');
      await CameraPlatform.instance.initializeCamera(_cameraId!);
      debugPrint('Camera initialized successfully with ID: $_cameraId');
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization failed: $e'), duration: Duration(seconds: 3)),
      );
      setState(() {
        _isCameraActive = false;
      });
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    _startCamera();
  }

  Future<ui.Size> _getImageSize(File file) async {
    try {
      debugPrint('Reading image file to get size: ${file.path}');
      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      debugPrint('Image size: ${frame.image.width}x${frame.image.height}');
      return ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    } catch (e) {
      debugPrint('Failed to get image size: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load image dimensions: $e'), duration: Duration(seconds: 3)),
      );
      return ui.Size(0.0, 0.0);
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraId != null && _initialized) {
      try {
        debugPrint('Capturing photo with camera ID: $_cameraId');
        final XFile file = await CameraPlatform.instance.takePicture(_cameraId!);
        debugPrint('Photo captured at path: ${file.path}');
        final File imageFile = File(file.path);
        final ui.Size size = await _getImageSize(imageFile);
        if (size.width == 0.0 || size.height == 0.0) {
          debugPrint('Invalid image dimensions: ${size.width}x${size.height}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load image dimensions'), duration: Duration(seconds: 3)),
          );
          return;
        }
        setState(() {
          _selectedImage = imageFile;
          imageWidth = size.width;
          imageHeight = size.height;
          _isCameraActive = false;
          _isProcessing = true;
          _detections = []; // Clear previous detections
        });
        debugPrint('Disposing camera after photo capture');
        await _disposeCamera();
        await _processImage(imageFile);
        setState(() {
          _isProcessing = false;
        });
      } catch (e) {
        debugPrint('Failed to capture image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e'), duration: Duration(seconds: 3)),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    final ImagePicker _picker = ImagePicker();
    try {
      debugPrint('Requesting photo library permission...');
      Map<Permission, PermissionStatus> statuses;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        if (sdkInt >= 33) {
          statuses = await [Permission.photos, Permission.videos].request();
        } else if (sdkInt >= 30) {
          statuses = await [Permission.photos, Permission.storage].request();
        } else {
          statuses = await [Permission.storage].request();
        }
      } else {
        statuses = await [Permission.photos].request();
      }

      if (statuses.values.any((status) => status.isPermanentlyDenied)) {
        debugPrint('Photo library permission permanently denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo library access denied. Please enable in app settings.'),
            duration: Duration(seconds: 3),
          ),
        );
        await openAppSettings();
        return;
      }

      if (statuses.values.every((status) => status.isGranted)) {
        debugPrint('Picking image from gallery...');
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          debugPrint('Image selected: ${image.path}');
          final File imageFile = File(image.path);
          final ui.Size size = await _getImageSize(imageFile);
          if (size.width == 0.0 || size.height == 0.0) {
            debugPrint('Invalid image dimensions: ${size.width}x${size.height}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load image dimensions'), duration: Duration(seconds: 3)),
            );
            return;
          }
          setState(() {
            _selectedImage = imageFile;
            imageWidth = size.width;
            imageHeight = size.height;
            _isProcessing = true;
            _detections = []; // Clear previous detections
          });
          await _processImage(imageFile);
          setState(() {
            _isProcessing = false;
          });
        } else {
          debugPrint('No image selected');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected'), duration: Duration(seconds: 3)),
          );
        }
      } else {
        debugPrint('Photo library permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo library permission denied'), duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), duration: Duration(seconds: 3)),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/detect_objects/'));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var result = await response.stream.bytesToString();
        var json = jsonDecode(result);
        setState(() {
          _detections = json['detections'] ?? [];
        });
        debugPrint('Object Detection Results: $result');
      } else {
        debugPrint('Error: ${response.statusCode}');
        setState(() { _detections = []; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: HTTP ${response.statusCode}'), duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      debugPrint('API Error: $e');
      setState(() { _detections = []; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Error: $e'), duration: Duration(seconds: 2)),
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
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _startCamera();
              setState(() {
                _isCameraActive = true;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Upload from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _uploadImage();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prepare data for the table
    List<DataRow> detectionRows = _detections.map((det) {
      return DataRow(cells: [
        DataCell(Text(det['label'])),
        DataCell(Text(det['conf'].toStringAsFixed(2))),
        DataCell(Text('(${det['x1']},${det['y1']})-(${det['x2']},${det['y2']})')),
      ]);
    }).toList();

    bool isMobile = Platform.isAndroid || Platform.isIOS;

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
                  'Image Detection',
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
                          'Original Image',
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
                            child: _selectedImage == null && !_isCameraActive
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: AppTheme.primaryBlue.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Add an image using the "+" button',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                                : _isCameraActive
                                ? Stack(
                              children: [
                                if (_initialized && _cameraId != null)
                                  Positioned.fill(
                                    child: CameraPlatform.instance.buildPreview(_cameraId!),
                                  )
                                else
                                  const Center(child: CircularProgressIndicator()),
                                if (isMobile && _cameras.length > 1)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.switch_camera, color: Colors.white),
                                      onPressed: _switchCamera,
                                    ),
                                  ),
                              ],
                            )
                                : Image.file(
                              _selectedImage!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isCameraActive)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera),
                              label: const Text('Capture'),
                              onPressed: _takePhoto,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else if (_selectedImage != null)
                          Center(
                            child: OutlinedButton(
                              onPressed: () {
                                debugPrint('User clicked Retake/Change');
                                setState(() {
                                  _selectedImage = null;
                                  _detections = [];
                                  _isCameraActive = false;
                                });
                              },
                              child: const Text('Retake/Change'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else if (_selectedImage != null && _detections.isNotEmpty) ...[
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
                            'Processed Image with Detections',
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
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final scaleX = constraints.maxWidth / imageWidth;
                                  final scaleY = constraints.maxHeight / imageHeight;
                                  final scale = scaleX < scaleY ? scaleX : scaleY;
                                  final offsetX = (constraints.maxWidth - imageWidth * scale) / 2;
                                  final offsetY = (constraints.maxHeight - imageHeight * scale) / 2;
                                  return Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      ..._detections.map((det) => Positioned(
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
                    'Total Bounding Boxes: ${_detections.length}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_detections.isEmpty)
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
        floatingActionButton: _selectedImage == null && !_isCameraActive
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