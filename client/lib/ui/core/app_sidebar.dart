import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/transaction_repository.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int index) onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final isBusiness = repo.currentProfile == ProfileType.business;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0D1B3E) : Colors.white,
      child: Column(
        children: [
          // ── Gradient Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B3E), Color(0xFF1565C0), Color(0xFF2979FF)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo Image — large, centered, fills sidebar width
                    Container(
                      width: double.infinity,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/enx_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF1565C0),
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Enx money',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Expenses tracker app',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Profile Switcher
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ProfileType.values.map((profile) {
                          final isSelected = repo.currentProfile == profile;
                          return Expanded(
                            child: InkWell(
                              onTap: () => repo.switchProfile(profile),
                              borderRadius: BorderRadius.circular(9),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      profile == ProfileType.business ? Icons.business_center : Icons.person,
                                      size: 14,
                                      color: isSelected ? const Color(0xFF1565C0) : Colors.white70,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      profile == ProfileType.business ? 'Business' : 'Personal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? const Color(0xFF1565C0) : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Navigation Items ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildNavItem(context, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(context, Icons.donut_small_outlined, Icons.donut_small, 'Analytics & Charts', 1),

                if (isBusiness) ...[
                  _buildSectionLabel('BUSINESS ENTITIES'),
                  _buildNavItem(context, Icons.domain_outlined, Icons.domain, 'Enterprises & Companies', 2),
                  _buildNavItem(context, Icons.people_outline, Icons.people, 'Customers & Receivables', 3),
                  _buildNavItem(context, Icons.local_shipping_outlined, Icons.local_shipping, 'Suppliers & Vendors', 4),
                ],

                _buildSectionLabel('AI & AUTOMATION'),
                _buildNavItem(
                  context,
                  Icons.chat_bubble_outline_rounded,
                  Icons.chat_bubble_rounded,
                  'WhatsApp Assistant',
                  7,
                  badge: 'AI BOT',
                  badgeColor: const Color(0xFF00A884),
                ),

                _buildSectionLabel('TOOLS'),
                _buildNavItem(context, Icons.list_alt_outlined, Icons.list_alt, 'Transaction Ledger', 5),
                _buildNavItem(context, Icons.description_outlined, Icons.description, 'Custom Report Builder', 6),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      repo.isDarkMode ? Icons.dark_mode : Icons.light_mode_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      repo.isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Switch(
                  value: repo.isDarkMode,
                  onChanged: (_) => repo.toggleTheme(),
                  activeThumbColor: const Color(0xFF2979FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    IconData selectedIcon,
    String title,
    int index, {
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? (badgeColor != null
                    ? badgeColor.withValues(alpha: 0.18)
                    : theme.colorScheme.primary.withValues(alpha: 0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected
                ? (badgeColor ?? theme.colorScheme.primary)
                : (badgeColor ?? Colors.grey),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? (badgeColor ?? theme.colorScheme.primary) : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? theme.colorScheme.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (badgeColor ?? theme.colorScheme.primary).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor ?? theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          onItemSelected(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}

