import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libraryapp/screens/addbook/addbook_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  String scanResult = '';
  bool isScanning = false;
  bool _isProcessing = false;
  
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup scanning animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _playSuccessSound() async {
    try {
      // Play custom beep sound from assets
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
      // Fallback to system sound if asset fails
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _showSuccessAnimation() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    // Play success sound
    await _playSuccessSound();
    
    // Vibrate
    HapticFeedback.mediumImpact();
    
    // Show success overlay briefly
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen scanner view with tap to focus
          GestureDetector(
            onTap: () {
              // Reset zoom to help with focus
              controller.setZoomScale(1.0);
            },
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) async {
                if (_isProcessing) return;
                
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final Barcode barcode = barcodes.first;

                  if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                    await _showSuccessAnimation();

                    if (mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddBookScreen(upc: barcode.rawValue!),
                        ),
                      );
                    }

                    // Reset processing state when returning to scanner
                    if (mounted) {
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                  }
                }
              },
            ),
          ),
          
          // Dark overlay with transparent scanning area
          IgnorePointer(
            child: CustomPaint(
              painter: ScannerOverlayPainter(
                scanAreaWidth: MediaQuery.of(context).size.width * 0.8,
                scanAreaHeight: 150,
              ),
              child: Container(),
            ),
          ),
          
          // Top instruction text
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: const Text(
                'Place an ISBN inside the rectangle to scan it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Back button (top left)
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  controller.dispose();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          
          
          // Scanning animation line
          if (!_isProcessing)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                final screenHeight = MediaQuery.of(context).size.height;
                final screenWidth = MediaQuery.of(context).size.width;
                final frameHeight = 150.0;
                
                // Calculate center position
                final frameCenterY = screenHeight / 2;
                final frameTop = frameCenterY - (frameHeight / 2);
                
                return Positioned(
                  top: frameTop + (_scanAnimation.value * frameHeight),
                  left: screenWidth * 0.1,
                  right: screenWidth * 0.1,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          // Scanning frame
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 2,
                ),
              
              ),
              child: Stack(
                children: [
                 
                ],
              ),
            ),
          ),
          
          // Bottom control bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flash_off, color: Colors.white, size: 28),
                      onPressed: () {
                        controller.toggleTorch();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Success overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.black,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ISBN Detected!',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Loading book details...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
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
}

// Custom painter for the scanner overlay with cutout
class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaWidth;
  final double scanAreaHeight;

  ScannerOverlayPainter({
    required this.scanAreaWidth,
    required this.scanAreaHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Calculate the center position for the scan area
    final left = (size.width - scanAreaWidth) / 2;
    final top = (size.height - scanAreaHeight) / 2;
    final right = left + scanAreaWidth;
    final bottom = top + scanAreaHeight;

    // Create path for the overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTRB(left, top, right, bottom))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
