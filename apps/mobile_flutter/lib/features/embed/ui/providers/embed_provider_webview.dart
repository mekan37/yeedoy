import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbedProviderWebview extends StatefulWidget {
  const EmbedProviderWebview({
    super.key,
    required this.pageUrl,
    required this.allowedHosts,
    required this.fallbackMessage,
    required this.onFallback,
  });

  final Uri pageUrl;
  final Set<String> allowedHosts;
  final String fallbackMessage;
  final ValueChanged<String?> onFallback;

  @override
  State<EmbedProviderWebview> createState() => _EmbedProviderWebviewState();
}

class _EmbedProviderWebviewState extends State<EmbedProviderWebview> {
  static const _loadTimeout = Duration(seconds: 9);

  late final WebViewController _controller;
  Timer? _timeoutTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isAllowedEmbedUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            _timeoutTimer?.cancel();
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            widget.onFallback(widget.fallbackMessage);
          },
        ),
      )
      ..loadRequest(widget.pageUrl);

    _timeoutTimer = Timer(_loadTimeout, () {
      widget.onFallback(widget.fallbackMessage);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  bool _isAllowedEmbedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == 'about') return true;
    return widget.allowedHosts.contains(uri.host.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
