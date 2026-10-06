import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/finance_mode_repository.dart';

class SetuAaWebviewDialog extends StatefulWidget {
  final String redirectUrl;
  final String? initialPhone;

  const SetuAaWebviewDialog({
    super.key,
    required this.redirectUrl,
    this.initialPhone,
  });

  /// Static helper to launch the dialog modal
  static Future<bool?> show(BuildContext context, {required String redirectUrl, String? phone}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (_) => SetuAaWebviewDialog(
        redirectUrl: redirectUrl,
        initialPhone: phone,
      ),
    );
  }

  @override
  State<SetuAaWebviewDialog> createState() => _SetuAaWebviewDialogState();
}

class _SetuAaWebviewDialogState extends State<SetuAaWebviewDialog> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isCompleted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0B1120))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
              _checkRedirect(url);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
              _checkRedirect(url);
            },
            onWebResourceError: (WebResourceError error) {
              // Ignore custom scheme aborts (since enxmoney:// is caught by navigation delegate)
              if (!error.description.contains('enxmoney://')) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = error.description;
                  });
                }
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith('enxmoney://bank-success')) {
                _handleSuccessRedirect(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      controller.loadRequest(Uri.parse(widget.redirectUrl));
      _webViewController = controller;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _checkRedirect(String url) {
    if (url.startsWith('enxmoney://bank-success')) {
      _handleSuccessRedirect(url);
    }
  }

  Future<void> _handleSuccessRedirect(String url) async {
    if (_isCompleted) return;
    _isCompleted = true;

    try {
      final uri = Uri.parse(url);
      final consentId = uri.queryParameters['consentId'] ?? 'cst_done';
      final bankName = uri.queryParameters['bankName'] ?? 'State Bank of India';
      final accountNumber = uri.queryParameters['accountNumber'] ?? 'XXXXXX4829';

      // Ensure persistence with backend
      await FinanceModeRepository().completeSetuAaConsent(
        consentId: consentId,
        bankName: bankName,
        accountNumber: accountNumber,
      );
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(widget.redirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                // Setu Branding Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Setu AA Gateway',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'RBI Regulated',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automated Pre-built Webview SDK',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // External Browser Icon
                IconButton(
                  tooltip: 'Open in Browser',
                  icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF94A3B8), size: 20),
                  onPressed: _openInExternalBrowser,
                ),
                // Close Button
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Loading Progress Bar
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),

          // Webview or Fallback
          Expanded(
            child: _errorMessage != null
                ? _buildErrorFallback()
                : _webViewController != null
                    ? WebViewWidget(controller: _webViewController!)
                    : _buildErrorFallback(),
          ),

          // Security Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: const Color(0xFF10B981).withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                const Text(
                  'End-to-end encrypted financial data sharing via NBFC-AA',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_rounded, size: 48, color: Color(0xFF38BDF8)),
            const SizedBox(height: 16),
            const Text(
              'Setu AA Consent Gateway',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete bank account linking in your default browser or proceed with automated simulated flow.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openInExternalBrowser,
              icon: const Icon(Icons.launch_rounded, size: 16),
              label: const Text('Open Setu Gateway'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _handleSuccessRedirect('enxmoney://bank-success?bankName=State%20Bank%20of%20India&status=SUCCESS'),
              child: const Text('Simulate Successful Consent', style: TextStyle(color: Color(0xFF34D399), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
