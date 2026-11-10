import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/pdf_letterhead_helper.dart';

/// বকেয়া তালিকা PDF-এর একটি সারি।
class DuePdfRow {
  final String applicantName;
  final String applicantPhone;
  final String workType;
  final Money agreedAmount;
  final Money receivedAmount;
  final Money dueAmount;

  const DuePdfRow({
    required this.applicantName,
    required this.applicantPhone,
    required this.workType,
    required this.agreedAmount,
    required this.receivedAmount,
    required this.dueAmount,
  });
}

class _MeasuredDueRow {
  final TextPainter serialPainter;
  final TextPainter namePainter;
  final TextPainter detailPainter;
  final TextPainter agreedPainter;
  final TextPainter receivedPainter;
  final TextPainter duePainter;
  final double height;

  const _MeasuredDueRow({
    required this.serialPainter,
    required this.namePainter,
    required this.detailPainter,
    required this.agreedPainter,
    required this.receivedPainter,
    required this.duePainter,
    required this.height,
  });
}

/// 'বকেয়া হিসাব ও তাগাদা' তালিকার প্রিন্ট-উপযোগী A4 PDF তৈরির সার্ভিস।
///
/// বাংলা যুক্তাক্ষর ও কার ১০০% নিখুঁত রাখতে Flutter-এর নেটিভ HarfBuzz টেক্সট ইঞ্জিন
/// (`TextPainter` + `Canvas`) দিয়ে প্রতিটি A4 পৃষ্ঠা হাই-রেজোলিউশন ইমেজ হিসেবে
/// রেন্ডার করে PDF-এ সংযুক্ত করা হয়।
class DuePdfService {
  const DuePdfService._();

  static const double _pageWidth = 595.28; // A4 width in points (72 DPI)
  static const double _pageHeight = 841.89; // A4 height in points (72 DPI)
  static const double _marginH = 28.0;
  static const double _marginV = 28.0;
  static const double _renderScale = 2.5; // ~180 DPI crisp print quality

  static const double _contentWidth = _pageWidth - (_marginH * 2); // 539.28
  static const double _colSerialW = 38.0;
  static const double _colAgreedW = 92.0;
  static const double _colReceivedW = 92.0;
  static const double _colDueW = 98.0;
  static const double _colNameW =
      _contentWidth - _colSerialW - _colAgreedW - _colReceivedW - _colDueW;

  static const double _cellPadH = 7.0;
  static const double _cellPadV = 6.0;
  static const double _tableHeaderHeight = 28.0;
  static const double _totalRowHeight = 30.0;
  static const double _footerReserve = 26.0;

  static TextPainter _makePainter(
    String text, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = const Color(0xFF0F172A),
    TextAlign textAlign = TextAlign.left,
    required double maxWidth,
  }) {
    return PdfLetterheadLayout.makePainter(
      text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      textAlign: textAlign,
      maxWidth: maxWidth,
    );
  }

  /// বকেয়া তালিকা নিয়ে প্রিন্ট-উপযোগী A4 PDF বাইট তৈরি করে।
  static Future<Uint8List> buildDueListPdf({
    required List<DuePdfRow> rows,
    String shopName = 'রজব ভূমি সেবা ঘর',
    String? proprietorName,
    String? shopPhone,
    String? shopAddress,
    String title = 'বকেয়া হিসাব ও তাগাদা — বকেয়া তালিকা',
    DateTime? printedAt,
  }) async {
    final date = printedAt ?? DateTime.now();
    final formattedDate =
        '${BengaliDigits.toBengali(date.day.toString().padLeft(2, '0'))}/'
        '${BengaliDigits.toBengali(date.month.toString().padLeft(2, '0'))}/'
        '${BengaliDigits.toBengali(date.year)}';

    Money totalAgreed = Money.zero;
    Money totalReceived = Money.zero;
    Money totalDue = Money.zero;
    for (final r in rows) {
      totalAgreed += r.agreedAmount;
      totalReceived += r.receivedAmount;
      totalDue += r.dueAmount;
    }

    final cleanShop = shopName.trim();
    final metaLeftText =
        'মোট বকেয়া ফাইল: ${BengaliDigits.toBengali(rows.length)} টি';
    final metaRightText = 'তারিখ: $formattedDate';

    final letterhead = PdfLetterheadLayout.measure(
      shopInfo: PdfShopInfo(
        shopName: cleanShop.isNotEmpty ? cleanShop : 'রজব ভূমি সেবা ঘর',
        proprietorName: proprietorName,
        shopPhone: shopPhone,
        shopAddress: shopAddress,
      ),
      title: title,
      contentWidth: _contentWidth,
      metaLeft: metaLeftText,
      metaRight: metaRightText,
    );

    final summaryText =
        'সর্বমোট বকেয়া: ${totalDue.formatBengali()}   |   '
        'মোট চুক্তি: ${totalAgreed.formatBengali()}   |   '
        'মোট জমা: ${totalReceived.formatBengali()}';
    final summaryPainter = _makePainter(
      summaryText,
      fontSize: 9.8,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
      textAlign: TextAlign.center,
      maxWidth: _contentWidth - 20,
    );
    final summaryBoxHeight = summaryPainter.height + 12;

    final tableStartY = _marginV + letterhead.totalHeight + summaryBoxHeight + 10;
    const maxContentBottomY = _pageHeight - _marginV - _footerReserve;

    // Pass 1: সব সারি মেপে পৃষ্ঠায় ভাগ করা
    final measuredRows = <_MeasuredDueRow>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final detailParts = <String>[];
      if (row.workType.trim().isNotEmpty) {
        detailParts.add(row.workType.trim());
      }
      if (row.applicantPhone.trim().isNotEmpty) {
        detailParts.add(BengaliDigits.toBengali(row.applicantPhone.trim()));
      }
      final detailText = detailParts.join(' • ');

      final serialPainter = _makePainter(
        BengaliDigits.toBengali(i + 1),
        fontSize: 9.5,
        color: const Color(0xFF1E293B),
        textAlign: TextAlign.center,
        maxWidth: _colSerialW - (_cellPadH * 2),
      );
      final namePainter = _makePainter(
        row.applicantName,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
        maxWidth: _colNameW - (_cellPadH * 2),
      );
      final detailPainter = _makePainter(
        detailText,
        fontSize: 8.8,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF475569),
        maxWidth: _colNameW - (_cellPadH * 2),
      );
      final agreedPainter = _makePainter(
        row.agreedAmount.formatBengali(),
        fontSize: 9.5,
        color: const Color(0xFF334155),
        textAlign: TextAlign.right,
        maxWidth: _colAgreedW - (_cellPadH * 2),
      );
      final receivedPainter = _makePainter(
        row.receivedAmount.formatBengali(),
        fontSize: 9.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E293B),
        textAlign: TextAlign.right,
        maxWidth: _colReceivedW - (_cellPadH * 2),
      );
      final duePainter = _makePainter(
        row.dueAmount.formatBengali(),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
        textAlign: TextAlign.right,
        maxWidth: _colDueW - (_cellPadH * 2),
      );

      final nameBlockH = namePainter.height +
          (detailText.isNotEmpty ? 2 + detailPainter.height : 0);
      final contentH = math.max(
        nameBlockH,
        math.max(
          serialPainter.height,
          math.max(
            agreedPainter.height,
            math.max(receivedPainter.height, duePainter.height),
          ),
        ),
      );
      final rowH = math.max(28.0, contentH + (_cellPadV * 2));

      measuredRows.add(
        _MeasuredDueRow(
          serialPainter: serialPainter,
          namePainter: namePainter,
          detailPainter: detailPainter,
          agreedPainter: agreedPainter,
          receivedPainter: receivedPainter,
          duePainter: duePainter,
          height: rowH,
        ),
      );
    }

    final pages = <List<_MeasuredDueRow>>[];
    if (measuredRows.isEmpty) {
      pages.add(const []);
    } else {
      var currentPage = <_MeasuredDueRow>[];
      var cursorY = tableStartY + _tableHeaderHeight;

      for (final row in measuredRows) {
        if (currentPage.isNotEmpty && cursorY + row.height > maxContentBottomY) {
          pages.add(currentPage);
          currentPage = <_MeasuredDueRow>[];
          cursorY = tableStartY + _tableHeaderHeight;
        }
        currentPage.add(row);
        cursorY += row.height;
      }
      if (currentPage.isNotEmpty) {
        pages.add(currentPage);
      }

      // শেষ পৃষ্ঠায় সর্বমোট সারির জন্য জায়গা না থাকলে নতুন পৃষ্ঠা তৈরি না করে
      // শেষ পৃষ্ঠার শেষ সারি পরের পৃষ্ঠায় নেওয়া (যাতে মোট সারি একসাথে থাকে)।
      if (cursorY + _totalRowHeight > maxContentBottomY &&
          pages.last.length > 1) {
        final overflowRow = pages.last.removeLast();
        pages.add([overflowRow]);
      }
    }

    // Pass 2: প্রতিটি পৃষ্ঠা রেন্ডার করে PDF ডকুমেন্ট তৈরি
    final doc = pw.Document(
      title: title,
      author: cleanShop.isNotEmpty ? cleanShop : 'রজব ভূমি সেবা ঘর',
    );

    final thSerial = _makePainter(
      'ক্রমিক',
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      textAlign: TextAlign.center,
      maxWidth: _colSerialW - (_cellPadH * 2),
    );
    final thName = _makePainter(
      'গ্রাহক ও কাজের বিবরণ',
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      maxWidth: _colNameW - (_cellPadH * 2),
    );
    final thAgreed = _makePainter(
      'মোট চুক্তি',
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      textAlign: TextAlign.right,
      maxWidth: _colAgreedW - (_cellPadH * 2),
    );
    final thReceived = _makePainter(
      'জমা',
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      textAlign: TextAlign.right,
      maxWidth: _colReceivedW - (_cellPadH * 2),
    );
    final thDue = _makePainter(
      'বকেয়া',
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      textAlign: TextAlign.right,
      maxWidth: _colDueW - (_cellPadH * 2),
    );

    final totLabelPainter = _makePainter(
      'সর্বমোট (${BengaliDigits.toBengali(rows.length)} টি ফাইল)',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
      textAlign: TextAlign.right,
      maxWidth: _colSerialW + _colNameW - (_cellPadH * 2),
    );
    final totAgreedPainter = _makePainter(
      totalAgreed.formatBengali(),
      fontSize: 9.8,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
      textAlign: TextAlign.right,
      maxWidth: _colAgreedW - (_cellPadH * 2),
    );
    final totReceivedPainter = _makePainter(
      totalReceived.formatBengali(),
      fontSize: 9.8,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
      textAlign: TextAlign.right,
      maxWidth: _colReceivedW - (_cellPadH * 2),
    );
    final totDuePainter = _makePainter(
      totalDue.formatBengali(),
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
      textAlign: TextAlign.right,
      maxWidth: _colDueW - (_cellPadH * 2),
    );

    final pixelWidth = (_pageWidth * _renderScale).round();
    final pixelHeight = (_pageHeight * _renderScale).round();

    for (var pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final pageRows = pages[pageIdx];
      final isLastPage = pageIdx == pages.length - 1;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(_renderScale, _renderScale);

      // সাদা পটভূমি
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, _pageWidth, _pageHeight),
        ui.Paint()..color = Colors.white,
      );

      // হেডার
      final summaryY = letterhead.paint(
        canvas,
        marginH: _marginH,
        marginV: _marginV,
        pageWidth: _pageWidth,
      );

      // সারাংশ বক্স (রঙহীন, পরিষ্কার বর্ডারসহ)
      final summaryRect = ui.Rect.fromLTWH(
        _marginH,
        summaryY,
        _contentWidth,
        summaryBoxHeight,
      );
      canvas.drawRect(
        summaryRect,
        ui.Paint()
          ..color = const Color(0xFF475569)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      summaryPainter.paint(
        canvas,
        ui.Offset(
          _marginH + (_contentWidth - summaryPainter.width) / 2,
          summaryY + (summaryBoxHeight - summaryPainter.height) / 2,
        ),
      );

      // টেবিল হেডার
      var tableY = tableStartY;

      thSerial.paint(
        canvas,
        ui.Offset(
          _marginH + (_colSerialW - thSerial.width) / 2,
          tableY + (_tableHeaderHeight - thSerial.height) / 2,
        ),
      );
      thName.paint(
        canvas,
        ui.Offset(
          _marginH + _colSerialW + _cellPadH,
          tableY + (_tableHeaderHeight - thName.height) / 2,
        ),
      );
      thAgreed.paint(
        canvas,
        ui.Offset(
          _marginH + _colSerialW + _colNameW + _colAgreedW - _cellPadH - thAgreed.width,
          tableY + (_tableHeaderHeight - thAgreed.height) / 2,
        ),
      );
      thReceived.paint(
        canvas,
        ui.Offset(
          _marginH +
              _colSerialW +
              _colNameW +
              _colAgreedW +
              _colReceivedW -
              _cellPadH -
              thReceived.width,
          tableY + (_tableHeaderHeight - thReceived.height) / 2,
        ),
      );
      thDue.paint(
        canvas,
        ui.Offset(
          _pageWidth - _marginH - _cellPadH - thDue.width,
          tableY + (_tableHeaderHeight - thDue.height) / 2,
        ),
      );

      final headerBorderPaint = ui.Paint()
        ..color = const Color(0xFF1E293B)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.9;
      final borderPaint = ui.Paint()
        ..color = const Color(0xFF64748B)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.6;

      _drawRowBorders(
        canvas,
        top: tableY,
        height: _tableHeaderHeight,
        paint: headerBorderPaint,
      );
      tableY += _tableHeaderHeight;

      if (pageRows.isEmpty) {
        final emptyPainter = _makePainter(
          'কোনো বকেয়া পাওনা নেই',
          fontSize: 11,
          color: const Color(0xFF64748B),
          textAlign: TextAlign.center,
          maxWidth: _contentWidth - 16,
        );
        const emptyRowH = 36.0;
        canvas.drawRect(
          ui.Rect.fromLTWH(_marginH, tableY, _contentWidth, emptyRowH),
          borderPaint,
        );
        emptyPainter.paint(
          canvas,
          ui.Offset(
            _marginH + (_contentWidth - emptyPainter.width) / 2,
            tableY + (emptyRowH - emptyPainter.height) / 2,
          ),
        );
      } else {
        for (var rIdx = 0; rIdx < pageRows.length; rIdx++) {
          final r = pageRows[rIdx];

          r.serialPainter.paint(
            canvas,
            ui.Offset(
              _marginH + (_colSerialW - r.serialPainter.width) / 2,
              tableY + (r.height - r.serialPainter.height) / 2,
            ),
          );

          const nameX = _marginH + _colSerialW + _cellPadH;
          r.namePainter.paint(canvas, ui.Offset(nameX, tableY + _cellPadV));
          if (r.detailPainter.text?.toPlainText().isNotEmpty == true) {
            r.detailPainter.paint(
              canvas,
              ui.Offset(nameX, tableY + _cellPadV + r.namePainter.height + 2),
            );
          }

          r.agreedPainter.paint(
            canvas,
            ui.Offset(
              _marginH +
                  _colSerialW +
                  _colNameW +
                  _colAgreedW -
                  _cellPadH -
                  r.agreedPainter.width,
              tableY + (r.height - r.agreedPainter.height) / 2,
            ),
          );
          r.receivedPainter.paint(
            canvas,
            ui.Offset(
              _marginH +
                  _colSerialW +
                  _colNameW +
                  _colAgreedW +
                  _colReceivedW -
                  _cellPadH -
                  r.receivedPainter.width,
              tableY + (r.height - r.receivedPainter.height) / 2,
            ),
          );
          r.duePainter.paint(
            canvas,
            ui.Offset(
              _pageWidth - _marginH - _cellPadH - r.duePainter.width,
              tableY + (r.height - r.duePainter.height) / 2,
            ),
          );

          _drawRowBorders(
            canvas,
            top: tableY,
            height: r.height,
            paint: borderPaint,
          );
          tableY += r.height;
        }

        // শেষ পৃষ্ঠায় সর্বমোট সারি
        if (isLastPage) {
          totLabelPainter.paint(
            canvas,
            ui.Offset(
              _marginH + _colSerialW + _colNameW - _cellPadH - totLabelPainter.width,
              tableY + (_totalRowHeight - totLabelPainter.height) / 2,
            ),
          );
          totAgreedPainter.paint(
            canvas,
            ui.Offset(
              _marginH +
                  _colSerialW +
                  _colNameW +
                  _colAgreedW -
                  _cellPadH -
                  totAgreedPainter.width,
              tableY + (_totalRowHeight - totAgreedPainter.height) / 2,
            ),
          );
          totReceivedPainter.paint(
            canvas,
            ui.Offset(
              _marginH +
                  _colSerialW +
                  _colNameW +
                  _colAgreedW +
                  _colReceivedW -
                  _cellPadH -
                  totReceivedPainter.width,
              tableY + (_totalRowHeight - totReceivedPainter.height) / 2,
            ),
          );
          totDuePainter.paint(
            canvas,
            ui.Offset(
              _pageWidth - _marginH - _cellPadH - totDuePainter.width,
              tableY + (_totalRowHeight - totDuePainter.height) / 2,
            ),
          );

          // সর্বমোট সারির বর্ডার (ক্রমিক+নাম একসাথে মার্জড)
          canvas.drawRect(
            ui.Rect.fromLTWH(_marginH, tableY, _contentWidth, _totalRowHeight),
            borderPaint,
          );
          const x2 = _marginH + _colSerialW + _colNameW;
          const x3 = x2 + _colAgreedW;
          const x4 = x3 + _colReceivedW;
          canvas.drawLine(
            ui.Offset(x2, tableY),
            ui.Offset(x2, tableY + _totalRowHeight),
            borderPaint,
          );
          canvas.drawLine(
            ui.Offset(x3, tableY),
            ui.Offset(x3, tableY + _totalRowHeight),
            borderPaint,
          );
          canvas.drawLine(
            ui.Offset(x4, tableY),
            ui.Offset(x4, tableY + _totalRowHeight),
            borderPaint,
          );
        }
      }

      // ফুটার
      final footerPainter = _makePainter(
        'পৃষ্ঠা ${BengaliDigits.toBengali(pageIdx + 1)} / ${BengaliDigits.toBengali(pages.length)}',
        fontSize: 9,
        color: const Color(0xFF64748B),
        textAlign: TextAlign.right,
        maxWidth: _contentWidth,
      );
      footerPainter.paint(
        canvas,
        ui.Offset(
          _pageWidth - _marginH - footerPainter.width,
          _pageHeight - _marginV - footerPainter.height,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(pixelWidth, pixelHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();

      if (byteData == null) {
        throw StateError('PDF পৃষ্ঠার ইমেজ তৈরি করা যায়নি।');
      }
      final pngBytes = byteData.buffer.asUint8List();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(pngBytes),
            fit: pw.BoxFit.fill,
          ),
        ),
      );
    }

    return doc.save();
  }

  static void _drawRowBorders(
    ui.Canvas canvas, {
    required double top,
    required double height,
    required ui.Paint paint,
  }) {
    canvas.drawRect(
      ui.Rect.fromLTWH(_marginH, top, _contentWidth, height),
      paint,
    );
    const x1 = _marginH + _colSerialW;
    const x2 = x1 + _colNameW;
    const x3 = x2 + _colAgreedW;
    const x4 = x3 + _colReceivedW;
    canvas.drawLine(ui.Offset(x1, top), ui.Offset(x1, top + height), paint);
    canvas.drawLine(ui.Offset(x2, top), ui.Offset(x2, top + height), paint);
    canvas.drawLine(ui.Offset(x3, top), ui.Offset(x3, top + height), paint);
    canvas.drawLine(ui.Offset(x4, top), ui.Offset(x4, top + height), paint);
  }
}

