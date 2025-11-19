import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;

  CameraController? get controller => _controller;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _initializeController(_cameras![_currentCameraIndex]);
    }
  }

  Future<void> _initializeController(CameraDescription cameraDescription) async {
    final previousController = _controller;
    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await previousController?.dispose();

    if (kIsWeb) {
      // Web specific handling if needed
    }

    try {
      await newController.initialize();
      _controller = newController;
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    await _initializeController(_cameras![_currentCameraIndex]);
  }

  Future<void> startImageStream(Function(CameraImage) onLatestImageAvailable) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.startImageStream(onLatestImageAvailable);
    }
  }

  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}
