import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isInitialized = false;

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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final XFile picture = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      
      final faces = await _faceDetector.processImage(inputImage);
      
      if (!mounted) return;

      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wajah tidak terdeteksi! Posisikan wajah di dalam frame.")),
        );
      } else if (faces.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terdeteksi lebih dari 1 wajah! Pastikan hanya Anda di dalam frame.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wajah terverifikasi!")),
        );
        Navigator.pop(context, true); // Return true indicating success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
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
          Builder(builder: (context) {
            final size = MediaQuery.of(context).size;
            var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
            if (scale < 1) scale = 1 / scale;
            return Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(_cameraController!),
              ),
            );
          }),
          
          // Overlay mask
          CustomPaint(
            painter: _OverlayPainter(),
          ),
          
          // UI Elements
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
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
