import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'barcode_reader_overlay_painter.dart';

class BarcodeReaderPage extends StatefulWidget {
  final bool showBorder;
  final int borderFlashDuration;
  final double viewfinderWidth;
  final double viewfinderHeight;
  final double borderRadius;
  final Color scrimColor;
  final Color borderColor;
  final double borderStrokeWidth;
  final Color buttonColor;
  final String cancelButtonText;
  final bool successBeep;

  BarcodeReaderPage({
    this.showBorder = true,
    this.borderFlashDuration = 500,
    this.viewfinderWidth = 240.0,
    this.viewfinderHeight = 240.0,
    this.borderRadius = 16.0,
    this.scrimColor = Colors.black54,
    this.borderColor = Colors.green,
    this.borderStrokeWidth = 4.0,
    this.buttonColor = Colors.white,
    this.cancelButtonText = "Cancel",
    this.successBeep = true,
  });

  @override
  _BarcodeReaderPageState createState() => _BarcodeReaderPageState();
}

class _BarcodeReaderPageState extends State<BarcodeReaderPage> {
  MobileScannerController _captureController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isBorderVisible = false;
  Timer? _borderFlashTimer;

  @override
  void initState() {
    super.initState();

    if (widget.showBorder) {
      setState(() {
        _isBorderVisible = true;
      });

      if (widget.borderFlashDuration > 0) {
        _borderFlashTimer = Timer.periodic(
            Duration(milliseconds: widget.borderFlashDuration), (timer) {
          setState(() {
            _isBorderVisible = !_isBorderVisible;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _captureController.dispose();
    _borderFlashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildCaptureView(),
          _buildViewfinder(context),
          _buildButtonBar(),
        ],
      ),
    );
  }

  Widget _buildCaptureView() {
    return MobileScanner(
      onDetect: (barcodes) async {
        await _captureController.stop();
        if (widget.successBeep) FlutterBeep.beep();
        Navigator.of(context).pop(barcodes.barcodes.first.rawValue);
      },
      controller: _captureController,
    );
  }

  Widget _buildViewfinder(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: BarcodeReaderOverlayPainter(
        drawBorder: _isBorderVisible,
        viewfinderWidth: widget.viewfinderWidth,
        viewfinderHeight: widget.viewfinderHeight,
        borderRadius: widget.borderRadius,
        scrimColor: widget.scrimColor,
        borderColor: widget.borderColor,
        borderStrokeWidth: widget.borderStrokeWidth,
      ),
    );
  }

  Widget _buildButtonBar() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        color: Colors.black26,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTorchButton(),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTorchButton() {
    return ValueListenableBuilder<MobileScannerState>(
      builder: (context, state, child) {
        switch ((state.torchState)) {
          case TorchState.auto:
            return IconButton(
              color: Colors.white,
              iconSize: 32.0,
              icon: const Icon(Icons.flash_auto),
              onPressed: () async {
                await _captureController.toggleTorch();
              },
            );
          case TorchState.off:
            return IconButton(
              color: Colors.white,
              iconSize: 32.0,
              icon: const Icon(Icons.flash_off),
              onPressed: () async {
                await _captureController.toggleTorch();
              },
            );
          case TorchState.on:
            return IconButton(
              color: Colors.white,
              iconSize: 32.0,
              icon: const Icon(Icons.flash_on),
              onPressed: () async {
                await _captureController.toggleTorch();
              },
            );
          case TorchState.unavailable:
            return const Icon(
              Icons.no_flash,
              color: Colors.grey,
            );
        }
      },
      valueListenable: _captureController,
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      style: TextButton.styleFrom(
        foregroundColor: widget.buttonColor,
      ),
      child: Text(widget.cancelButtonText),
    );
  }
}
