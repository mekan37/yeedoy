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

  @override
  bool operator ==(Object other) =>
      other is EmbedDecision &&
      other.provider == provider &&
      other.normalizedUri == normalizedUri &&
      other.embedUrl == embedUrl &&
      other.fallbackUrl == fallbackUrl;

  @override
  int get hashCode =>
      Object.hash(provider, normalizedUri, embedUrl, fallbackUrl);

  @override
  String toString() =>
      'EmbedDecision(provider: $provider, normalizedUri: $normalizedUri, embedUrl: $embedUrl)';
}
