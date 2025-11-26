// lib/screens/security/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  // --- ORIGINAL STATE VARIABLES - UNCHANGED ---
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // --- ORIGINAL INITIALIZATION - UNCHANGED ---
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // The animation will go back and forth
  }

  @override
  Widget build(BuildContext context) {
    // --- MODIFIED: Made the scan window larger ---
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 300, // Increased from 250
      height: 300, // Increased from 250
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            // --- YOUR ORIGINAL SCANNING LOGIC - UNCHANGED ---
            onDetect: (capture) async {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() => _isProcessing = true);
                  controller.stop();
                  final doc = await FirebaseFirestore.instance.collection('outpass_requests').doc(code).get();
                  if (doc.exists) {
                    if (mounted) Navigator.of(context).pop(code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid QR code!')),
                    );
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        controller.start();
                        setState(() => _isProcessing = false);
                      }
                    });
                  }
                }
              }
            },
          ),
          
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow),
          ),
          
          // --- REMOVED: The "Tap to scan" text widget is gone ---

          // --- ADDED: Animated scanning line ---
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Positioned(
                top: scanWindow.top + (scanWindow.height * _animationController.value),
                left: scanWindow.left,
                child: Container(
                  width: scanWindow.width,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xffb2ff59),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffb2ff59).withOpacity(0.7),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3)
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // --- ORIGINAL DISPOSE LOGIC - UNCHANGED ---
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  ScannerOverlayPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xff1a237e), Color(0xff3f51b5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)));

    canvas.drawPath(Path.combine(PathOperation.difference, backgroundPath, cutoutPath), backgroundPaint);

    final starPaint = Paint()..color = Colors.white.withOpacity(0.8);
    for (int i = 0; i < 60; i++) {
      var seed = i * i * 31;
      canvas.drawCircle(
        Offset(
          (seed % size.width.toInt()).toDouble(),
          (seed * 0.37 % size.height.toInt()).toDouble(),
        ),
        1.0 + (i % 2),
        starPaint,
      );
    }
    
    final borderPaint = Paint()
      ..color = const Color(0xffb2ff59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const cornerLength = 35.0;
    const cornerRadius = Radius.circular(15.0);

    final path = Path()
      ..moveTo(scanWindow.left, scanWindow.top + cornerLength)
      ..arcToPoint(Offset(scanWindow.left + cornerLength, scanWindow.top), radius: cornerRadius)
      ..moveTo(scanWindow.right - cornerLength, scanWindow.top)
      ..arcToPoint(Offset(scanWindow.right, scanWindow.top + cornerLength), radius: cornerRadius)
      ..moveTo(scanWindow.right, scanWindow.bottom - cornerLength)
      ..arcToPoint(Offset(scanWindow.right - cornerLength, scanWindow.bottom), radius: cornerRadius)
      ..moveTo(scanWindow.left + cornerLength, scanWindow.bottom)
      ..arcToPoint(Offset(scanWindow.left, scanWindow.bottom - cornerLength), radius: cornerRadius);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}