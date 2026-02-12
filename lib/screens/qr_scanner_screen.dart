import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/city_chart.dart';
import 'details_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            color: Colors.cyan,
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            color: Colors.cyan,
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _isScanning = false;
                  _processScannedData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Overlay guide
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Scan QR Code',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processScannedData(String data) async {
    // Stop scanning
    await controller.stop();

    // Simulate finding an area from QR data
    final area = _findAreaFromQRData(data);

    if (area != null) {
      // Show success dialog
      _showAreaFoundDialog(area);
    } else {
      // Show error dialog
      _showErrorDialog();
    }
  }

  CityArea? _findAreaFromQRData(String data) {
    // In a real app, you would parse the QR data to find the area
    // For demo, just return a random area
    if (cityAreas.isNotEmpty) {
      return cityAreas[0]; // Return first area for demo
    }
    return null;
  }

  void _showAreaFoundDialog(CityArea area) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.check_circle, color: _getScoreColor(area.stressScore)),
            const SizedBox(width: 10),
            Text('Area Found!', style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              area.name,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getScoreColor(area.stressScore).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Health Status: ${area.healthStatus}',
                    style: TextStyle(color: _getScoreColor(area.stressScore)),
                  ),
                  const SizedBox(height: 4),
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close scanner
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close scanner
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(area: area),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Invalid QR Code', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This QR code does not contain valid city area data.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _isScanning = true;
              controller.start(); // Resume scanning
            },
            child: const Text('Try Again', style: TextStyle(color: Colors.cyan)),
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