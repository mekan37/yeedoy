import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/linking/link_provider.dart';
import '../../../core/linking/link_utils.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import 'embed_provider_iframe.dart';
import 'embed_provider_webview.dart' deferred as embed_provider_webview;
import 'embed_provider_youtube.dart' deferred as embed_provider_youtube;

enum _EmbedRuntimeProvider { iframe, youtube, webview, unsupported }

class EmbedViewerPage extends StatefulWidget {
  const EmbedViewerPage({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<EmbedViewerPage> createState() => _EmbedViewerPageState();
}

class _EmbedViewerPageState extends State<EmbedViewerPage> {
  EmbedDecision? _decision;
  _EmbedRuntimeProvider? _provider;
  Future<void>? _providerLoadFuture;
  bool _loading = true;
  bool _openedInBrowser = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final t = AppLocalizations.of(context);
    final normalized = normalizeUrl(widget.url);
    if (normalized == null) {
      setState(() {
        _loading = false;
        _errorMessage = t.invalidLinkMessage;
        _provider = _EmbedRuntimeProvider.unsupported;
      });
      return;
    }

    final decision = getEmbedDecision(normalized);
    final provider = _selectProvider(decision);
    Future<void>? providerLoadFuture;
    if (provider == _EmbedRuntimeProvider.youtube) {
      providerLoadFuture = embed_provider_youtube.loadLibrary();
    } else if (provider == _EmbedRuntimeProvider.webview) {
      providerLoadFuture = embed_provider_webview.loadLibrary();
    }

    setState(() {
      _decision = decision;
      _provider = provider;
      _providerLoadFuture = providerLoadFuture;
      _loading = providerLoadFuture != null;
      _errorMessage = provider == _EmbedRuntimeProvider.unsupported
          ? t.embedUnsupported
          : null;
    });

    if (providerLoadFuture != null) {
      try {
        await providerLoadFuture;
        if (!mounted) return;
        setState(() => _loading = false);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  _EmbedRuntimeProvider _selectProvider(EmbedDecision decision) {
    final uri = decision.normalizedUri;
    switch (decision.provider) {
      case LinkProvider.youtube:
        return decision.embedUrl == null
            ? _EmbedRuntimeProvider.unsupported
            : _EmbedRuntimeProvider.youtube;
      case LinkProvider.instagram:
        return _supportsInstagramIframe(uri) && decision.embedUrl != null
            ? _EmbedRuntimeProvider.iframe
            : _EmbedRuntimeProvider.webview;
      case LinkProvider.facebook:
        return _supportsFacebookIframe(uri) && decision.embedUrl != null
            ? _EmbedRuntimeProvider.iframe
            : _EmbedRuntimeProvider.webview;
      case LinkProvider.unknown:
        return _EmbedRuntimeProvider.unsupported;
    }
  }

  bool _supportsInstagramIframe(Uri uri) {
    final first = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    return first == 'p' ||
        first == 'reel' ||
        first == 'reels' ||
        first == 'tv';
  }

  bool _supportsFacebookIframe(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'fb.watch') return true;
    final first = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    return first == 'watch' || first == 'videos';
  }

  Future<void> _copyLink() async {
    final link = (_decision?.fallbackUrl ?? Uri.tryParse(widget.url))?.toString();
    if (link == null || link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.ownerCopied)));
  }

  Future<void> _openInBrowser({String? message}) async {
    final url = _decision?.fallbackUrl;
    if (url == null) return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      _openedInBrowser = true;
      _errorMessage = message ?? context.l10n.browserOpened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final title = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : t.embed;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const BackButton(),
        actions: [
          if (_decision != null)
            IconButton(
              tooltip: t.embedCopyLinkAction,
              onPressed: _copyLink,
              icon: const Icon(Icons.link_outlined),
            ),
          if (_decision != null)
            IconButton(
              tooltip: t.embedOpenBrowserAction,
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser_outlined),
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
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final t = AppLocalizations.of(context);
    final decision = _decision;
    final provider = _provider;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: OwnerPanelFeedback.loading(cardCount: 2),
      );
    }

    if (decision == null ||
        provider == null ||
        provider == _EmbedRuntimeProvider.unsupported ||
        _openedInBrowser ||
        _errorMessage != null) {
      return _FallbackInfo(
        message: _errorMessage ?? t.embedUnsupported,
        link: decision?.fallbackUrl.toString() ?? widget.url,
        onCopy: _copyLink,
        onOpenInBrowser: decision == null ? null : _openInBrowser,
      );
    }

    if (provider == _EmbedRuntimeProvider.iframe) {
      final src = decision.embedUrl ?? decision.fallbackUrl;
      return EmbedIframeView(src: src.toString());
    }

    if (provider == _EmbedRuntimeProvider.youtube) {
      return FutureBuilder<void>(
        future: _providerLoadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: OwnerPanelFeedback.loading(cardCount: 2),
            );
          }
          if (snapshot.hasError) {
            return _FallbackInfo(
              message: t.embedFailed,
              link: decision.fallbackUrl.toString(),
              onCopy: _copyLink,
              onOpenInBrowser: _openInBrowser,
            );
          }
          return embed_provider_youtube.EmbedYoutubeView(
            sourceUrl: decision.normalizedUri.toString(),
            fallbackMessage: t.embedFailed,
          );
        },
      );
    }

    return FutureBuilder<void>(
      future: _providerLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: OwnerPanelFeedback.loading(cardCount: 2),
          );
        }
        if (snapshot.hasError) {
          return _FallbackInfo(
            message: t.embedFailed,
            link: decision.fallbackUrl.toString(),
            onCopy: _copyLink,
            onOpenInBrowser: _openInBrowser,
          );
        }
        return embed_provider_webview.EmbedWebviewView(
          pageUrl: decision.fallbackUrl,
          fallbackMessage: t.embedFailed,
          onFallback: (message) => _openInBrowser(message: message),
        );
      },
    );
  }
}

class _FallbackInfo extends StatelessWidget {
  const _FallbackInfo({
    required this.message,
    required this.link,
    required this.onCopy,
    this.onOpenInBrowser,
  });

  final String message;
  final String link;
  final VoidCallback onCopy;
  final VoidCallback? onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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
              SelectableText(
                link,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(t.embedCopyLinkAction),
                  ),
                  if (onOpenInBrowser != null)
                    FilledButton.icon(
                      onPressed: onOpenInBrowser,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(t.embedOpenBrowserAction),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(t.back),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
