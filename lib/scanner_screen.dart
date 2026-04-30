import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'open_food_facts_service.dart';
import 'groq_service.dart';
import 'nutrition_data.dart';
import 'review_screen.dart';
import 'key_details_screen.dart';

enum ScanMode { barcode, label }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

// Added AutomaticKeepAliveClientMixin so the camera doesn't turn off when swiping tabs
class _ScannerScreenState extends State<ScannerScreen> with AutomaticKeepAliveClientMixin {
  final MobileScannerController cameraController = MobileScannerController();
  final GlobalKey _cameraKey = GlobalKey(); 
  bool _isProcessing = false;
  ScanMode _currentMode = ScanMode.barcode;

  @override
  bool get wantKeepAlive => true; 

  Future<void> _handleDataRouting(NutritionData data) async {
    cameraController.stop();

    final bool? userClickedSave = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(nutritionData: data),
      ),
    );

    if (userClickedSave == true && data.keyDetails != null && data.keyDetails!.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KeyDetailsScreen(keyDetails: data.keyDetails!),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      cameraController.start();
    }
  }

  Future<void> _processBarcode(String barcode) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });
    cameraController.stop();

    NutritionData? data = await OpenFoodFactsService.fetchNutritionByBarcode(barcode);

    if (data != null) {
      final keyDetails = await GroqService.fetchKeyDetails(data);
      data.keyDetails = keyDetails;
      await _handleDataRouting(data);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found. Switch to LABEL mode and snap a photo.')),
        );
        setState(() { _isProcessing = false; });
        cameraController.start();
      }
    }
  }

  Future<void> _snapLabel() async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });

    try {
      RenderRepaintBoundary boundary = _cameraKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.5); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      cameraController.stop();

      NutritionData data = await GroqService.parseLabelFromBytes(pngBytes);
      await _handleDataRouting(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture label. Please try again.')),
        );
        setState(() { _isProcessing = false; });
        cameraController.start();
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RepaintBoundary(
            key: _cameraKey,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                if (_currentMode != ScanMode.barcode || _isProcessing) return;
                
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processBarcode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _currentMode == ScanMode.barcode
                  ? Container(
                      key: const ValueKey('barcode_box'),
                      width: 250,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty_box')),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 20),
                      const Text("Analyzing...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: _currentMode == ScanMode.label
                          ? Padding(
                              key: const ValueKey('shutter_button'),
                              padding: const EdgeInsets.only(bottom: 32.0),
                              child: GestureDetector(
                                onTap: _isProcessing ? null : _snapLabel,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    color: Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty_shutter')),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeToggle(ScanMode.barcode, "BARCODE"),
                          _buildModeToggle(ScanMode.label, "LABEL"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ScanMode mode, String label) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        if (!_isProcessing) {
          setState(() => _currentMode = mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black87 : Colors.white70,
          ),
        ),
      ),
    );
  }
}