import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../embed/ui/embed_viewer_page.dart' deferred as embed_viewer_page;
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/linking/link_utils.dart';
import '../../../../shared/ui/components/deferred_page_loader.dart';

class LinkPasteField extends StatefulWidget {
  const LinkPasteField({
    super.key,
    this.label,
    this.hintText,
    this.previewTitle,
    this.controller,
  });

  final String? label;
  final String? hintText;
  final String? previewTitle;
  final TextEditingController? controller;

  @override
  State<LinkPasteField> createState() => _LinkPasteFieldState();
}

class _LinkPasteFieldState extends State<LinkPasteField> {
  static const _debounce = Duration(milliseconds: 400);

  late final TextEditingController _controller;
  Timer? _debounceTimer;
  Uri? _normalized;
  LinkProvider _provider = LinkProvider.unknown;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _evaluate(_controller.text);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _scheduleEvaluate(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _evaluate(value));
  }

  void _evaluate(String value) {
    final normalized = normalizeUrl(value);
    setState(() {
      _normalized = normalized;
      _provider = normalized == null ? LinkProvider.unknown : detectProvider(normalized);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    _controller.text = text;
    _scheduleEvaluate(text);
  }

  Future<void> _openPreview() async {
    final uri = _normalized;
    if (uri == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeferredPageLoader(
          loadLibrary: embed_viewer_page.loadLibrary,
          fullscreen: true,
          builder: (_) => embed_viewer_page.EmbedViewerPage(
            url: uri.toString(),
            title: widget.previewTitle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPreview = _normalized != null;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onChanged: _scheduleEvaluate,
          onSubmitted: _scheduleEvaluate,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText ?? l10n.ownerOnboardingUrlHint,
            suffixIcon: IconButton(
              tooltip: l10n.ownerOnboardingPasteAction,
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.paste_rounded),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ProviderBadge(provider: _provider),
            const Spacer(),
            FilledButton.tonal(
              onPressed: canPreview ? _openPreview : null,
              child: Text(l10n.preview),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.provider});

  final LinkProvider provider;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (provider) {
      LinkProvider.youtube => ('YouTube', Colors.red),
      LinkProvider.instagram => ('Instagram', Colors.pink),
      LinkProvider.facebook => ('Facebook', Colors.blue),
      LinkProvider.unknown => (context.l10n.unknown, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
