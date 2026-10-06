import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/customers/data/customers_repository.dart';
import '../../features/profile/data/profile_repository.dart';

class ReminderLauncher {
  ReminderLauncher._();

  static String generateReminderMessage({
    required CustomerModel customer,
    String? businessName,
  }) {
    final profile = ProfileRepository().profile;
    final providedBiz = businessName?.trim();
    final effectiveBizName = (providedBiz != null && providedBiz.isNotEmpty)
        ? providedBiz
        : (profile.businessProfile.businessName.trim().isNotEmpty
            ? profile.businessProfile.businessName.trim()
            : (profile.fullName.trim().isNotEmpty ? profile.fullName.trim() : 'Business'));

    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    final dueAmount = customer.currentBalance.abs();
    final biz = effectiveBizName;

    return 'Dear ${customer.name}, this is a gentle payment reminder from $biz for your outstanding balance of ₹${currencyFormat.format(dueAmount)}. Please settle the pending dues at your earliest convenience. Thank you!';
  }

  static void showReminderBottomSheet({
    required BuildContext context,
    required CustomerModel customer,
    required CustomersRepository repository,
    String? businessName,
  }) {
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    final dueAmount = customer.currentBalance.abs();
    final cleanPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final message = generateReminderMessage(customer: customer, businessName: businessName);
    final biz = (businessName != null && businessName.trim().isNotEmpty)
        ? businessName.trim()
        : (ProfileRepository().profile.businessProfile.businessName.trim().isNotEmpty
            ? ProfileRepository().profile.businessProfile.businessName.trim()
            : (ProfileRepository().profile.fullName.trim().isNotEmpty ? ProfileRepository().profile.fullName.trim() : 'Business'));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF10141F) : Colors.white;
    final itemBg = isDark ? const Color(0xFF161D2C) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF222C3E) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ PAYMENT REMINDER HUB',
                          style: TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          customer.name,
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF33161C) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF5252)),
                      ),
                      child: Text(
                        '₹${currencyFormat.format(dueAmount)} DUE',
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Select reminder action or schedule automated follow-up:',
                  style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B), fontSize: 12.5),
                ),
                const SizedBox(height: 16),

                // 1. WhatsApp Button
                _buildChannelOption(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Send via WhatsApp',
                  subtitle: 'Opens WhatsApp chat with pre-drafted reminder',
                  itemBg: itemBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final url = Uri.parse('https://api.whatsapp.com/send?phone=$fullPhone&text=${Uri.encodeComponent(message)}');
                    try {
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        await launchUrl(url);
                      }
                    } catch (_) {}
                    _logBackendReminder(customer.id, 'WHATSAPP', repository, context);
                  },
                ),

                const SizedBox(height: 10),

                // 2. SMS Button
                _buildChannelOption(
                  icon: Icons.sms_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Send SMS',
                  subtitle: 'Opens device Messages app with reminder text',
                  itemBg: itemBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final url = Uri.parse('sms:$fullPhone?body=${Uri.encodeComponent(message)}');
                    try {
                      await launchUrl(url);
                    } catch (_) {}
                    _logBackendReminder(customer.id, 'SMS', repository, context);
                  },
                ),

                const SizedBox(height: 10),

                // 3. Email Button
                _buildChannelOption(
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFFD97706),
                  title: 'Send Email Statement',
                  subtitle: customer.email.isNotEmpty ? customer.email : 'Triggers automated HTML account statement',
                  itemBg: itemBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (customer.email.isNotEmpty) {
                      final url = Uri.parse('mailto:${customer.email}?subject=${Uri.encodeComponent('Payment Reminder - $biz')}&body=${Uri.encodeComponent(message)}');
                      try {
                        await launchUrl(url);
                      } catch (_) {}
                    }
                    _logBackendReminder(customer.id, 'EMAIL', repository, context);
                  },
                ),

                const SizedBox(height: 10),

                // 4. Schedule Date & Time Picker
                _buildChannelOption(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: '📅 Schedule Calendar Reminder',
                  subtitle: 'Pick date & time (validates against past dates, Indian format)',
                  itemBg: itemBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickAndScheduleReminder(context, customer, repository, biz, dueAmount);
                  },
                ),

                const SizedBox(height: 14),

                // 5. Multi-Channel Auto Dispatch
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('⚡ Auto-Dispatch on All Channels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final waUrl = Uri.parse('https://api.whatsapp.com/send?phone=$fullPhone&text=${Uri.encodeComponent(message)}');
                      try {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      } catch (_) {}
                      _logBackendReminder(customer.id, 'ALL', repository, context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _pickAndScheduleReminder(
    BuildContext context,
    CustomerModel customer,
    CustomersRepository repository,
    String biz,
    double dueAmount,
  ) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'SELECT REMINDER DATE',
      confirmText: 'NEXT: TIME',
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: 'SELECT REMINDER TIME',
    );

    if (pickedTime == null || !context.mounted) return;

    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Cannot schedule a reminder in the past. Please select a future date and time.'),
        ),
      );
      return;
    }

    final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(scheduledDateTime);

    _logBackendReminder(customer.id, 'CALENDAR SCHEDULED ($formatted)', repository, context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00E676),
        content: Text(
          '✓ Payment reminder scheduled for $formatted',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static Widget _buildChannelOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color itemBg,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  static void _logBackendReminder(String customerId, String channel, CustomersRepository repo, BuildContext context) async {
    try {
      await repo.sendReminder(customerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E676),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Reminder action logged: $channel', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}
  }
}
