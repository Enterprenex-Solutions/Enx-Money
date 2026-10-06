import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/auth/data/auth_repository.dart';

class DeviceApprovalDialog extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onResolved;

  const DeviceApprovalDialog({
    super.key,
    required this.request,
    this.onResolved,
  });

  static Future<void> show(BuildContext context, Map<String, dynamic> request, {VoidCallback? onResolved}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeviceApprovalDialog(request: request, onResolved: onResolved),
    );
  }

  @override
  State<DeviceApprovalDialog> createState() => _DeviceApprovalDialogState();
}

class _DeviceApprovalDialogState extends State<DeviceApprovalDialog> {
  final AuthRepository _authRepo = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _approve() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestId = widget.request['id'] as String;
      final ok = await _authRepo.approveDevice(requestId);
      if (ok && mounted) {
        Navigator.of(context).pop();
        widget.onResolved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.successMint,
            content: Text('Device approved successfully.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _reject() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestId = widget.request['id'] as String;
      final ok = await _authRepo.rejectDevice(requestId);
      if (ok && mounted) {
        Navigator.of(context).pop();
        widget.onResolved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.brandNavy,
            content: Text('Device access denied.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final deviceName = req['deviceName'] ?? req['device_name'] ?? 'Unknown Device';
    final platform = req['platform'] ?? 'Mobile';
    final ipAddress = req['ipAddress'] ?? req['ip_address'] ?? 'Unknown IP';
    final verificationCode = req['verificationCode'] ?? req['verification_code'] ?? '----';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alert Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'New Device Login Request',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'A new device is attempting to log in to your account. Please verify the code below.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.brandTextSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Details Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.brandBorder),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.devices, 'Device', deviceName),
                  const SizedBox(height: 8),
                  _infoRow(Icons.system_update_alt, 'Platform', platform.toString().toUpperCase()),
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on_outlined, 'IP Address', ipAddress),
                  const Divider(height: 20, color: AppColors.brandBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verification Code',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.brandTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlueLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          verificationCode.toString(),
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandBlue),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _reject,
                      child: const Text('DENY', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _approve,
                      child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brandTextMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.brandTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
