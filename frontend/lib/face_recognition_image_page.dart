import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:yolofusion/theme/app_theme.dart';
import 'config.dart';

class FaceRecognitionImagePage extends StatefulWidget {
  const FaceRecognitionImagePage({super.key});

  @override
  _FaceRecognitionImagePageState createState() => _FaceRecognitionImagePageState();
}

class _FaceRecognitionImagePageState extends State<FaceRecognitionImagePage> {
  CameraController? _cameraController;
  File? _selectedImage;
  bool _isCameraActive = false;
  List<dynamic> _detections = [];
  double imageWidth = 0.0;
  double imageHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.high);
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization failed: $e'), duration: Duration(seconds: 3)),
      );
    }
  }

  Future<ui.Size> _getImageSize(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  Future<void> _takePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile image = await _cameraController!.takePicture();
        final File imageFile = File(image.path);
        final ui.Size size = await _getImageSize(imageFile);
        setState(() {
          _selectedImage = imageFile;
          imageWidth = size.width;
          imageHeight = size.height;
          _isCameraActive = false;
        });
        _processFaceImage(_selectedImage!);
      } catch (e) {
        debugPrint('Failed to capture image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e'), duration: Duration(seconds: 3)),
        );
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
        XFile? image;
        try {
          image = await _picker.pickImage(source: ImageSource.gallery);
        } on PlatformException catch (e) {
          debugPrint('PlatformException in pickImage: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to access gallery: $e'), duration: Duration(seconds: 3)),
          );
          return;
        }
        if (image != null) {
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
          });
          _processFaceImage(_selectedImage!);
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
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processFaceImage(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/detect_faces/'));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var result = await response.stream.bytesToString();
        var json = jsonDecode(result);
        setState(() {
          _detections = json['detections'] ?? [];
        });
        debugPrint('Face Recognition Results: $result');
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
        SnackBar(content: Text('API Error: $e'), duration: Duration(seconds: 3)),
      );
    }
  }

  Widget _buildImageView(bool withBoundingBoxes) {
    return SizedBox(
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
                if (withBoundingBoxes)
                  ..._detections.map((det) {
                    // Parse color from backend (assumes [R, G, B] format)
                    Color borderColor = Colors.green; // Match backend face_color (0, 255, 0)
                    if (det['color'] != null && det['color'] is List && det['color'].length == 3) {
                      borderColor = Color.fromRGBO(det['color'][0], det['color'][1], det['color'][2], 1.0);
                    }
                    // Handle potential analysis failure
                    String labelText = det['label'] ?? 'Unknown';
                    if (labelText.contains('Analysis Failed')) {
                      labelText = 'Face (Unknown Attributes)';
                    }
                    return Positioned(
                      left: offsetX + det['x1'] * scale,
                      top: offsetY + det['y1'] * scale,
                      width: (det['x2'] - det['x1']) * scale,
                      height: (det['y2'] - det['y1']) * scale,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            color: borderColor.withOpacity(0.6),
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              '$labelText (${det['conf'].toStringAsFixed(2)})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Face Attribute Detection'),
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
                  'Face Attribute Detection',
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
                                ? CameraPreview(_cameraController!)
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
                                setState(() {
                                  _selectedImage = null;
                                  _detections = [];
                                });
                              },
                              child: const Text('Retake/Change'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_selectedImage != null && _detections.isNotEmpty) ...[
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
                          _buildImageView(true),
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
                          'Detection Results',
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
                          child: _detections.isEmpty
                              ? const Text(
                            'No detections or processing...',
                            style: TextStyle(fontSize: 16, height: 1.5),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _detections.length,
                            itemBuilder: (context, index) {
                              var det = _detections[index];
                              String labelText = det['label'] ?? 'Unknown';
                              if (labelText.contains('Analysis Failed')) {
                                labelText = 'Face (Unknown Attributes)';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Face ${index + 1}:',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.5,
                                      ),
                                    ),
                                    Text(
                                      'Attributes: $labelText',
                                      style: const TextStyle(fontSize: 14, height: 1.5),
                                    ),
                                    Text(
                                      'Confidence: ${det['conf'].toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14, height: 1.5),
                                    ),
                                    Text(
                                      'Box: (${det['x1']}, ${det['y1']})-(${det['x2']}, ${det['y2']})',
                                      style: const TextStyle(fontSize: 14, height: 1.5),
                                    ),
                                  ],
                                ),
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