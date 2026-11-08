import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriodIndex = 1; // Default to 'গত ৩ মাস'
  final List<String> _periods = ['চলতি মাস', 'গত ৩ মাস', 'চলতি বছর', 'সর্বকালের'];

  int _touchedPieIndex = -1;

  // Analytics datasets depending on selected period
  final List<Map<String, dynamic>> _periodStats = [
    {
      'totalApps': 23,
      'completed': 18,
      'successRate': '৭৮%',
      'netIncome': '৳৭০,১০০',
      'avgIncome': '৳৩,০৪৮',
      'activeFiles': 5,
      'trendIncome': [18.0, 22.0, 35.0, 52.0, 78.0],
      'trendIncomeNet': [11.0, 14.0, 23.0, 36.0, 50.0],
    },
    {
      'totalApps': 64,
      'completed': 49,
      'successRate': '৭৬%',
      'netIncome': '৳১,৯৪,৫০০',
      'avgIncome': '৳৩,০৩৯',
      'activeFiles': 15,
      'trendIncome': [28.0, 42.0, 55.0, 68.0, 85.0],
      'trendIncomeNet': [18.0, 27.0, 38.0, 47.0, 60.0],
    },
    {
      'totalApps': 128,
      'completed': 98,
      'successRate': '৭৬%',
      'netIncome': '৳৩,৮৫,০০০',
      'avgIncome': '৳৩,০০৭',
      'activeFiles': 30,
      'trendIncome': [35.0, 50.0, 65.0, 82.0, 110.0],
      'trendIncomeNet': [22.0, 32.0, 43.0, 56.0, 78.0],
    },
    {
      'totalApps': 182,
      'completed': 142,
      'successRate': '৭৮%',
      'netIncome': '৳৫,৪০,০০০',
      'avgIncome': '৳২,৯৬৭',
      'activeFiles': 40,
      'trendIncome': [40.0, 60.0, 80.0, 105.0, 130.0],
      'trendIncomeNet': [25.0, 40.0, 54.0, 72.0, 92.0],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentStats = _periodStats[_selectedPeriodIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ব্যবসায়িক বিশ্লেষণ'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'রিফ্রেশ করুন',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('সর্বশেষ ব্যবসায়িক তথ্য আপডেট হয়েছে'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
        children: [
          // Period Selector Chips
          _buildPeriodSelector(),

          const SizedBox(height: AppSpacing.base),

          // 4 Executive KPI Cards
          _buildExecutiveSummary(currentStats),

          const SizedBox(height: AppSpacing.lg),

          // Multi-Month Growth & Net Income Trend Chart
          _buildTrendChartCard(currentStats),

          const SizedBox(height: AppSpacing.lg),

          // Work Type Distribution (Donut Chart & Legend)
          _buildWorkTypeDistributionCard(),

          const SizedBox(height: AppSpacing.lg),

          // Pipeline & Application Funnel
          _buildPipelineFunnelCard(),

          const SizedBox(height: AppSpacing.lg),

          // Land Office Performance & Distribution
          _buildOfficePerformanceCard(),

          const SizedBox(height: AppSpacing.lg),

          // Smart Business Insights
          _buildSmartInsightsCard(),
        ],
      ),
    );
  }

  // --- PERIOD SELECTOR ---
  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = _selectedPeriodIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_periods[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPeriodIndex = index);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }),
      ),
    );
  }

  // --- 4 EXECUTIVE KPI SUMMARY CARDS ---
  Widget _buildExecutiveSummary(Map<String, dynamic> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'মোট আবেদন',
                value: '${BengaliDigits.toBengali(stats['totalApps'])} টি',
                subtitle: '+১৫% বিগত সময়ের চেয়ে',
                icon: Icons.folder_shared_outlined,
                accentColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: 'সম্পন্নতার হার',
                value: stats['successRate'],
                subtitle: '${BengaliDigits.toBengali(stats['completed'])} টি সফল ডেলিভারি',
                icon: Icons.verified_outlined,
                accentColor: AppColors.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'প্রকৃত ইনকাম',
                value: stats['netIncome'],
                subtitle: 'আয়ের অনুপাত ৬৩.৪%',
                icon: Icons.trending_up,
                accentColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: 'গড় ইনকাম / ফাইল',
                value: stats['avgIncome'],
                subtitle: '${BengaliDigits.toBengali(stats['activeFiles'])} টি প্রক্রিয়াধীন',
                icon: Icons.pie_chart_outline,
                accentColor: AppColors.amberDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.headingMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- MULTI-MONTH TREND CHART ---
  Widget _buildTrendChartCard(Map<String, dynamic> stats) {
    final List<double> incomeData = List<double>.from(stats['trendIncome']);
    final List<double> netIncomeData = List<double>.from(stats['trendIncomeNet']);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'মাসভিত্তিক আদায় ও ইনকাম প্রবৃদ্ধি',
                      style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'গত ৫ মাসের ধারাবাহিক আর্থিক ট্রেন্ড (হাজার টাকায়)',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _buildLegendIndicator(AppColors.primary, 'আদায়'),
                  const SizedBox(width: 8),
                  _buildLegendIndicator(AppColors.emerald, 'ইনকাম'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.slate200,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${BengaliDigits.toBengali(value.toInt())}k',
                          style: const TextStyle(
                            color: AppColors.slate400,
                            fontSize: 10,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = ['জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে'];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[idx],
                              style: const TextStyle(
                                color: AppColors.slate600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTypography.fontFamily,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: 140,
                lineBarsData: [
                  // Income Line
                  LineChartBarData(
                    spots: List.generate(
                      incomeData.length,
                      (i) => FlSpot(i.toDouble(), incomeData[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  // Net Income Line
                  LineChartBarData(
                    spots: List.generate(
                      netIncomeData.length,
                      (i) => FlSpot(i.toDouble(), netIncomeData[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.emerald,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.emerald,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.emerald.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- WORK TYPE DONUT CHART CARD ---
  Widget _buildWorkTypeDistributionCard() {
    final workTypes = [
      {'name': 'নামজারি', 'count': 12, 'percent': 52, 'amount': '৳৫৫,০০০', 'color': AppColors.primary},
      {'name': 'জমাভাগ', 'count': 5, 'percent': 22, 'amount': '৳২৮,০০০', 'color': AppColors.emerald},
      {'name': 'খতিয়ান সংশোধন', 'count': 4, 'percent': 17, 'amount': '৳১৮,৫০০', 'color': AppColors.amberDark},
      {'name': 'বিবিধ সেবা', 'count': 2, 'percent': 9, 'amount': '৳৯,০০০', 'color': AppColors.rose},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'কাজের ধরন ভিত্তিক বিভাজন',
                style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  'মোট ২৩ টি ফাইল',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),

          // Donut Chart & Side Details
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: List.generate(workTypes.length, (i) {
                          final isTouched = i == _touchedPieIndex;
                          final radius = isTouched ? 30.0 : 25.0;
                          final item = workTypes[i];
                          return PieChartSectionData(
                            color: item['color'] as Color,
                            value: (item['percent'] as int).toDouble(),
                            title: '',
                            radius: radius,
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _touchedPieIndex >= 0 && _touchedPieIndex < workTypes.length
                              ? '${BengaliDigits.toBengali(workTypes[_touchedPieIndex]['percent'])}%'
                              : '২৩ টি',
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _touchedPieIndex >= 0 && _touchedPieIndex < workTypes.length
                              ? workTypes[_touchedPieIndex]['name'] as String
                              : 'মোট কাজ',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              // Legend List
              Expanded(
                child: Column(
                  children: workTypes.map((item) {
                    final color = item['color'] as Color;
                    final name = item['name'] as String;
                    final percent = BengaliDigits.toBengali(item['percent']);
                    final count = BengaliDigits.toBengali(item['count']);
                    final amount = item['amount'] as String;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                amount,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 11.5,
                                ),
                              ),
                              Text(
                                '$count টি ($percent%)',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- APPLICATION PIPELINE & FUNNEL CARD ---
  Widget _buildPipelineFunnelCard() {
    final stages = [
      {'title': 'নতুন আবেদন দাখিল', 'count': 23, 'percent': 100, 'color': AppColors.statusNew},
      {'title': 'প্রস্তাব ও নথি প্রেরণ', 'count': 17, 'percent': 74, 'color': AppColors.statusSent},
      {'title': 'শুনানি পর্যায়', 'count': 12, 'percent': 52, 'color': AppColors.statusHearing},
      {'title': 'অনুমোদিত ও পাশ', 'count': 8, 'percent': 35, 'color': AppColors.statusPassed},
      {'title': 'সম্পন্ন ও ডেলিভারি', 'count': 5, 'percent': 22, 'color': AppColors.statusCompleted},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ফাইলের ধাপভিত্তিক অগ্রগতি',
                style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.slate400),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'আবেদন গ্রহণ থেকে ডেলিভারি পর্যন্ত রূপান্তরের গতি ও প্রবাহ',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: AppSpacing.base),

          ...stages.map((stage) {
            final title = stage['title'] as String;
            final count = BengaliDigits.toBengali(stage['count']);
            final percent = stage['percent'] as int;
            final color = stage['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$count টি (${BengaliDigits.toBengali(percent)}%)',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 7,
                      backgroundColor: AppColors.slate100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- LAND OFFICE PERFORMANCE & DISTRIBUTION CARD ---
  Widget _buildOfficePerformanceCard() {
    final offices = [
      {
        'name': 'উপজেলা ভূমি অফিস, সাভার',
        'count': 12,
        'revenue': '৳৬০,০০০',
        'percentage': 0.52,
        'color': AppColors.primary,
      },
      {
        'name': 'সহকারী কমিশনার (ভূমি), কেরানীগঞ্জ',
        'count': 7,
        'revenue': '৳৩৫,০০০',
        'percentage': 0.30,
        'color': AppColors.emerald,
      },
      {
        'name': 'ইউনিয়ন ভূমি অফিস, কালীগঞ্জ',
        'count': 4,
        'revenue': '৳১৫,৫০০',
        'percentage': 0.18,
        'color': AppColors.amberDark,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ভূমি অফিস ভিত্তিক পরিসংখ্যান',
                style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.account_balance_outlined, size: 18, color: AppColors.slate400),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'অফিসভিত্তিক আবেদনের চাপ, কার্যক্ষমতা ও রাজস্ব',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: AppSpacing.base),

          ...offices.map((office) {
            final name = office['name'] as String;
            final count = BengaliDigits.toBengali(office['count']);
            final revenue = office['revenue'] as String;
            final pct = office['percentage'] as double;
            final pctText = BengaliDigits.toBengali((pct * 100).toInt());
            final color = office['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        revenue,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$count টি সক্রিয় ফাইল',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        '$pctText% মোট ব্যবসার ভাগ',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- SMART BUSINESS INSIGHTS CARD ---
  Widget _buildSmartInsightsCard() {
    final insights = [
      {
        'icon': Icons.insights_rounded,
        'title': 'সর্বাধিক ইনকাম প্রদানকারী সেবা',
        'desc': 'নামজারি আবেদন থেকে গড় আয় ৳৪,৫৮০ এবং ব্যয় অনুপাত মাত্র ১৮%।',
        'color': AppColors.emerald,
      },
      {
        'icon': Icons.bolt_rounded,
        'title': 'দ্রুততম নিষ্পত্তি হার',
        'desc': 'খতিয়ান সংশোধন সংক্রান্ত কাজগুলো গড়ে মাত্র ৯ দিনে নিষ্পত্তি হচ্ছে।',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.location_city_rounded,
        'title': 'প্রধান অপারেশন কেন্দ্র',
        'desc': 'সাভার উপজেলা ভূমি অফিসে সবচেয়ে বেশি (৫২%) ফাইল চলমান রয়েছে।',
        'color': AppColors.amberDark,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.amberSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.amberDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ব্যবসায়িক অন্তর্দৃষ্টি ও পরামর্শ',
                style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          ...insights.map((item) {
            final color = item['color'] as Color;
            final icon = item['icon'] as IconData;
            final title = item['title'] as String;
            final desc = item['desc'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          desc,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
