import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/profile_repository.dart';
import '../widgets/profile_modals.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/biometric_service.dart';
import '../../../auth/presentation/screens/security_questions_setup_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final ProfileRepository _repo = ProfileRepository();
  final AppLockService _appLockService = AppLockService.instance;
  final AuthRepository _authRepo = AuthRepository();

  // ── Change Password ──────────────────────────────────────────────────────
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;
  bool _isSavingPw = false;
  String? _pwError;

  // ── MPIN ─────────────────────────────────────────────────────────────────
  final List<String> _autoLockOptions = const [
    'Immediately',
    '1 Minute',
    '5 Minutes',
    '15 Minutes',
    '30 Minutes',
    'Never',
  ];

  // ── Biometrics ────────────────────────────────────────────────────────────
  BiometricStatus _biometricStatus = BiometricStatus.notSupported;
  bool _isBiometricSupported = false;

  // ── Save all ─────────────────────────────────────────────────────────────
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final status = await BiometricService.instance.checkBiometricStatus();
    if (mounted) {
      setState(() {
        _biometricStatus = status;
        _isBiometricSupported = (status != BiometricStatus.notSupported);
      });
      if (status == BiometricStatus.notEnrolled) {
        NotificationService.showWarning(BiometricService.notEnrolledMessage);
      }
    }
  }

  Future<void> _handleBiometricToggle(bool enable, bool isDark, bool isPinEnabled) async {
    if (enable) {
      final status = await BiometricService.instance.checkBiometricStatus();
      if (status == BiometricStatus.notSupported) {
        if (mounted) NotificationService.showError('Biometric hardware is not available on this device.');
        return;
      }
      if (status == BiometricStatus.notEnrolled) {
        if (mounted) NotificationService.showWarning(BiometricService.notEnrolledMessage);
        return;
      }

      final ok = await BiometricService.instance.authenticate(
        reason: 'Confirm your fingerprint or face to enable biometric unlock',
      );
      if (ok) {
        await _repo.updateSecurity(isBiometricEnabled: true);
        if (mounted) {
          NotificationService.showSuccess('Biometric unlock enabled!');
          setState(() {});
        }
      } else {
        if (mounted) {
          NotificationService.showError('Biometric verification failed or cancelled.');
          setState(() {});
        }
      }
    } else {
      final verified = await _showDisableBiometricChallengeDialog(
        context: context,
        isDark: isDark,
        isPinEnabled: isPinEnabled,
      );
      if (verified == true) {
        await _repo.updateSecurity(isBiometricEnabled: false);
        if (mounted) {
          NotificationService.showSuccess('Biometric unlock disabled.');
          setState(() {});
        }
      }
    }
  }

  Future<bool?> _showDisableBiometricChallengeDialog({
    required BuildContext context,
    required bool isDark,
    required bool isPinEnabled,
  }) async {
    final pinCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    bool usePassword = !isPinEnabled;
    bool obscurePw = true;
    bool isVerifying = false;
    String? errorText;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final fieldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

            return AlertDialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Disable Biometrics',
                      style: AppTypography.titleMedium.copyWith(color: textColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usePassword
                          ? 'Enter your Account Password to disable biometric unlock.'
                          : 'Enter your 4-digit MPIN to disable biometric unlock.',
                      style: AppTypography.bodySmall.copyWith(color: subColor),
                    ),
                    const SizedBox(height: 16),
                    if (!usePassword) ...[
                      TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, letterSpacing: 8, color: textColor, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '••••',
                          hintStyle: TextStyle(letterSpacing: 8, color: subColor),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onChanged: (_) {
                          if (errorText != null) {
                            setDialogState(() => errorText = null);
                          }
                        },
                      ),
                    ] else ...[
                      TextField(
                        controller: pwCtrl,
                        obscureText: obscurePw,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter your account password',
                          hintStyle: TextStyle(color: subColor),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePw ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: subColor, size: 20),
                            onPressed: () => setDialogState(() => obscurePw = !obscurePw),
                          ),
                        ),
                        onChanged: (_) {
                          if (errorText != null) {
                            setDialogState(() => errorText = null);
                          }
                        },
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!, style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                    ],
                    if (isPinEnabled) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: isVerifying
                              ? null
                              : () {
                                  setDialogState(() {
                                    usePassword = !usePassword;
                                    errorText = null;
                                  });
                                },
                          child: Text(
                            usePassword ? 'Use 4-digit MPIN instead' : 'Use Account Password instead',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: subColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (!usePassword) {
                            final pin = pinCtrl.text.trim();
                            if (pin.length != 4) {
                              setDialogState(() => errorText = 'Please enter your 4-digit MPIN.');
                              return;
                            }
                            setDialogState(() => isVerifying = true);
                            final isValid = await _appLockService.verifyPin(pin);
                            if (isValid) {
                              Navigator.pop(ctx, true);
                            } else {
                              setDialogState(() {
                                isVerifying = false;
                                errorText = 'Incorrect 4-digit MPIN. Please try again.';
                              });
                            }
                          } else {
                            final pw = pwCtrl.text;
                            if (pw.isEmpty) {
                              setDialogState(() => errorText = 'Please enter your account password.');
                              return;
                            }
                            setDialogState(() => isVerifying = true);
                            final isValid = await _authRepo.verifyPassword(pw);
                            if (isValid) {
                              Navigator.pop(ctx, true);
                            } else {
                              setDialogState(() {
                                isVerifying = false;
                                errorText = 'Incorrect account password. Please try again.';
                              });
                            }
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Disable'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Password Save ─────────────────────────────────────────────────────────
  Future<void> _handleChangePassword(bool isDark) async {
    final current = _currentPwCtrl.text.trim();
    final newPw = _newPwCtrl.text.trim();
    final confirm = _confirmPwCtrl.text.trim();

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _pwError = 'All password fields are required.');
      return;
    }
    if (newPw.length < 8) {
      setState(() => _pwError = 'New password must be at least 8 characters.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _pwError = 'New password and confirmation do not match.');
      return;
    }

    setState(() {
      _isSavingPw = true;
      _pwError = null;
    });

    try {
      await _authRepo.changePassword(
        currentPassword: current,
        newPassword: newPw,
      );
      if (!mounted) return;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      setState(() => _isSavingPw = false);
      NotificationService.showSuccess('Password updated successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingPw = false;
        _pwError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Save All Settings ─────────────────────────────────────────────────────
  Future<void> _handleSaveAll(bool isDark) async {
    // If password fields are filled, save password
    if (_currentPwCtrl.text.trim().isNotEmpty || _newPwCtrl.text.trim().isNotEmpty) {
      await _handleChangePassword(isDark);
      if (_pwError != null) return;
    }
    setState(() => _isSavingAll = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isSavingAll = false);
      NotificationService.showSuccess('Security settings saved successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_repo, _appLockService]),
      builder: (context, _) {
        final profile = _repo.profile;
        final isPinEnabled = _appLockService.isLockEnabled;
        final isBiometricEnabled = profile.isBiometricEnabled;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Theme-adaptive colors
        final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        final sectionLabelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: titleColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: titleColor),
              onPressed: () => Navigator.maybePop(context),
            ),
            centerTitle: true,
            title: Text(
              'Security & Recovery',
              style: AppTypography.titleLarge.copyWith(color: titleColor),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Change Password ─────────────────────────
                  _sectionLabel('CHANGE / RESET PASSWORD', sectionLabelColor),
                  const SizedBox(height: 10),
                  _card(
                    color: cardColor,
                    border: borderColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FintechTextField(
                          controller: _currentPwCtrl,
                          label: 'Current Password',
                          hintText: 'Enter current password',
                          obscureText: !_showCurrentPw,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showCurrentPw ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: sectionLabelColor,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _showCurrentPw = !_showCurrentPw),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                        ),
                        const SizedBox(height: 14),
                        FintechTextField(
                          controller: _newPwCtrl,
                          label: 'New Password',
                          hintText: 'Min 8 characters',
                          obscureText: !_showNewPw,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showNewPw ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: sectionLabelColor,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _showNewPw = !_showNewPw),
                          ),
                          prefixIcon: const Icon(Icons.key_rounded, size: 18),
                          onChanged: (_) => setState(() => _pwError = null),
                        ),
                        const SizedBox(height: 14),
                        FintechTextField(
                          controller: _confirmPwCtrl,
                          label: 'Confirm New Password',
                          hintText: 'Re-enter new password',
                          obscureText: !_showConfirmPw,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPw ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: sectionLabelColor,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _showConfirmPw = !_showConfirmPw),
                          ),
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          onChanged: (_) => setState(() => _pwError = null),
                        ),
                        if (_pwError != null) ...[
                          const SizedBox(height: 10),
                          _errorBanner(_pwError!, isDark),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section 2: MPIN & Biometrics ───────────────────────
                  _sectionLabel('MPIN & BIOMETRICS', sectionLabelColor),
                  const SizedBox(height: 10),
                  _card(
                    color: cardColor,
                    border: borderColor,
                    child: Column(
                      children: [
                        // MPIN toggle
                        _switchRow(
                          icon: Icons.pin_outlined,
                          title: 'Enable 4-Digit MPIN',
                          subtitle: isPinEnabled
                              ? 'Active — tap to manage or disable'
                              : 'Set a 4-digit passcode to lock the app',
                          iconColor: isPinEnabled ? AppColors.primaryGreen : sectionLabelColor,
                          value: isPinEnabled,
                          onChanged: (bool enable) {
                            if (enable) {
                              ProfileModals.showSetPinModal(
                                context,
                                onSuccess: () => setState(() {}),
                              );
                            } else {
                              ProfileModals.showDisablePinModal(
                                context,
                                onSuccess: () => setState(() {}),
                              );
                            }
                          },
                          isDark: isDark,
                          titleColor: titleColor,
                          subtitleColor: sectionLabelColor,
                        ),

                        if (isPinEnabled) ...[
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 12),

                          // Change MPIN button
                          InkWell(
                            onTap: () => ProfileModals.showChangePinModal(
                              context,
                              onSuccess: () => setState(() {}),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.primaryGreen),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Change MPIN', style: AppTypography.titleSmall.copyWith(color: titleColor)),
                                        const SizedBox(height: 2),
                                        Text('Update your 4-digit master passcode', style: AppTypography.bodySmall.copyWith(color: sectionLabelColor)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: sectionLabelColor),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 12),

                          // Auto-lock
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 20, color: AppColors.primaryGreen),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Auto-Lock App', style: AppTypography.titleSmall.copyWith(color: titleColor)),
                                    const SizedBox(height: 2),
                                    Text('Lock when app is backgrounded', style: AppTypography.bodySmall.copyWith(color: sectionLabelColor)),
                                  ],
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _autoLockOptions.contains(_appLockService.autoLockDuration)
                                      ? _appLockService.autoLockDuration
                                      : _autoLockOptions[0],
                                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: sectionLabelColor, size: 18),
                                  items: _autoLockOptions.map((opt) => DropdownMenuItem<String>(
                                    value: opt,
                                    child: Text(opt, style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      _appLockService.setAutoLockDuration(val);
                                      _repo.updateSecurity(autoLockDuration: val);
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],

                        Divider(color: borderColor, height: isPinEnabled ? 1 : 16),
                        SizedBox(height: isPinEnabled ? 12 : 0),

                        // Fingerprint / Face ID toggle
                        _switchRow(
                          icon: Icons.fingerprint_rounded,
                          title: 'Enable Fingerprint / Face ID',
                          subtitle: () {
                            if (_biometricStatus == BiometricStatus.notSupported) {
                              return 'Biometric hardware not available on this device';
                            }
                            if (_biometricStatus == BiometricStatus.notEnrolled) {
                              return 'No biometrics enrolled — set up in device settings';
                            }
                            return isBiometricEnabled
                                ? 'Active — biometric unlock enabled'
                                : 'Unlock with fingerprint or face scan';
                          }(),
                          iconColor: isBiometricEnabled ? AppColors.primaryGreen : sectionLabelColor,
                          value: isBiometricEnabled,
                          onChanged: _isBiometricSupported
                              ? (bool enable) => _handleBiometricToggle(enable, isDark, isPinEnabled)
                              : null,
                          isDark: isDark,
                          titleColor: titleColor,
                          subtitleColor: sectionLabelColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section 3: Security & Recovery Questions ───────────
                  _sectionLabel('SECURITY & RECOVERY QUESTIONS', sectionLabelColor),
                  const SizedBox(height: 10),
                  _card(
                    color: cardColor,
                    border: borderColor,
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecurityRecoveryQuestionsScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        NotificationService.showSuccess('Security recovery questions saved!');
                        await _repo.loadProfile();
                        setState(() {});
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.help_outline_rounded, size: 22, color: AppColors.accentPurple),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security & Recovery Questions',
                                style: AppTypography.titleSmall.copyWith(color: titleColor),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                profile.hasSecurityQuestions
                                    ? '2 recovery questions set — tap to update'
                                    : 'Not set — tap to configure account recovery',
                                style: AppTypography.bodySmall.copyWith(color: sectionLabelColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: profile.hasSecurityQuestions
                                ? AppColors.primaryGreen.withValues(alpha: 0.12)
                                : Colors.orangeAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.hasSecurityQuestions ? 'UPDATE' : 'SET UP',
                            style: AppTypography.badge.copyWith(
                              color: profile.hasSecurityQuestions ? AppColors.primaryGreen : Colors.orangeAccent,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: sectionLabelColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section 4: Device Management ───────────────────────
                  _sectionLabel('DEVICE MANAGEMENT', sectionLabelColor),
                  const SizedBox(height: 10),
                  _card(
                    color: cardColor,
                    border: borderColor,
                    child: InkWell(
                      onTap: () => ProfileModals.showActiveDevicesSheet(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.devices_rounded, size: 22, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active Login Sessions', style: AppTypography.titleSmall.copyWith(color: titleColor)),
                                const SizedBox(height: 3),
                                Text(
                                  '${profile.activeDevices.length} device(s) currently registered',
                                  style: AppTypography.bodySmall.copyWith(color: sectionLabelColor),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${profile.activeDevices.length} ACTIVE',
                              style: AppTypography.badge.copyWith(color: AppColors.primaryGreen, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: sectionLabelColor),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section 5: Encryption Info ─────────────────────────
                  _sectionLabel('DATA INTEGRITY & ENCRYPTION', sectionLabelColor),
                  const SizedBox(height: 10),
                  _card(
                    color: cardColor,
                    border: borderColor,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '256-Bit Financial Encryption',
                                style: AppTypography.titleSmall.copyWith(color: titleColor),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your cryptographic keys, OTP hashes, and business financial ledgers are protected using AES-256 and TLS 1.3 encryption protocols.',
                                style: AppTypography.bodySmall.copyWith(color: sectionLabelColor, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Primary CTA ────────────────────────────────────────
                  PrimaryButton(
                    text: 'Save Security Settings',
                    icon: Icons.security_rounded,
                    isLoading: _isSavingAll || _isSavingPw,
                    onPressed: () => _handleSaveAll(isDark),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        letterSpacing: 1.2,
        color: color,
      ),
    );
  }

  Widget _card({
    required Color color,
    required Color border,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }

  Widget _errorBanner(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required bool isDark,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(color: titleColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: subtitleColor)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primaryGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
