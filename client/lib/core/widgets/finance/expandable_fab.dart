import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Expandable Floating Action Button with animated speed dial & glowing gradient
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({super.key});

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          _buildActionButton(
            label: 'WhatsApp AI Chatbot',
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF25D366),
            textColor: Colors.white,
            onPressed: () {
              _toggle();
              Navigator.pushNamed(context, '/whatsapp-chatbot');
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Transfer Funds / Drawings',
            icon: Icons.swap_horiz_rounded,
            color: AppColors.primaryGreen,
            textColor: Colors.black,
            onPressed: () {
              _toggle();
              Navigator.pushNamed(context, '/fund-transfer');
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Create GST Invoice',
            icon: Icons.receipt_long_rounded,
            color: AppColors.accentCyan,
            textColor: Colors.black,
            onPressed: () {
              _toggle();
              Navigator.pushNamed(context, '/create-invoice');
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Add Customer Khata',
            icon: Icons.person_add_alt_1_rounded,
            color: AppColors.accentPurple,
            textColor: Colors.white,
            onPressed: () {
              _toggle();
              Navigator.pushNamed(context, '/add-customer');
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Add Loan / EMI',
            icon: Icons.account_balance_rounded,
            color: AppColors.accentGold,
            textColor: Colors.black,
            onPressed: () {
              _toggle();
              Navigator.pushNamed(context, '/add-loan');
            },
          ),
          const SizedBox(height: 16),
        ],
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.greenGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              customBorder: const CircleBorder(),
              child: Center(
                child: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _expandAnimation,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(icon, color: textColor, size: 19),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
