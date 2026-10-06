import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../core/empty_state_widget.dart';
import 'add_transaction_dialog.dart';

class TransactionListView extends StatelessWidget {
  const TransactionListView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final transactions = repo.filteredTransactions;
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open Sidebar',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Row(
          children: [
            Icon(Icons.list_alt_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Transaction Ledger'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search description, invoice, category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: repo.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => repo.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (val) => repo.setSearchQuery(val),
            ),
          ),

          // List or Empty state
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: EmptyStateWidget(
                        title: 'No Matching Transactions',
                        message: 'No transactions match your search or filter criteria. Add a transaction or reset filters.',
                        onAddData: () {
                          showDialog(
                            context: context,
                            builder: (_) => const AddTransactionDialog(),
                          );
                        },
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      final isPositive = item.type == TransactionType.revenue || item.type == TransactionType.receivable;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.15),
                            child: Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${item.category} • ${DateFormat('dd MMM yyyy').format(item.date)} • ${item.paymentMode.label}${item.invoiceNumber != null ? " • Inv: ${item.invoiceNumber}" : ""}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? "+" : "-"} ${currencyFormatter.format(item.amount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                              Text(item.type.label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddTransactionDialog(initialItem: item),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddTransactionDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}
