import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/linking/link_utils.dart';
import '../../../core/monitoring/app_telemetry.dart';
import 'providers/embed_provider_webview.dart';
import 'providers/embed_provider_youtube.dart';

class EmbedViewerPage extends ConsumerStatefulWidget {
  const EmbedViewerPage({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  ConsumerState<EmbedViewerPage> createState() => _EmbedViewerPageState();
}

class _EmbedViewerPageState extends ConsumerState<EmbedViewerPage> {
  EmbedDecision? _decision;
  bool _loading = true;
  bool _openedInBrowser = false;
  String? _errorMessage;
  final Stopwatch _openWatch = Stopwatch()..start();
  bool _perfLogged = false;
  bool _prepared = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prepared) return;
    _prepared = true;
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final t = AppLocalizations.of(context);
    final normalized = normalizeUrl(widget.url);
    if (normalized == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = t.invalidLinkMessage;
      });
      _logOpenPerf(fallbackUsed: true);
      return;
    }

    final decision = getEmbedDecision(normalized);
    if (!mounted) return;
    setState(() {
      _decision = decision;
      _loading = true;
      _errorMessage = null;
    });

    switch (decision.provider) {
      case LinkProvider.youtube:
        if (!mounted) return;
        setState(() => _loading = false);
        _logOpenPerf(fallbackUsed: false);
        return;
      case LinkProvider.instagram:
      case LinkProvider.facebook:
        if (decision.embedUrl == null) {
          await _fallbackToBrowser(
            decision.fallbackUrl,
            message: t.embedFailed,
          );
          return;
        }
        if (!mounted) return;
        setState(() => _loading = false);
        _logOpenPerf(fallbackUsed: false);
        return;
      case LinkProvider.unknown:
        await _fallbackToBrowser(
          decision.fallbackUrl,
          message: t.browserOpened,
        );
        return;
    }
  }

  Future<void> _fallbackToBrowser(Uri fallbackUrl, {String? message}) async {
    if (_openedInBrowser) return;
    await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      _openedInBrowser = true;
      _loading = false;
      _errorMessage = message;
    });
    _logOpenPerf(fallbackUsed: true);
  }

  void _logOpenPerf({required bool fallbackUsed}) {
    if (_perfLogged) return;
    _perfLogged = true;
    _openWatch.stop();
    final provider = (_decision?.provider.name ?? LinkProvider.unknown.name);
    try {
      unawaited(
        ref.read(appTelemetryProvider).logEmbedOpenLatency(
              elapsed: _openWatch.elapsed,
              provider: provider,
              fallbackUsed: fallbackUsed,
            ),
      );
    } catch (_) {
      // Telemetry bootstrap is non-blocking for embed UX.
    }
  }

  Set<String> _allowedHosts(LinkProvider provider) {
    switch (provider) {
      case LinkProvider.instagram:
        return const {'instagram.com', 'www.instagram.com'};
      case LinkProvider.facebook:
        return const {'facebook.com', 'www.facebook.com', 'fb.watch'};
      case LinkProvider.youtube:
      case LinkProvider.unknown:
        return const <String>{};
    }
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
      return EmbedProviderYoutube(
        sourceUrl: decision.normalizedUri.toString(),
        fallbackMessage: t.embedFailed,
      );
    }

    if (decision.provider == LinkProvider.instagram ||
        decision.provider == LinkProvider.facebook) {
      final embedUrl = decision.embedUrl;
      if (embedUrl == null) {
        return _FallbackInfo(message: t.embedFailed);
      }
      return EmbedProviderWebview(
        pageUrl: embedUrl,
        allowedHosts: _allowedHosts(decision.provider),
        fallbackMessage: t.embedFailed,
        onFallback: (message) => unawaited(
          _fallbackToBrowser(
            decision.fallbackUrl,
            message: message ?? t.embedFailed,
          ),
        ),
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
