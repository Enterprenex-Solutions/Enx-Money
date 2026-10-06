import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/services/notification_service.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? provider;
  final String? failedPrompt;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.provider,
    this.failedPrompt,
  });
}

class MetaAiChatScreen extends StatefulWidget {
  const MetaAiChatScreen({super.key});

  @override
  State<MetaAiChatScreen> createState() => _MetaAiChatScreenState();
}

class _MetaAiChatScreenState extends State<MetaAiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String _selectedProvider = 'auto'; // 'auto', 'meta', 'gemini'
  bool _isLoading = false;
  bool _isFetchingHistory = true;

  String _getProviderLabel(String provider) {
    switch (provider) {
      case 'meta':
        return 'Meta AI (Llama 3.3)';
      case 'gemini':
        return 'Google Gemini 3.6';
      default:
        return 'Auto Dual Engine';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isFetchingHistory = true);
    try {
      final res = await ApiClient.instance.get(ApiConfig.aiHistory);
      if (res['data'] is List) {
        final List list = res['data'];
        final List<ChatMessage> loaded = [];
        for (final item in list) {
          if (item is Map) {
            loaded.add(ChatMessage(
              id: 'hist_${DateTime.now().microsecondsSinceEpoch}_${loaded.length}',
              text: item['content']?.toString() ?? '',
              isUser: item['role'] == 'user',
              timestamp: item['timestamp'] != null
                  ? DateTime.tryParse(item['timestamp'].toString()) ?? DateTime.now()
                  : DateTime.now(),
            ));
          }
        }
        if (mounted && loaded.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(loaded);
          });
        }
      }
    } catch (e) {
      debugPrint('[MetaAI] Could not load history: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingHistory = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat History?'),
        content: const Text('This will delete all past conversations with Meta AI from this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.instance.delete(ApiConfig.aiHistory);
        setState(() => _messages.clear());
        NotificationService.showSuccess('Chat history cleared');
      } catch (e) {
        NotificationService.showError('Failed to clear history');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? predefinedText}) async {
    final text = predefinedText ?? _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (predefinedText == null) {
      _textController.clear();
    }

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final langCode = LocaleController.instance.locale.languageCode;
      final historyPayload = _messages
          .where((m) => !m.isError)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final res = await ApiClient.instance.post(
        ApiConfig.aiChat,
        body: {
          'message': text,
          'language': langCode,
          'history': historyPayload,
          'provider': _selectedProvider,
        },
      );

      final replyText = res['data']?['reply'] ??
          res['message'] ??
          'I am ready to assist with your business queries.';

      final providerName = res['data']?['provider']?.toString() ??
          (res['data']?['source'] == 'GOOGLE_GEMINI'
              ? 'Google Gemini 3.6'
              : 'Meta AI (Llama 3.3)');

      final aiMsg = ChatMessage(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
        text: replyText.toString(),
        isUser: false,
        timestamp: DateTime.now(),
        provider: providerName,
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      String displayError = 'AI service is temporarily unavailable. Please try again.';
      if (e is ApiException && e.message.isNotEmpty) {
        final lower = e.message.toLowerCase();
        // Prevent accidental leakage of keys, tokens, or backend secrets
        if (!lower.contains('key') && !lower.contains('secret') && !lower.contains('token') && !lower.contains('bearer')) {
          displayError = e.message;
        }
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            id: 'err_${DateTime.now().millisecondsSinceEpoch}',
            text: displayError,
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
            failedPrompt: text,
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandText;
    final currentLang = LocaleController.instance.currentLanguageName;

    final suggestions = [
      'What is GST Input Tax Credit (ITC)?',
      'How do I collect Khata balance faster?',
      'How to file GSTR-1 vs GSTR-3B?',
      'Tips to optimize retail inventory holding',
      'What are mandatory fields on a GST invoice?',
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0.5,
        iconTheme: IconThemeData(color: textColor),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandBlue, Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.tr('meta_ai_title'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentLang,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.successMint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Live • ${_getProviderLabel(_selectedProvider)}',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.brandTextSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Switch AI Engine',
            icon: const Icon(Icons.tune_rounded),
            initialValue: _selectedProvider,
            onSelected: (val) {
              setState(() => _selectedProvider = val);
              NotificationService.showSuccess('Active AI: ${_getProviderLabel(val)}');
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'auto',
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFF00E676), size: 18),
                    SizedBox(width: 8),
                    Text('Auto Dual Engine (Live)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'meta',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF2979FF), size: 18),
                    SizedBox(width: 8),
                    Text('Meta AI (Llama 3.3)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'gemini',
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Color(0xFFFF9800), size: 18),
                    SizedBox(width: 8),
                    Text('Google Gemini 3.6 Flash'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear History',
            onPressed: _messages.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message Stream
            Expanded(
              child: _isFetchingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _buildEmptyState(isDark, textColor, suggestions)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isLoading) {
                              return _buildThinkingIndicator(isDark);
                            }
                            final msg = _messages[index];
                            return _buildMessageBubble(msg, isDark, textColor);
                          },
                        ),
            ),

            // Suggestions bar when messages exist
            if (_messages.isNotEmpty && !_isLoading)
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return ActionChip(
                      backgroundColor: cardBg,
                      side: BorderSide(
                        color: isDark ? AppColors.border : AppColors.brandBorder,
                      ),
                      label: Text(
                        suggestions[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppColors.brandText,
                        ),
                      ),
                      onPressed: () => _sendMessage(predefinedText: suggestions[i]),
                    );
                  },
                ),
              ),

            // Input Bar
            _buildInputBar(isDark, cardBg, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, List<String> suggestions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandBlue.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 54,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('meta_ai_title'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your 24/7 financial and business advisor. Ask anything about GST rules, daily book management, invoices, and debt recovery.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.brandTextSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Topics',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: suggestions.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _sendMessage(predefinedText: s),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.border : AppColors.brandBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16, color: AppColors.brandBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark, Color textColor) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandBlue, Color(0xFF2563EB)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isError
                    ? AppColors.error.withValues(alpha: 0.1)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: msg.isError
                      ? AppColors.error.withValues(alpha: 0.3)
                      : (isDark ? AppColors.border : AppColors.brandBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.text,
                    style: TextStyle(
                      color: msg.isError ? AppColors.error : textColor,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.provider != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            msg.provider!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          NotificationService.showInfo('Copied to clipboard');
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (msg.isError && msg.failedPrompt != null && msg.failedPrompt!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            final retryText = msg.failedPrompt!;
                            setState(() {
                              _messages.remove(msg);
                              // Remove preceding user message if it matches so it does not duplicate
                              if (_messages.isNotEmpty && _messages.last.isUser && _messages.last.text == retryText) {
                                _messages.removeLast();
                              }
                            });
                            _sendMessage(predefinedText: retryText);
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: AppColors.brandBlue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.border : AppColors.brandBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandBlue),
                ),
                const SizedBox(width: 8),
                Text(
                  'Meta AI is thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white60 : AppColors.brandTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.border : AppColors.brandBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: context.tr('ask_meta_ai'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.brandTextSecondary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(Icons.send_rounded, size: 20),
            onPressed: _isLoading ? null : () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
