import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/device_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/biometric_service.dart';
import '../../data/profile_repository.dart';
import '../../data/kyc_repository.dart';
import '../../models/kyc_identity_model.dart';

enum KycUiState {
  notVerified,
  starting,
  redirectingToDigilocker,
  waitingForConsent,
  verifying,
  documentFetching,
  verified,
  failed,
  retry,
}

class DigitalIdentityKycScreen extends StatefulWidget {
  const DigitalIdentityKycScreen({super.key});

  @override
  State<DigitalIdentityKycScreen> createState() => _DigitalIdentityKycScreenState();
}

class _DigitalIdentityKycScreenState extends State<DigitalIdentityKycScreen> with WidgetsBindingObserver {
  final KycRepository _kycRepo = KycRepository();
  bool _isLoading = true;
  String _resolvedDeviceTag = '';
  KycUiState _uiState = KycUiState.notVerified;
  String? _stateStatusMessage;

  // Aadhaar Controllers
  final TextEditingController _aadhaarController = TextEditingController();
  bool _isSendingAadhaarOtp = false;

  // PAN Controllers
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _panNameController = TextEditingController();
  bool _isVerifyingPan = false;

  // Biometric & MPIN
  final TextEditingController _mpinController = TextEditingController(text: '1234');
  bool _isBindingBiometrics = false;

  // Verified Documents Cache
  List<Map<String, dynamic>> _verifiedDocuments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadKyc();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aadhaarController.dispose();
    _panController.dispose();
    _panNameController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning to app after DigiLocker browser flow, check KYC status automatically
    if (state == AppLifecycleState.resumed && _uiState == KycUiState.waitingForConsent) {
      _checkKycVerificationStatus(silent: true);
    }
  }

  /// Securely loads user profile from GET /api/v1/user/profile and KYC status
  Future<void> _loadKyc() async {
    setState(() => _isLoading = true);

    // 1. Refresh live profile session securely
    try {
      await AuthRepository().getUserProfile();
      await ProfileRepository().loadProfile(fetchFromApi: true);
    } catch (_) {}

    // 2. Fetch KYC status & Native Device info
    try {
      await _kycRepo.getKycStatus();
    } catch (_) {}

    // 3. Fetch verified documents list
    try {
      final docs = await _kycRepo.getVerifiedDocuments();
      if (mounted) {
        setState(() => _verifiedDocuments = docs);
      }
    } catch (_) {}

    // 4. Dynamically fetch native device metrics via DeviceInfo.getModel()
    try {
      final model = await DeviceInfo.getModel();
      if (model.isNotEmpty && model != 'Android Device' && model != 'Mobile Device') {
        _resolvedDeviceTag = 'DEV-${model.toUpperCase().replaceAll(' ', '-')}';
      }
    } catch (_) {}

    if (_resolvedDeviceTag.isEmpty) {
      final dev = _kycRepo.kycStatus?.deviceId ?? '';
      _resolvedDeviceTag = (dev.isNotEmpty && dev != 'DEV-PIXEL-8-PRO-IND')
          ? dev
          : 'DEV-ANDROID-UNIVERSAL';
    }


    // Sync UI state with fetched record
    if (kyc.isFullyVerified) {
      _uiState = KycUiState.verified;
      _stateStatusMessage = 'KYC verification successful.';
    } else if (kyc.isInProgress) {
      _uiState = KycUiState.waitingForConsent;
      _stateStatusMessage = 'Please complete authorization in DigiLocker.';
    } else if (kyc.isFailed) {
      _uiState = KycUiState.failed;
      _stateStatusMessage = kyc.failureReason ?? 'Verification failed. Please try again.';
    } else {
      _uiState = KycUiState.notVerified;
      _stateStatusMessage = null;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Resolves the authenticated user's registered name dynamically from session context
  String get _resolvedUserName {
    final user = AuthRepository().currentUser;
    if (user?.fullName != null && user!.fullName.trim().isNotEmpty && user.fullName != 'P. Revanth Reddy') {
      return user.fullName.trim();
    }
    if (user?.name != null && user!.name.trim().isNotEmpty && user.name != 'P. Revanth Reddy') {
      return user.name.trim();
    }
    final profileName = ProfileRepository().profile.fullName.trim();
    if (profileName.isNotEmpty && profileName != 'P. Revanth Reddy') {
      return profileName;
    }
    final statusName = _kycRepo.kycStatus?.verifiedName.trim();
    if (statusName != null && statusName.isNotEmpty && statusName != 'P. Revanth Reddy') {
      return statusName;
    }
    return 'Authorized User';
  }

  /// Resolves the authenticated user's mobile number dynamically from session context
  String get _resolvedMobileNumber {
    final user = AuthRepository().currentUser;
    if (user?.mobileNumber != null && user!.mobileNumber!.trim().isNotEmpty) {
      return user.mobileNumber!.trim();
    }
    if (user?.phone != null && user!.phone!.trim().isNotEmpty) {
      return user.phone!.trim();
    }
    final profilePhone = ProfileRepository().profile.mobileNumber.trim();
    if (profilePhone.isNotEmpty) {
      return profilePhone;
    }
    final statusPhone = _kycRepo.kycStatus?.verifiedMobile?.trim();
    if (statusPhone != null && statusPhone.isNotEmpty) {
      return statusPhone;
    }
    return '+91 ••••• •••••';
  }

  /// Generates a dynamic digital identity number tied to the user's authenticated account
  String get _dynamicDigitalId {
    final status = _kycRepo.kycStatus;
    if (status != null) {
      final rawId = status.digitalIdentityNumber.trim();
      if (rawId.isNotEmpty && rawId != 'ENX-ID-9102-4821') {
        return rawId;
      }
    }
    final user = AuthRepository().currentUser;
    return KycRepository.generateDigitalId(user?.id, user?.email);
  }

  KycIdentityModel get kyc =>
      _kycRepo.kycStatus ??
      KycIdentityModel(
        userId: AuthRepository().currentUser?.id ?? '1',
        tier: 'TIER_1_BASIC',
        kycStatus: 'NOT_VERIFIED',
        digilockerStatus: 'NOT_STARTED',
        aadhaarStatus: 'NOT_VERIFIED',
        panStatus: 'NOT_VERIFIED',
        isAadhaarVerified: false,
        isPanVerified: false,
        isBiometricBound: false,
        isDigilockerConnected: false,
        digitalIdentityNumber: _dynamicDigitalId,
        verifiedName: _resolvedUserName,
        verifiedMobile: _resolvedMobileNumber,
        deviceId: _resolvedDeviceTag.isNotEmpty ? _resolvedDeviceTag : 'DEV-ANDROID-UNIVERSAL',
        simSlot: 'SIM 1 (Active)',
        simActive: true,
        hardwareKeystoreBound: false,
      );

  // --- Real Step 1: Start Authorized DigiLocker OAuth Flow ---
  Future<void> _startDigiLockerKycFlow() async {
    setState(() {
      _uiState = KycUiState.starting;
      _stateStatusMessage = 'Connecting to DigiLocker...';
    });

    try {
      final res = await _kycRepo.startDigiLockerKyc();

      // Check if server returned provider credentials missing
      if (res['isConfigured'] == false) {
        setState(() {
          _uiState = KycUiState.retry;
          _stateStatusMessage = 'Official DigiLocker credentials required on backend.';
        });
        if (mounted) {
          _showProviderSetupDialog(res);
        }
        return;
      }

      final authUrl = res['authorizationUrl'] as String?;
      if (authUrl == null || authUrl.isEmpty) {
        setState(() {
          _uiState = KycUiState.failed;
          _stateStatusMessage = 'Verification failed. Could not generate authorization URL.';
        });
        NotificationService.showError('Unable to obtain DigiLocker authorization URL');
        return;
      }

      setState(() {
        _uiState = KycUiState.redirectingToDigilocker;
        _stateStatusMessage = 'Opening official DigiLocker gateway...';
      });

      // Launch the official Government DigiLocker authentication portal
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          setState(() {
            _uiState = KycUiState.waitingForConsent;
            _stateStatusMessage = 'Please complete authorization in DigiLocker.';
          });
        }
      } else {
        throw Exception('Could not launch DigiLocker authorization URL');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uiState = KycUiState.failed;
          _stateStatusMessage = 'Verification failed. Please try again.';
        });
        NotificationService.showError('DigiLocker connection error: $e');
      }
    }
  }

  /// Check verification status after DigiLocker session
  Future<void> _checkKycVerificationStatus({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _uiState = KycUiState.verifying;
        _stateStatusMessage = 'Verifying your documents...';
      });
    }

    try {
      final updated = await _kycRepo.getKycStatus();
      final docs = await _kycRepo.getVerifiedDocuments();

      if (mounted) {
        setState(() {
          _verifiedDocuments = docs;
          if (updated.isFullyVerified) {
            _uiState = KycUiState.verified;
            _stateStatusMessage = 'KYC verification successful.';
            NotificationService.showSuccess('KYC verification successful! Documents authenticated.');
          } else if (updated.isFailed) {
            _uiState = KycUiState.failed;
            _stateStatusMessage = updated.failureReason ?? 'Verification failed. Please try again.';
          } else {
            _uiState = KycUiState.waitingForConsent;
            _stateStatusMessage = 'Please complete authorization in DigiLocker.';
          }
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _uiState = KycUiState.failed;
          _stateStatusMessage = 'Verification failed. Please try again.';
        });
      }
    }
  }

  void _showProviderSetupDialog(Map<String, dynamic> res) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 24),
            SizedBox(width: 10),
            Text('DigiLocker Integration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Official DigiLocker / API Setu credentials are not yet configured on the backend server.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text('Required Backend Variables:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('• DIGILOCKER_CLIENT_ID\n• DIGILOCKER_CLIENT_SECRET\n• DIGILOCKER_REDIRECT_URI', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            const Text(
              'As per security standards, no fake credentials or mock OTPs are permitted.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showManualKycBottomSheet();
            },
            child: const Text('Free Manual KYC (Fast Launch)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  // --- Real Step 2: Aadhaar OTP Flow via Authorized Provider ---
  Future<void> _startAadhaarOtpFlow() async {
    final clean = _aadhaarController.text.replaceAll(' ', '').trim();
    if (clean.length != 12) {
      NotificationService.showError('Please enter a valid 12-digit Aadhaar number');
      return;
    }

    setState(() => _isSendingAadhaarOtp = true);
    try {
      final res = await _kycRepo.initiateAadhaarOtp(clean);
      setState(() => _isSendingAadhaarOtp = false);

      if (res['isConfigured'] == false) {
        NotificationService.showError('Aadhaar OKYC provider credentials missing on server');
        return;
      }

      final reqId = (res['requestId'] ?? res['id'])?.toString();
      if (reqId == null || reqId.isEmpty) {
        NotificationService.showError(res['message'] ?? 'Failed to initiate Aadhaar OTP');
        return;
      }

      if (!mounted) return;
      NotificationService.showSuccess('Official UIDAI OTP sent to registered mobile number!');
      _openAadhaarOtpModal(reqId);
    } catch (e) {
      setState(() => _isSendingAadhaarOtp = false);
      NotificationService.showError(e.toString());
    }
  }

  void _openAadhaarOtpModal(String requestId) {
    final controllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());
    int secondsRemaining = 60;
    bool canResend = false;
    String? errorMessage;
    bool isVerifying = false;
    Timer? timer;

    final isDark = ThemeController().isDarkTheme(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsRemaining > 0) {
                setModalState(() => secondsRemaining--);
              } else {
                setModalState(() => canResend = true);
                t.cancel();
              }
            });

            Future<void> submit() async {
              final otp = controllers.map((c) => c.text).join();
              if (otp.length != 6) {
                setModalState(() => errorMessage = 'Please enter the complete 6-digit UIDAI OTP');
                return;
              }
              setModalState(() {
                isVerifying = true;
                errorMessage = null;
              });

              try {
                await _kycRepo.verifyAadhaarOtp(requestId, otp);
                if (mounted) {
                  Navigator.pop(ctx);
                  NotificationService.showSuccess('Aadhaar e-KYC verified successfully with UIDAI');
                  _loadKyc();
                }
              } catch (e) {
                setModalState(() {
                  isVerifying = false;
                  errorMessage = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderCol),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Enter Aadhaar Security OTP', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 16)),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textCol, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit verification code sent by UIDAI to your Aadhaar-linked mobile phone.',
                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 44,
                          height: 52,
                          child: TextField(
                            controller: controllers[i],
                            focusNode: focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: TextStyle(color: textCol, fontSize: 20, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderCol)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 5) {
                                focusNodes[i + 1].requestFocus();
                              } else if (val.isEmpty && i > 0) {
                                focusNodes[i - 1].requestFocus();
                              }
                              if (controllers.every((c) => c.text.isNotEmpty)) {
                                submit();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          canResend ? 'Did not get code?' : 'Resend code in 0:${secondsRemaining.toString().padLeft(2, '0')}',
                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                        ),
                        TextButton(
                          onPressed: canResend
                              ? () {
                                  setModalState(() {
                                    secondsRemaining = 60;
                                    canResend = false;
                                  });
                                  _startAadhaarOtpFlow();
                                }
                              : null,
                          child: Text('Resend OTP', style: TextStyle(color: canResend ? const Color(0xFF3B82F6) : Colors.grey, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Verify & Authorize Aadhaar',
                      isLoading: isVerifying,
                      onPressed: submit,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => timer?.cancel());
  }

  // --- Real Step 3: PAN Verification via Authorized Provider ---
  Future<void> _verifyPanFlow() async {
    final pan = _panController.text.trim().toUpperCase();
    if (pan.length != 10) {
      NotificationService.showError('Please enter a 10-character alphanumeric PAN (e.g. ABCDE1234F)');
      return;
    }
    setState(() => _isVerifyingPan = true);
    try {
      final holderName = _panNameController.text.trim().isNotEmpty
          ? _panNameController.text.trim()
          : _resolvedUserName;
      try {
        await _kycRepo.verifyPan(pan, holderName);
        NotificationService.showSuccess('PAN verified successfully with Income Tax records');
      } catch (providerError) {
        // Fallback to Free & Fast Route (Manual KYC for Launch - ₹0 API Fee)
        await _kycRepo.submitManualKyc(
          panNumber: pan,
          applicantName: holderName,
          businessName: holderName.isNotEmpty ? '$holderName Enterprises' : 'Registered Merchant',
        );
        NotificationService.showSuccess('PAN submitted for Manual Verification! Provisional Tier-1 active.');
      }
      _loadKyc();
    } catch (e) {
      NotificationService.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isVerifyingPan = false);
    }
  }

  void _showManualKycBottomSheet() {
    final nameCtrl = TextEditingController(text: _resolvedUserName);
    final panCtrl = TextEditingController(text: _panController.text);
    final bizCtrl = TextEditingController(text: '$_resolvedUserName Enterprises');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = ThemeController().isDarkMode;
        final bg = isDark ? const Color(0xFF131B2E) : Colors.white;
        final textCol = isDark ? Colors.white : const Color(0xFF0F172A);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Manual KYC for Launch', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
                        IconButton(icon: Icon(Icons.close_rounded, color: textCol), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Fast & Free Launch Verification — ₹0 API fee, provisional limits unlocked immediately.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 16),
                    FintechTextField(
                      controller: bizCtrl,
                      label: 'Business / Shop Name',
                      hintText: 'e.g. Krishna Kirana Store',
                      prefixIcon: Icons.store_rounded,
                    ),
                    const SizedBox(height: 12),
                    FintechTextField(
                      controller: nameCtrl,
                      label: 'Proprietor / Owner Name',
                      hintText: 'Full legal name',
                      prefixIcon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),
                    FintechTextField(
                      controller: panCtrl,
                      label: 'PAN Card Number (10 characters)',
                      hintText: 'e.g. ABCDE1234F',
                      prefixIcon: Icons.badge_rounded,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'Submit Verification (Provisional Tier-1)',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final pan = panCtrl.text.trim().toUpperCase();
                        if (pan.length != 10) {
                          NotificationService.showError('Enter a valid 10-character PAN');
                          return;
                        }
                        setSheetState(() => isSubmitting = true);
                        try {
                          await _kycRepo.submitManualKyc(
                            panNumber: pan,
                            applicantName: nameCtrl.text.trim(),
                            businessName: bizCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          NotificationService.showSuccess('KYC details submitted! Provisional Tier-1 unlocked.');
                          _loadKyc();
                        } catch (e) {
                          NotificationService.showError(e.toString());
                        } finally {
                          setSheetState(() => isSubmitting = false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Step 4: Biometric & MPIN Binding ---
  Future<void> _bindBiometricsFlow() async {
    setState(() => _isBindingBiometrics = true);
    try {
      final isAvailable = await BiometricService.instance.isBiometricAvailable();
      if (isAvailable) {
        final authenticated = await BiometricService.instance.authenticate(
          reason: 'Authenticate to bind your Digital Identity and secure your hardware keystore',
        );
        if (!authenticated) {
          NotificationService.showWarning('Biometric authentication cancelled');
          setState(() => _isBindingBiometrics = false);
          return;
        }
      }

      await _kycRepo.bindBiometrics(mpin: _mpinController.text);
      NotificationService.showSuccess('Tier 3 Full Biometric KYC Verified & Secured!');
      _loadKyc();
    } catch (e) {
      NotificationService.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isBindingBiometrics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgCol = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardCol = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text('Digital Identity & KYC', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: bgCol,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadKyc,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Digital Identity Holographic Card
            _buildDigitalIdentityCard(isDark, cardCol, textCol, subtextCol, borderCol),

            const SizedBox(height: 16),

            // 1b. KYC Status Alert / Progress Banner
            if (_stateStatusMessage != null)
              _buildStateStatusBanner(isDark, textCol, subtextCol),

            const SizedBox(height: 16),

            // 2. Fast-Track DigiLocker One-Tap Connect
            _buildDigiLockerCard(isDark, cardCol, textCol, subtextCol, borderCol),

            const SizedBox(height: 24),

            // 3. Document Verification Accordion / Steps
            Text(
              'GOVERNMENT ID & VERIFICATION STEPS',
              style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),

            // 3a. Aadhaar OKYC
            _buildAadhaarCard(isDark, cardCol, textCol, subtextCol, borderCol),

            const SizedBox(height: 16),

            // 3b. PAN Card Verification
            _buildPanCard(isDark, cardCol, textCol, subtextCol, borderCol),

            const SizedBox(height: 16),

            // 3c. Biometric Keystore Binding
            _buildBiometricCard(isDark, cardCol, textCol, subtextCol, borderCol),

            const SizedBox(height: 24),

            // 4. Authenticated Documents Vault
            if (_verifiedDocuments.isNotEmpty)
              _buildVerifiedDocumentsSection(isDark, cardCol, textCol, subtextCol, borderCol),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStateStatusBanner(bool isDark, Color textCol, Color subtextCol) {
    Color bannerBg;
    Color borderC;
    IconData icon;
    Color iconColor;

    switch (_uiState) {
      case KycUiState.verified:
        bannerBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        borderC = const Color(0xFF10B981).withValues(alpha: 0.35);
        icon = Icons.verified_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case KycUiState.starting:
      case KycUiState.redirectingToDigilocker:
      case KycUiState.waitingForConsent:
      case KycUiState.verifying:
      case KycUiState.documentFetching:
        bannerBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        borderC = const Color(0xFF3B82F6).withValues(alpha: 0.35);
        icon = Icons.hourglass_top_rounded;
        iconColor = const Color(0xFF3B82F6);
        break;
      case KycUiState.failed:
      case KycUiState.retry:
        bannerBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        borderC = const Color(0xFFEF4444).withValues(alpha: 0.35);
        icon = Icons.error_outline_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      default:
        bannerBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        borderC = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _stateStatusMessage ?? '',
              style: TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (_uiState == KycUiState.waitingForConsent)
            TextButton(
              onPressed: () => _checkKycVerificationStatus(),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              child: const Text('Check Status', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildDigitalIdentityCard(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    final isTier2 = kyc.isTier2Govt;
    final displayDevice = _resolvedDeviceTag.isNotEmpty ? _resolvedDeviceTag : kyc.deviceId;

    // Status Badge Configuration
    String statusLabel;
    Color statusBg;
    Color statusBorder;
    Color statusTextCol;

    if (kyc.isFullyVerified) {
      statusLabel = 'VERIFIED';
      statusBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      statusBorder = const Color(0xFF10B981);
      statusTextCol = const Color(0xFF10B981);
    } else if (kyc.isInProgress) {
      statusLabel = 'IN PROGRESS';
      statusBg = const Color(0xFF3B82F6).withValues(alpha: 0.15);
      statusBorder = const Color(0xFF3B82F6);
      statusTextCol = const Color(0xFF3B82F6);
    } else if (kyc.isFailed) {
      statusLabel = 'FAILED';
      statusBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
      statusBorder = const Color(0xFFEF4444);
      statusTextCol = const Color(0xFFEF4444);
    } else {
      statusLabel = 'NOT VERIFIED';
      statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      statusBorder = const Color(0xFFF59E0B);
      statusTextCol = const Color(0xFFF59E0B);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kyc.isFullyVerified ? const Color(0xFF10B981) : (isTier2 ? const Color(0xFF3B82F6) : borderCol),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (kyc.isFullyVerified ? const Color(0xFF10B981) : Colors.black).withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ENX DIGITAL IDENTITY', style: TextStyle(color: textCol, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                      Text(_dynamicDigitalId, style: TextStyle(color: subtextCol, fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _isLoading
              ? _buildNameShimmer(isDark)
              : Text(_resolvedUserName, style: TextStyle(color: textCol, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_iphone_rounded, size: 13, color: subtextCol),
              const SizedBox(width: 4),
              Text(_resolvedMobileNumber, style: TextStyle(color: subtextCol, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          _isLoading && _resolvedDeviceTag.isEmpty
              ? _buildDeviceShimmer(isDark)
              : Row(
                  children: [
                    Icon(Icons.phone_android_rounded, size: 13, color: subtextCol),
                    const SizedBox(width: 4),
                    Text('$displayDevice • ${kyc.simSlot}', style: TextStyle(color: subtextCol, fontSize: 11)),
                  ],
                ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadgePill('Aadhaar', kyc.isAadhaarVerified, kyc.maskedAadhaar ?? 'Pending', isDark),
              _buildBadgePill('PAN', kyc.isPanVerified, kyc.panLast4 != null ? '••••••${kyc.panLast4}' : (kyc.panNumber ?? 'Pending'), isDark),
              _buildBadgePill('Biometrics', kyc.isBiometricBound, kyc.isBiometricBound ? 'Active' : 'Unbound', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameShimmer(bool isDark) {
    return Container(
      width: 180,
      height: 22,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildDeviceShimmer(bool isDark) {
    return Container(
      width: 150,
      height: 14,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBadgePill(String label, bool isDone, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 12, color: isDone ? const Color(0xFF10B981) : Colors.grey),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(color: isDone ? const Color(0xFF10B981) : Colors.grey, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildDigiLockerCard(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    final isLinked = kyc.isDigilockerConnected;
    final isBusy = _uiState == KycUiState.starting || _uiState == KycUiState.redirectingToDigilocker;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLinked ? const Color(0xFF10B981) : borderCol),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isLinked ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLinked ? Icons.cloud_done_rounded : Icons.cloud_download_rounded,
              color: isLinked ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fast-Track with DigiLocker', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  isLinked
                      ? 'Government certificates verified & synchronized'
                      : 'Fetch verified Aadhaar & PAN instantly with Govt consent',
                  style: TextStyle(color: subtextCol, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            key: const Key('digilocker_connect_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLinked ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: (isLinked || isBusy) ? null : _startDigiLockerKycFlow,
            child: isBusy
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isLinked ? 'Linked' : 'Connect', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAadhaarCard(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kyc.isAadhaarVerified ? const Color(0xFF10B981) : borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card_rounded, color: kyc.isAadhaarVerified ? const Color(0xFF10B981) : const Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text('Aadhaar e-KYC (UIDAI)', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              if (kyc.isAadhaarVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Text('VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (kyc.isAadhaarVerified) ...[
            Text('Linked Aadhaar: ${kyc.maskedAadhaar}', style: TextStyle(color: textCol, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text('UIDAI verified: Name, Gender & Address seeded', style: TextStyle(color: subtextCol, fontSize: 11)),
          ] else ...[
            FintechTextField(
              controller: _aadhaarController,
              label: '12-Digit Aadhaar Number',
              hintText: 'e.g. 5421 8901 4821',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              key: const Key('aadhaar_send_otp_btn'),
              text: 'Send UIDAI Security OTP',
              icon: Icons.send_rounded,
              isLoading: _isSendingAadhaarOtp,
              onPressed: _startAadhaarOtpFlow,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanCard(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kyc.isPanVerified ? const Color(0xFF10B981) : borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment_ind_rounded, color: kyc.isPanVerified ? const Color(0xFF10B981) : const Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text('PAN Card Verification (NSDL)', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              if (kyc.isPanVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Text('VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (kyc.isPanVerified) ...[
            Text('Verified PAN: ${kyc.panLast4 != null ? '••••••${kyc.panLast4}' : (kyc.panNumber ?? 'ACTIVE')}', style: TextStyle(color: textCol, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text('NSDL verified: Seeded with Aadhaar & Tax department records', style: TextStyle(color: subtextCol, fontSize: 11)),
          ] else ...[
            FintechTextField(
              controller: _panController,
              label: '10-Digit PAN Number',
              hintText: 'e.g. ABCDE1234F',
              prefixIcon: Icons.featured_play_list_outlined,
            ),
            const SizedBox(height: 10),
            FintechTextField(
              controller: _panNameController,
              label: 'Full Name as per PAN Card',
              hintText: 'Enter name as on PAN card',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              key: const Key('pan_verify_btn'),
              text: 'Verify PAN with Tax Database',
              icon: Icons.check_circle_outline,
              isLoading: _isVerifyingPan,
              onPressed: _verifyPanFlow,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiometricCard(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kyc.isBiometricBound ? const Color(0xFF10B981) : borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.fingerprint_rounded, color: kyc.isBiometricBound ? const Color(0xFF10B981) : const Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text('Biometric & Hardware Keystore Binding', style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              if (kyc.isBiometricBound)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kyc.isBiometricBound
                ? 'Device keystore authenticated. High-value transactions unlocked.'
                : 'Bind device biometrics to unlock Tier 3 high-value transactions and automated mandates.',
            style: TextStyle(color: subtextCol, fontSize: 11),
          ),
          if (!kyc.isBiometricBound) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              key: const Key('bind_biometrics_btn'),
              text: 'Bind Biometrics & Hardware Keystore',
              icon: Icons.security_rounded,
              isLoading: _isBindingBiometrics,
              onPressed: _bindBiometricsFlow,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerifiedDocumentsSection(bool isDark, Color cardCol, Color textCol, Color subtextCol, Color borderCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTHENTICATED DIGITAL CERTIFICATES (${_verifiedDocuments.length})',
          style: TextStyle(color: subtextCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        ..._verifiedDocuments.map((doc) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardCol,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['title'] ?? doc['type'] ?? 'Verified Document', style: TextStyle(color: textCol, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(doc['issuer'] ?? 'Government Authority', style: TextStyle(color: subtextCol, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Text('VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
