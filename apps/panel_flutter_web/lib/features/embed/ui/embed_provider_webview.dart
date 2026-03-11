import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../shared/ui/components/owner_panel_feedback.dart';

class EmbedWebviewView extends StatefulWidget {
  const EmbedWebviewView({
    super.key,
    required this.pageUrl,
    required this.onFallback,
    required this.fallbackMessage,
  });

  final Uri pageUrl;
  final ValueChanged<String?> onFallback;
  final String fallbackMessage;

  @override
  State<EmbedWebviewView> createState() => _EmbedWebviewViewState();
}

class _EmbedWebviewViewState extends State<EmbedWebviewView> {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: OwnerPanelFeedback.loading(cardCount: 2),
              ),
            ),
          ),
      ],
    );
  }
}
