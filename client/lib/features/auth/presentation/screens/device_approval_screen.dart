import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../data/auth_repository.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';

class DeviceApprovalScreen extends StatefulWidget {
  final String approvalRequestId;
  final String verificationCode;
  final String deviceName;
  final String identifier;

  const DeviceApprovalScreen({
    super.key,
    required this.approvalRequestId,
    required this.verificationCode,
    required this.deviceName,
    required this.identifier,
  });

  @override
  State<DeviceApprovalScreen> createState() => _DeviceApprovalScreenState();
}

class _DeviceApprovalScreenState extends State<DeviceApprovalScreen> with SingleTickerProviderStateMixin {
  final AuthRepository _authRepo = AuthRepository();
  Timer? _pollingTimer;
  bool _isChecking = false;
  String? _errorMessage;
  bool _isApproved = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start polling every 2.5 seconds
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_isChecking || !mounted || _isApproved) return;
    _isChecking = true;

    try {
      final res = await _authRepo.checkDeviceApprovalStatus(widget.approvalRequestId);
      final status = res['status'] as String?;

      if (!mounted) return;

      if (status == 'APPROVED') {
        _pollingTimer?.cancel();
        setState(() {
          _isApproved = true;
          _errorMessage = null;
        });

        // Small delay to show success celebration
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShellScreen()),
            (route) => false,
          );
        }
      } else if (status == 'REJECTED') {
        _pollingTimer?.cancel();
        setState(() {
          _errorMessage = 'Access denied: The primary device rejected this login request.';
        });
      } else if (status == 'EXPIRED') {
        _pollingTimer?.cancel();
        setState(() {
          _errorMessage = 'Approval request expired. Please try signing in again.';
        });
      }
    } catch (_) {
      // Ignore transient network errors during poll
    } finally {
      _isChecking = false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codeDigits = widget.verificationCode.padLeft(4, '0').split('');

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brandNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'DEVICE APPROVAL',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.brandNavy,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Shield Icon with Brand Pulse
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isApproved ? AppColors.successMint.withValues(alpha: 0.12) : AppColors.brandBlueLight,
                    border: Border.all(
                      color: _isApproved ? AppColors.successMint : AppColors.brandBlue,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isApproved ? AppColors.successMint : AppColors.brandBlue).withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isApproved
                        ? Icons.check_circle_outline_rounded
                        : Icons.security_rounded,
                    size: 48,
                    color: _isApproved ? AppColors.successMint : AppColors.brandBlue,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                _isApproved ? 'Device Approved!' : 'Permission Required',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                _isApproved
                    ? 'Connecting your account securely...'
                    : 'This account is active on another device. Please approve this new device login request on your primary device.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.brandTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Verification Code Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brandBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'MATCHING VERIFICATION CODE',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.brandTextMuted,
                        letterSpacing: 1.5,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: codeDigits.map((digit) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 52,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.brandBlueLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit,
                            style: AppTypography.displaySmall.copyWith(
                              color: AppColors.brandNavy,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm that this code matches the prompt on your primary device.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.brandTextSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Security notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brandBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: AppColors.brandBlue, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A security notification and login alert email was sent to ${widget.identifier}. You can also approve access from your registered email alert.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.brandNavy,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              if (_errorMessage != null) ...[
                PrimaryButton(
                  text: 'TRY AGAIN',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ] else ...[
                // Loading status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandBlue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for permission...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SecondaryButton(
                  text: 'CANCEL LOGIN',
                  onPressed: () => Navigator.of(context).pop(),
                  borderColor: AppColors.brandBorder,
                  textColor: AppColors.brandNavy,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
