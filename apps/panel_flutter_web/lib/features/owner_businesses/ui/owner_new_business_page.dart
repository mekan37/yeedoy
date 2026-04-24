import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../legal/legal_routes.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../data/owner_business_repository.dart';

class OwnerNewBusinessPage extends ConsumerStatefulWidget {
  const OwnerNewBusinessPage({super.key});

  @override
  ConsumerState<OwnerNewBusinessPage> createState() =>
      _OwnerNewBusinessPageState();
}

class _OwnerNewBusinessPageState extends ConsumerState<OwnerNewBusinessPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  bool _saving = false;
  bool _acceptedBusinessTerms = false;
  bool _acceptedAccuracyResponsibility = false;

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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bu alan zorunludur';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          PanelPageHeader(
            eyebrow: 'Owner',
            title: Text(l10n.ownerNewBusinessTitle),
            description: l10n.ownerNewBusinessIntro,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İşletme Bilgileri',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        validator: _required,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: l10n.ownerBusinessNameLabel,
                          prefixIcon: const Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityCtrl,
                              validator: _required,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: l10n.city,
                                prefixIcon: const Icon(Icons.location_city_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: districtCtrl,
                              validator: _required,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: l10n.district,
                                prefixIcon: const Icon(Icons.map_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: categoryCtrl,
                        validator: _required,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: l10n.ownerCategoryLabel,
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressCtrl,
                        validator: _required,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: l10n.ownerAddressLabel,
                          prefixIcon: const Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: phoneCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.ownerPhoneOptionalLabel,
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: websiteCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.ownerWebsiteOptionalLabel,
                                prefixIcon: const Icon(Icons.language_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sözleşme ve Onay',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _acceptedBusinessTerms,
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                  () => _acceptedBusinessTerms = value ?? false,
                                ),
                        title: const Text(
                          "İşletme Kullanım Koşulları'nı kabul ediyorum.",
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _acceptedAccuracyResponsibility,
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                  () => _acceptedAccuracyResponsibility =
                                      value ?? false,
                                ),
                        title: const Text(
                          'Menü ve işletme bilgilerinin doğruluğundan sorumlu olduğumu kabul ediyorum.',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => context.go(
                                  LegalRoutes.detail(LegalRoutes.businessSlug),
                                ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("İşletme Kullanım Koşulları'nı aç"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _saving
                          ? l10n.ownerSubmitting
                          : l10n.ownerSubmitApplication,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedBusinessTerms || !_acceptedAccuracyResponsibility) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Devam etmek için işletme koşullarını ve doğruluk beyanını kabul edin.',
          ),
        ),
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
            website: websiteCtrl.text.trim().isEmpty
                ? null
                : websiteCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerApplicationReceived)),
      );
      context.go('/owner/businesses/submissions');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
