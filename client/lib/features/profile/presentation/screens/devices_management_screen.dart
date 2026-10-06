import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/device_service.dart';
import '../../../../core/widgets/device_approval_dialog.dart';
import '../../../auth/data/auth_repository.dart';

class DevicesManagementScreen extends StatefulWidget {
  const DevicesManagementScreen({super.key});

  @override
  State<DevicesManagementScreen> createState() => _DevicesManagementScreenState();
}

class _DevicesManagementScreenState extends State<DevicesManagementScreen> {
  final AuthRepository _authRepo = AuthRepository();
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentDeviceId = await DeviceService.getDeviceId();
      final devices = await _authRepo.getUserDevices();
      final pending = await _authRepo.getPendingDeviceApprovals();

      if (mounted) {
        setState(() {
          _devices = devices;
          _pendingRequests = pending;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _revokeDevice(String deviceId, String deviceName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Revoke Device Access?', style: AppTypography.titleMedium.copyWith(color: AppColors.brandNavy)),
        content: Text(
          'Are you sure you want to log out and revoke access for "$deviceName"?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.brandTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('REVOKE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authRepo.revokeDevice(deviceId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.brandNavy,
              content: Text('Access revoked for $deviceName'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Failed to revoke device: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brandNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Connected Devices',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandBlue),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.brandBlue,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Pending Approvals Section
                  if (_pendingRequests.isNotEmpty) ...[
                    Text(
                      'PENDING PERMISSION REQUESTS (${_pendingRequests.length})',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.warning,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._pendingRequests.map((req) {
                      final name = req['deviceName'] ?? req['device_name'] ?? 'New Device';
                      final code = req['verificationCode'] ?? req['verification_code'] ?? '----';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.warning.withValues(alpha: 0.12),
                              ),
                              child: const Icon(Icons.security, color: AppColors.warning, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.brandNavy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Code: $code',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                DeviceApprovalDialog.show(context, req, onResolved: _loadData);
                              },
                              child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'ACTIVE AUTHORIZED DEVICES',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.brandTextMuted,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_devices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.brandBorder),
                      ),
                      child: Center(
                        child: Text(
                          'No devices registered.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.brandTextMuted),
                        ),
                      ),
                    )
                  else
                    ..._devices.map((dev) {
                      final devId = dev['deviceId'] ?? dev['device_id'] ?? '';
                      final isCurrent = devId == _currentDeviceId;
                      final name = dev['deviceName'] ?? dev['device_name'] ?? 'Mobile Device';
                      final platform = dev['platform'] ?? 'Android';
                      final lastActive = dev['lastActiveAt'] ?? dev['last_active_at'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent ? AppColors.brandBlue.withValues(alpha: 0.5) : AppColors.brandBorder,
                            width: isCurrent ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent ? AppColors.brandBlueLight : AppColors.brandBackground,
                              ),
                              child: Icon(
                                platform.toString().toLowerCase().contains('ios') || platform.toString().toLowerCase().contains('apple')
                                    ? Icons.phone_iphone
                                    : (platform.toString().toLowerCase().contains('web') || platform.toString().toLowerCase().contains('window')
                                        ? Icons.laptop_mac
                                        : Icons.phone_android),
                                color: isCurrent ? AppColors.brandBlue : AppColors.brandTextSecondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: AppColors.brandNavy,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandBlueLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'THIS DEVICE',
                                            style: AppTypography.badge.copyWith(
                                              color: AppColors.brandBlue,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastActive.isNotEmpty ? 'Active: ${lastActive.toString().split('T').first}' : 'Active now',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.brandTextMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCurrent)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                tooltip: 'Revoke device',
                                onPressed: () => _revokeDevice(devId, name),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
