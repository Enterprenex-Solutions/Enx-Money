import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/transactions_repository.dart';
import '../../models/transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionsRepository _txRepo = TransactionsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<TransactionItem> _transactions = [];
  TransactionCategory? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final txs = await _txRepo.getTransactions(
      category: _selectedCategory,
      query: _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _transactions = txs;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(TransactionCategory? category) {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    _loadTransactions();
  }

  void _showTransactionDetails(TransactionItem tx) {
    final isCredit = tx.type == TransactionType.credit;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tx.status,
                  style: AppTypography.badge.copyWith(
                    color: AppColors.primaryGreen,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${isCredit ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                style: AppTypography.currencyLarge.copyWith(
                  color: isCredit ? AppColors.primaryGreen : AppColors.pureWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tx.title,
                style: AppTypography.titleMedium,
              ),
              Text(
                tx.subtitle,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Transaction ID', tx.id.toUpperCase()),
              _buildDetailRow('Payment Mode', tx.paymentMethod ?? 'ENX Direct Pay'),
              _buildDetailRow('Timestamp', '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year} • ${tx.dateTime.hour}:${tx.dateTime.minute.toString().padLeft(2, '0')}'),
              if (tx.cashbackEarned != null)
                _buildDetailRow('Cashback Earned', tx.cashbackEarned!, isHighlight: true),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: isHighlight ? AppColors.primaryGreen : AppColors.pureWhite,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FintechAppBar(
        title: 'Passbook & Expenses',
        subtitle: 'WALNUT INTELLIGENCE',
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: FintechTextField(
              controller: _searchController,
              hintText: 'Search merchant, UPI ID, category...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
              onChanged: (val) => _loadTransactions(),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('All Categories', null),
                _buildFilterChip('Shopping', TransactionCategory.shopping),
                _buildFilterChip('Food', TransactionCategory.food),
                _buildFilterChip('Investments', TransactionCategory.investment),
                _buildFilterChip('Salary', TransactionCategory.salary),
                _buildFilterChip('Travel', TransactionCategory.travel),
                _buildFilterChip('Utilities', TransactionCategory.utilities),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _transactions.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions found',
                          style: AppTypography.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isCredit = tx.type == TransactionType.credit;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FintechCard(
                              onTap: () => _showTransactionDetails(tx),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCredit
                                          ? AppColors.primaryGreen.withValues(alpha: 0.12)
                                          : AppColors.surfaceElevated,
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(tx.category),
                                      size: 20,
                                      color: isCredit ? AppColors.primaryGreen : AppColors.pureWhite,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: AppTypography.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${tx.paymentMethod ?? 'ENX'} • ${tx.subtitle}',
                                          style: AppTypography.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isCredit ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                                        style: AppTypography.currencySmall.copyWith(
                                          color: isCredit ? AppColors.primaryGreen : AppColors.pureWhite,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (tx.cashbackEarned != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '+${tx.cashbackEarned} cashback',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.primaryGreen,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionCategory? category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: AppTypography.badge.copyWith(
            color: isSelected ? AppColors.background : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(category),
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primaryGreen,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.shopping:
        return Icons.shopping_bag_outlined;
      case TransactionCategory.food:
        return Icons.restaurant_outlined;
      case TransactionCategory.investment:
        return Icons.trending_up_rounded;
      case TransactionCategory.salary:
        return Icons.payments_outlined;
      case TransactionCategory.travel:
        return Icons.flight_outlined;
      case TransactionCategory.utilities:
        return Icons.bolt_outlined;
      case TransactionCategory.entertainment:
        return Icons.movie_outlined;
      case TransactionCategory.transfer:
        return Icons.swap_horiz_rounded;
    }
  }
}
