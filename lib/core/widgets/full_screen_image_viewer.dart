import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// পূর্ণ স্ক্রিন জুমযোগ্য ছবি প্রদর্শন স্ক্রিন
class FullScreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;
  final String? subtitle;

  const FullScreenImageViewer({
    super.key,
    required this.imageBytes,
    required this.title,
    this.subtitle,
  });

  /// পূর্ণ স্ক্রিন ভিউয়ার খোলার স্ট্যাটিক হেল্পার মেথড
  static Future<void> open(
    BuildContext context, {
    required Uint8List imageBytes,
    required String title,
    String? subtitle,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        pageBuilder: (context, _, __) => FullScreenImageViewer(
          imageBytes: imageBytes,
          title: title,
          subtitle: subtitle,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      // ignore: deprecated_member_use
      final zoomed = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        // ignore: deprecated_member_use
        ..scale(2.5);
      _transformationController.value = zoomed;
    }
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          tooltip: 'বন্ধ করুন',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
              Text(
                widget.subtitle!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70),
            tooltip: 'জুম রিসেট করুন',
            onPressed: _resetZoom,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: _handleDoubleTap,
          child: Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                  cacheWidth: 2560,
                  errorBuilder: (context, error, stackTrace) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ছবিটি প্রদর্শন করা যাচ্ছে না',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black.withValues(alpha: 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pinch_rounded, color: Colors.white60, size: 16),
            const SizedBox(width: 8),
            Text(
              'জুম করতে দুটি আঙুল দিয়ে টানুন বা ডাবল ট্যাপ করুন',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
