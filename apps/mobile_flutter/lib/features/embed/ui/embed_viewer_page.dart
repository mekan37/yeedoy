import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/linking/link_provider.dart';
import '../../../core/linking/link_utils.dart';

class EmbedViewerPage extends StatefulWidget {
  const EmbedViewerPage({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<EmbedViewerPage> createState() => _EmbedViewerPageState();
}

class _EmbedViewerPageState extends State<EmbedViewerPage> {
  static const _loadTimeout = Duration(seconds: 9);

  EmbedDecision? _decision;
  WebViewController? _webController;
  Timer? _timeoutTimer;
  bool _loading = true;
  bool _openedInBrowser = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    final t = AppLocalizations.of(context);
    final normalized = normalizeUrl(widget.url);
    if (normalized == null) {
      setState(() {
        _loading = false;
        _errorMessage = t.invalidLinkMessage;
      });
      return;
    }

    final decision = getEmbedDecision(normalized);
    _decision = decision;

    switch (decision.provider) {
      case LinkProvider.youtube:
        setState(() => _loading = false);
        return;
      case LinkProvider.instagram:
      case LinkProvider.facebook:
        await _initWebView(decision);
        return;
      case LinkProvider.unknown:
        await _fallbackToBrowser(
          decision.fallbackUrl,
          message: t.browserOpened,
        );
        return;
    }
  }

  Future<void> _initWebView(EmbedDecision decision) async {
    final t = AppLocalizations.of(context);
    final embedUrl = decision.embedUrl;
    if (embedUrl == null) {
      await _fallbackToBrowser(decision.fallbackUrl, message: t.embedFailed);
      return;
    }

    final controller = WebViewController()
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
          onWebResourceError: (_) async {
            await _fallbackToBrowser(
              decision.fallbackUrl,
              message: t.embedFailed,
            );
          },
        ),
      )
      ..loadRequest(embedUrl);

    _webController = controller;
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_loadTimeout, () async {
      await _fallbackToBrowser(decision.fallbackUrl, message: t.embedFailed);
    });

    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
  }

  bool _isAllowedEmbedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == 'about') return true;
    final host = uri.host.toLowerCase();
    return host == 'www.instagram.com' ||
        host == 'instagram.com' ||
        host == 'www.facebook.com' ||
        host == 'facebook.com' ||
        host == 'fb.watch';
  }

  Future<void> _fallbackToBrowser(Uri fallbackUrl, {String? message}) async {
    _timeoutTimer?.cancel();
    await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      _openedInBrowser = true;
      _loading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final decision = _decision;
    final title = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : t.embed;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const BackButton(),
        actions: [
          if (decision != null)
            IconButton(
              tooltip: t.share,
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: decision.fallbackUrl.toString()),
              ),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
            ),
            child: _buildBody(decision),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(EmbedDecision? decision) {
    final t = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _openedInBrowser || decision == null) {
      return _FallbackInfo(message: _errorMessage ?? t.embedFailed);
    }

    if (decision.provider == LinkProvider.youtube) {
      final videoId = YoutubePlayerController.convertUrlToId(
        decision.normalizedUri.toString(),
      );
      if (videoId == null || videoId.isEmpty) {
        return _FallbackInfo(message: t.embedFailed);
      }
      final controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
      return YoutubePlayer(controller: controller, aspectRatio: 16 / 9);
    }

    if ((decision.provider == LinkProvider.instagram ||
            decision.provider == LinkProvider.facebook) &&
        _webController != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _webController!),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return _FallbackInfo(message: t.embedFailed);
  }
}

class _FallbackInfo extends StatelessWidget {
  const _FallbackInfo({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser, size: 36, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 16),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(t.back),
            ),
          ],
        ),
      ),
    );
  }
}
