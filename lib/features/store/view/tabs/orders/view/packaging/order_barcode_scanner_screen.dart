import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Barcode Scanner screen matching Android OrderBarcodeScannerActivity & activity_barcode_order.xml
class OrderBarcodeScannerScreen extends StatefulWidget {
  const OrderBarcodeScannerScreen({super.key});

  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const OrderBarcodeScannerScreen(),
      ),
    );
  }

  @override
  State<OrderBarcodeScannerScreen> createState() =>
      _OrderBarcodeScannerScreenState();
}

class _OrderBarcodeScannerScreenState extends State<OrderBarcodeScannerScreen>
    with WidgetsBindingObserver {
  final TextEditingController _codeController = TextEditingController();
  late final MobileScannerController _scannerController;
  bool _hasScanned = false;
  bool _isStopping = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: true,
    );
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted && mounted) {
          setState(() => _permissionDenied = true);
        }
      }
    } catch (_) {
      // Ignore if permission_handler encounters platform differences
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        if (!_hasScanned && !_isStopping) {
          _scannerController.start();
        }
        break;
      case AppLifecycleState.inactive:
        _scannerController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_hasScanned || _isStopping) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _hasScanned = true;
        _isStopping = true;
        try {
          await _scannerController.stop();
        } catch (_) {}
        if (mounted) {
          Navigator.of(context).pop(code);
        }
        break;
      }
    }
  }

  Future<void> _handleManualSearch() async {
    final text = _codeController.text.trim();
    if (text.length >= 8) {
      if (_hasScanned || _isStopping) return;
      _hasScanned = true;
      _isStopping = true;
      try {
        await _scannerController.stop();
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pop(text);
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alert'),
          content: const Text('Please enter UPC/EAN/SKU of product'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleClose() async {
    if (_isStopping) return;
    _isStopping = true;
    try {
      await _scannerController.stop();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: AppBar(
            backgroundColor: const Color(0xFFF3F3F3),
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'Scan Product',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: _handleClose,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFF2727),
          mini: false,
          onPressed: _handleClose,
          child: const Icon(Icons.close, color: Colors.white),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Top Banner: Scan Product Barcode Here.
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 28,
                        color: Color(0xFF0288D1),
                      ),
                      SizedBox(width: 14),
                      Text(
                        'Scan Product Barcode Here.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Camera Scanner View (matching zxing_barcode_scanner height ~30%)
                Container(
                  height: size.height * 0.32,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _permissionDenied
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Camera permission is required to scan barcodes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => openAppSettings(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0288D1),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: const Text(
                                    'Grant Permission',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _onBarcodeDetected,
                              errorBuilder: (context, error, child) {
                                return Container(
                                  color: Colors.black,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.videocam_off,
                                        color: Colors.white70,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        error.errorCode ==
                                                MobileScannerErrorCode
                                                    .permissionDenied
                                            ? 'Camera permission denied.\nPlease allow camera access in device settings.'
                                            : 'Camera error: ${error.errorDetails?.message ?? error.errorCode.name}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Aiming reticle overlay
                            Container(
                              width: 220,
                              height: 140,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF0288D1)
                                      .withValues(alpha: 0.8),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),

                // OR divider
                const Text(
                  '------------ OR ------------',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Manual Entry Label
                const Text(
                  'Enter UPC / EAN / SKU Code Manually',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),

                // Manual Input Field + Search Button
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBDBDBD)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleManualSearch(),
                          decoration: const InputDecoration(
                            hintText: 'Enter UPC/EAN/SKU Number',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _handleManualSearch,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.all(3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0288D1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
