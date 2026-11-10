import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../finance/presentation/providers/finance_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedPeriodIndex = 0; // 0: চলতি মাস, 1: গত ৩ মাস, 2: চলতি বছর, 3: সর্বকালের
  final List<String> _periods = ['চলতি মাস', 'গত ৩ মাস', 'চলতি বছর', 'সর্বকালের'];

  int _touchedPieIndex = -1;

  static const List<String> _bengaliMonthsShort = [
    'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'
  ];

  DateTime _getPeriodStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriodIndex) {
      case 0: // চলতি মাস
        return DateTime(now.year, now.month, 1);
      case 1: // গত ৩ মাস
        final m = now.month - 2;
        return m > 0 ? DateTime(now.year, m, 1) : DateTime(now.year - 1, m + 12, 1);
      case 2: // চলতি বছর
        return DateTime(now.year, 1, 1);
      case 3: // সর্বকালের
      default:
        return DateTime(2000, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];

    final allTxsAsync = ref.watch(allUnifiedTransactionsStreamProvider);
    final allTxs = allTxsAsync.valueOrNull ?? const [];

    final startMs = _getPeriodStartDate().millisecondsSinceEpoch;

    // পিরিয়ড অনুযায়ী ফিল্টার
    final filteredApps = allApps.where((a) {
      return a.application.applicationDate >= startMs;
    }).toList();

    final filteredTxs = allTxs.where((t) {
      return t.date >= startMs;
    }).toList();

    // এক্সিকিউটিভ মেট্রিক্স ক্যালকুলেশন
    final totalApps = filteredApps.length;
    final completedApps = filteredApps.where((a) {
      final s = a.application.status;
      return s == 'সম্পন্ন' || s == 'খতিয়ান ডেলিভারি';
    }).length;

    final successRate = totalApps > 0
        ? '${BengaliDigits.toBengali(((completedApps / totalApps) * 100).round())}%'
        : '০%';

    int totalIncomePaisa = 0;
    int appIncomePaisa = 0;
    int otherIncomePaisa = 0;

    for (final tx in filteredTxs) {
      if (tx.type == 'income') {
        totalIncomePaisa += tx.amount;
        if (tx.source == 'applicationPayment' || tx.source == 'statusIncome' || tx.applicationId != null) {
          appIncomePaisa += tx.amount;
        } else {
          otherIncomePaisa += tx.amount;
        }
      }
    }

    final appIncomeFormatted = Money.fromPaisa(appIncomePaisa).formatBengali();
    final otherIncomeFormatted = Money.fromPaisa(otherIncomePaisa).formatBengali();

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
              ref.invalidate(applicationsWithFinancialsStreamProvider);
              ref.invalidate(allUnifiedTransactionsStreamProvider);
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
          _buildExecutiveSummary(
            totalApps: totalApps,
            completedApps: completedApps,
            successRate: successRate,
            appIncomeFormatted: appIncomeFormatted,
            otherIncomeFormatted: otherIncomeFormatted,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Multi-Month Growth & Net Income Trend Chart
          _buildTrendChartCard(allTxs),

          const SizedBox(height: AppSpacing.lg),

          // Work Type Distribution (Donut Chart & Legend)
          _buildWorkTypeDistributionCard(filteredApps),

          const SizedBox(height: AppSpacing.lg),

          // Pipeline & Application Funnel
          _buildPipelineFunnelCard(filteredApps),

          const SizedBox(height: AppSpacing.lg),

          // Land Office Performance & Distribution
          _buildOfficePerformanceCard(filteredApps),

          const SizedBox(height: AppSpacing.lg),

          // Smart Business Insights
          _buildSmartInsightsCard(filteredApps, totalIncomePaisa, completedApps),
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
  Widget _buildExecutiveSummary({
    required int totalApps,
    required int completedApps,
    required String successRate,
    required String appIncomeFormatted,
    required String otherIncomeFormatted,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'মোট আবেদন',
                value: '${BengaliDigits.toBengali(totalApps)} টি',
                subtitle: totalApps > 0 ? 'নির্ধারিত সময়কালের ফাইল' : 'কোনো আবেদন নেই',
                icon: Icons.folder_shared_outlined,
                accentColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: 'সম্পন্নতার হার',
                value: successRate,
                subtitle: '${BengaliDigits.toBengali(completedApps)} টি সফল ডেলিভারি',
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
                title: 'আবেদন ইনকাম',
                value: appIncomeFormatted,
                subtitle: 'ভূমি সেবা সংক্রান্ত',
                icon: Icons.trending_up,
                accentColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: 'অন্যান্য আয়',
                value: otherIncomeFormatted,
                subtitle: 'অন্যান্য সেবা বাবদ',
                icon: Icons.storefront_outlined,
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
  Widget _buildTrendChartCard(List<dynamic> allTxs) {
    final now = DateTime.now();

    // বিগত ৫ মাসের নাম ও রেঞ্জ
    final monthLabels = <String>[];
    final appIncomeSpots = <FlSpot>[];
    final otherIncomeSpots = <FlSpot>[];

    double maxVal = 10.0;

    for (int i = 4; i >= 0; i--) {
      int yr = now.year;
      int mo = now.month - i;
      while (mo <= 0) {
        mo += 12;
        yr -= 1;
      }

      monthLabels.add(_bengaliMonthsShort[mo - 1]);

      int monthAppIncome = 0;
      int monthOtherIncome = 0;

      for (final tx in allTxs) {
        final d = DateTime.fromMillisecondsSinceEpoch(tx.date as int);
        if (d.year == yr && d.month == mo) {
          if (tx.type == 'income') {
            if (tx.source == 'applicationPayment' ||
                tx.source == 'statusIncome' ||
                tx.applicationId != null) {
              monthAppIncome += (tx.amount as int);
            } else {
              monthOtherIncome += (tx.amount as int);
            }
          }
        }
      }

      final appThousand = monthAppIncome / 100000.0; // টাকা / ১০০০
      final otherThousand = monthOtherIncome / 100000.0;

      if (appThousand > maxVal) maxVal = appThousand;
      if (otherThousand > maxVal) maxVal = otherThousand;

      final spotIdx = (4 - i).toDouble();
      appIncomeSpots.add(FlSpot(spotIdx, math.max(0.0, appThousand)));
      otherIncomeSpots.add(FlSpot(spotIdx, math.max(0.0, otherThousand)));
    }

    final double chartMaxY = (maxVal * 1.25).clamp(10.0, 1000.0);

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'মাসভিত্তিক ইনকাম প্রবৃদ্ধি',
                style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                'গত ৫ মাসের ধারাবাহিক ইনকাম ট্রেন্ড (হাজার টাকায়)',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLegendIndicator(AppColors.primary, 'আবেদন ইনকাম'),
                  const SizedBox(width: 14),
                  _buildLegendIndicator(AppColors.amberDark, 'অন্যান্য আয়'),
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
                  horizontalInterval: chartMaxY / 4,
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
                      interval: chartMaxY / 4,
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
                        final idx = value.toInt();
                        if (idx >= 0 && idx < monthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              monthLabels[idx],
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
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: appIncomeSpots,
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
                  LineChartBarData(
                    spots: otherIncomeSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.amberDark,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.amberDark,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.amberDark.withValues(alpha: 0.06),
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
  Widget _buildWorkTypeDistributionCard(List<dynamic> apps) {
    if (apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
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
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '০ টি ফাইল',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Icon(Icons.pie_chart_outline, size: 40, color: AppColors.slate300),
            const SizedBox(height: 8),
            Text(
              'এখনও কোনো কাজের তথ্য নেই',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'নতুন আবেদন তৈরি করলে কাজের ধরন অনুযায়ী বিশ্লেষণ চার্ট এখানে দৃশ্যমান হবে।',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    }

    // গ্রুপ বাই workType
    final Map<String, int> typeCounts = {};
    final Map<String, int> typeAmounts = {};

    for (final appWithFin in apps) {
      final wt = (appWithFin.application.workType as String?)?.trim() ?? 'অন্যান্য';
      typeCounts[wt] = (typeCounts[wt] ?? 0) + 1;
      typeAmounts[wt] = (typeAmounts[wt] ?? 0) + (appWithFin.application.agreedAmount as int);
    }

    final palette = [
      AppColors.primary,
      AppColors.emerald,
      AppColors.amberDark,
      AppColors.rose,
      AppColors.primaryDeep,
      AppColors.slate600,
    ];

    final workTypeList = <Map<String, dynamic>>[];
    int colorIdx = 0;
    typeCounts.forEach((name, count) {
      final pct = ((count / apps.length) * 100).round();
      final amt = Money.fromPaisa(typeAmounts[name] ?? 0).formatBengali();
      workTypeList.add({
        'name': name,
        'count': count,
        'percent': pct,
        'amount': amt,
        'color': palette[colorIdx % palette.length],
      });
      colorIdx++;
    });

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
                  'মোট ${BengaliDigits.toBengali(apps.length)} টি ফাইল',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
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
                        sections: List.generate(workTypeList.length, (i) {
                          final isTouched = i == _touchedPieIndex;
                          final radius = isTouched ? 30.0 : 25.0;
                          final item = workTypeList[i];
                          return PieChartSectionData(
                            color: item['color'] as Color,
                            value: (item['count'] as int).toDouble(),
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
                          _touchedPieIndex >= 0 && _touchedPieIndex < workTypeList.length
                              ? '${BengaliDigits.toBengali(workTypeList[_touchedPieIndex]['percent'])}%'
                              : '${BengaliDigits.toBengali(apps.length)} টি',
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _touchedPieIndex >= 0 && _touchedPieIndex < workTypeList.length
                              ? workTypeList[_touchedPieIndex]['name'] as String
                              : 'মোট কাজ',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  children: workTypeList.map((item) {
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
  Widget _buildPipelineFunnelCard(List<dynamic> apps) {
    final int newCount = apps.where((a) {
      final s = a.application.status as String;
      return s == 'আবেদন' || s == 'দাখিলকৃত' || s == 'নতুন';
    }).length;

    final int processingCount = apps.where((a) {
      final s = a.application.status as String;
      return s == 'প্রস্তাব প্রেরণ' ||
          s == 'তহশিলদার প্রতিবেদন' ||
          s == 'এসিল্যান্ড আদেশ' ||
          s == 'কার্যক্রম শুরু';
    }).length;

    final int hearingCount = apps.where((a) {
      final s = a.application.status as String;
      return s == 'শুনানি' || s == 'শুনানি সম্পন্ন';
    }).length;

    final int approvedCount = apps.where((a) {
      final s = a.application.status as String;
      return s == 'মঞ্জুর' ||
          s == 'ডিসিআর প্রস্তুত' ||
          s == 'অনুমোদিত' ||
          s == 'ডিসিআর কাটা' ||
          s == 'পাশ';
    }).length;

    final int completedCount = apps.where((a) {
      final s = a.application.status as String;
      return s == 'সম্পন্ন' || s == 'খতিয়ান ডেলিভারি';
    }).length;

    final total = apps.length;

    final stages = [
      {'title': 'নতুন আবেদন দাখিল', 'count': newCount, 'color': AppColors.statusNew},
      {'title': 'প্রস্তাব ও নথি প্রেরণ', 'count': processingCount, 'color': AppColors.statusSent},
      {'title': 'শুনানি পর্যায়', 'count': hearingCount, 'color': AppColors.statusHearing},
      {'title': 'অনুমোদিত ও পাশ', 'count': approvedCount, 'color': AppColors.statusPassed},
      {'title': 'সম্পন্ন ও ডেলিভারি', 'count': completedCount, 'color': AppColors.statusCompleted},
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
            final count = stage['count'] as int;
            final percent = total > 0 ? ((count / total) * 100).round() : 0;
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
                        '${BengaliDigits.toBengali(count)} টি (${BengaliDigits.toBengali(percent)}%)',
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
                      value: total > 0 ? (count / total) : 0.0,
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
  Widget _buildOfficePerformanceCard(List<dynamic> apps) {
    if (apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
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
            const SizedBox(height: AppSpacing.lg),
            const Icon(Icons.account_balance_outlined, size: 40, color: AppColors.slate300),
            const SizedBox(height: 8),
            Text(
              'এখনও কোনো ভূমি অফিসের আবেদন নেই',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'আবেদনে সংশ্লিষ্ট ভূমি অফিস নির্বাচন করলে অফিসভিত্তিক পারফরম্যান্স এখানে দৃশ্যমান হবে।',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    }

    final Map<String, int> officeCounts = {};
    final Map<String, int> officeRevenues = {};

    for (final appWithFin in apps) {
      final off = (appWithFin.application.officeName as String?)?.trim() ?? 'অনির্ধারিত অফিস';
      officeCounts[off] = (officeCounts[off] ?? 0) + 1;
      officeRevenues[off] = (officeRevenues[off] ?? 0) + (appWithFin.application.agreedAmount as int);
    }

    final colors = [AppColors.primary, AppColors.emerald, AppColors.amberDark, AppColors.primaryDeep];

    int cIdx = 0;
    final officeList = <Map<String, dynamic>>[];
    officeCounts.forEach((name, count) {
      final rev = Money.fromPaisa(officeRevenues[name] ?? 0).formatBengali();
      final pct = apps.isNotEmpty ? (count / apps.length) : 0.0;
      officeList.add({
        'name': name,
        'count': count,
        'revenue': rev,
        'percentage': pct,
        'color': colors[cIdx % colors.length],
      });
      cIdx++;
    });

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
          ...officeList.map((office) {
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
  Widget _buildSmartInsightsCard(List<dynamic> apps, int totalIncomePaisa, int completedApps) {
    final List<Map<String, dynamic>> insights = [];

    if (apps.isNotEmpty) {
      // টপ সার্ভিস
      final Map<String, int> typeCounts = {};
      for (final a in apps) {
        final wt = (a.application.workType as String?)?.trim() ?? 'অন্যান্য';
        typeCounts[wt] = (typeCounts[wt] ?? 0) + 1;
      }
      String topType = 'নামজারি';
      int maxTypeCount = 0;
      typeCounts.forEach((k, v) {
        if (v > maxTypeCount) {
          maxTypeCount = v;
          topType = k;
        }
      });

      insights.add({
        'icon': Icons.insights_rounded,
        'title': 'সর্বাধিক ফাইল পরিচালনাকারী খাত',
        'desc': '$topType সংক্রান্ত সেবায় সবচেয়ে বেশি (${BengaliDigits.toBengali(maxTypeCount)} টি) ফাইল চলছে।',
        'color': AppColors.emerald,
      });

      // ডেলিভারি ও নিষ্পত্তি
      final rate = ((completedApps / apps.length) * 100).round();
      insights.add({
        'icon': Icons.bolt_rounded,
        'title': 'নিষ্পত্তির হার ও অগ্রগতি',
        'desc': 'মোট আবেদনের ${BengaliDigits.toBengali(rate)}% কাজ সফলভাবে সম্পন্ন হয়েছে।',
        'color': AppColors.primary,
      });

      // অফিস ইনসাইট
      final Map<String, int> offCounts = {};
      for (final a in apps) {
        final off = (a.application.officeName as String?)?.trim() ?? 'অফিস';
        offCounts[off] = (offCounts[off] ?? 0) + 1;
      }
      String topOff = 'ভূমি অফিস';
      int maxOffCount = 0;
      offCounts.forEach((k, v) {
        if (v > maxOffCount) {
          maxOffCount = v;
          topOff = k;
        }
      });

      insights.add({
        'icon': Icons.location_city_rounded,
        'title': 'প্রধান অপারেশন কেন্দ্র',
        'desc': '$topOff-এ সবচেয়ে বেশি (${BengaliDigits.toBengali(maxOffCount)} টি) ফাইলের কাজ চলমান রয়েছে।',
        'color': AppColors.amberDark,
      });
    } else {
      // যখন কোনো আবেদন বা লেনদেন নেই
      insights.addAll([
        {
          'icon': Icons.post_add_rounded,
          'title': 'নতুন আবেদন এন্ট্রি করুন',
          'desc': 'গ্রাহকের প্রথম আবেদন এন্ট্রি করে কাজের ধরন ও চুক্তি ফি নির্ধারণ করুন।',
          'color': AppColors.primary,
        },
        {
          'icon': Icons.account_balance_wallet_outlined,
          'title': 'দৈনন্দিন আয় ও খরচের হিসাব',
          'desc': 'দোকান ও আবেদনের প্রতিটি খরচ ও পেমেন্ট লিপিবদ্ধ করলে স্বয়ংক্রিয়ভাবে আর্থিক ইনকামের হিসাব তৈরি হবে।',
          'color': AppColors.emerald,
        },
        {
          'icon': Icons.verified_user_outlined,
          'title': 'সুরক্ষিত অফলাইন ব্যাকআপ',
          'desc': 'প্রতিদিনের কাজের শেষে সেটিংস থেকে ফোনে বা টেলিগ্রামে ব্যাকআপ নিয়ে রাখুন।',
          'color': AppColors.amberDark,
        },
      ]);
    }

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
