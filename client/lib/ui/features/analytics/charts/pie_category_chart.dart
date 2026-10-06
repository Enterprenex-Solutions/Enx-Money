import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieCategoryChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final Function(String category)? onCategoryTap;

  const PieCategoryChart({
    super.key,
    required this.categoryData,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const Center(
        child: Text('No category breakdown available.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    final total = categoryData.values.fold(0.0, (sum, val) => sum + val);
    final colors = [
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
    ];

    int colorIndex = 0;
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    categoryData.forEach((category, value) {
      final percentage = (value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      legendItems.add(
        InkWell(
          onTap: () => onCategoryTap?.call(category),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: legendItems,
        ),
      ],
    );
  }
}
