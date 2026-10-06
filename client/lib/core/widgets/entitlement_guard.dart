import 'package:flutter/material.dart';
import '../../features/subscription/data/entitlement_repository.dart';
import '../../features/subscription/presentation/screens/upgrade_prompt_screen.dart';

class EntitlementGuard extends StatefulWidget {
  final String featureCode;
  final String? featureName;
  final String? requiredTier;
  final Widget child;
  final Widget? fallback;
  final Widget? placeholder;

  const EntitlementGuard({
    super.key,
    required this.featureCode,
    this.featureName,
    this.requiredTier = 'PRO',
    required this.child,
    this.fallback,
    this.placeholder,
  });

  @override
  State<EntitlementGuard> createState() => _EntitlementGuardState();
}

class _EntitlementGuardState extends State<EntitlementGuard> {
  final EntitlementRepository _repo = EntitlementRepository();
  bool _isLoading = true;
  bool _isAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final allowed = await _repo.canAccess(widget.featureCode);
      if (mounted) {
        setState(() {
          _isAllowed = allowed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAllowed = true; // Fail open on network error
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
    }

    if (_isAllowed) {
      return widget.child;
    }

    return widget.fallback ??
        UpgradePromptScreen(
          feature: widget.featureCode,
          featureName: widget.featureName,
          requiredTier: widget.requiredTier,
        );
  }
}
