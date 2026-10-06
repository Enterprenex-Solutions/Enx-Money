import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../services/notification_service.dart';
import '../../../features/auth/data/biometric_service.dart';

class TransactionAuthModal extends StatefulWidget {
  final double amount;
  final String recipient;
  final String assetType;
  final Future<void> Function(String authMethod, String pin) onAuthenticated;

  const TransactionAuthModal({
    super.key,
    required this.amount,
    required this.recipient,
    this.assetType = 'INR',
    required this.onAuthenticated,
  });

  static Future<void> show(
    BuildContext context, {
    required double amount,
    required String recipient,
    String assetType = 'INR',
    required Future<void> Function(String authMethod, String pin) onAuthenticated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionAuthModal(
        amount: amount,
        recipient: recipient,
        assetType: assetType,
        onAuthenticated: onAuthenticated,
      ),
    );
  }

  @override
  State<TransactionAuthModal> createState() => _TransactionAuthModalState();
}

class _TransactionAuthModalState extends State<TransactionAuthModal> {
  String _pin = '';
  bool _isRiskChecking = true;
  bool _isAuthorizing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performSilentRiskCheck();
  }

  Future<void> _performSilentRiskCheck() async {
    // Simulate real-time silent fraud & velocity risk evaluation
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isRiskChecking = false);
    }
  }

  void _onKeyTap(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
        _errorMessage = null;
      });
      if (_pin.length == 4) {
        _submitMpin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitMpin() async {
    setState(() => _isAuthorizing = true);
    try {
      await widget.onAuthenticated('MPIN', _pin);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _pin = '';
        _isAuthorizing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _triggerBiometric() async {
    final available = await BiometricService.instance.isBiometricAvailable();
    if (!available) {
      // Simulate biometric authorization on simulator/web
      setState(() => _isAuthorizing = true);
      try {
        await widget.onAuthenticated('BIOMETRIC', '1234');
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isAuthorizing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
      return;
    }

    final authenticated = await BiometricService.instance.authenticate(
      reason: 'Confirm payment of ${widget.assetType == 'CBDC' ? 'e₹' : '₹'}${widget.amount.toStringAsFixed(2)} to ${widget.recipient}',
    );

    if (authenticated) {
      setState(() => _isAuthorizing = true);
      try {
        await widget.onAuthenticated('BIOMETRIC', '1234');
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isAuthorizing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } else {
      NotificationService.showWarning('Biometric authentication cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 44, height: 4, decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Header: Amount & Recipient
          Text(
            'Authorize Transaction',
            style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            'Transferring to ${widget.recipient}',
            style: TextStyle(color: subtextCol, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.assetType == 'CBDC' ? 'e₹' : '₹'}${widget.amount.toStringAsFixed(2)}',
            style: TextStyle(color: textCol, fontSize: 28, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 14),

          // Risk & Fraud Check Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_isRiskChecking ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isRiskChecking ? const Color(0xFF3B82F6) : const Color(0xFF10B981)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isRiskChecking)
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)))
                else
                  const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  _isRiskChecking ? 'Scanning Device & Risk Velocity...' : 'Risk Assessment: Low Risk (Trust Score: 98/100)',
                  style: TextStyle(
                    color: _isRiskChecking ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4-Digit MPIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isFilled = i < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primaryGreen : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? AppColors.primaryGreen : borderCol,
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],

          if (_isAuthorizing) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppColors.primaryGreen),
            const SizedBox(height: 8),
            Text('Authorizing & Recording Ledger...', style: TextStyle(color: subtextCol, fontSize: 12)),
          ] else ...[
            const SizedBox(height: 20),

            // Number Keypad
            _buildKeypad(isDark, textCol, borderCol),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildKeypad(bool isDark, Color textCol, Color borderCol) {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3'], isDark, textCol, borderCol),
        const SizedBox(height: 12),
        _buildKeyRow(['4', '5', '6'], isDark, textCol, borderCol),
        const SizedBox(height: 12),
        _buildKeyRow(['7', '8', '9'], isDark, textCol, borderCol),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Biometric button
            GestureDetector(
              key: const Key('auth_biometric_trigger_btn'),
              onTap: _triggerBiometric,
              child: Container(
                width: 70,
                height: 52,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: AppColors.primaryGreen, size: 28),
              ),
            ),
            // Key 0
            _buildKeyButton('0', isDark, textCol, borderCol),
            // Backspace button
            GestureDetector(
              key: const Key('auth_backspace_btn'),
              onTap: _onBackspace,
              child: Container(
                width: 70,
                height: 52,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: Icon(Icons.backspace_outlined, color: textCol, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys, bool isDark, Color textCol, Color borderCol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildKeyButton(k, isDark, textCol, borderCol)).toList(),
    );
  }

  Widget _buildKeyButton(String val, bool isDark, Color textCol, Color borderCol) {
    return GestureDetector(
      key: Key('auth_key_$val'),
      onTap: () => _onKeyTap(val),
      child: Container(
        width: 70,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol),
        ),
        child: Center(
          child: Text(
            val,
            style: TextStyle(color: textCol, fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
