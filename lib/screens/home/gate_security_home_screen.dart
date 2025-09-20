import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'outpass_details_screen.dart';
import 'package:accomy/screens/login_screen.dart';

class GateSecurityHomeScreen extends StatefulWidget {
  const GateSecurityHomeScreen({super.key});

  @override
  State<GateSecurityHomeScreen> createState() => _GateSecurityHomeScreenState();
}

class _GateSecurityHomeScreenState extends State<GateSecurityHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Security Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const QRViewExample(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('outpass_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending outpass requests.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['reason'] ?? 'No Reason'),
                subtitle: Text(data['destination'] ?? 'No Destination'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => OutpassDetailsScreen(outpassId: doc.id),
                  ));
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (capture) async {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() {
                    _isProcessing = true;
                  });

                  controller.stop();

                  final doc = await FirebaseFirestore.instance
                      .collection('outpass_requests')
                      .doc(code)
                      .get();

                  if (mounted) {
                    if (doc.exists) {
                      Navigator.of(context).pop(); // Pop the scanner screen
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            OutpassDetailsScreen(outpassId: code),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid QR code!')),
                      );
                      // Resume scanning after a delay
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          controller.start();
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                      });
                    }
                  }
                }
              }
            },
          ),
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow),
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Positioned(
                top: scanWindow.top +
                    (scanWindow.height * _animationController.value),
                left: scanWindow.left,
                child: Container(
                  width: scanWindow.width,
                  height: 2,
                  color: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
    final backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRect(scanWindow);
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);

    final backgroundPathDiff = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(backgroundPathDiff, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(Offset(scanWindow.left, scanWindow.top), Offset(scanWindow.left + cornerLength, scanWindow.top), borderPaint);
    canvas.drawLine(Offset(scanWindow.left, scanWindow.top), Offset(scanWindow.left, scanWindow.top + cornerLength), borderPaint);

    // Top-right corner
    canvas.drawLine(Offset(scanWindow.right, scanWindow.top), Offset(scanWindow.right - cornerLength, scanWindow.top), borderPaint);
    canvas.drawLine(Offset(scanWindow.right, scanWindow.top), Offset(scanWindow.right, scanWindow.top + cornerLength), borderPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(scanWindow.left, scanWindow.bottom), Offset(scanWindow.left + cornerLength, scanWindow.bottom), borderPaint);
    canvas.drawLine(Offset(scanWindow.left, scanWindow.bottom), Offset(scanWindow.left, scanWindow.bottom - cornerLength), borderPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(scanWindow.right, scanWindow.bottom), Offset(scanWindow.right - cornerLength, scanWindow.bottom), borderPaint);
    canvas.drawLine(Offset(scanWindow.right, scanWindow.bottom), Offset(scanWindow.right, scanWindow.bottom - cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
