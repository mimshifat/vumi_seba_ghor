import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../domain/models/proposal_print_models.dart';

class _MeasuredRow {
  final int serial;
  final TextPainter serialPainter;
  final TextPainter namePainter;
  final TextPainter casePainter;
  final double height;

  const _MeasuredRow({
    required this.serial,
    required this.serialPainter,
    required this.namePainter,
    required this.casePainter,
    required this.height,
  });
}

/// 'প্রস্তাব প্রেরণ' কেস তালিকার A4 PDF তৈরির সার্ভিস।
///
/// বাংলা যুক্তাক্ষর ও কার (`প্রস্তাব`, `প্রেরণ`, `ি`, `ে`) ১০০% নিখুঁত রাখতে
/// Flutter-এর নেটিভ HarfBuzz টেক্সট ইঞ্জিন (`TextPainter` + `Canvas`) দিয়ে
/// প্রতিটি A4 পৃষ্ঠা হাই-রেজোলিউশন ইমেজ হিসেবে রেন্ডার করে PDF-এ সংযুক্ত করা হয়।
class ProposalPdfService {
  const ProposalPdfService._();

  static const double _pageWidth = 595.28; // A4 width in points (72 DPI)
  static const double _pageHeight = 841.89; // A4 height in points (72 DPI)
  static const double _marginH = 30.0;
  static const double _marginV = 30.0;
  static const double _renderScale = 2.5; // ~180 DPI crisp print quality

  static const double _colSerialW = 54.0;
  static const double _colCaseW = 200.0;
  static const double _contentWidth = _pageWidth - (_marginH * 2);
  static const double _colNameW = _contentWidth - _colSerialW - _colCaseW;
  static const double _cellPadH = 8.0;
  static const double _cellPadV = 6.0;
  static const double _tableHeaderHeight = 28.0;
  static const double _footerReserve = 28.0;

  static TextPainter _makePainter(
    String text, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = const Color(0xFF0F172A),
    TextAlign textAlign = TextAlign.left,
    required double maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    tp.layout(minWidth: 0, maxWidth: maxWidth);
    return tp;
  }

  /// আবেদনকারীর নাম ও কেস নম্বর নিয়ে প্রিন্ট-উপযোগী A4 PDF বাইট তৈরি করে।
  static Future<Uint8List> buildProposalListPdf({
    required List<ProposalPrintRow> rows,
    String shopName = 'রজব ভূমি সেবা ঘর',
    String title = 'প্রস্তাব প্রেরণ — কেস তালিকা',
    String? officeLabel,
    DateTime? printedAt,
  }) async {
    final date = printedAt ?? DateTime.now();
    final formattedDate =
        '${BengaliDigits.toBengali(date.day.toString().padLeft(2, '0'))}/'
        '${BengaliDigits.toBengali(date.month.toString().padLeft(2, '0'))}/'
        '${BengaliDigits.toBengali(date.year)}';

    final cleanShop = shopName.trim();
    final officeText = (officeLabel != null && officeLabel.trim().isNotEmpty)
        ? 'অফিস: ${officeLabel.trim()}'
        : 'অফিস: সকল অফিস';
    final metaRightText =
        'তারিখ: $formattedDate  |  মোট: ${BengaliDigits.toBengali(rows.length)} টি';

    // হেডার উচ্চতা হিসাব
    final shopPainter = cleanShop.isNotEmpty
        ? _makePainter(
            cleanShop,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            maxWidth: _contentWidth,
          )
        : null;
    final titlePainter = _makePainter(
      title,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1E293B),
      maxWidth: _contentWidth,
    );
    final officePainter = _makePainter(
      officeText,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF475569),
      maxWidth: _contentWidth * 0.58,
    );
    final metaPainter = _makePainter(
      metaRightText,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF475569),
      textAlign: TextAlign.right,
      maxWidth: _contentWidth * 0.40,
    );

    final headerBlockHeight = (shopPainter != null ? shopPainter.height + 2 : 0) +
        titlePainter.height +
        6 +
        math.max(officePainter.height, metaPainter.height) +
        14;

    final tableStartY = _marginV + headerBlockHeight;
    const maxContentBottomY = _pageHeight - _marginV - _footerReserve;

    // Pass 1: সব রো মেপে পেজ অনুযায়ী ভাগ করা
    final measuredRows = <_MeasuredRow>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final caseText = (row.caseNumber?.trim().isNotEmpty == true)
          ? row.caseNumber!.trim()
          : '—';

      final serialPainter = _makePainter(
        BengaliDigits.toBengali(i + 1),
        fontSize: 10.5,
        color: const Color(0xFF1E293B),
        textAlign: TextAlign.center,
        maxWidth: _colSerialW - (_cellPadH * 2),
      );
      final namePainter = _makePainter(
        row.applicantName,
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A),
        maxWidth: _colNameW - (_cellPadH * 2),
      );
      final casePainter = _makePainter(
        caseText,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
        maxWidth: _colCaseW - (_cellPadH * 2),
      );

      final contentH = math.max(
        serialPainter.height,
        math.max(namePainter.height, casePainter.height),
      );
      final rowH = math.max(24.0, contentH + (_cellPadV * 2));

      measuredRows.add(
        _MeasuredRow(
          serial: i + 1,
          serialPainter: serialPainter,
          namePainter: namePainter,
          casePainter: casePainter,
          height: rowH,
        ),
      );
    }

    final pages = <List<_MeasuredRow>>[];
    if (measuredRows.isEmpty) {
      pages.add(const []);
    } else {
      var currentPage = <_MeasuredRow>[];
      var cursorY = tableStartY + _tableHeaderHeight;

      for (final row in measuredRows) {
        if (currentPage.isNotEmpty && cursorY + row.height > maxContentBottomY) {
          pages.add(currentPage);
          currentPage = <_MeasuredRow>[];
          cursorY = tableStartY + _tableHeaderHeight;
        }
        currentPage.add(row);
        cursorY += row.height;
      }
      if (currentPage.isNotEmpty) {
        pages.add(currentPage);
      }
    }

    // Pass 2: প্রতিটি পেজ রেন্ডার করে PDF ডকুমেন্ট তৈরি
    final doc = pw.Document(
      title: title,
      author: cleanShop.isNotEmpty ? cleanShop : 'রজব ভূমি সেবা ঘর',
    );

    final thSerial = _makePainter(
      'ক্রমিক',
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      textAlign: TextAlign.center,
      maxWidth: _colSerialW - (_cellPadH * 2),
    );
    final thName = _makePainter(
      'আবেদনকারীর নাম',
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      maxWidth: _colNameW - (_cellPadH * 2),
    );
    final thCase = _makePainter(
      'কেস নং',
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      maxWidth: _colCaseW - (_cellPadH * 2),
    );

    final pixelWidth = (_pageWidth * _renderScale).round();
    final pixelHeight = (_pageHeight * _renderScale).round();

    for (var pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final pageRows = pages[pageIdx];
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(_renderScale, _renderScale);

      // সাদা পটভূমি
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, _pageWidth, _pageHeight),
        ui.Paint()..color = Colors.white,
      );

      // হেডার আঁকা
      var y = _marginV;
      if (shopPainter != null) {
        shopPainter.paint(canvas, ui.Offset(_marginH, y));
        y += shopPainter.height + 2;
      }
      titlePainter.paint(canvas, ui.Offset(_marginH, y));
      y += titlePainter.height + 6;

      officePainter.paint(canvas, ui.Offset(_marginH, y));
      metaPainter.paint(
        canvas,
        ui.Offset(_pageWidth - _marginH - metaPainter.width, y),
      );
      y += math.max(officePainter.height, metaPainter.height) + 8;

      canvas.drawLine(
        ui.Offset(_marginH, y),
        ui.Offset(_pageWidth - _marginH, y),
        ui.Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 0.8,
      );

      // টেবিল হেডার
      var tableY = tableStartY;
      final headerRect = ui.Rect.fromLTWH(
        _marginH,
        tableY,
        _contentWidth,
        _tableHeaderHeight,
      );
      canvas.drawRect(
        headerRect,
        ui.Paint()..color = const Color(0xFFE2E8F0),
      );

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
      thCase.paint(
        canvas,
        ui.Offset(
          _marginH + _colSerialW + _colNameW + _cellPadH,
          tableY + (_tableHeaderHeight - thCase.height) / 2,
        ),
      );

      final borderPaint = ui.Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.6;

      _drawRowBorders(
        canvas,
        top: tableY,
        height: _tableHeaderHeight,
        paint: borderPaint,
      );
      tableY += _tableHeaderHeight;

      if (pageRows.isEmpty) {
        final emptyPainter = _makePainter(
          'কোনো কেস পাওয়া যায়নি',
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
          if (rIdx.isOdd) {
            canvas.drawRect(
              ui.Rect.fromLTWH(_marginH, tableY, _contentWidth, r.height),
              ui.Paint()..color = const Color(0xFFF8FAFC),
            );
          }

          r.serialPainter.paint(
            canvas,
            ui.Offset(
              _marginH + (_colSerialW - r.serialPainter.width) / 2,
              tableY + (r.height - r.serialPainter.height) / 2,
            ),
          );
          r.namePainter.paint(
            canvas,
            ui.Offset(
              _marginH + _colSerialW + _cellPadH,
              tableY + _cellPadV,
            ),
          );
          r.casePainter.paint(
            canvas,
            ui.Offset(
              _marginH + _colSerialW + _colNameW + _cellPadH,
              tableY + _cellPadV,
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
      }

      // ফুটার (পৃষ্ঠা নম্বর)
      final footerPainter = _makePainter(
        'পৃষ্ঠা ${BengaliDigits.toBengali(pageIdx + 1)} / ${BengaliDigits.toBengali(pages.length)}',
        fontSize: 9.5,
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
    const x2 = _marginH + _colSerialW + _colNameW;
    canvas.drawLine(ui.Offset(x1, top), ui.Offset(x1, top + height), paint);
    canvas.drawLine(ui.Offset(x2, top), ui.Offset(x2, top + height), paint);
  }
}
