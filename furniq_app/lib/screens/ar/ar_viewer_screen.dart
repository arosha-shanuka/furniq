import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class ARViewerScreen extends StatefulWidget {
  final String productId;
  final String arModelUrl;
  final List<String> availableColors;
  final String selectedColor;

  const ARViewerScreen({
    super.key,
    required this.productId,
    required this.arModelUrl,
    required this.availableColors,
    required this.selectedColor,
  });

  @override
  State<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<ARViewerScreen> {
  UnityWidgetController? _unityController;
  bool _isUnityReady = false;
  bool _isModelLoading = true;
  bool _showUnity = false;
  late String _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.selectedColor;
    // Wait for the route transition to complete before mounting Unity
    // This prevents Unity from calculating its viewport size based on a transitioning container
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showUnity = true);
    });
  }

  void _onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;

    Future.delayed(const Duration(milliseconds: 500), () async {
      await _unityController?.pause();
      await Future.delayed(const Duration(milliseconds: 300));
      await _unityController?.resume();
    });
    
    setState(() => _isUnityReady = true);

    // Send the model URL to Unity
    Future.delayed(const Duration(seconds: 2), () {
      _unityController?.postMessage(
        'XR Origin (AR Rig)', // MUST match the exact name in Unity Hierarchy
        'LoadModel',         // Method name on ARModelPlacer script
        widget.arModelUrl,   // The .glb URL from Firebase
      );
      if (_currentColor.isNotEmpty) {
        // Wait for model to load before applying color
        Future.delayed(const Duration(milliseconds: 500), () {
          _unityController?.postMessage(
            'XR Origin (AR Rig)',
            'ChangeColor',
            _currentColor,
          );
        });
      }
      setState(() => _isModelLoading = false);
    });
  }

  void _onUnityMessage(message) {
    debugPrint('Unity says: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // MUST be transparent to see Unity behind Flutter!
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Unity AR View (full screen)
            if (_showUnity)
              Positioned.fill(
                child: UnityWidget(
                  onUnityCreated: _onUnityCreated,
                  onUnityMessage: _onUnityMessage,
                  fullscreen: true, // Force fullscreen on Android
                  useAndroidViewSurface: true,
                ),
              ),

            // Top bar overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          _unityController?.postMessage(
                            'XR Origin (AR Rig)', 'Cleanup', '');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point at a flat surface, then tap to place',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading indicator
            if (_isModelLoading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Loading AR model...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),

            // Color Selector Overlay
            if (!_isModelLoading && widget.availableColors.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Wrap(
                      spacing: 12,
                      children: widget.availableColors.map((hexColor) {
                        final isSelected = _currentColor == hexColor;
                        Color color = Colors.black;
                        try {
                          String hex = hexColor.replaceAll('#', '');
                          if (hex.length == 6) hex = 'FF$hex';
                          color = Color(int.parse(hex, radix: 16));
                        } catch (e) {}

                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentColor = hexColor);
                            _unityController?.postMessage(
                              'XR Origin (AR Rig)',
                              'ChangeColor',
                              hexColor,
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white30,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected 
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                )
                              : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _unityController?.dispose();
    super.dispose();
  }
}
