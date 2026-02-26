import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../features/owner_claims/owner_claim_controller.dart';

class OwnerClaimBottomSheet extends ConsumerStatefulWidget {
  const OwnerClaimBottomSheet({
    super.key,
    required this.businessId,
    required this.redirectUrl,
  });

  final String businessId;
  final String redirectUrl;

  @override
  ConsumerState<OwnerClaimBottomSheet> createState() => _OwnerClaimBottomSheetState();
}

class _OwnerClaimBottomSheetState extends ConsumerState<OwnerClaimBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _evidenceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  static final _phoneRegex = RegExp(r'^\+?\d{10,15}$');

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _evidenceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(ownerClaimControllerProvider(widget.businessId));
    final isLoading = st.status == OwnerClaimStatus.loading;
    final errorText = _errorText(st);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İşletme Sahipliği Başvurusu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'Ad soyad gerekli.';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Telefon'),
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'Telefon gerekli.';
                if (!_phoneRegex.hasMatch(text)) {
                  return 'Telefon formatı geçersiz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _evidenceCtrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Kanıt Linki (opsiyonel)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteCtrl,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                alignLabelWithHint: true,
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 6),
              Text(errorText, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : _submit,
                child: Text(isLoading ? 'Gönderiliyor...' : 'Gönder'),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  String? _errorText(OwnerClaimState st) {
    if (st.status != OwnerClaimStatus.error) return null;
    if (st.errorCode == 'rate_limited_7d') {
      return 'Bu işletmenin sahipliği için son 7 günde zaten başvuruda bulundun.';
    }
    if (st.errorCode == 'already_submitted') {
      return 'Bu işletmenin sahipliği için daha önce başvuruda bulundun.';
    }
    if (st.message != null && st.message!.isNotEmpty) {
      return st.message;
    }
    return 'Bir hata oluştu.';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final res = await ref.read(ownerClaimControllerProvider(widget.businessId).notifier).submit(
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          evidenceUrl: _evidenceCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
        );

    if (!mounted) return;

    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başvurun alındı, incelenecek.')),
      );
      Navigator.pop(context);
      return;
    }

    if (res.error == 'not_authenticated') {
      Navigator.pop(context);
      final redirect = Uri.encodeComponent(widget.redirectUrl);
      context.go('/login?redirect=$redirect');
      return;
    }

    if (res.error != 'rate_limited_7d' && res.error != 'already_submitted') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Bir hata oluştu.')),
      );
    }
  }
}




