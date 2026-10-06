import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../finance_mode/finance_mode_service.dart';
import '../theme/theme_controller.dart';
import '../../features/auth/data/auth_repository.dart';

/// Interactive menu item specification for ENX Money Sidebar
class SidebarMenuItem {
  final String key;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String? badge;
  final Color? badgeColor;
  final String route;
  final String? tooltip;

  const SidebarMenuItem({
    required this.key,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.badge,
    this.badgeColor,
    this.tooltip,
  });
}

/// Unified Luxury Fintech Sidebar for ENX Money
class AppSidebar extends StatefulWidget {
  final String activeKey;
  final ValueChanged<String>? onSelectMenuItem;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onCloseDrawer;

  const AppSidebar({
    super.key,
    this.activeKey = 'dashboard',
    this.onSelectMenuItem,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onCloseDrawer,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final ScrollController _scrollController = ScrollController();
  final AuthRepository _authRepo = AuthRepository();
  final FinanceModeService _financeModeService = FinanceModeService.instance;

  String _hoveredItemKey = '';

  // 1. BUSINESS FINANCE MENU ITEMS
  final List<SidebarMenuItem> _businessItems = const [
    SidebarMenuItem(
      key: 'dashboard',
      title: 'Business Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      route: '/home',
      tooltip: 'Live business revenue, receivables & profit',
    ),
    SidebarMenuItem(
      key: 'customers',
      title: 'Customers & Khata',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      route: '/customers',
      badge: 'Live',
      badgeColor: AppColors.primaryGreen,
      tooltip: 'Customer ledger, dues & payment tracking',
    ),
    SidebarMenuItem(
      key: 'suppliers',
      title: 'Suppliers & Purchases',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      route: '/suppliers',
      tooltip: 'Vendor accounts & procurement bills',
    ),
    SidebarMenuItem(
      key: 'expenses',
      title: 'Expenses',
      icon: Icons.receipt_outlined,
      selectedIcon: Icons.receipt_rounded,
      route: '/expenses',
      tooltip: 'Operating expenses, vendor vouchers & bills',
    ),
    SidebarMenuItem(
      key: 'invoices',
      title: 'GST Invoicing',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      route: '/invoices',
      badge: 'GST',
      badgeColor: Color(0xFF6C63FF),
      tooltip: 'CGST, SGST, IGST tax invoice generator',
    ),
    SidebarMenuItem(
      key: 'inventory',
      title: 'Inventory & Stock',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      route: '/inventory',
      tooltip: 'Products catalog, stock in/out & valuation',
    ),
    SidebarMenuItem(
      key: 'business_banking',
      title: 'Business Accounts',
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance_rounded,
      route: '/business-banking',
      tooltip: 'Current accounts, cash reserves & bank balance',
    ),
    SidebarMenuItem(
      key: 'fund_transfer',
      title: 'Fund Transfer',
      icon: Icons.swap_horiz_rounded,
      selectedIcon: Icons.swap_horizontal_circle_rounded,
      route: '/fund-transfer',
      tooltip: 'Atomic drawings & capital contributions',
    ),
    SidebarMenuItem(
      key: 'loans',
      title: 'Loans & EMI Hub',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      route: '/loans',
      tooltip: 'Business borrowings & amortization schedules',
    ),
    SidebarMenuItem(
      key: 'analytics',
      title: 'Analytics & Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      route: '/analytics',
      tooltip: 'P&L, cash flow trends & drill-downs',
    ),
    SidebarMenuItem(
      key: 'compliance',
      title: 'Compliance Center',
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user_rounded,
      route: '/compliance-center',
      badge: 'Sec 21',
      badgeColor: Color(0xFFFF9800),
      tooltip: 'Data lineage, retention schedule & audit logs',
    ),
    SidebarMenuItem(
      key: 'meta_ai',
      title: 'Meta AI & Live Chat',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome_rounded,
      route: '/meta-ai',
      badge: 'Live',
      badgeColor: Color(0xFF00E676),
      tooltip: 'Real-time AI advisor powered by Meta Llama & Gemini',
    ),
    SidebarMenuItem(
      key: 'whatsapp_chatbot',
      title: 'WhatsApp Chatbot',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      route: '/whatsapp-chatbot',
      badge: 'AI BOT',
      badgeColor: Color(0xFF00A884),
      tooltip: 'Real-time WhatsApp bookkeeping & AI assistant',
    ),
    SidebarMenuItem(
      key: 'consolidated',
      title: 'Consolidated Wealth',
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
      route: '/consolidated-dashboard',
      tooltip: 'Combined business & personal net worth',
    ),
    SidebarMenuItem(
      key: 'devices',
      title: 'Connected Devices',
      icon: Icons.devices_outlined,
      selectedIcon: Icons.devices_rounded,
      route: '/devices',
      badge: 'Security',
      badgeColor: AppColors.brandBlue,
      tooltip: 'Manage authorized devices and login permissions',
    ),
    SidebarMenuItem(
      key: 'subscription',
      title: 'Plans & Billing',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
      route: '/billing',
      badge: 'PRO',
      badgeColor: Color(0xFF6366F1),
      tooltip: 'Manage subscriptions, plans & GST invoices',
    ),
  ];

  // 2. PERSONAL FINANCE MENU ITEMS
  final List<SidebarMenuItem> _personalItems = const [
    SidebarMenuItem(
      key: 'personal_dashboard',
      title: 'Personal Dashboard',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: '/personal-dashboard',
      tooltip: 'Personal income, spends & net savings',
    ),
    SidebarMenuItem(
      key: 'account_setup',
      title: 'Savings & Wallets',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      route: '/account-setup',
      tooltip: 'Personal bank accounts and cash on hand',
    ),
    SidebarMenuItem(
      key: 'personal_expenses',
      title: 'Personal Expenses',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      route: '/personal-expenses',
      tooltip: 'Categorized living expenses & bills',
    ),
    SidebarMenuItem(
      key: 'personal_budget',
      title: 'Personal Budget',
      icon: Icons.donut_large_outlined,
      selectedIcon: Icons.donut_large_rounded,
      route: '/personal-budget',
      tooltip: 'Monthly spending limits & alerts',
    ),
    SidebarMenuItem(
      key: 'financial_goals',
      title: 'Financial Goals',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
      route: '/financial-goals',
      tooltip: 'Savings goals, emergency fund & milestones',
    ),
    SidebarMenuItem(
      key: 'personal_analytics',
      title: 'Personal Analytics',
      icon: Icons.insights_rounded,
      selectedIcon: Icons.insights_rounded,
      route: '/personal-analytics',
      tooltip: 'Income vs expense breakdown & velocity',
    ),
    SidebarMenuItem(
      key: 'fund_transfer_p',
      title: 'Transfer to Business',
      icon: Icons.swap_horiz_rounded,
      selectedIcon: Icons.swap_horizontal_circle_rounded,
      route: '/fund-transfer',
      tooltip: 'Inject funds into business accounts',
    ),
    SidebarMenuItem(
      key: 'loans_p',
      title: 'Personal Loans & EMI',
      icon: Icons.request_quote_outlined,
      selectedIcon: Icons.request_quote_rounded,
      route: '/loans',
      tooltip: 'Home, vehicle & personal loan tracking',
    ),
    SidebarMenuItem(
      key: 'devices_p',
      title: 'Connected Devices',
      icon: Icons.devices_outlined,
      selectedIcon: Icons.devices_rounded,
      route: '/devices',
      badge: 'Security',
      badgeColor: AppColors.brandBlue,
      tooltip: 'Manage authorized devices and login permissions',
    ),
    SidebarMenuItem(
      key: 'subscription_p',
      title: 'Plans & Billing',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
      route: '/billing',
      badge: 'PRO',
      badgeColor: Color(0xFF6366F1),
      tooltip: 'Manage subscriptions, plans & GST invoices',
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNavigation(SidebarMenuItem item) {
    if (widget.onCloseDrawer != null) {
      widget.onCloseDrawer!();
    }
    if (widget.onSelectMenuItem != null) {
      widget.onSelectMenuItem!(item.key);
    }
    Navigator.pushNamed(context, item.route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusiness = _financeModeService.currentMode == FinanceMode.business;
    final activeList = isBusiness ? _businessItems : _personalItems;
    final user = _authRepo.currentUser;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF10141D) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header: Brand & Pro Badge
            _buildBrandHeader(context, isDark, isBusiness),

            const Divider(height: 1, color: Color(0xFF1E2638)),

            // Finance Mode Switcher Banner
            _buildFinanceModeBanner(context, isDark, isBusiness),

            // Navigation Menu Items
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: activeList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = activeList[index];
                  final isSelected = widget.activeKey == item.key;
                  final isHovered = _hoveredItemKey == item.key;

                  return InkWell(
                    onTap: () => _handleNavigation(item),
                    onHover: (hovering) {
                      setState(() {
                        _hoveredItemKey = hovering ? item.key : '';
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen.withValues(alpha: 0.15)
                            : (isHovered ? const Color(0xFF1C2436) : Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : (isDark ? const Color(0xFF8E9BAE) : const Color(0xFF4A5568)),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : (isDark ? Colors.white : Colors.black87),
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (item.badgeColor ?? AppColors.primaryGreen).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (item.badgeColor ?? AppColors.primaryGreen).withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: item.badgeColor ?? AppColors.primaryGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1E2638)),

            // Footer: User Profile, Theme & Logout
            _buildFooter(context, isDark, user),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context, bool isDark, bool isBusiness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryGreen,
                  child: const Center(
                    child: Text('ENX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENX Money',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  isBusiness ? 'Business Operations Mode' : 'Personal Wealth Mode',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF8E9BAE) : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onCloseDrawer != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: widget.onCloseDrawer,
            ),
        ],
      ),
    );
  }

  Widget _buildFinanceModeBanner(BuildContext context, bool isDark, bool isBusiness) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C28) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isBusiness ? AppColors.primaryGreen : const Color(0xFF6C63FF)).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBusiness ? Icons.business_center_rounded : Icons.account_balance_wallet_rounded,
            size: 18,
            color: isBusiness ? AppColors.primaryGreen : const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isBusiness ? 'Mode: Business Finance' : 'Mode: Personal Finance',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              _financeModeService.toggleMode();
              setState(() {});
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Switch',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isBusiness ? const Color(0xFF6C63FF) : AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                child: Text(
                  user?.name != null && user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : 'E',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'ENX User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      user?.email ?? 'user@enxmoney.com',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF8E9BAE) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Theme Toggle
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF8E9BAE) : const Color(0xFF4A5568),
                ),
                tooltip: 'Toggle Theme',
                onPressed: () => ThemeController().toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Connected Devices Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (widget.onCloseDrawer != null) {
                  widget.onCloseDrawer!();
                }
                Navigator.pushNamed(context, '/devices');
              },
              icon: const Icon(Icons.devices_rounded, size: 16, color: AppColors.brandBlue),
              label: const Text('Connected Devices', style: TextStyle(color: AppColors.brandBlue, fontSize: 12, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.brandBlue.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _authRepo.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFFF5252)),
              label: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF5252), fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x33FF5252)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
