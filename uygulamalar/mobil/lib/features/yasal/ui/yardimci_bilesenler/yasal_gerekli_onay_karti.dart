import 'package:flutter/material.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../yasal_katalog.dart';

enum LegalConsentLinkStyle { text, outlined }

class LegalRequiredConsentCard extends StatelessWidget {
  const LegalRequiredConsentCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onOpenLink,
    this.disabled = false,
    this.helperText,
    this.includeCookiesLink = false,
    this.linkStyle = LegalConsentLinkStyle.text,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final ValueChanged<String> onOpenLink;
  final bool disabled;
  final String? helperText;
  final bool includeCookiesLink;
  final LegalConsentLinkStyle linkStyle;

  @override
  Widget build(BuildContext context) {
    final links = <LegalLinkDescriptor>[
      ...LegalCatalog.requiredAcceptanceLinks,
      if (includeCookiesLink) LegalCatalog.cookies,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: value,
          onChanged: disabled ? null : onChanged,
          title: const Text(
            'Devam ederek Kullanım Şartları ve Gizlilik Politikası’nı kabul ediyorum.',
          ),
        ),
        if (helperText != null && helperText!.trim().isNotEmpty) ...[
          Text(
            helperText!,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in links)
              switch (linkStyle) {
                LegalConsentLinkStyle.outlined => OutlinedButton(
                    onPressed: disabled ? null : () => onOpenLink(item.url),
                    child: Text(item.title),
                  ),
                LegalConsentLinkStyle.text => TextButton(
                    onPressed: disabled ? null : () => onOpenLink(item.url),
                    child: Text(item.title),
                  ),
              },
          ],
        ),
      ],
    );
  }
}

