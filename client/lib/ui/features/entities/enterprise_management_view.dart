import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/enterprise_model.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../core/empty_state_widget.dart';

class EnterpriseManagementView extends StatelessWidget {
  const EnterpriseManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TransactionRepository>();
    final enterprises = repo.enterprises;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open Sidebar',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Row(
          children: [
            Icon(Icons.domain, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Enterprises & Companies'),
          ],
        ),
      ),
      body: enterprises.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateWidget(
                  title: 'No Enterprises Added',
                  message: 'Add your business entity, GSTIN, and company details to link invoices and transactions.',
                  icon: Icons.business,
                  onAddData: () => _showAddEnterpriseDialog(context),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: enterprises.length,
              itemBuilder: (context, index) {
                final ent = enterprises[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: const Icon(Icons.business, color: Colors.indigo),
                    ),
                    title: Text(ent.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'GSTIN: ${ent.gstin}\n${ent.email ?? ""} ${ent.phone ?? ""}\n${ent.address ?? ""}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => repo.deleteEnterprise(ent.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEnterpriseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Enterprise'),
      ),
    );
  }

  void _showAddEnterpriseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String companyName = '';
    String gstin = '';
    String? email;
    String? phone;
    String? address;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Enterprise / Company'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Company Name *', prefixIcon: Icon(Icons.business)),
                  validator: (val) => val == null || val.isEmpty ? 'Enter company name' : null,
                  onSaved: (val) => companyName = val!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'GSTIN Registration Number *', prefixIcon: Icon(Icons.receipt_long)),
                  validator: (val) => val == null || val.isEmpty ? 'Enter GSTIN' : null,
                  onSaved: (val) => gstin = val!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Business Email', prefixIcon: Icon(Icons.email)),
                  onSaved: (val) => email = val?.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                  onSaved: (val) => phone = val?.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Office Address', prefixIcon: Icon(Icons.location_on)),
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
                repo.addEnterprise(
                  EnterpriseModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    companyName: companyName,
                    gstin: gstin,
                    email: email,
                    phone: phone,
                    address: address,
                    createdAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Enterprise'),
          ),
        ],
      ),
    );
  }
}
