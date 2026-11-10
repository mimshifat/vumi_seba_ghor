import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';

/// তৈরি করা বকেয়া তালিকা PDF প্রিভিউ, প্রিন্ট ও শেয়ার করার স্ক্রিন।
class DuePdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String pdfFileName;

  const DuePdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.pdfFileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('বকেয়া তালিকা PDF প্রিভিউ'),
      ),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        pdfFileName: pdfFileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}

