import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  final GeminiService _geminiService = GeminiService();
  final VoiceService _voiceService = VoiceService();
  
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusText = "SYSTEM ONLINE";
  String _lastResponse = "";

  @override
  void initState() {
    super.initState();
    _initializeSystems();
  }

  Future<void> _initializeSystems() async {
    try {
      // Init Camera
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first, 
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() => _isCameraInitialized = true);
      }

      // Init Services
      await _geminiService.init();
      await _voiceService.init();

    } catch (e) {
      setState(() => _statusText = "SYSTEM ERROR: $e");
    }
  }

  Future<void> _onListenPressed() async {
    if (_isProcessing) return;

    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      return;
    }

    setState(() {
      _statusText = "LISTENING...";
    });

    await _voiceService.listen(onResult: (text) {
      _processInput(text);
    });
  }

  Future<void> _processInput(String text) async {
    setState(() {
      _statusText = "PROCESSING...";
      _isProcessing = true;
    });

    try {
      // Capture Image
      Uint8List? imageBytes;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        imageBytes = await image.readAsBytes();
      }

      // Send to Gemini
      final response = await _geminiService.chat(text, imageBytes);

      setState(() {
        _lastResponse = response;
        _statusText = "RESPONDING...";
      });

      // Speak Response
      await _voiceService.speak(response);

    } catch (e) {
      setState(() => _statusText = "ERROR: $e");
      await _voiceService.speak("System malfunction.");
    } finally {
      setState(() {
        _isProcessing = false;
        _statusText = "SYSTEM ONLINE";
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Layer
          if (_isCameraInitialized)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),

          // Overlay Layer (Sci-Fi Grid/Vignette effect could go here)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // UI Layer
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FadeInDown(
                        child: const Text(
                          "JARVIS VISION",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.cyanAccent,
                            shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
                          ),
                        ),
                      ),
                      FadeInDown(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.cyanAccent),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "LIVE",
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Response Text
                if (_lastResponse.isNotEmpty)
                  FadeInUp(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        border: Border(
                          left: BorderSide(color: Colors.cyanAccent, width: 2),
                        ),
                      ),
                      child: Text(
                        _lastResponse,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Status Indicator
                FadeInUp(
                  child: Text(
                    _statusText,
                    style: const TextStyle(
                      color: Colors.cyanAccent, 
                      letterSpacing: 3,
                      fontSize: 12
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Interaction Button
                FadeInUp(
                  child: GestureDetector(
                    onTap: _onListenPressed,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _isProcessing 
                                ? Colors.redAccent.withOpacity(0.5) 
                                : Colors.cyanAccent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Icon(
                        _isProcessing ? Icons.hourglass_empty : Icons.mic,
                        color: _isProcessing ? Colors.redAccent : Colors.cyanAccent,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
