import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../uygulama/tema/renkler.dart';

class EmbedProviderYoutube extends StatefulWidget {
  const EmbedProviderYoutube({
    super.key,
    required this.sourceUrl,
    required this.fallbackMessage,
  });

  final String sourceUrl;
  final String fallbackMessage;

  @override
  State<EmbedProviderYoutube> createState() => _EmbedProviderYoutubeState();
}

class _EmbedProviderYoutubeState extends State<EmbedProviderYoutube> {
  YoutubePlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.sourceUrl);
    if (videoId == null || videoId.isEmpty) {
      _error = widget.fallbackMessage;
      return;
    }
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Center(
        child: Text(
          _error ?? widget.fallbackMessage,
          style: const TextStyle(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      );
    }
    return YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9);
  }
}
