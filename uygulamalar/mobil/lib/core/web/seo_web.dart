// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void setSeo({
  required String title,
  String? description,
  String? imageUrl,
  String? url,
  String? siteName,
}) {
  html.document.title = title;
  _setMeta('description', description ?? '');
  _setMetaProperty('og:title', title);
  _setMetaProperty('og:type', 'website');
  if (siteName != null && siteName.trim().isNotEmpty) {
    _setMetaProperty('og:site_name', siteName);
  }
  if (url != null && url.trim().isNotEmpty) {
    _setMetaProperty('og:url', url);
  }
  if (description != null && description.trim().isNotEmpty) {
    _setMetaProperty('og:description', description);
  }
  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    _setMetaProperty('og:image', imageUrl);
    _setMetaProperty('twitter:image', imageUrl);
  }
  _setMetaProperty(
    'twitter:card',
    imageUrl != null && imageUrl.trim().isNotEmpty
        ? 'summary_large_image'
        : 'summary',
  );
  _setMetaProperty('twitter:title', title);
  if (description != null && description.trim().isNotEmpty) {
    _setMetaProperty('twitter:description', description);
  }
}

void _setMeta(String name, String content) {
  var el = html.document.head?.querySelector('meta[name="$name"]') as html.MetaElement?;
  el ??= html.MetaElement()..name = name;
  el.content = content;
  if (el.parent == null) {
    html.document.head?.append(el);
  }
}

void _setMetaProperty(String property, String content) {
  var el = html.document.head?.querySelector('meta[property="$property"]') as html.MetaElement?;
  el ??= html.MetaElement()..setAttribute('property', property);
  el.content = content;
  if (el.parent == null) {
    html.document.head?.append(el);
  }
}
