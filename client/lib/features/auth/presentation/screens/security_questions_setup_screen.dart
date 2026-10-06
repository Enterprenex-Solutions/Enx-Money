import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/auth_repository.dart';

/// Curated fallback catalog — shown immediately while the server catalog loads,
/// or if the API is unreachable. Covers common recovery scenarios.
const List<Map<String, String>> _kFallbackQuestions = [
  {'id': 'q1', 'text': 'What was the name of your first school?'},
  {'id': 'q2', 'text': 'In what city were you born?'},
  {'id': 'q3', 'text': 'What is the name of your childhood best friend?'},
  {'id': 'q4', 'text': "What is your mother's maiden name?"},
  {'id': 'q5', 'text': 'What was the make and model of your first car or bike?'},
  {'id': 'q6', 'text': 'What was your childhood nickname?'},
  {'id': 'q7', 'text': 'What was the name of your first pet?'},
  {'id': 'q8', 'text': 'What city did you meet your spouse / partner in?'},
  {'id': 'q9', 'text': "What is your oldest sibling's middle name?"},
  {'id': 'q10', 'text': 'What was the first concert you attended?'},
];

/// Screen for setting up or updating the 2 security & recovery questions
/// used to verify identity during account recovery and password reset.
class SecurityRecoveryQuestionsScreen extends StatefulWidget {
  static const String routeName = '/security-recovery-questions';

  final String? userEmail;
  final String? userPhone;

  const SecurityRecoveryQuestionsScreen({
    super.key,
    this.userEmail,
    this.userPhone,
  });

  @override
  State<SecurityRecoveryQuestionsScreen> createState() =>
      _SecurityRecoveryQuestionsScreenState();
}

/// Backward compatibility alias for SecurityRecoveryQuestionsScreen
typedef SecurityQuestionsSetupScreen = SecurityRecoveryQuestionsScreen;

class _SecurityRecoveryQuestionsScreenState
    extends State<SecurityRecoveryQuestionsScreen> {
  final AuthRepository _authRepo = AuthRepository();

  // Catalog (starts with fallback, may be enriched from server)
  List<Map<String, String>> _catalog = List.from(_kFallbackQuestions);

  // Exactly 2 question slots
  static const int _numSlots = 2;
  final List<String?> _selectedIds = ['q1', 'q2'];
  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  // Answers visible by default for clarity, with eye toggle
  final List<bool> _obscure = [false, false];

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadQuestionsCatalogAndUserData();
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fetch the server catalog in the background and pre-populate configured questions
  /// if already configured. The UI is already rendered with fallback questions so it never hangs.
  Future<void> _loadQuestionsCatalogAndUserData() async {
    try {
      final rawQuestions = await _authRepo.fetchSecurityQuestionsCatalog();
      if (mounted && rawQuestions.isNotEmpty) {
        final serverList = rawQuestions.map((q) => {
          'id': q['id']?.toString() ?? '',
          'text': q['text']?.toString() ?? '',
        }).where((q) => q['id']!.isNotEmpty && q['text']!.isNotEmpty).toList();

        if (serverList.isNotEmpty) {
          setState(() {
            _catalog = serverList;
            // Ensure selected IDs remain valid
            for (int i = 0; i < _numSlots; i++) {
              final id = _selectedIds[i];
              if (id != null && !_catalog.any((q) => q['id'] == id)) {
                _selectedIds[i] = _catalog.length > i ? _catalog[i]['id'] : null;
              }
            }
          });
        }
      }
    } catch (_) {
      // Fallback catalog is already active; do not interrupt user
    }

    // Try to pre-populate user's previously chosen question selections
    try {
      final email = widget.userEmail ?? ProfileRepository().profile.email;
      if (email.isNotEmpty && ProfileRepository().profile.hasSecurityQuestions) {
        final userQuestions = await _authRepo.fetchQuestionsForUser(email);
        if (mounted && userQuestions.isNotEmpty) {
          setState(() {
            for (int i = 0; i < _numSlots && i < userQuestions.length; i++) {
              final qId = userQuestions[i]['questionId']?.toString();
              if (qId != null && _catalog.any((q) => q['id'] == qId)) {
                _selectedIds[i] = qId;
              }
            }
          });
        }
      }
    } catch (_) {
      // Silent fail
    }
  }

  bool get _isFormValid {
    // Both slots must have a unique, non-duplicate question and answer ≥ 2 chars
    if (_selectedIds.contains(null)) return false;
    if (_selectedIds[0] == _selectedIds[1]) return false;
    for (final c in _answerControllers) {
      if (c.text.trim().length < 2) return false;
    }
    return true;
  }

  /// Questions available for a given slot (excludes other slot's selection)
  List<Map<String, String>> _availableFor(int slot) {
    final otherId = _selectedIds[slot == 0 ? 1 : 0];
    return _catalog.where((q) => q['id'] != otherId).toList();
  }

  Future<void> _onSave() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final payload = List.generate(_numSlots, (i) {
        final qId = _selectedIds[i]!.toString();
        final q = _catalog.firstWhere((item) => item['id'] == qId, orElse: () => {'text': ''});
        return {
          'questionId': qId,
          'questionText': q['text'] ?? '',
          'answer': _answerControllers[i].text.trim(),
        };
      });

      await _authRepo.setupSecurityQuestions(payload);
      ProfileRepository().updateSecurity(hasSecurityQuestions: true);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = msg.isNotEmpty ? msg : 'Failed to save. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dropdownColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dropdownTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: titleColor,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text(
          'Security & Recovery Questions',
          style: AppTypography.titleLarge.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.accentPurple,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Recovery Setup',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.accentPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure 2 recovery questions to quickly verify your identity and recover your account if you forget your password or lose OTP access.',
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Question Slots ───────────────────────────────────────────
            for (int i = 0; i < _numSlots; i++) ...[
              _buildQuestionSlot(
                index: i,
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                dropdownColor: dropdownColor,
                dropdownTextColor: dropdownTextColor,
              ),
              if (i < _numSlots - 1) const SizedBox(height: 24),
            ],

            // ── Error Banner ─────────────────────────────────────────────
            if (_saveError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _saveError!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Save CTA ─────────────────────────────────────────────────
            PrimaryButton(
              text: 'Save Recovery Questions',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSaving,
              onPressed: _isFormValid ? _onSave : null,
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSlot({
    required int index,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color dropdownColor,
    required Color dropdownTextColor,
  }) {
    final available = _availableFor(index);
    final currentId = _selectedIds[index];
    final selectedValue =
        available.any((q) => q['id'] == currentId) ? currentId : null;

    final questionNum = index + 1;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot Header
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.40),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$questionNum',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'QUESTION $questionNum',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Dropdown Selector ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedValue,
                hint: Text(
                  'Select Question $questionNum…',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                dropdownColor: dropdownColor,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: dropdownTextColor,
                  fontWeight: FontWeight.w500,
                ),
                items: available.map((q) {
                  return DropdownMenuItem<String>(
                    value: q['id'],
                    child: Text(
                      q['text'] ?? '',
                      style: AppTypography.bodyMedium.copyWith(
                        color: dropdownTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedIds[index] = val;
                    _saveError = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Answer Label ────────────────────────────────────────────
          Text(
            'ANSWER $questionNum',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),

          // ── High-Contrast Answer Input Box ──────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _answerControllers[index],
              obscureText: _obscure[index],
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.primaryGreen,
              decoration: InputDecoration(
                hintText: index == 0
                    ? 'Type your answer to question 1…'
                    : 'Type your answer to question 2…',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure[index]
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscure[index] = !_obscure[index]),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (_) => setState(() => _saveError = null),
            ),
          ),
        ],
      ),
    );
  }
}
