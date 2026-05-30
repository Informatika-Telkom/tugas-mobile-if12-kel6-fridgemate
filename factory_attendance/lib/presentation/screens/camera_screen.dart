import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../../core/services/notification_service.dart';
import 'selfie_result_screen.dart';

class SelfieCaptureResult {
  final bool success;
  final String? filePath;

  const SelfieCaptureResult({required this.success, this.filePath});
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isInitialized = false;
  String _lightingLabel = 'Unknown';
  Color _lightingColor = Colors.white70;

  static const double _sharpnessThreshold = 80.0;
  static const double _lightingLow = 60.0;
  static const double _lightingHigh = 200.0;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(options: FaceDetectorOptions());
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  Future<void> _captureAndValidate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      final XFile picture = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);

      final faces = await _faceDetector.processImage(inputImage);
      final analysis = await _analyzeImage(picture.path);
      if (!mounted) return;

      final issues = <String>[];
      if (faces.isEmpty) {
        issues.add('Wajah tidak terdeteksi. Posisikan wajah di dalam frame.');
      } else if (faces.length > 1) {
        issues.add(
          'Terdeteksi lebih dari 1 wajah. Pastikan hanya Anda di frame.',
        );
      }

      if (analysis.sharpness < _sharpnessThreshold) {
        issues.add('Foto terlihat blur. Coba stabilkan kamera.');
      }

      if (analysis.brightness < _lightingLow) {
        issues.add('Pencahayaan terlalu gelap. Cari tempat lebih terang.');
      } else if (analysis.brightness > _lightingHigh) {
        issues.add('Pencahayaan terlalu terang. Hindari backlight.');
      }

      final isSuccess = issues.isEmpty;

      if (!isSuccess) {
        await NotificationService.instance.showFaceDetectionFailure(
          issues.isEmpty ? 'Wajah tidak terdeteksi dengan baik.' : issues.first,
        );
      }

      final usePhoto = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SelfieResultScreen(
            imagePath: picture.path,
            isSuccess: isSuccess,
            lightingLabel: analysis.lightingLabel,
            brightness: analysis.brightness,
            sharpness: analysis.sharpness,
            issues: issues,
          ),
        ),
      );

      if (!mounted) return;

      if (usePhoto == true && isSuccess) {
        Navigator.pop(
          context,
          SelfieCaptureResult(success: true, filePath: picture.path),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fix aspect ratio
          Builder(
            builder: (context) {
              final size = MediaQuery.of(context).size;
              var scale =
                  size.aspectRatio * _cameraController!.value.aspectRatio;
              if (scale < 1) scale = 1 / scale;
              return Transform.scale(
                scale: scale,
                child: Center(child: CameraPreview(_cameraController!)),
              );
            },
          ),

          // Overlay mask
          CustomPaint(painter: _OverlayPainter()),

          // UI Elements
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _LightingIndicator(
                        label: _lightingLabel,
                        color: _lightingColor,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: GestureDetector(
                    onTap: _captureAndValidate,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
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

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2 - 50),
          width: size.width * 0.7,
          height: size.height * 0.5,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Border for the oval
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 50),
        width: size.width * 0.7,
        height: size.height * 0.5,
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LightingIndicator extends StatelessWidget {
  final String label;
  final Color color;

  const _LightingIndicator({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          Icon(Icons.light_mode, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            'Lighting: $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageAnalysisResult {
  final double sharpness;
  final double brightness;
  final String lightingLabel;
  final Color lightingColor;

  const _ImageAnalysisResult({
    required this.sharpness,
    required this.brightness,
    required this.lightingLabel,
    required this.lightingColor,
  });
}

extension on _CameraScreenState {
  Future<_ImageAnalysisResult> _analyzeImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const _ImageAnalysisResult(
        sharpness: 0,
        brightness: 0,
        lightingLabel: 'Unknown',
        lightingColor: Colors.white70,
      );
    }

    final gray = img.grayscale(decoded);
    final brightness = _calculateAverageLuminance(gray);
    final sharpness = _calculateLaplacianVariance(gray);
    final lightingLabel = _brightnessLabel(brightness);
    final lightingColor = _brightnessColor(brightness);

    if (mounted) {
      setState(() {
        _lightingLabel = lightingLabel;
        _lightingColor = lightingColor;
      });
    }

    return _ImageAnalysisResult(
      sharpness: sharpness,
      brightness: brightness,
      lightingLabel: lightingLabel,
      lightingColor: lightingColor,
    );
  }

  double _calculateAverageLuminance(img.Image image) {
    double total = 0;
    final width = image.width;
    final height = image.height;
    final count = width * height;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        total += img.getLuminance(pixel).toDouble();
      }
    }

    return count == 0 ? 0 : total / count;
  }

  double _calculateLaplacianVariance(img.Image image) {
    final width = image.width;
    final height = image.height;
    if (width < 3 || height < 3) return 0;

    double sum = 0;
    double sumSq = 0;
    int n = 0;

    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final center = img.getLuminance(image.getPixel(x, y)).toDouble();
        final top = img.getLuminance(image.getPixel(x, y - 1)).toDouble();
        final bottom = img.getLuminance(image.getPixel(x, y + 1)).toDouble();
        final left = img.getLuminance(image.getPixel(x - 1, y)).toDouble();
        final right = img.getLuminance(image.getPixel(x + 1, y)).toDouble();

        final laplacian = (4 * center) - top - bottom - left - right;
        sum += laplacian;
        sumSq += laplacian * laplacian;
        n++;
      }
    }

    if (n == 0) return 0;
    final mean = sum / n;
    return (sumSq / n) - (mean * mean);
  }

  String _brightnessLabel(double brightness) {
    if (brightness < _CameraScreenState._lightingLow) return 'Low';
    if (brightness > _CameraScreenState._lightingHigh) return 'High';
    return 'OK';
  }

  Color _brightnessColor(double brightness) {
    if (brightness < _CameraScreenState._lightingLow) return Colors.orange;
    if (brightness > _CameraScreenState._lightingHigh) return Colors.red;
    return Colors.green;
  }
}
