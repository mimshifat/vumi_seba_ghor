import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';

class DocumentViewerScreen extends StatelessWidget {
  final DemoDocument document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final isPdf = document.type == 'pdf';

    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        title: Text(
          document.name,
          style: AppTypography.headingSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'শেয়ার করুন',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ফাইল শেয়ার করা হচ্ছে...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            tooltip: 'ডাউনলোড',
            onPressed: () async {
              if (document.fileData != null) {
                final savePath = await FilePicker.platform.saveFile(
                  dialogTitle: 'ফাইল ডাউনলোড/সংরক্ষণ করুন',
                  fileName: document.name,
                );
                if (savePath != null) {
                  await File(savePath).writeAsBytes(document.fileData!);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${document.name}" ডিভাইসে সংরক্ষিত হয়েছে।'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ডেমো ফাইলের ডাটা ডাউনলোডযোগ্য নয়।')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // File Meta Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            color: AppColors.slate800,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.image,
                      color: isPdf ? AppColors.rose : AppColors.primaryLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'আকার: ${document.size}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.slate300),
                    ),
                  ],
                ),
                Text(
                  'আপলোড: ${BengaliDigits.toBengali('${document.uploadDate.day}/${document.uploadDate.month}/${document.uploadDate.year}')}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate300),
                ),
              ],
            ),
          ),

          // Document Viewer Body
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: (document.fileData != null && document.type == 'image')
                    ? InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.memory(
                            document.fileData!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: isPdf ? AppColors.roseSurface : AppColors.primarySurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPdf ? Icons.picture_as_pdf : Icons.image,
                                  size: 64,
                                  color: isPdf ? AppColors.rose : AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                document.name,
                                style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                isPdf
                                    ? 'গণপ্রজাতন্ত্রী বাংলাদেশ সরকার\nভূমি মন্ত্রণালয় — ই-নামজারি অনলাইন আবেদন কপি'
                                    : 'জমির দলিল বা পর্চার স্ক্যান কপি',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              if (document.fileData != null) ...[
                                const SizedBox(height: AppSpacing.lg),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.file_download_outlined, size: 18),
                                  label: const Text('ডিভাইসে ডাউনলোড করুন'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () async {
                                    final savePath = await FilePicker.platform.saveFile(
                                      dialogTitle: 'ফাইল সংরক্ষণ করুন',
                                      fileName: document.name,
                                    );
                                    if (savePath != null) {
                                      await File(savePath).writeAsBytes(document.fileData!);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('"${document.name}" সংরক্ষিত হয়েছে।'),
                                          backgroundColor: AppColors.emerald,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.base),
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ডকুমেন্ট বিবরণ:',
                                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text('ফাইলের নাম: ${document.name}'),
                                    Text('ফাইলের ধরন: ${document.type.toUpperCase()}'),
                                    Text('ফাইলের আকার: ${document.size}'),
                                    Text('আপলোডের তারিখ: ${BengaliDigits.toBengali('${document.uploadDate.day}/${document.uploadDate.month}/${document.uploadDate.year}')}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

