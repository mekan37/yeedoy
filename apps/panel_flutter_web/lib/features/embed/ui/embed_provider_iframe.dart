import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class EmbedIframeView extends StatefulWidget {
  const EmbedIframeView({
    super.key,
    required this.src,
  });

  final String src;

  @override
  State<EmbedIframeView> createState() => _EmbedIframeViewState();
}

class _EmbedIframeViewState extends State<EmbedIframeView> {
  static int _nextViewId = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'embed-iframe-view-${_nextViewId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = widget.src
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..referrerPolicy = 'strict-origin-when-cross-origin';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
