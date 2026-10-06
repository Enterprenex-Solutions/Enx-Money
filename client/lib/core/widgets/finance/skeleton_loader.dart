import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

/// Reusable theme-adaptive Skeleton Placeholder with smooth animation
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Color.lerp(baseColor, highlightColor, _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Personal Dashboard Multi-Card Skeleton View
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode switch placeholder
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 140, height: 16, borderRadius: 4),
              SkeletonBox(width: 110, height: 28, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 16),

          // Net worth hero card skeleton
          const SkeletonBox(width: double.infinity, height: 155, borderRadius: 16),
          const SizedBox(height: 16),

          // Top KPI metric cards skeleton
          const Row(
            children: [
              Expanded(child: SkeletonBox(height: 90, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 90, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 14),

          // Velocity card skeleton
          const SkeletonBox(width: double.infinity, height: 65, borderRadius: 16),
          const SizedBox(height: 22),

          // Accounts carousel skeleton
          const SkeletonBox(width: 180, height: 18, borderRadius: 4),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: SkeletonBox(height: 120, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 120, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 22),

          // Transactions list skeleton
          const SkeletonBox(width: 160, height: 18, borderRadius: 4),
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 60, borderRadius: 12),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 60, borderRadius: 12),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 60, borderRadius: 12),
          const SizedBox(height: 22),

          // Loans skeleton
          const SkeletonBox(width: 160, height: 18, borderRadius: 4),
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 90, borderRadius: 16),
        ],
      ),
    );
  }
}
