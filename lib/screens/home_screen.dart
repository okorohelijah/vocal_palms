import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_service.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = CameraService();
  // WARNING: In a real app, store this securely!
  final GeminiService _geminiService = GeminiService(
    'AIzaSyB6PQY9J4uOgB6lkgkikU878BNgncevZWc',
  );

  bool _isCameraInitialized = false;
  String _translation = "Waiting...";
  bool _isAnalyzing = false;
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _requestPermission();
    await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
      _startAnalysisLoop();
    }
  }

  Future<void> _requestPermission() async {
    await Permission.camera.request();
  }

  void _startAnalysisLoop() {
    // Analyze every 2 seconds
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isCameraInitialized ||
          _isAnalyzing ||
          _cameraService.controller == null)
        return;
      if (_cameraService.controller!.value.isTakingPicture) return;

      setState(() {
        _isAnalyzing = true;
      });

      try {
        // Take a picture
        final XFile image = await _cameraService.controller!.takePicture();
        final imageBytes = await image.readAsBytes();

        // Send to Gemini
        final result = await _geminiService.analyzeImage(imageBytes);

        if (mounted && result != null) {
          setState(() {
            _translation = result;
          });
        }
      } catch (e) {
        print('Analysis Error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraService.controller != null)
            SizedBox.expand(child: CameraPreview(_cameraService.controller!))
          else
            const Center(child: CircularProgressIndicator()),

          // Top Bar with Camera Switch
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vocal Palms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Translation Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 50),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAnalyzing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    _translation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Gemini AI",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (!_isCameraInitialized) return;

    _analysisTimer?.cancel();
    setState(() => _isCameraInitialized = false);

    await _cameraService.switchCamera();

    setState(() => _isCameraInitialized = true);
    _startAnalysisLoop();
  }
}
