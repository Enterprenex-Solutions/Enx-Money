import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../core/date_filter_bar.dart';
import 'charts/bar_sales_chart.dart';
import 'charts/line_trend_chart.dart';
import 'charts/pie_category_chart.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open Sidebar',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Row(
          children: [
            Icon(Icons.donut_small, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Advanced Analytics'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DateFilterBar(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Donut / Pie Category Breakdown
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Chip(
                                label: Text(repo.currentProfile.label, style: const TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PieCategoryChart(
                            categoryData: repo.categoryBreakdown,
                            onCategoryTap: (cat) => repo.setCategoryFilter(cat),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Line Trend Cash Flow
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cash Flow Trend (Inflow vs Outflow)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          LineTrendChart(dailyTrend: repo.dailyTrend),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bar Comparison
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Revenue vs Expense Bar Comparison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          BarSalesChart(dailyTrend: repo.dailyTrend),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
