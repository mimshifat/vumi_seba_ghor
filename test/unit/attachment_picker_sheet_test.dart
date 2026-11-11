import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/demo/demo_data.dart';
import 'package:bhumi_kajer_hisab/core/theme/app_theme.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';
import 'package:bhumi_kajer_hisab/core/widgets/attachment_picker_sheet.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/providers/application_providers.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/screens/application_detail_screen.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/providers/finance_providers.dart';
import 'package:bhumi_kajer_hisab/features/references/presentation/providers/reference_providers.dart';
import 'package:bhumi_kajer_hisab/features/references/presentation/screens/reference_list_screen.dart';
import 'package:bhumi_kajer_hisab/features/references/presentation/widgets/reference_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG bytes for clean Image.memory rendering in widget tests
final Uint8List _validPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _FakeAttachmentPickerDelegate implements AttachmentPickerDelegate {
  final PickedAttachment? fileManagerResult;
  final PickedAttachment? galleryResult;
  final List<PickedAttachment?> cameraResults;
  final List<PickedAttachment>? multipleFileManagerResults;
  final List<PickedAttachment>? multipleGalleryResults;
  int cameraCallCount = 0;

  _FakeAttachmentPickerDelegate({
    this.fileManagerResult,
    this.galleryResult,
    this.cameraResults = const [],
    this.multipleFileManagerResults,
    this.multipleGalleryResults,
  });

  @override
  Future<PickedAttachment?> pickFromFileManager() async => fileManagerResult;

  @override
  Future<PickedAttachment?> pickFromGallery() async => galleryResult;

  @override
  Future<List<PickedAttachment>> pickMultipleFromFileManager() async =>
      multipleFileManagerResults ??
      (fileManagerResult != null ? [fileManagerResult!] : const []);

  @override
  Future<List<PickedAttachment>> pickMultipleFromGallery() async =>
      multipleGalleryResults ??
      (galleryResult != null ? [galleryResult!] : const []);

  @override
  Future<PickedAttachment?> captureFromCamera() async {
    final idx = cameraCallCount;
    cameraCallCount++;
    if (idx < cameraResults.length) {
      return cameraResults[idx];
    }
    return null;
  }
}

void main() {
  group('AttachmentPickerSheet helpers', () {
    test('formatFileSize formats KB and MB cleanly', () {
      expect(AttachmentPickerSheet.formatFileSize(0), '0 KB');
      expect(AttachmentPickerSheet.formatFileSize(512), '1 KB');
      expect(AttachmentPickerSheet.formatFileSize(2048), '2 KB');
      expect(AttachmentPickerSheet.formatFileSize(1024 * 1024 * 2), '2.0 MB');
    });

    test('extractExtension and normalizeImageExtension handle various filenames', () {
      expect(AttachmentPickerSheet.extractExtension('dalil.PDF'), 'pdf');
      expect(AttachmentPickerSheet.extractExtension('noext'), '');
      expect(AttachmentPickerSheet.normalizeImageExtension('png'), 'png');
      expect(AttachmentPickerSheet.normalizeImageExtension('unknown'), 'jpg');
    });

    test('sanitizeFileName clamps long names under SQLite limit and preserves extension', () {
      final longName = '${'a' * 300}.pdf';
      final sanitized = AttachmentPickerSheet.sanitizeFileName(longName);
      expect(sanitized.length <= 200, isTrue);
      expect(sanitized.endsWith('.pdf'), isTrue);

      final emptySanitized = AttachmentPickerSheet.sanitizeFileName('   \n\t  ', fallbackExt: 'jpg');
      expect(emptySanitized.endsWith('.jpg'), isTrue);
      expect(emptySanitized.isNotEmpty, isTrue);
    });
  });

  group('AttachmentPickerSheet widget flows', () {
    testWidgets('pickMultiple selecting FileManager returns multiple attachments', (tester) async {
      final delegate = _FakeAttachmentPickerDelegate(
        multipleFileManagerResults: [
          PickedAttachment(
            fileName: 'doc1.pdf',
            bytes: Uint8List.fromList([1, 2, 3, 4]),
            fileType: 'pdf',
            fileSize: '1 KB',
          ),
          PickedAttachment(
            fileName: 'doc2.pdf',
            bytes: Uint8List.fromList([5, 6, 7, 8]),
            fileType: 'pdf',
            fileSize: '1 KB',
          ),
        ],
      );

      List<PickedAttachment> picked = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pickMultiple(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Attach Multiple'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach Multiple'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('attachment_source_file_manager')));
      await tester.pumpAndSettle();

      expect(picked.length, 2);
      expect(picked[0].fileName, 'doc1.pdf');
      expect(picked[1].fileName, 'doc2.pdf');
    });

    testWidgets('pickMultiple selecting Gallery returns multiple attachments', (tester) async {
      final delegate = _FakeAttachmentPickerDelegate(
        multipleGalleryResults: [
          PickedAttachment(
            fileName: 'photo1.jpg',
            bytes: Uint8List.fromList([1, 2, 3]),
            fileType: 'image',
            fileSize: '1 KB',
          ),
          PickedAttachment(
            fileName: 'photo2.jpg',
            bytes: Uint8List.fromList([4, 5, 6]),
            fileType: 'image',
            fileSize: '1 KB',
          ),
        ],
      );

      List<PickedAttachment> picked = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pickMultiple(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Attach Photos'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach Photos'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('attachment_source_gallery')));
      await tester.pumpAndSettle();

      expect(picked.length, 2);
      expect(picked[0].fileName, 'photo1.jpg');
      expect(picked[1].fileName, 'photo2.jpg');
    });

    testWidgets('shows File Manager, Gallery, and Camera options and returns File Manager choice',
        (tester) async {
      final delegate = _FakeAttachmentPickerDelegate(
        fileManagerResult: PickedAttachment(
          fileName: 'namjari.pdf',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          fileType: 'pdf',
          fileSize: '1 KB',
        ),
      );

      PickedAttachment? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pick(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Attach'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();

      expect(find.text('ফাইল ম্যানেজার'), findsOneWidget);
      expect(find.text('গ্যালারি'), findsOneWidget);
      expect(find.text('ক্যামেরা'), findsOneWidget);

      await tester.tap(find.byKey(const Key('attachment_source_file_manager')));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.fileName, 'namjari.pdf');
      expect(picked!.fileType, 'pdf');
    });

    testWidgets('selecting Gallery returns gallery image attachment', (tester) async {
      final delegate = _FakeAttachmentPickerDelegate(
        galleryResult: PickedAttachment(
          fileName: 'gallery_photo.jpg',
          bytes: _validPngBytes,
          fileType: 'image',
          fileSize: '1 KB',
        ),
      );

      PickedAttachment? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pick(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Attach'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('attachment_source_gallery')));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.fileName, 'gallery_photo.jpg');
      expect(picked!.fileType, 'image');
    });

    testWidgets('selecting Camera shows photo preview, supports retake, rename, and attach',
        (tester) async {
      final delegate = _FakeAttachmentPickerDelegate(
        cameraResults: [
          PickedAttachment(
            fileName: 'camera_first.jpg',
            bytes: _validPngBytes,
            fileType: 'image',
            fileSize: '1 KB',
          ),
          PickedAttachment(
            fileName: 'camera_second.jpg',
            bytes: _validPngBytes,
            fileType: 'image',
            fileSize: '2 KB',
          ),
        ],
      );

      PickedAttachment? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pick(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Attach'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('attachment_source_camera')));
      await tester.pumpAndSettle();

      // Preview dialog should appear with first photo
      expect(find.text('তোলা ছবি প্রিভিউ'), findsOneWidget);
      expect(find.text('camera_first'), findsOneWidget);
      expect(delegate.cameraCallCount, 1);

      // Tap retake
      await tester.tap(find.byKey(const Key('camera_preview_retake')));
      await tester.pumpAndSettle();

      // Camera was invoked again and second photo preview is shown
      expect(delegate.cameraCallCount, 2);
      expect(find.text('তোলা ছবি প্রিভিউ'), findsOneWidget);
      expect(find.text('camera_second'), findsOneWidget);

      // Rename file and confirm attach
      await tester.enterText(find.byType(TextField), 'dalil_page_1');
      await tester.tap(find.byKey(const Key('camera_preview_attach')));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.fileName, 'dalil_page_1.jpg');
      expect(picked!.fileType, 'image');
      expect(picked!.bytes, _validPngBytes);
    });

    testWidgets('ApplicationDetailScreen Documents tab opens attachment source sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final app = DemoApplication(
        id: 'app-1',
        applicantId: 'person-1',
        applicantName: 'রহিম মিয়া',
        applicantPhone: '01700000000',
        workType: 'নামজারি',
        officeName: 'সদর ভূমি অফিস',
        applicationDate: DateTime(2026, 1, 1),
        status: 'আবেদন',
        agreedAmount: Money.fromTaka(5000),
        receivedAmount: Money.fromTaka(2000),
        expenseAmount: Money.fromTaka(500),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            applicationPaymentsProvider.overrideWith((ref, id) => const Stream.empty()),
            applicationExpensesProvider.overrideWith((ref, id) => const Stream.empty()),
            applicationStatusHistoryProvider.overrideWith((ref, id) => const Stream.empty()),
            applicationDocumentsProvider.overrideWith((ref, id) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ApplicationDetailScreen(application: app),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to 4th tab (ডকুমেন্ট)
      await tester.tap(find.text('৪. ডকুমেন্ট'));
      await tester.pumpAndSettle();

      // Tap "ফাইল যোগ করুন"
      await tester.tap(find.text('ফাইল যোগ করুন'));
      await tester.pumpAndSettle();

      // Source chooser sheet opens with all 3 options
      expect(find.text('ফাইল ম্যানেজার'), findsOneWidget);
      expect(find.text('গ্যালারি'), findsOneWidget);
      expect(find.text('ক্যামেরা'), findsOneWidget);
    });

    testWidgets('rejects oversized file (> 10 MB) safely with SnackBar', (tester) async {
      final oversized = Uint8List(AttachmentPickerSheet.maxAttachmentBytes + 1);
      final delegate = _FakeAttachmentPickerDelegate(
        fileManagerResult: PickedAttachment(
          fileName: 'huge.pdf',
          bytes: oversized,
          fileType: 'pdf',
          fileSize: '10.1 MB',
        ),
      );

      PickedAttachment? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pick(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Attach'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attachment_source_file_manager')));
      await tester.pumpAndSettle();

      expect(picked, isNull);
      expect(find.textContaining('১০ MB'), findsOneWidget);
    });

    testWidgets('handles camera PlatformException gracefully without crashing', (tester) async {
      final delegate = _ThrowingDelegate(
        PlatformException(code: 'camera_access_denied'),
      );

      PickedAttachment? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pick(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Attach'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attachment_source_camera')));
      await tester.pumpAndSettle();

      expect(picked, isNull);
      expect(find.textContaining('ক্যামেরা ব্যবহারের অনুমতি'), findsOneWidget);
    });

    testWidgets('Documents tab clearly distinguishes PDF and picture items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final app = DemoApplication(
        id: 'app-docs-1',
        applicantId: 'person-1',
        applicantName: 'করিম উদ্দিন',
        applicantPhone: '01711111111',
        workType: 'নামজারি',
        officeName: 'সদর ভূমি অফিস',
        applicationDate: DateTime(2026, 2, 1),
        status: 'আবেদন',
        agreedAmount: Money.fromTaka(4000),
        receivedAmount: Money.fromTaka(2000),
        expenseAmount: Money.fromTaka(500),
        documents: [
          DemoDocument(
            id: 'doc-pdf',
            name: 'abedon_copy.pdf',
            type: 'pdf',
            size: '350 KB',
            uploadDate: DateTime(2026, 2, 1),
          ),
          DemoDocument(
            id: 'doc-img',
            name: 'camera_20260201.jpg',
            type: 'image',
            size: '120 KB',
            uploadDate: DateTime(2026, 2, 1),
            fileData: _validPngBytes,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            applicationPaymentsProvider.overrideWith((ref, id) => const Stream.empty()),
            applicationExpensesProvider.overrideWith((ref, id) => const Stream.empty()),
            applicationStatusHistoryProvider.overrideWith((ref, id) => const Stream.empty()),
            applicationDocumentsProvider.overrideWith((ref, id) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ApplicationDetailScreen(application: app),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('৪. ডকুমেন্ট'));
      await tester.pumpAndSettle();

      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('ছবি'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsNWidgets(2)); // leading + badge
      expect(find.byType(Image), findsOneWidget); // picture thumbnail
    });

    testWidgets('pickImage shows only Gallery and Camera without File Manager', (tester) async {
      final delegate = _FakeAttachmentPickerDelegate(
        galleryResult: PickedAttachment(
          fileName: 'ref_photo.jpg',
          bytes: _validPngBytes,
          fileType: 'image',
          fileSize: '1 KB',
        ),
      );

      PickedAttachment? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await AttachmentPickerSheet.pickImage(
                    context,
                    delegate: delegate,
                  );
                },
                child: const Text('Pick Photo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Photo'));
      await tester.pumpAndSettle();

      expect(find.text('ফাইল ম্যানেজার'), findsNothing);
      expect(find.text('গ্যালারি'), findsOneWidget);
      expect(find.text('ক্যামেরা'), findsOneWidget);

      await tester.tap(find.byKey(const Key('attachment_source_gallery')));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.fileName, 'ref_photo.jpg');
    });

    testWidgets('ReferenceListScreen create sheet opens Gallery and Camera chooser for photo',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referencesStreamProvider.overrideWith((ref) => Stream.value([])),
            applicationsWithFinancialsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ReferenceListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open create reference sheet
      await tester.tap(find.text('নতুন রেফারেন্স'));
      await tester.pumpAndSettle();

      // Tap photo selector circle
      await tester.tap(find.byIcon(Icons.handshake_outlined));
      await tester.pumpAndSettle();

      expect(find.text('ফাইল ম্যানেজার'), findsNothing);
      expect(find.text('গ্যালারি'), findsOneWidget);
      expect(find.text('ক্যামেরা'), findsOneWidget);
    });

    testWidgets(
        'ReferenceSelectorSheet inline create form includes photo picker (Gallery & Camera) and notes field',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referencesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ReferenceSelectorSheet.show(context),
                  child: const Text('Select Ref'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select Ref'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ নতুন রেফারেন্স'));
      await tester.pumpAndSettle();

      expect(find.text('নোট বা মন্তব্য (ঐচ্ছিক)'), findsOneWidget);
      expect(find.byIcon(Icons.handshake_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.handshake_outlined));
      await tester.pumpAndSettle();

      expect(find.text('ফাইল ম্যানেজার'), findsNothing);
      expect(find.text('গ্যালারি'), findsOneWidget);
      expect(find.text('ক্যামেরা'), findsOneWidget);
    });

    testWidgets(
        'ReferenceSelectorSheet shows inline error on empty submit and renders corrupted avatar bytes safely',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final badRef = Reference(
        id: 'ref-bad-img',
        name: 'করিম সাহেব',
        phone: '01711111111',
        photo: Uint8List.fromList([1, 2, 3, 4]), // invalid image bytes
        createdAt: 1000,
        updatedAt: 1000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referencesStreamProvider.overrideWith((ref) => Stream.value([badRef])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ReferenceSelectorSheet.show(context),
                  child: const Text('Select Ref'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select Ref'));
      await tester.pumpAndSettle();

      // List renders safely even with invalid avatar bytes
      expect(find.text('করিম সাহেব'), findsOneWidget);

      // Switch to create form and submit empty
      await tester.tap(find.text('+ নতুন রেফারেন্স'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('সংরক্ষণ ও নির্বাচন করুন'));
      await tester.pumpAndSettle();

      // Inline error appears visibly inside the sheet
      expect(find.text('নাম এবং মোবাইল নম্বর আবশ্যক।'), findsOneWidget);
    });
  });
}

class _ThrowingDelegate implements AttachmentPickerDelegate {
  final Object error;
  _ThrowingDelegate(this.error);

  @override
  Future<PickedAttachment?> pickFromFileManager() async => throw error;

  @override
  Future<PickedAttachment?> pickFromGallery() async => throw error;

  @override
  Future<PickedAttachment?> captureFromCamera() async => throw error;

  @override
  Future<List<PickedAttachment>> pickMultipleFromFileManager() async => throw error;

  @override
  Future<List<PickedAttachment>> pickMultipleFromGallery() async => throw error;
}
