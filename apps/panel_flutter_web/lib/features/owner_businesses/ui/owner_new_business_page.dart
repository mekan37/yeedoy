import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/app_scaffold.dart';
import '../data/owner_business_repository.dart';

class OwnerNewBusinessPage extends ConsumerStatefulWidget {
  const OwnerNewBusinessPage({super.key});

  @override
  ConsumerState<OwnerNewBusinessPage> createState() =>
      _OwnerNewBusinessPageState();
}

class _OwnerNewBusinessPageState extends ConsumerState<OwnerNewBusinessPage> {
  final nameCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    cityCtrl.dispose();
    districtCtrl.dispose();
    categoryCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(context.l10n.ownerNewBusinessTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            context.l10n.ownerNewBusinessIntro,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.ownerBusinessNameLabel,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: cityCtrl,
            decoration: InputDecoration(labelText: context.l10n.city),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: districtCtrl,
            decoration: InputDecoration(labelText: context.l10n.district),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: categoryCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.ownerCategoryLabel,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: addressCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.ownerAddressLabel,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.ownerPhoneOptionalLabel,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: websiteCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.ownerWebsiteOptionalLabel,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(
                _saving
                    ? context.l10n.ownerSubmitting
                    : context.l10n.ownerSubmitApplication,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty ||
        cityCtrl.text.trim().isEmpty ||
        districtCtrl.text.trim().isEmpty ||
        categoryCtrl.text.trim().isEmpty ||
        addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerRequiredFieldsWarning)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(ownerBusinessRepositoryProvider).submitNewBusiness(
        name: nameCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        district: districtCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        website: websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerApplicationReceived)),
      );
      context.go('/owner/businesses/submissions');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
