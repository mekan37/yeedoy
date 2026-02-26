import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeedoy/core/i18n/app_localizations.dart';

import '../../../../app/theme/colors.dart';

class DiscoverySearchBar extends StatefulWidget {
  const DiscoverySearchBar({
    super.key,
    required this.controller,
    required this.recentSearches,
    required this.onDebouncedChanged,
    required this.onSubmitted,
    required this.onRecentTap,
    required this.onSuggestionTap,
    required this.onRecentRemove,
    required this.onClearRecent,
    this.suggestions = const [],
    this.hintText,
    this.debounce = const Duration(milliseconds: 300),
  });

  final TextEditingController controller;
  final List<String> recentSearches;
  final ValueChanged<String> onDebouncedChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onRecentRemove;
  final VoidCallback onClearRecent;
  final List<DiscoverySearchSuggestion> suggestions;
  final String? hintText;
  final Duration debounce;

  @override
  State<DiscoverySearchBar> createState() => _DiscoverySearchBarState();
}

class _DiscoverySearchBarState extends State<DiscoverySearchBar> {
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  bool get _showRecent =>
      _focusNode.hasFocus &&
      widget.controller.text.trim().isEmpty &&
      widget.recentSearches.isNotEmpty;

  bool get _showSuggestions =>
      _focusNode.hasFocus &&
      widget.controller.text.trim().isNotEmpty &&
      widget.suggestions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focusNode.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant DiscoverySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_refresh);
    _focusNode.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (value) {
              final query = value.trim();
              widget.onSubmitted(query);
              _focusNode.unfocus();
            },
            decoration: InputDecoration(
              hintText: widget.hintText ?? t.searchKebabsHint,
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
              suffixIcon: widget.controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: t.temizle,
                      onPressed: () {
                        widget.controller.clear();
                        widget.onDebouncedChanged('');
                        _focusNode.requestFocus();
                      },
                    ),
            ),
          ),
        ),
        if (_showRecent) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                t.discoveryRecentSearches,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onClearRecent,
                child: Text(t.temizle),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final query in widget.recentSearches)
                InputChip(
                  label: Text(query),
                  onPressed: () {
                    widget.controller.text = query;
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: query.length),
                    );
                    widget.onRecentTap(query);
                    _focusNode.unfocus();
                  },
                  onDeleted: () => widget.onRecentRemove(query),
                ),
            ],
          ),
        ],
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Text(
            t.discoveryCatalogSuggestions,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in widget.suggestions)
                InputChip(
                  label: Text(
                    suggestion.subtitle == null
                        ? suggestion.label
                        : '${suggestion.label} • ${suggestion.subtitle}',
                  ),
                  onPressed: () {
                    widget.controller.text = suggestion.label;
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: suggestion.label.length),
                    );
                    widget.onSuggestionTap(suggestion.label);
                    _focusNode.unfocus();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      widget.onDebouncedChanged(value.trim());
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}

class DiscoverySearchSuggestion {
  const DiscoverySearchSuggestion({required this.label, this.subtitle});

  final String label;
  final String? subtitle;
}
