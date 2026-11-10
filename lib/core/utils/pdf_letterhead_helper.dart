import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_typography.dart';
import 'bengali_digits.dart';

/// দোকানের সেটিংস থেকে প্রাপ্ত অফিসিয়াল PDF প্যাড হেডারের তথ্য।
class PdfShopInfo {
  final String shopName;
  final String? proprietorName;
  final String? shopPhone;
  final String? shopAddress;

  const PdfShopInfo({
    this.shopName = 'রজব ভূমি সেবা ঘর',
    this.proprietorName,
    this.shopPhone,
    this.shopAddress,
  });

  factory PdfShopInfo.fromSettings(Map<String, String>? settings) {
    String? cleanOrNull(String? raw) {
      final t = raw?.trim();
      return (t != null && t.isNotEmpty) ? t : null;
    }

    final name = cleanOrNull(settings?['shop_name']) ?? 'রজব ভূমি সেবা ঘর';
    return PdfShopInfo(
      shopName: name,
      proprietorName: cleanOrNull(settings?['proprietor_name']),
      shopPhone: cleanOrNull(settings?['shop_phone']),
      shopAddress: cleanOrNull(settings?['shop_address']),
    );
  }
}

/// প্রিন্ট-উপযোগী A4 PDF-এর জন্য সাদা-কালো অফিসিয়াল হেডার লেআউট ও পেইন্টার।
class PdfLetterheadLayout {
  final TextPainter? shopPainter;
  final TextPainter? contactPainter;
  final TextPainter? addressPainter;
  final TextPainter titlePainter;
  final TextPainter? metaLeftPainter;
  final TextPainter? metaRightPainter;
  final double contentWidth;
  final double totalHeight;

  const PdfLetterheadLayout._({
    required this.shopPainter,
    required this.contactPainter,
    required this.addressPainter,
    required this.titlePainter,
    required this.metaLeftPainter,
    required this.metaRightPainter,
    required this.contentWidth,
    required this.totalHeight,
  });

  static TextPainter makePainter(
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

  /// দোকানের তথ্য, শিরোনাম ও মেটাডাটা পরিমাপ করে লেআউট তৈরি করে।
  factory PdfLetterheadLayout.measure({
    required PdfShopInfo shopInfo,
    required String title,
    required double contentWidth,
    String? metaLeft,
    String? metaRight,
  }) {
    final cleanShop = shopInfo.shopName.trim();
    final shopPainter = cleanShop.isNotEmpty
        ? makePainter(
            cleanShop,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            textAlign: TextAlign.center,
            maxWidth: contentWidth,
          )
        : null;

    final contactParts = <String>[];
    final owner = shopInfo.proprietorName?.trim();
    final phone = shopInfo.shopPhone?.trim();
    if (owner != null && owner.isNotEmpty) {
      contactParts.add('পরিচালনায়: $owner');
    }
    if (phone != null && phone.isNotEmpty) {
      contactParts.add('মোবাইল: ${BengaliDigits.toBengali(phone)}');
    }
    final contactText = contactParts.join('   |   ');
    final contactPainter = contactText.isNotEmpty
        ? makePainter(
            contactText,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF334155),
            textAlign: TextAlign.center,
            maxWidth: contentWidth,
          )
        : null;

    final address = shopInfo.shopAddress?.trim();
    final addressPainter = (address != null && address.isNotEmpty)
        ? makePainter(
            address,
            fontSize: 9.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF334155),
            textAlign: TextAlign.center,
            maxWidth: contentWidth,
          )
        : null;

    final titlePainter = makePainter(
      title,
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
      textAlign: TextAlign.center,
      maxWidth: contentWidth,
    );

    final hasLeft = metaLeft != null && metaLeft.trim().isNotEmpty;
    final hasRight = metaRight != null && metaRight.trim().isNotEmpty;

    final metaLeftPainter = hasLeft
        ? makePainter(
            metaLeft.trim(),
            fontSize: 9.8,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
            maxWidth: contentWidth * 0.56,
          )
        : null;

    final metaRightPainter = hasRight
        ? makePainter(
            metaRight.trim(),
            fontSize: 9.8,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
            textAlign: TextAlign.right,
            maxWidth: contentWidth * 0.42,
          )
        : null;

    var h = 0.0;
    if (shopPainter != null) h += shopPainter.height + 2;
    if (contactPainter != null) h += contactPainter.height + 2;
    if (addressPainter != null) h += addressPainter.height + 2;
    h += 6 + 4 + 8; // ডাবল রুল ও গ্যাপ
    h += titlePainter.height + 8;
    if (metaLeftPainter != null || metaRightPainter != null) {
      h += math.max(
            metaLeftPainter?.height ?? 0,
            metaRightPainter?.height ?? 0,
          ) +
          10;
    }

    return PdfLetterheadLayout._(
      shopPainter: shopPainter,
      contactPainter: contactPainter,
      addressPainter: addressPainter,
      titlePainter: titlePainter,
      metaLeftPainter: metaLeftPainter,
      metaRightPainter: metaRightPainter,
      contentWidth: contentWidth,
      totalHeight: h,
    );
  }

  /// ক্যানভাসে সাদা-কালো অফিসিয়াল হেডার আঁকে এবং হেডারের নিচের Y অবস্থান ফেরত দেয়।
  double paint(
    ui.Canvas canvas, {
    required double marginH,
    required double marginV,
    required double pageWidth,
  }) {
    var y = marginV;

    if (shopPainter != null) {
      shopPainter!.paint(
        canvas,
        ui.Offset(marginH + (contentWidth - shopPainter!.width) / 2, y),
      );
      y += shopPainter!.height + 2;
    }

    if (contactPainter != null) {
      contactPainter!.paint(
        canvas,
        ui.Offset(marginH + (contentWidth - contactPainter!.width) / 2, y),
      );
      y += contactPainter!.height + 2;
    }

    if (addressPainter != null) {
      addressPainter!.paint(
        canvas,
        ui.Offset(marginH + (contentWidth - addressPainter!.width) / 2, y),
      );
      y += addressPainter!.height + 2;
    }

    y += 6;
    canvas.drawLine(
      ui.Offset(marginH, y),
      ui.Offset(pageWidth - marginH, y),
      ui.Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = 1.2,
    );
    y += 2.5;
    canvas.drawLine(
      ui.Offset(marginH, y),
      ui.Offset(pageWidth - marginH, y),
      ui.Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 0.5,
    );
    y += 9.5;

    titlePainter.paint(
      canvas,
      ui.Offset(marginH + (contentWidth - titlePainter.width) / 2, y),
    );
    y += titlePainter.height + 8;

    if (metaLeftPainter != null || metaRightPainter != null) {
      if (metaLeftPainter != null) {
        metaLeftPainter!.paint(canvas, ui.Offset(marginH, y));
      }
      if (metaRightPainter != null) {
        metaRightPainter!.paint(
          canvas,
          ui.Offset(pageWidth - marginH - metaRightPainter!.width, y),
        );
      }
      y += math.max(
            metaLeftPainter?.height ?? 0,
            metaRightPainter?.height ?? 0,
          ) +
          10;
    }

    return y;
  }
}

