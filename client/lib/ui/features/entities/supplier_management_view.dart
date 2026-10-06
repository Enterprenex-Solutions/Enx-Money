import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/supplier_model.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../core/empty_state_widget.dart';

class SupplierManagementView extends StatelessWidget {
  const SupplierManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final suppliers = repo.suppliers;
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
            Icon(Icons.storefront_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Suppliers & Vendors'),
          ],
        ),
      ),
      body: suppliers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateWidget(
                  title: 'No Suppliers Added',
                  message: 'Add vendor & supplier accounts to track procurement bills and outstanding payables.',
                  icon: Icons.storefront_outlined,
                  onAddData: () => _showAddSupplierDialog(context),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supp = suppliers[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: const Icon(Icons.store, color: Colors.amber),
                    ),
                    title: Text(supp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${supp.category} • Payables: ${currencyFormatter.format(supp.outstandingPayable)}\nPhone: ${supp.phone ?? "-"}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => repo.deleteSupplier(supp.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplierDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String category = 'General Vendor';
    String? companyName;
    String? phone;
    String? email;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Supplier / Vendor'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Supplier / Vendor Name *', prefixIcon: Icon(Icons.person)),
                  validator: (val) => val == null || val.isEmpty ? 'Enter supplier name' : null,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Vendor Category (e.g. Hardware, Cloud)', prefixIcon: Icon(Icons.category)),
                  onSaved: (val) => category = (val != null && val.isNotEmpty) ? val.trim() : 'General Vendor',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Company Name', prefixIcon: Icon(Icons.business)),
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
                repo.addSupplier(
                  SupplierModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    companyName: companyName,
                    category: category,
                    phone: phone,
                    email: email,
                    createdAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );
  }
}
