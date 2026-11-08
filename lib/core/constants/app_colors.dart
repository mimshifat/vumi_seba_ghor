import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Indigo Palette
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryDeep = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFE0E7FF);
  static const Color primarySurface = Color(0xFFEEF2FF);

  // Success & Positive (Emerald)
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color emeraldSurface = Color(0xFFECFDF5);

  // Warning & Pending (Amber)
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color amberSurface = Color(0xFFFFFBEB);

  // Danger, Expense & Urgent (Rose)
  static const Color rose = Color(0xFFF43F5E);
  static const Color roseDark = Color(0xFFE11D48);
  static const Color roseLight = Color(0xFFFFE4E6);
  static const Color roseSurface = Color(0xFFFFF1F2);

  // Cool Neutral Slate Palette
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Semantics
  static const Color background = slate50;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = slate100;
  static const Color border = slate200;
  static const Color divider = Color(0xFFEDF2F7);

  // Text colors
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate600;
  static const Color textMuted = slate400;
  static const Color textOnPrimary = Colors.white;

  // Status specific colors
  static const Color statusNew = Color(0xFF0284C7);          // আবেদন - Sky Blue
  static const Color statusSent = Color(0xFF6366F1);         // প্রস্তাব প্রেরণ / প্রতিবেদন দাখিল - Indigo
  static const Color statusHearing = Color(0xFF8B5CF6);      // শুনানি - Violet
  static const Color statusApproved = Color(0xFF10B981);     // মঞ্জুর / পাশ - Emerald
  static const Color statusPassed = statusApproved;          // Legacy alias
  static const Color statusDcr = Color(0xFF06B6D4);          // ডিসিআর প্রস্তুত / PER - Cyan
  static const Color statusPer = statusDcr;                  // Legacy alias
  static const Color statusCompleted = Color(0xFF16A34A);    // সম্পন্ন - Green
  static const Color statusWaiting = Color(0xFFF59E0B);      // অপেক্ষমাণ - Amber
  static const Color statusObjection = Color(0xFFEA580C);    // আপত্তি - Orange
  static const Color statusCorrection = Color(0xFFF43F5E);   // সংশোধন প্রয়োজন - Rose
  static const Color statusRejected = Color(0xFF64748B);     // নামঞ্জুর / বাতিল - Slate
  static const Color statusCancelled = statusRejected;       // Legacy alias

  static Color getStatusColor(String status) {
    switch (status.trim()) {
      case 'আবেদন':
      case 'আবেদন দাখিল':
        return statusNew;
      case 'প্রস্তাব প্রেরণ':
      case 'প্রতিবেদন দাখিল':
      case 'তদন্ত প্রতিবেদন':
        return statusSent;
      case 'শুনানি':
        return statusHearing;
      case 'মঞ্জুর':
      case 'পাশ':
        return statusApproved;
      case 'ডিসিআর প্রস্তুত':
      case 'ডিসিআর':
      case 'PER':
        return statusDcr;
      case 'সম্পন্ন':
        return statusCompleted;
      case 'অপেক্ষমাণ':
        return statusWaiting;
      case 'আপত্তি':
        return statusObjection;
      case 'সংশোধন প্রয়োজন':
      case 'সংশোধন প্রয়োজন':
        return statusCorrection;
      case 'নামঞ্জুর':
      case 'বাতিল':
        return statusRejected;
      default:
        return primary;
    }
  }

  static Color getStatusBgColor(String status) {
    return getStatusColor(status).withValues(alpha: 0.12);
  }
}

