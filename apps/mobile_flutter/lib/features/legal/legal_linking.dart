import 'package:url_launcher/url_launcher.dart';

Future<void> openLegalUrl(String raw) async {
  final uri = Uri.tryParse(raw);
  if (uri == null) {
    throw Exception('legal_link_unavailable');
  }
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw Exception('legal_link_unavailable');
  }
}
