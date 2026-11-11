import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../utils/bengali_digits.dart';

/// ফাইল বা ছবি সংযুক্ত করার উৎস
enum AttachmentSource {
  fileManager,
  gallery,
  camera,
}

/// সংযুক্তির জন্য নির্বাচিত বা তোলা ফাইলের তথ্য
class PickedAttachment {
  final String fileName;
  final Uint8List bytes;
  final String fileType; // 'pdf' অথবা 'image'
  final String fileSize;

  const PickedAttachment({
    required this.fileName,
    required this.bytes,
    required this.fileType,
    required this.fileSize,
  });
}

/// প্ল্যাটফর্ম-নির্ভর ফাইল ও ইমেজ পিকার অ্যাবস্ট্রাকশন (টেস্টযোগ্যতার জন্য)
abstract class AttachmentPickerDelegate {
  Future<PickedAttachment?> pickFromFileManager();
  Future<PickedAttachment?> pickFromGallery();
  Future<PickedAttachment?> captureFromCamera();

  Future<List<PickedAttachment>> pickMultipleFromFileManager() async {
    final single = await pickFromFileManager();
    return single != null ? [single] : const [];
  }

  Future<List<PickedAttachment>> pickMultipleFromGallery() async {
    final single = await pickFromGallery();
    return single != null ? [single] : const [];
  }
}

class DefaultAttachmentPickerDelegate implements AttachmentPickerDelegate {
  final ImagePicker _imagePicker;

  DefaultAttachmentPickerDelegate({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<List<PickedAttachment>> pickMultipleFromFileManager() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: kIsWeb,
      dialogTitle: 'আবেদনের PDF বা ছবি নির্বাচন করুন',
    );
    if (result == null || result.files.isEmpty) return const [];

    final attachments = <PickedAttachment>[];
    for (final picked in result.files) {
      if (picked.size > AttachmentPickerSheet.maxAttachmentBytes) {
        continue;
      }

      Uint8List? bytes = picked.bytes;
      if (bytes == null && picked.path != null) {
        final f = File(picked.path!);
        if (await f.exists()) {
          final fileLen = await f.length();
          if (fileLen <= AttachmentPickerSheet.maxAttachmentBytes) {
            bytes = await f.readAsBytes();
          }
        }
      }

      if (bytes == null || bytes.isEmpty) continue;

      final ext = picked.extension?.toLowerCase() ??
          AttachmentPickerSheet.extractExtension(picked.name);
      final fileType = ext == 'pdf' ? 'pdf' : 'image';
      final safeName = AttachmentPickerSheet.sanitizeFileName(
        picked.name,
        fallbackExt: fileType == 'pdf' ? 'pdf' : 'jpg',
      );

      attachments.add(
        PickedAttachment(
          fileName: safeName,
          bytes: bytes,
          fileType: fileType,
          fileSize: AttachmentPickerSheet.formatFileSize(bytes.length),
        ),
      );
    }
    return attachments;
  }

  @override
  Future<List<PickedAttachment>> pickMultipleFromGallery() async {
    final xFiles = await _imagePicker.pickMultiImage(
      maxWidth: AttachmentPickerSheet.maxImageDimension,
      maxHeight: AttachmentPickerSheet.maxImageDimension,
      imageQuality: 82,
    );
    if (xFiles.isEmpty) return const [];

    final attachments = <PickedAttachment>[];
    for (final xFile in xFiles) {
      final fileLen = await xFile.length();
      if (fileLen > AttachmentPickerSheet.maxAttachmentBytes) {
        continue;
      }
      final bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) continue;

      final ext = AttachmentPickerSheet.normalizeImageExtension(
        AttachmentPickerSheet.extractExtension(xFile.name),
      );
      final rawName = xFile.name.trim();
      final safeName = rawName.isEmpty
          ? AttachmentPickerSheet.generateTimestampedName(prefix: 'gallery', ext: ext)
          : AttachmentPickerSheet.sanitizeFileName(rawName, fallbackExt: ext);

      attachments.add(
        PickedAttachment(
          fileName: safeName,
          bytes: bytes,
          fileType: 'image',
          fileSize: AttachmentPickerSheet.formatFileSize(bytes.length),
        ),
      );
    }
    return attachments;
  }

  @override
  Future<PickedAttachment?> pickFromFileManager() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: kIsWeb,
      dialogTitle: 'আবেদনের PDF বা ছবি নির্বাচন করুন',
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    // মেমোরিতে লোড করার আগেই সাইজ চেক করে OOM ও ফ্রিজ প্রতিরোধ করি
    if (picked.size > AttachmentPickerSheet.maxAttachmentBytes) {
      throw const FormatException(
        'ফাইলের আকার ১০ MB-এর বেশি হওয়া যাবে না। অনুগ্রহ করে ছোট ফাইল নির্বাচন করুন।',
      );
    }

    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      final f = File(picked.path!);
      if (!await f.exists()) {
        throw const FormatException('নির্বাচিত ফাইলটি পাওয়া যায়নি।');
      }
      final fileLen = await f.length();
      if (fileLen > AttachmentPickerSheet.maxAttachmentBytes) {
        throw const FormatException(
          'ফাইলের আকার ১০ MB-এর বেশি হওয়া যাবে না। অনুগ্রহ করে ছোট ফাইল নির্বাচন করুন।',
        );
      }
      bytes = await f.readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('ফাইলটি পড়া যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।');
    }
    if (bytes.length > AttachmentPickerSheet.maxAttachmentBytes) {
      throw const FormatException(
        'ফাইলের আকার ১০ MB-এর বেশি হওয়া যাবে না। অনুগ্রহ করে ছোট ফাইল নির্বাচন করুন।',
      );
    }

    final ext = picked.extension?.toLowerCase() ??
        AttachmentPickerSheet.extractExtension(picked.name);
    final fileType = ext == 'pdf' ? 'pdf' : 'image';
    final safeName = AttachmentPickerSheet.sanitizeFileName(
      picked.name,
      fallbackExt: fileType == 'pdf' ? 'pdf' : 'jpg',
    );

    return PickedAttachment(
      fileName: safeName,
      bytes: bytes,
      fileType: fileType,
      fileSize: AttachmentPickerSheet.formatFileSize(bytes.length),
    );
  }

  @override
  Future<PickedAttachment?> pickFromGallery() async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: AttachmentPickerSheet.maxImageDimension,
      maxHeight: AttachmentPickerSheet.maxImageDimension,
      imageQuality: 82,
    );
    if (xFile == null) return null;

    final fileLen = await xFile.length();
    if (fileLen > AttachmentPickerSheet.maxAttachmentBytes) {
      throw const FormatException(
        'ছবির আকার ১০ MB-এর বেশি হওয়া যাবে না। অনুগ্রহ করে ছোট ছবি নির্বাচন করুন।',
      );
    }

    final bytes = await xFile.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('ছবিটি পড়া যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।');
    }
    if (bytes.length > AttachmentPickerSheet.maxAttachmentBytes) {
      throw const FormatException(
        'ছবির আকার ১০ MB-এর বেশি হওয়া যাবে না। অনুগ্রহ করে ছোট ছবি নির্বাচন করুন।',
      );
    }

    final ext = AttachmentPickerSheet.normalizeImageExtension(
      AttachmentPickerSheet.extractExtension(xFile.name),
    );
    final rawName = xFile.name.trim();
    final safeName = rawName.isEmpty
        ? AttachmentPickerSheet.generateTimestampedName(prefix: 'gallery', ext: ext)
        : AttachmentPickerSheet.sanitizeFileName(rawName, fallbackExt: ext);

    return PickedAttachment(
      fileName: safeName,
      bytes: bytes,
      fileType: 'image',
      fileSize: AttachmentPickerSheet.formatFileSize(bytes.length),
    );
  }

  @override
  Future<PickedAttachment?> captureFromCamera() async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: AttachmentPickerSheet.maxImageDimension,
      maxHeight: AttachmentPickerSheet.maxImageDimension,
      imageQuality: 82,
    );
    if (xFile == null) return null;

    final fileLen = await xFile.length();
    if (fileLen > AttachmentPickerSheet.maxAttachmentBytes) {
      throw const FormatException(
        'তোলা ছবির আকার ১০ MB-এর বেশি। অনুগ্রহ করে পুনরায় চেষ্টা করুন।',
      );
    }

    final bytes = await xFile.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('তোলা ছবিটি পড়া যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।');
    }
    if (bytes.length > AttachmentPickerSheet.maxAttachmentBytes) {
      throw const FormatException(
        'তোলা ছবির আকার ১০ MB-এর বেশি। অনুগ্রহ করে পুনরায় চেষ্টা করুন।',
      );
    }

    final ext = AttachmentPickerSheet.normalizeImageExtension(
      AttachmentPickerSheet.extractExtension(xFile.name),
    );
    final fileName = AttachmentPickerSheet.generateTimestampedName(
      prefix: 'camera',
      ext: ext,
    );

    return PickedAttachment(
      fileName: fileName,
      bytes: bytes,
      fileType: 'image',
      fileSize: AttachmentPickerSheet.formatFileSize(bytes.length),
    );
  }
}

enum _CameraPreviewAction {
  attach,
  retake,
  cancel,
}

class _CameraPreviewResult {
  final _CameraPreviewAction action;
  final String fileName;

  const _CameraPreviewResult({
    required this.action,
    required this.fileName,
  });
}

/// ফাইল ম্যানেজার, গ্যালারি অথবা ক্যামেরা থেকে ডকুমেন্ট/ছবি নির্বাচনের শেয়ার্ড হেল্পার
class AttachmentPickerSheet {
  AttachmentPickerSheet._();

  /// সর্বোচ্চ অনুমোদিত ফাইলের আকার (১০ MB) — OOM ও SQLite ব্লোট রোধ করতে
  static const int maxAttachmentBytes = 10 * 1024 * 1024;

  /// ক্যামেরা ও গ্যালারি ছবির সর্বোচ্চ রেজোলিউশন — মেমোরি নিরাপদ রাখতে
  static const double maxImageDimension = 1920.0;

  static String formatFileSize(int bytesLen) {
    if (bytesLen >= 1024 * 1024) {
      return '${(bytesLen / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytesLen <= 0) return '0 KB';
    final kb = math.max(1, (bytesLen / 1024).round());
    return '$kb KB';
  }

  static String extractExtension(String fileName) {
    final dotIdx = fileName.lastIndexOf('.');
    if (dotIdx == -1 || dotIdx == fileName.length - 1) return '';
    return fileName.substring(dotIdx + 1).toLowerCase();
  }

  static String normalizeImageExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
      case 'webp':
      case 'jpeg':
      case 'jpg':
        return ext.toLowerCase();
      default:
        return 'jpg';
    }
  }

  /// ডেটাবেজের ২৫৫ অক্ষরের সীমা ও খালি নামের ঝুঁকি এড়াতে ফাইলের নাম নিরাপদ করে
  static String sanitizeFileName(
    String rawName, {
    String fallbackExt = 'jpg',
    int maxLength = 200,
  }) {
    final cleaned = rawName
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
    if (cleaned.isEmpty) {
      return generateTimestampedName(prefix: 'file', ext: fallbackExt);
    }

    final dotIdx = cleaned.lastIndexOf('.');
    final hasExt = dotIdx > 0 && dotIdx < cleaned.length - 1;
    final base = hasExt ? cleaned.substring(0, dotIdx).trim() : cleaned;
    final ext = hasExt
        ? cleaned.substring(dotIdx + 1).trim().toLowerCase()
        : fallbackExt;

    final safeBase = base.isEmpty ? 'file' : base;
    final suffix = ext.isEmpty ? '' : '.$ext';
    final allowedBaseLen = math.max(1, maxLength - suffix.length);
    final truncatedBase = safeBase.length > allowedBaseLen
        ? safeBase.substring(0, allowedBaseLen)
        : safeBase;
    return '$truncatedBase$suffix';
  }

  static String generateTimestampedName({
    required String prefix,
    String ext = 'jpg',
  }) {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$stamp.$ext';
  }

  /// ফাইল সংযুক্ত করার উৎস নির্বাচনের বটম শিট দেখায়
  static Future<AttachmentSource?> showSourceSheet(
    BuildContext context, {
    bool includeFileManager = true,
    String title = 'ফাইল বা ছবি সংযুক্ত করুন',
    String subtitle = 'কোন মাধ্যম থেকে সংযুক্ত করতে চান তা নির্বাচন করুন',
  }) {
    return showModalBottomSheet<AttachmentSource>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) {
        var popped = false;
        void selectSource(AttachmentSource? source) {
          if (popped) return;
          popped = true;
          Navigator.of(ctx).pop(source);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.md,
              AppSpacing.base,
              AppSpacing.base,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        includeFileManager
                            ? Icons.attach_file_rounded
                            : Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.headingSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                if (includeFileManager) ...[
                  _SourceOptionTile(
                    key: const Key('attachment_source_file_manager'),
                    icon: Icons.folder_open_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primarySurface,
                    title: 'ফাইল ম্যানেজার',
                    subtitle: 'PDF, দলিল বা ডিভাইসের যেকোনো ফাইল',
                    onTap: () => selectSource(AttachmentSource.fileManager),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _SourceOptionTile(
                  key: const Key('attachment_source_gallery'),
                  icon: Icons.photo_library_rounded,
                  iconColor: AppColors.emeraldDark,
                  iconBgColor: AppColors.emeraldSurface,
                  title: 'গ্যালারি',
                  subtitle: 'ফোনের গ্যালারি থেকে ছবি বাছুন',
                  onTap: () => selectSource(AttachmentSource.gallery),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SourceOptionTile(
                  key: const Key('attachment_source_camera'),
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppColors.amberDark,
                  iconBgColor: AppColors.amberSurface,
                  title: 'ক্যামেরা',
                  subtitle: 'সরাসরি ছবি তুলে দেখে সংযুক্ত করুন',
                  onTap: () => selectSource(AttachmentSource.camera),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => selectSource(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.slate700,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'বাতিল',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// শুধু ছবি (গ্যালারি বা ক্যামেরা) নির্বাচনের শর্টকাট
  static Future<PickedAttachment?> pickImage(
    BuildContext context, {
    AttachmentPickerDelegate? delegate,
    String title = 'ছবি নির্বাচন করুন',
    String subtitle = 'গ্যালারি থেকে বাছুন বা ক্যামেরা দিয়ে ছবি তুলুন',
  }) {
    return pick(
      context,
      delegate: delegate,
      includeFileManager: false,
      title: title,
      subtitle: subtitle,
    );
  }

  /// সোর্স বেছে নেওয়া থেকে শুরু করে (ক্যামেরা হলে প্রিভিউসহ) চূড়ান্ত ফাইল রিটার্ন করে
  static Future<PickedAttachment?> pick(
    BuildContext context, {
    AttachmentPickerDelegate? delegate,
    bool includeFileManager = true,
    String title = 'ফাইল বা ছবি সংযুক্ত করুন',
    String subtitle = 'কোন মাধ্যম থেকে সংযুক্ত করতে চান তা নির্বাচন করুন',
  }) async {
    try {
      final pickerDelegate = delegate ?? DefaultAttachmentPickerDelegate();
      final source = await showSourceSheet(
        context,
        includeFileManager: includeFileManager,
        title: title,
        subtitle: subtitle,
      );
      if (source == null || !context.mounted) return null;

      switch (source) {
        case AttachmentSource.fileManager:
          final file = await pickerDelegate.pickFromFileManager();
          return _validatePickedAttachment(file);

        case AttachmentSource.gallery:
          final image = await pickerDelegate.pickFromGallery();
          return _validatePickedAttachment(image);

        case AttachmentSource.camera:
          while (context.mounted) {
            final captured = _validatePickedAttachment(
              await pickerDelegate.captureFromCamera(),
            );
            if (captured == null || !context.mounted) return null;

            final previewResult = await _showCameraPhotoPreview(
              context,
              attachment: captured,
            );
            if (previewResult == null ||
                previewResult.action == _CameraPreviewAction.cancel) {
              return null;
            }
            if (previewResult.action == _CameraPreviewAction.retake) {
              continue;
            }
            return PickedAttachment(
              fileName: sanitizeFileName(
                previewResult.fileName,
                fallbackExt: normalizeImageExtension(
                  extractExtension(captured.fileName),
                ),
              ),
              bytes: captured.bytes,
              fileType: 'image',
              fileSize: captured.fileSize,
            );
          }
          return null;
      }
    } on PlatformException catch (e) {
      if (!context.mounted) return null;
      final code = e.code.toLowerCase();
      String message;
      if (code.contains('already_active')) {
        message =
            'ফাইল বা ক্যামেরা পিকার ইতিমধ্যেই চালু আছে। অনুগ্রহ করে একটু অপেক্ষা করুন।';
      } else if (code.contains('camera')) {
        message =
            'ক্যামেরা ব্যবহারের অনুমতি পাওয়া যায়নি। অনুগ্রহ করে সেটিংস থেকে অনুমতি দিন।';
      } else if (code.contains('photo') || code.contains('storage')) {
        message =
            'গ্যালারি ব্যবহারের অনুমতি পাওয়া যায়নি। অনুগ্রহ করে সেটিংস থেকে অনুমতি দিন।';
      } else {
        message = 'ফাইল বা ছবি নির্বাচন করা যায়নি: ${e.message ?? e.code}';
      }
      _showError(context, message);
      return null;
    } on FormatException catch (e) {
      if (!context.mounted) return null;
      _showError(context, e.message);
      return null;
    } on FileSystemException {
      if (!context.mounted) return null;
      _showError(context, 'ফাইলটি পড়া যায়নি। ডিভাইস স্টোরেজ পরীক্ষা করে আবার চেষ্টা করুন।');
      return null;
    } catch (e) {
      if (!context.mounted) return null;
      _showError(context, 'ফাইল বা ছবি নির্বাচন করা যায়নি: $e');
      return null;
    }
  }

  /// এক বা একাধিক ফাইল/ছবি একসাথে নির্বাচনের মেথড
  static Future<List<PickedAttachment>> pickMultiple(
    BuildContext context, {
    AttachmentPickerDelegate? delegate,
    bool includeFileManager = true,
    String title = 'ফাইল বা ছবি সংযুক্ত করুন',
    String subtitle = 'এক বা একাধিক ফাইল নির্বাচন করতে পারেন',
  }) async {
    try {
      final pickerDelegate = delegate ?? DefaultAttachmentPickerDelegate();
      final source = await showSourceSheet(
        context,
        includeFileManager: includeFileManager,
        title: title,
        subtitle: subtitle,
      );
      if (source == null || !context.mounted) return const [];

      switch (source) {
        case AttachmentSource.fileManager:
          final files = await pickerDelegate.pickMultipleFromFileManager();
          return files
              .map((f) => _validatePickedAttachment(f))
              .whereType<PickedAttachment>()
              .toList();

        case AttachmentSource.gallery:
          final images = await pickerDelegate.pickMultipleFromGallery();
          return images
              .map((img) => _validatePickedAttachment(img))
              .whereType<PickedAttachment>()
              .toList();

        case AttachmentSource.camera:
          final single = await pick(
            context,
            delegate: pickerDelegate,
            includeFileManager: includeFileManager,
            title: title,
            subtitle: subtitle,
          );
          return single != null ? [single] : const [];
      }
    } on PlatformException catch (e) {
      if (!context.mounted) return const [];
      final code = e.code.toLowerCase();
      String message;
      if (code.contains('already_active')) {
        message =
            'ফাইল বা ক্যামেরা পিকার ইতিমধ্যেই চালু আছে। অনুগ্রহ করে একটু অপেক্ষা করুন।';
      } else if (code.contains('camera')) {
        message =
            'ক্যামেরা ব্যবহারের অনুমতি পাওয়া যায়নি। অনুগ্রহ করে সেটিংস থেকে অনুমতি দিন।';
      } else if (code.contains('photo') || code.contains('storage')) {
        message =
            'গ্যালারি ব্যবহারের অনুমতি পাওয়া যায়নি। অনুগ্রহ করে সেটিংস থেকে অনুমতি দিন।';
      } else {
        message = 'ফাইল বা ছবি নির্বাচন করা যায়নি: ${e.message ?? e.code}';
      }
      _showError(context, message);
      return const [];
    } on FormatException catch (e) {
      if (!context.mounted) return const [];
      _showError(context, e.message);
      return const [];
    } on FileSystemException {
      if (!context.mounted) return const [];
      _showError(context, 'ফাইলটি পড়া যায়নি। ডিভাইস স্টোরেজ পরীক্ষা করে আবার চেষ্টা করুন।');
      return const [];
    } catch (e) {
      if (!context.mounted) return const [];
      _showError(context, 'ফাইল বা ছবি নির্বাচন করা যায়নি: $e');
      return const [];
    }
  }

  static PickedAttachment? _validatePickedAttachment(PickedAttachment? item) {
    if (item == null) return null;
    if (item.bytes.isEmpty) {
      throw const FormatException('ফাইলটি খালি বা পড়া যায়নি।');
    }
    if (item.bytes.length > maxAttachmentBytes) {
      throw const FormatException(
        'ফাইলের আকার ১০ MB-এর বেশি হওয়া যাবে না। অনুগ্রহ করে ছোট ফাইল বা ছবি দিন।',
      );
    }
    final fallbackExt = item.fileType == 'pdf' ? 'pdf' : 'jpg';
    return PickedAttachment(
      fileName: sanitizeFileName(item.fileName, fallbackExt: fallbackExt),
      bytes: item.bytes,
      fileType: item.fileType,
      fileSize: item.fileSize,
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.rose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ক্যামেরা দিয়ে তোলা ছবির প্রিভিউ ডায়ালগ দেখায় (দেখে সংযুক্ত বা আবার তোলার সুযোগসহ)
  static Future<_CameraPreviewResult?> _showCameraPhotoPreview(
    BuildContext context, {
    required PickedAttachment attachment,
  }) {
    return showDialog<_CameraPreviewResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CameraPhotoPreviewDialog(attachment: attachment),
    );
  }

  /// ইতোমধ্যে সংযুক্ত করা ছবির পূর্ণ স্ক্রিন/ডায়ালগ প্রিভিউ দেখায়
  static Future<void> showImagePreviewDialog(
    BuildContext context, {
    required Uint8List bytes,
    required String title,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.slate900,
        insetPadding: const EdgeInsets.all(AppSpacing.base),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.65,
                ),
                width: double.infinity,
                color: Colors.black,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      cacheWidth: 1920,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOptionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.slate50,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.slate400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraPhotoPreviewDialog extends StatefulWidget {
  final PickedAttachment attachment;

  const _CameraPhotoPreviewDialog({required this.attachment});

  @override
  State<_CameraPhotoPreviewDialog> createState() =>
      _CameraPhotoPreviewDialogState();
}

class _CameraPhotoPreviewDialogState extends State<_CameraPhotoPreviewDialog> {
  late final TextEditingController _nameController;
  late final String _extension;
  bool _actionHandled = false;

  @override
  void initState() {
    super.initState();
    final fullName = widget.attachment.fileName;
    final dotIdx = fullName.lastIndexOf('.');
    if (dotIdx > 0 && dotIdx < fullName.length - 1) {
      _extension = fullName.substring(dotIdx + 1);
      _nameController = TextEditingController(text: fullName.substring(0, dotIdx));
    } else {
      _extension = 'jpg';
      _nameController = TextEditingController(text: fullName);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _resolvedFileName() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return widget.attachment.fileName;
    final candidate =
        trimmed.toLowerCase().endsWith('.$_extension') ? trimmed : '$trimmed.$_extension';
    return AttachmentPickerSheet.sanitizeFileName(
      candidate,
      fallbackExt: _extension,
    );
  }

  void _complete(_CameraPreviewAction action) {
    if (_actionHandled) return;
    _actionHandled = true;
    Navigator.of(context).pop(
      _CameraPreviewResult(
        action: action,
        fileName: action == _CameraPreviewAction.cancel
            ? widget.attachment.fileName
            : _resolvedFileName(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxImgHeight =
        (MediaQuery.sizeOf(context).height * 0.40).clamp(160.0, 320.0);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.amberSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.amberDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'তোলা ছবি প্রিভিউ',
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'আকার: ${BengaliDigits.toBengali(widget.attachment.fileSize)} • জুম করে দেখতে পারেন',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.slate500),
                    tooltip: 'বাতিল',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _complete(_CameraPreviewAction.cancel),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Image Preview Frame
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: double.infinity,
                  height: maxImgHeight,
                  decoration: BoxDecoration(
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.memory(
                        widget.attachment.bytes,
                        fit: BoxFit.contain,
                        cacheWidth: 1920,
                        errorBuilder: (_, __, ___) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: Colors.white54,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ছবি প্রিভিউ',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Optional File Name Edit
              Text(
                'ফাইলের নাম',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                maxLength: 180,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  suffixText: '.$_extension',
                  suffixStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('camera_preview_retake'),
                      onPressed: () => _complete(_CameraPreviewAction.retake),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('আবার তুলুন'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate700,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('camera_preview_attach'),
                      onPressed: () => _complete(_CameraPreviewAction.attach),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('সংযুক্ত করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
