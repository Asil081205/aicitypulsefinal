import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/city_chart.dart';
import 'details_screen.dart';

class MobileScannerScreen extends StatefulWidget {
  const MobileScannerScreen({super.key});

  @override
  State<MobileScannerScreen> createState() => _MobileScannerScreenState();
}

class _MobileScannerScreenState extends State<MobileScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _startScanner();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _startScanner() async {
    try {
      await controller.start();
    } catch (e) {
      print('Error starting scanner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Torch button
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.cyan,
            ),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              controller.toggleTorch();
            },
          ),
          // Switch camera button
          IconButton(
            icon: const Icon(Icons.switch_camera, color: Colors.cyan),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner View
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _isScanning = false;
                  _processScannedData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanning overlay
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyan, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Place QR code inside the frame',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Scanning...',
                        style: TextStyle(color: Colors.cyan),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processScannedData(String data) async {
    // Stop scanning
    await controller.stop();

    // Simulate finding an area from QR data
    // In a real app, you would parse the QR data to find the specific area
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Try to find area by name or ID in QR data
    final area = _findAreaFromQRData(data);

    if (area != null) {
      _showAreaFoundDialog(area);
    } else {
      _showErrorDialog();
    }
  }

  CityArea? _findAreaFromQRData(String data) {
    // Try to match QR data with area names or IDs
    final lowerData = data.toLowerCase();

    // Check if QR data matches any area name
    for (final area in cityAreas) {
      if (lowerData.contains(area.name.toLowerCase()) ||
          lowerData.contains(area.id.toLowerCase())) {
        return area;
      }
    }

    // If no match found, return a random area for demo
    if (cityAreas.isNotEmpty) {
      return cityAreas[0]; // Default to first area
    }

    return null;
  }

  void _showAreaFoundDialog(CityArea area) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: _getScoreColor(area.stressScore),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'QR Code Scanned!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getScoreColor(area.stressScore).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getScoreColor(area.stressScore).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    area.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(area.stressScore),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      area.healthStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stress Score: ${area.stressScore.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close scanner
            },
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close scanner
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(area: area),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getScoreColor(area.stressScore),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Invalid QR Code', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This QR code does not contain valid city area data.\n\nPlease scan a valid QR code from supported city areas.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              setState(() {
                _isScanning = true; // Resume scanning
              });
              controller.start(); // Restart scanner
            },
            child: const Text('Try Again', style: TextStyle(color: Colors.cyan)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close scanner
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score < 30) return const Color(0xFF00B894);
    if (score < 45) return const Color(0xFF00CEC9);
    if (score < 60) return const Color(0xFFFDCB6E);
    if (score < 75) return const Color(0xFFE17055);
    return const Color(0xFFD63031);
  }
}