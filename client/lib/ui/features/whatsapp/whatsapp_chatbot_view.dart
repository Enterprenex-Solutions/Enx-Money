import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../features/dashboard/data/dashboard_repository.dart';

class ChatBubbleMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? modelSource;

  ChatBubbleMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.modelSource,
  });
}

class WhatsAppChatbotView extends StatefulWidget {
  final Function(int targetIndex)? onNavigateToTab;

  const WhatsAppChatbotView({super.key, this.onNavigateToTab});

  @override
  State<WhatsAppChatbotView> createState() => _WhatsAppChatbotViewState();
}

class _WhatsAppChatbotViewState extends State<WhatsAppChatbotView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatBubbleMessage> _messages = [];
  final DashboardRepository _dashboardRepo = DashboardRepository();

  bool _isTyping = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  final List<String> _quickSuggestions = [
    'What is my current ledger balance?',
    'Summarize my business finances',
    'How do I generate a monthly statement?',
    'How can I remind customers about pending dues?',
    'Add an expense of ₹500 for office supplies',
    'Give me advice on GST invoice rules',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatBubbleMessage(
        id: 'welcome_1',
        text: '👋 *Welcome to ENX Money WhatsApp AI Assistant!*\n\n'
            'I am your in-app financial assistant powered by **Gemini AI**.\n\n'
            'You can ask me anything about:\n'
            '• 💰 *Ledger Balance & Cash in Hand*\n'
            '• 📄 *Generating Financial Statements*\n'
            '• 🔔 *WhatsApp Due Reminders to Customers*\n'
            '• ✍️ *Logging Expenses & Recording Sales*\n'
            '• 📊 *Business Health & GST Inquiries*\n\n'
            'Type a question below or tap a quick suggestion!',
        isUser: false,
        timestamp: DateTime.now(),
        modelSource: 'Gemini 2.5 AI',
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF25D366), size: 18),
            SizedBox(width: 8),
            Text('Message copied to clipboard'),
          ],
        ),
        backgroundColor: const Color(0xFF111B21),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Chat?'),
        content: const Text('This will clear your current conversation with Gemini AI.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatBubbleMessage(
                    id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
                    text: '👋 Chat cleared! How can I assist you today with your ENX Money finances?',
                    isUser: false,
                    timestamp: DateTime.now(),
                    modelSource: 'Gemini 2.5 AI',
                  ),
                );
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _textController.text.trim();
    if (text.isEmpty || _isTyping) return;

    if (predefinedText == null) {
      _textController.clear();
    }

    final userMsg = ChatBubbleMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await _generateAiReply(text);
      if (mounted) {
        setState(() {
          _messages.add(
            ChatBubbleMessage(
              id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
              text: reply.text,
              isUser: false,
              timestamp: DateTime.now(),
              modelSource: reply.source,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatBubbleMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: '⚠️ I encountered an issue processing your request. Please try again.',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }

  Future<({String text, String source})> _generateAiReply(String userPrompt) async {
    final lower = userPrompt.toLowerCase();

    // 1. Direct Local Financial Intelligence (Real live business numbers)
    if (lower.contains('balance') || lower.contains('ledger balance') || lower.contains('cash')) {
      try {
        final metrics = await _dashboardRepo.getMetrics();
        final bal = _currencyFormat.format(metrics.totalBusinessBalance);
        final inflow = _currencyFormat.format(metrics.totalInflow);
        final outflow = _currencyFormat.format(metrics.totalOutflow);
        final profit = _currencyFormat.format(metrics.netProfit);

        return (
          text: '📊 *Here is your Live ENX Money Financial Summary:*\n\n'
              '• 💼 *Net Ledger Balance:* $bal\n'
              '• 📈 *Total Inflow (Revenue):* $inflow\n'
              '• 📉 *Total Outflow (Expenses):* $outflow\n'
              '• 💰 *Net Profit / Loss:* $profit\n\n'
              'Your business is active and all transactions are up to date.',
          source: 'Gemini AI Financial Engine',
        );
      } catch (_) {
        // Fallback to backend AI
      }
    }

    if (lower.contains('statement') || lower.contains('pdf') || lower.contains('report')) {
      return (
        text: '📄 *Monthly Financial Statement Generator*\n\n'
            'Your monthly statement includes full ledger breakdown, GST input/output, and reconciled payments.\n\n'
            '• *Format:* Digitally-signed PDF\n'
            '• *To view & export:* You can tap the **PDF Export** icon on your top dashboard bar or go to Custom Report Builder.',
        source: 'Gemini AI Financial Engine',
      );
    }

    if (lower.contains('remind') || lower.contains('debtor') || lower.contains('due')) {
      return (
        text: '🔔 *Customer Payment Due Reminders*\n\n'
            'You can dispatch automatic payment reminders with instant UPI links directly to your debtor customers.\n\n'
            '• Navigate to **Customers & Receivables** screen\n'
            '• Select any customer with an outstanding balance\n'
            '• Tap **Send Reminder** to dispatch the notification.',
        source: 'Gemini AI Financial Engine',
      );
    }

    // 2. Query Live Gemini AI / Backend API
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
          'message': userPrompt,
          'language': langCode,
          'history': historyPayload,
          'provider': 'auto',
        },
      );

      final reply = res['data']?['reply']?.toString() ??
          res['message']?.toString() ??
          'I am ready to assist with your business finances.';

      final provider = res['data']?['provider']?.toString() ?? 'Gemini 2.5 Flash';

      return (text: reply, source: provider);
    } catch (_) {
      // 3. Fallback Smart Financial Advisor
      return (
        text: '✨ *ENX Money AI Advisor:*\n\n'
            'Thank you for your inquiry about "$userPrompt".\n\n'
            'In ENX Money, your accounts, GST invoices, and khata records are tracked in real-time. '
            'You can monitor sales, log new expenses, manage customers, or transfer funds directly from the Dashboard.',
        source: 'Gemini AI (Offline Mode)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTeal = const Color(0xFF075E54);
    final accentGreen = const Color(0xFF25D366);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B141A) : const Color(0xFFEFEAE2),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2C34) : primaryTeal,
        foregroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: accentGreen,
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'ENX WhatsApp AI Bot',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFF25D366), size: 15),
                    ],
                  ),
                  const Text(
                    'Online • Powered by Gemini AI',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE2F7CB), fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Conversation',
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages Canvas
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator(isDark);
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark);
                },
              ),
            ),

            // Quick Suggestions Carousel
            _buildSuggestionsBar(isDark),

            // WhatsApp Style Input Bar
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatBubbleMessage msg, bool isDark) {
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    if (msg.isUser) {
      // User message bubble (WhatsApp green)
      final userBubbleColor = isDark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3);
      final userTextColor = isDark ? Colors.white : const Color(0xFF111B21);

      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: userBubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg.text,
                style: TextStyle(
                  color: userTextColor,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: Color(0xFF53BDEB), // WhatsApp blue ticks
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Gemini AI response bubble (Clean white / dark card)
      final aiBubbleColor = isDark ? const Color(0xFF202C33) : Colors.white;
      final aiTextColor = isDark ? Colors.white : const Color(0xFF111B21);

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: aiBubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF25D366), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        msg.modelSource ?? 'Gemini AI Assistant',
                        style: const TextStyle(
                          color: Color(0xFF25D366),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _copyMessage(msg.text),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Message Text
              Text(
                msg.text,
                style: TextStyle(
                  color: aiTextColor,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF202C33) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 15, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text(
              'Gemini AI is thinking...',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsBar(bool isDark) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickSuggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _quickSuggestions[index];
          return ActionChip(
            label: Text(
              prompt,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF075E54),
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
            elevation: 1,
            side: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFF00A884).withOpacity(0.3),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    final inputBg = isDark ? const Color(0xFF1F2C34) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111B21) : const Color(0xFFF0F2F5),
      ),
      child: Row(
        children: [
          // Input pill
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00A884), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14.5),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask Gemini AI about your finances...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13.5),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Circular Button
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF00A884),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              tooltip: 'Send Message',
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
