import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/excel_exporter.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../core/empty_state_widget.dart';

class CustomerManagementView extends StatelessWidget {
  const CustomerManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final customers = repo.customers;
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
            Icon(Icons.people, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Customer Management'),
          ],
        ),
      ),
      body: customers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateWidget(
                  title: 'No Customers Added',
                  message: 'Add customer profiles to track sales, invoices, and outstanding receivables balance.',
                  icon: Icons.person_add,
                  onAddData: () => _showAddCustomerDialog(context),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final cust = customers[index];
                final custTxns = repo.allTransactions.where((t) => t.customerId == cust.id).toList();

                return Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${cust.companyName ?? "Individual"} • Balance: ${currencyFormatter.format(cust.outstandingBalance)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.table_chart, color: Colors.green),
                          tooltip: 'Export Customer Excel',
                          onPressed: () {
                            ExcelExporter.exportCustomerManagementExcel(
                              customer: cust,
                              customerTransactions: custTxns,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => repo.deleteCustomer(cust.id),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone: ${cust.phone ?? "N/A"}'),
                            Text('Email: ${cust.email ?? "N/A"}'),
                            Text('Address: ${cust.address ?? "N/A"}'),
                            const SizedBox(height: 8),
                            Text('Total Invoiced: ${currencyFormatter.format(cust.totalInvoiced)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('Outstanding Receivable: ${currencyFormatter.format(cust.outstandingBalance)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                ExcelExporter.exportCustomerManagementExcel(
                                  customer: cust,
                                  customerTransactions: custTxns,
                                );
                              },
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Export Customer Excel Ledger'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String? companyName;
    String? phone;
    String? email;
    String? address;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Customer'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person)),
                  validator: (val) => val == null || val.isEmpty ? 'Enter customer name' : null,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Company / Business Name', prefixIcon: Icon(Icons.business)),
                  onSaved: (val) => companyName = val?.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                  onSaved: (val) => phone = val?.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                  onSaved: (val) => email = val?.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                  onSaved: (val) => address = val?.trim(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final repo = context.read<TransactionRepository>();
                repo.addCustomer(
                  CustomerModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    companyName: companyName,
                    phone: phone,
                    email: email,
                    address: address,
                    createdAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }
}
