import 'package:flutter/material.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'package:provider/provider.dart';

class DateFilterBar extends StatelessWidget {
  const DateFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final theme = Theme.of(context);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: DateFilterOption.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = DateFilterOption.values[index];
          final isSelected = repo.dateFilter == option;

          return FilterChip(
            selected: isSelected,
            label: Text(option.label),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            ),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.cardTheme.color,
            side: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
            ),
            showCheckmark: false,
            onSelected: (_) async {
              if (option == DateFilterOption.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: repo.customDateRange ??
                      DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 30)),
                        end: DateTime.now(),
                      ),
                );
                if (range != null) {
                  repo.setDateFilter(DateFilterOption.custom, customRange: range);
                }
              } else {
                repo.setDateFilter(option);
              }
            },
          );
        },
      ),
    );
  }
}
