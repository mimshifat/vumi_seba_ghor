import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/app_typography.dart';
import '../core/utils/responsive.dart';
import 'applications/presentation/screens/application_list_screen.dart';
import 'backup/presentation/providers/backup_providers.dart';
import 'dashboard/presentation/screens/dashboard_screen.dart';
import 'dashboard/presentation/screens/more_menu_screen.dart';
import 'finance/presentation/screens/financial_overview_screen.dart';
import 'reports/presentation/screens/reports_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // অ্যাপ চালু হলে ব্যাকগ্রাউন্ডে দৈনিক অটো ব্যাকআপ যাচাই ও সম্পাদন
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupControllerProvider.notifier).checkAndRunDailyTelegramBackup();
    });
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isWide;

    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const ApplicationListScreen(),
      const FinancialOverviewScreen(),
      const ReportsScreen(),
      const MoreMenuScreen(),
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // ডেস্কটপ বাম সাইডবার
            _DesktopSidebar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            // মূল কন্টেন্ট এরিয়া
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    // মোবাইল ভিউ (আগের স্বাভাবিক রূপ)
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.slate400,
          selectedLabelStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
          unselectedLabelStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11.5,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'ড্যাশবোর্ড',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'আবেদন',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'হিসাব',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'বিশ্লেষণ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'মেনু',
            ),
          ],
        ),
      ),
    );
  }
}

/// আধুনিক ডেস্কটপ বাম সাইডবার উইজেট
class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ব্র্যান্ড হেডার
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(15, 23, 42, 0.06),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.asset(
                      AppStrings.appLogo,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ভূমি সেবা ও হিসাব ব্যবস্থাপনা',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.slate500,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // সেকশন লেবেল
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(
              'মূল নেভিগেশন',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.slate400,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // নেভিগেশন আইটেম লিস্ট
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItemTile(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'ড্যাশবোর্ড',
                  isSelected: currentIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                _SidebarItemTile(
                  icon: Icons.description_outlined,
                  activeIcon: Icons.description,
                  title: 'আবেদন সমূহ',
                  isSelected: currentIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
                _SidebarItemTile(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  title: 'টাকার হিসাব',
                  isSelected: currentIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
                _SidebarItemTile(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  title: 'রিপোর্ট ও বিশ্লেষণ',
                  isSelected: currentIndex == 3,
                  onTap: () => onTabSelected(3),
                ),
                _SidebarItemTile(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                  title: 'সেটিংস ও মেনু',
                  isSelected: currentIndex == 4,
                  onTap: () => onTabSelected(4),
                ),
              ],
            ),
          ),

          // নিচের স্ট্যাটাস / ইনফো কার্ড
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'অফলাইন সুরক্ষিত',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'স্বয়ংক্রিয় ব্যাকআপ সক্রিয়',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
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
}

/// সাইডবারের সিঙ্গেল আইটেম বাটন
class _SidebarItemTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItemTile({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          hoverColor: isSelected ? AppColors.primarySurface : AppColors.slate100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.slate600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? AppColors.primary : AppColors.slate700,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
