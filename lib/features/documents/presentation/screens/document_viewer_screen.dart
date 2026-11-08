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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ফাইল ডিভাইসে সেভ করা হয়েছে।')),
              );
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

          // Document Viewer Mockup Body
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
                child: Center(
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
                                'ডকুমেন্ট প্রিভিউ সারাংশ:',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Text('• আবেদনকারীর মূল জাতীয় পরিচয়পত্র ও স্বাক্ষর'),
                              const Text('• ওয়ারিশান ও দানপত্র দলিল নম্বর ৪২৮/২০২৬'),
                              const Text('• ভূমি উন্নয়ন কর হালনাগাদ দাখিলা কপি'),
                              const Text('• সার্ভেয়ার রিপোর্ট ও প্রস্তাবনা পত্র'),
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

