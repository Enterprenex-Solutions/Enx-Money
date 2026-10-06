import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../suppliers/presentation/screens/suppliers_screen.dart';
import '../../../analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;
  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomersScreen(),
    SuppliersScreen(),
    AnalyticsDashboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppSidebar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
