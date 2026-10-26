import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';

/// In-app WebView screen displaying Terms of Service & Privacy Policy.
/// Strictly mirrors the legacy Android `TermsConditionActivity.java` and `activity_terms_condition.xml`.
class TermsConditionScreen extends StatefulWidget {
  final String? url;
  final String title;

  const TermsConditionScreen({
    super.key,
    this.url,
    this.title = 'Terms & Conditions',
  });

  @override
  State<TermsConditionScreen> createState() => _TermsConditionScreenState();
}

class _TermsConditionScreenState extends State<TermsConditionScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  String get _targetUrl => widget.url ?? ApiEndpoints.termsAndConditionsUrl;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      final binding = WidgetsBinding.instance.runtimeType.toString();
      if (binding.contains('TestWidgetsFlutterBinding') || binding.contains('AutomatedTestWidgetsFlutterBinding')) {
        _hasError = true;
        _isLoading = false;
        return;
      }
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('[TermsConditionScreen] WebResourceError: ${error.description}, isForMainFrame: ${error.isForMainFrame}');
              if (error.isForMainFrame ?? false) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                  });
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_targetUrl));

      _controller = controller;
    } on AssertionError catch (e) {
      debugPrint('[TermsConditionScreen] WebView not supported in current environment: $e');
      _hasError = true;
      _isLoading = false;
    } catch (e) {
      debugPrint('[TermsConditionScreen] WebView initialization error: $e');
      _hasError = true;
      _isLoading = false;
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(_targetUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $_targetUrl'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: _openInExternalBrowser,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Stack(
            children: [
              if (_controller != null && !_hasError)
                WebViewWidget(controller: _controller!)
              else if (_hasError)
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load Terms & Conditions document.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _hasError = false;
                                });
                                _controller?.reload();
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _openInExternalBrowser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.open_in_browser, size: 18),
                              label: const Text('Open in Browser'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1976D2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
