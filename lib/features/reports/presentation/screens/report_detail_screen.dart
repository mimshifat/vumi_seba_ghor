import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportTitle;
  final String reportCategory; // 'work_type', 'office', 'finance', 'dues'

  const ReportDetailScreen({
    super.key,
    required this.reportTitle,
    required this.reportCategory,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String _selectedPeriod = 'চলতি মাস';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.reportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.rose),
            tooltip: 'PDF ডাউনলোড',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('রিপোর্ট PDF তৈরি হচ্ছে...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            tooltip: 'শেয়ার করুন',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('রিপোর্ট শেয়ার করা হচ্ছে...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Period selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['আজ', 'চলতি সপ্তাহ', 'চলতি মাস', 'চলতি বছর', 'কাস্টম রেঞ্জ'].map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedPeriod = period);
                    },
                    selectedColor: AppColors.primarySurface,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Chart Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'পরিসংখ্যান ও অনুপাত',
                  style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: 45,
                          title: '৪৫%',
                          color: AppColors.primary,
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        PieChartSectionData(
                          value: 25,
                          title: '২৫%',
                          color: AppColors.emerald,
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        PieChartSectionData(
                          value: 18,
                          title: '১৮%',
                          color: AppColors.amber,
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        PieChartSectionData(
                          value: 12,
                          title: '১২%',
                          color: AppColors.rose,
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Data Breakdown Table Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'বিস্তারিত বিবরণী',
                  style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._buildCategoryRows(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryRows() {
    switch (widget.reportCategory) {
      case 'office':
        return [
          _buildTableRow('সদর উপজেলা ভূমি অফিস', '১২ টি', '৳৬০,০০০', AppColors.primary),
          const Divider(),
          _buildTableRow('এসি ল্যান্ড অফিস', '৭ টি', '৳৩৫,০০০', AppColors.emerald),
          const Divider(),
          _buildTableRow('কালীগঞ্জ ইউনিয়ন ভূমি অফিস', '৪ টি', '৳১৫,৫০০', AppColors.amberDark),
          const Divider(thickness: 1.5),
          _buildTableRow('সর্বমোট অফিস ভিত্তিক', '২৩ টি', '৳১,১০,৫০০', AppColors.textPrimary, isTotal: true),
        ];
      case 'finance':
        return [
          _buildTableRow('মোট সেবা ফি আদায়', '২৩ টি', '৳১,১০,৫০০', AppColors.emerald),
          const Divider(),
          _buildTableRow('কাজের সরাসরি সরকারি/আইনি খরচ', '১৬ টি', '৳২৮,৪০০', AppColors.rose),
          const Divider(),
          _buildTableRow('দোকানের সাধারণ পরিচালন ব্যয়', '৭ টি', '৳১২,০০০', AppColors.amberDark),
          const Divider(thickness: 1.5),
          _buildTableRow('প্রকৃত ব্যবসায়িক ইনকাম', 'প্রবৃদ্ধি +১৮%', '৳৭০,১০০', AppColors.primary, isTotal: true),
        ];
      case 'pipeline':
        return [
          _buildTableRow('নতুন আবেদন জমা', '৬ টি', 'প্রক্রিয়াধীন', AppColors.primary),
          const Divider(),
          _buildTableRow('প্রস্তাব প্রেরণ সম্পন্ন', '৫ টি', 'অগ্রগতিতে', const Color(0xFF6366F1)),
          const Divider(),
          _buildTableRow('শুনানি অপেক্ষমাণ', '৩ টি', 'জরুরি', const Color(0xFF8B5CF6)),
          const Divider(),
          _buildTableRow('অনুমোদিত ও পাশ', '৪ টি', 'চূড়ান্ত পর্যায়', AppColors.emerald),
          const Divider(),
          _buildTableRow('সম্পন্ন ও ডেলিভারি', '৫ টি', 'পরিশোধিত', const Color(0xFF16A34A)),
          const Divider(thickness: 1.5),
          _buildTableRow('মোট অ্যাক্টিভ ফাইল', '২৩ টি', '১০০% ট্র্যাকিং', AppColors.textPrimary, isTotal: true),
        ];
      case 'custom_range':
        return [
          _buildTableRow('নির্বাচিত মেয়াদে নতুন গ্রাহক', '১৮ জন', 'নতুন এন্ট্রি', AppColors.primary),
          const Divider(),
          _buildTableRow('সম্পন্ন মোট আবেদন', '১৫ টি', 'সফল সমাপ্তি', AppColors.emerald),
          const Divider(),
          _buildTableRow('মোট নগদ/বিকাশ প্রাপ্তি', '২২ টি ভাউচার', '৳৯৫,০০০', AppColors.emeraldDark),
          const Divider(),
          _buildTableRow('মোট ব্যয় ভাউচার', '১৪ টি ভাউচার', '৳২৩,২০০', AppColors.rose),
          const Divider(thickness: 1.5),
          _buildTableRow('মেয়াদের উদ্বৃত্ত তহবিল', 'অডিট সমাপ্ত', '৳৭১,৮০০', AppColors.primary, isTotal: true),
        ];
      case 'work_type':
      default:
        return [
          _buildTableRow('নামজারি আবেদন', '১২ টি', '৳৫৫,০০০', AppColors.primary),
          const Divider(),
          _buildTableRow('জমাভাগ আবেদন', '৫ টি', '৳২৮,০০০', AppColors.emerald),
          const Divider(),
          _buildTableRow('খতিয়ান সংশোধন', '৪ টি', '৳১৮,৫০০', AppColors.amberDark),
          const Divider(),
          _buildTableRow('অন্যান্য বিবিধ কাজ', '২ টি', '৳৯,০০০', AppColors.rose),
          const Divider(thickness: 1.5),
          _buildTableRow('সর্বমোট কাজের ধরন', '২৩ টি', '৳১,১০,৫০০', AppColors.textPrimary, isTotal: true),
        ];
    }
  }

  Widget _buildTableRow(String label, String count, String amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                label,
                style: isTotal
                    ? AppTypography.headingSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w700)
                    : AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                count,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                amount,
                style: isTotal
                    ? AppTypography.moneyMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 15)
                    : AppTypography.moneySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
