import 'package:flutter/material.dart';

/// রেসপনসিভ ব্রেকপয়েন্ট এবং অ্যাডাপ্টিভ লেআউট সাপোর্ট।
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobile = 768.0;
  static const double desktop = 1024.0;
  static const double maxContentWidth = 1360.0;
}

/// [BuildContext] এর উপর রেসপনসিভ এক্সটেনশন
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < ResponsiveBreakpoints.mobile;
  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.mobile &&
      screenWidth < ResponsiveBreakpoints.desktop;
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.desktop;
  bool get isWide => screenWidth >= ResponsiveBreakpoints.mobile;
}

/// উইন্ডো সাইজ পরিবর্তনের সাথে রিয়্যাক্টিভভাবে লেআউট রেন্ডার করার উইজেট
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop &&
            desktop != null) {
          return desktop!(context);
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobile &&
            tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}

/// ডেস্কটপ এবং বড় স্ক্রিনে কন্টেন্টকে অতিরিক্ত চওড়া হওয়া রোধ করে মাঝখানে সুন্দরভাবে ধরে রাখার উইজেট
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
