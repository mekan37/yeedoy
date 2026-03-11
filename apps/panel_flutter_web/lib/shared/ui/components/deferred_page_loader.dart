import 'dart:async';

import 'package:flutter/material.dart';

import 'app_scaffold.dart';
import 'owner_panel_feedback.dart';

class DeferredPageLoader extends StatefulWidget {
  const DeferredPageLoader({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.fullscreen = false,
  });

  final Future<void> Function() loadLibrary;
  final WidgetBuilder builder;
  final bool fullscreen;

  @override
  State<DeferredPageLoader> createState() => _DeferredPageLoaderState();
}

class _DeferredPageLoaderState extends State<DeferredPageLoader> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError == false) {
          return widget.builder(context);
        }

        if (snapshot.hasError) {
          return _wrap(
            context,
            OwnerPanelFeedback.error(
              title: 'Lazy load error',
              description: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _loadFuture = widget.loadLibrary();
                });
              },
            ),
          );
        }

        return _wrap(context, const OwnerPanelFeedback.loading(cardCount: 4));
      },
    );
  }

  Widget _wrap(BuildContext context, Widget child) {
    if (widget.fullscreen) {
      return AppScaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
