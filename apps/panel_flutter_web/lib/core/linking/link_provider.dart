enum LinkProvider { youtube, instagram, facebook, unknown }

class EmbedDecision {
  const EmbedDecision({
    required this.provider,
    required this.normalizedUri,
    required this.fallbackUrl,
    this.embedUrl,
  });

  final LinkProvider provider;
  final Uri normalizedUri;
  final Uri? embedUrl;
  final Uri fallbackUrl;
}
