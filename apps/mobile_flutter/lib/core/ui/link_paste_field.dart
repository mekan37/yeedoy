import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/embed/ui/embed_viewer_page.dart';
import '../i18n/app_localizations.dart';
import '../linking/link_utils.dart';

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
      _provider = normalized == null
          ? LinkProvider.unknown
          : detectProvider(normalized);
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
        builder: (_) =>
            EmbedViewerPage(url: uri.toString(), title: widget.previewTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final canPreview = _normalized != null;
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
            hintText: widget.hintText ?? 'https://...',
            suffixIcon: IconButton(
              tooltip: t.paste,
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
              child: Text(t.preview),
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
    final t = context.l10n;
    final (label, color) = switch (provider) {
      LinkProvider.youtube => ('YouTube', Colors.red),
      LinkProvider.instagram => ('Instagram', Colors.pink),
      LinkProvider.facebook => ('Facebook', Colors.blue),
      LinkProvider.unknown => (t.unknown, Colors.grey),
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
