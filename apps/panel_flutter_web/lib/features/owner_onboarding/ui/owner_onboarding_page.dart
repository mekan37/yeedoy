import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/web/download_utils.dart';
import 'widgets/link_paste_field.dart';
import '../../../core/security/app_role_providers.dart';
import '../../auth/domain/auth_providers.dart';
import '../../owner_claims/my_claims_controller.dart';
import '../../../data/repositories/business_amenities_repository.dart';
import '../../business/domain/business_amenities_provider.dart';
import '../domain/owner_onboarding_models.dart';
import '../domain/owner_onboarding_providers.dart';
import '../../../shared/ui/components/app_scaffold.dart';

class OwnerOnboardingPage extends ConsumerStatefulWidget {
  const OwnerOnboardingPage({super.key, this.businessId, this.redirect});

  final String? businessId;
  final String? redirect;

  @override
  ConsumerState<OwnerOnboardingPage> createState() =>
      _OwnerOnboardingPageState();
}

class _OwnerOnboardingPageState extends ConsumerState<OwnerOnboardingPage> {
  final _logoCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _instagramLinkCtrl = TextEditingController();
  final _youtubeLinkCtrl = TextEditingController();
  final _facebookLinkCtrl = TextEditingController();
  final _qrKey = GlobalKey();
  final Set<String> _amenityKeys = {};

  String _selectedBusinessId = '';
  bool _profileSeeded = false;
  bool _amenitiesSeeded = false;
  int _currentStep = 0;
  bool _stepBusy = false;
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  @override
  void dispose() {
    _logoCtrl.dispose();
    _coverCtrl.dispose();
    _instagramLinkCtrl.dispose();
    _youtubeLinkCtrl.dispose();
    _facebookLinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      final redirect = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login?redirect=$redirect');
      });
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final claimsAsync = ref.watch(myClaimsProvider);
    final approved = claimsAsync.maybeWhen(
      data: (items) =>
          items.where((c) => c.claim.status == 'approved').toList(),
      orElse: () => const [],
    );

    if (_selectedBusinessId.isEmpty && approved.isNotEmpty) {
      final preferred =
          widget.businessId != null &&
              approved.any((c) => c.claim.businessId == widget.businessId)
          ? widget.businessId!
          : approved.first.claim.businessId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedBusinessId = preferred;
          _profileSeeded = false;
          _amenitiesSeeded = false;
        });
      });
    }

    if (_selectedBusinessId.isNotEmpty) {
      final canManageAsync = ref.watch(
        canManageBusinessProvider(_selectedBusinessId),
      );
      final canManage = canManageAsync.when<bool?>(
        loading: () => null,
        error: (_, _) => false,
        data: (value) => value,
      );
      if (canManage == null) {
        return const AppScaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (!canManage) {
        return const AppScaffold(
          body: Center(child: Text('Bu iÅŸletme iÃ§in yetkiniz yok.')),
        );
      }
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Kurulum'),
        actions: [
          IconButton(
            onPressed: _selectedBusinessId.isEmpty
                ? null
                : () {
                    ref.invalidate(
                      ownerOnboardingProgressProvider(_selectedBusinessId),
                    );
                    ref.invalidate(
                      ownerBusinessProfileProvider(_selectedBusinessId),
                    );
                    ref.invalidate(
                      ownerBusinessHoursProvider(_selectedBusinessId),
                    );
                    ref.invalidate(
                      ownerOnboardingMenuStatusProvider(_selectedBusinessId),
                    );
                    ref.invalidate(
                      ownerOnboardingMenuPreviewProvider(_selectedBusinessId),
                    );
                    ref.invalidate(
                      businessAmenitiesProvider(_selectedBusinessId),
                    );
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _selectedBusinessId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : claimsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(AppErrorMapper.message(e))),
              data: (items) {
                final approvedItems = items
                    .where((c) => c.claim.status == 'approved')
                    .toList();
                if (approvedItems.isEmpty) {
                  return const Center(
                    child: Text('OnaylÄ± iÅŸletme bulunamadÄ±.'),
                  );
                }

                final progressAsync = ref.watch(
                  ownerOnboardingProgressProvider(_selectedBusinessId),
                );
                return progressAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(AppErrorMapper.message(e))),
                  data: (progress) {
                    if (progress.stepCompleted >= 5) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        context.go(widget.redirect ?? '/owner/menus');
                      });
                      return const Center(child: CircularProgressIndicator());
                    }

                    final maxStep = min(progress.stepCompleted, 4);
                    if (_currentStep < maxStep) {
                      _currentStep = maxStep;
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _BusinessSelector(
                            items: approvedItems,
                            selectedId: _selectedBusinessId,
                            onChanged: (id) {
                              setState(() {
                                _selectedBusinessId = id;
                                _profileSeeded = false;
                                _amenitiesSeeded = false;
                                _currentStep = min(progress.stepCompleted, 4);
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: Stepper(
                            currentStep: _currentStep,
                            onStepTapped: (idx) {
                              final allowed =
                                  idx <=
                                  max(progress.stepCompleted, _currentStep);
                              if (!allowed) return;
                              setState(() => _currentStep = idx);
                            },
                            controlsBuilder: (ctx, details) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    FilledButton(
                                      onPressed: _stepBusy
                                          ? null
                                          : details.onStepContinue,
                                      child: Text(
                                        _currentStep == 4 ? 'Bitir' : 'Devam',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_currentStep > 0)
                                      OutlinedButton(
                                        onPressed: _stepBusy
                                            ? null
                                            : details.onStepCancel,
                                        child: const Text('Geri'),
                                      ),
                                  ],
                                ),
                              );
                            },
                            onStepContinue: () => _handleContinue(),
                            onStepCancel: () {
                              if (_currentStep > 0) {
                                setState(() => _currentStep -= 1);
                              }
                            },
                            steps: [
                              Step(
                                title: const Text('Profil'),
                                content: _buildProfileStep(),
                                isActive: _currentStep == 0,
                                state: progress.stepCompleted >= 1
                                    ? StepState.complete
                                    : StepState.indexed,
                              ),
                              Step(
                                title: const Text('Ã–zellikler'),
                                content: _buildAmenitiesStep(),
                                isActive: _currentStep == 1,
                                state: progress.stepCompleted >= 2
                                    ? StepState.complete
                                    : StepState.indexed,
                              ),
                              Step(
                                title: const Text('Menu'),
                                content: _buildMenuStep(),
                                isActive: _currentStep == 2,
                                state: progress.stepCompleted >= 3
                                    ? StepState.complete
                                    : StepState.indexed,
                              ),
                              Step(
                                title: const Text('Ã–nizleme'),
                                content: _buildPreviewStep(),
                                isActive: _currentStep == 3,
                                state: progress.stepCompleted >= 4
                                    ? StepState.complete
                                    : StepState.indexed,
                              ),
                              Step(
                                title: const Text('PaylaÅŸ'),
                                content: _buildShareStep(),
                                isActive: _currentStep == 4,
                                state: progress.stepCompleted >= 5
                                    ? StepState.complete
                                    : StepState.indexed,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildProfileStep() {
    final profileAsync = ref.watch(
      ownerBusinessProfileProvider(_selectedBusinessId),
    );
    final hoursAsync = ref.watch(
      ownerBusinessHoursProvider(_selectedBusinessId),
    );

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(AppErrorMapper.message(e)),
      data: (profile) {
        if (!_profileSeeded) {
          _logoCtrl.text = profile.logoUrl;
          _coverCtrl.text = profile.coverUrl;
          _profileSeeded = true;
        }

        hoursAsync.whenData((hours) {
          _openTime ??= _parseTime(hours?.openTime);
          _closeTime ??= _parseTime(hours?.closeTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logo ve kapak ekleyin, saatleri belirleyin.'),
            const SizedBox(height: 12),
            TextField(
              controller: _logoCtrl,
              decoration: const InputDecoration(labelText: 'Logo URL'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _coverCtrl,
              decoration: const InputDecoration(labelText: 'Kapak URL'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isOpen: true),
                    child: Text(
                      _openTime == null
                          ? 'AÃ§Ä±lÄ±ÅŸ saati seÃ§'
                          : 'AÃ§Ä±lÄ±ÅŸ: ${_openTime!.format(context)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isOpen: false),
                    child: Text(
                      _closeTime == null
                          ? 'KapanÄ±ÅŸ saati seÃ§'
                          : 'KapanÄ±ÅŸ: ${_closeTime!.format(context)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Saatler tÃ¼m gÃ¼nlere uygulanÄ±r.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ä°ÅŸletme Linkleri (IG/YouTube/Facebook)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            LinkPasteField(
              label: 'Instagram',
              hintText: 'https://instagram.com/...',
              previewTitle: 'Instagram Ã–nizleme',
              controller: _instagramLinkCtrl,
            ),
            const SizedBox(height: 10),
            LinkPasteField(
              label: 'YouTube',
              hintText: 'https://youtube.com/...',
              previewTitle: 'YouTube Ã–nizleme',
              controller: _youtubeLinkCtrl,
            ),
            const SizedBox(height: 10),
            LinkPasteField(
              label: 'Facebook',
              hintText: 'https://facebook.com/...',
              previewTitle: 'Facebook Ã–nizleme',
              controller: _facebookLinkCtrl,
            ),
            const SizedBox(height: 8),
            const Text(
              'Kaydetme adÄ±mÄ± yakÄ±nda eklenecek.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmenitiesStep() {
    final allAmenitiesAsync = ref.watch(allAmenitiesProvider);
    final selectedAsync = ref.watch(
      businessAmenitiesProvider(_selectedBusinessId),
    );

    selectedAsync.whenData((items) {
      if (_amenitiesSeeded) return;
      _amenitiesSeeded = true;
      _amenityKeys
        ..clear()
        ..addAll(items.map((e) => e.key));
    });

    return allAmenitiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(AppErrorMapper.message(e)),
      data: (items) {
        if (items.isEmpty) return const Text('Ã–zellik listesi bulunamadÄ±.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('En az 2 Ã¶zellik seÃ§melisiniz.'),
            const SizedBox(height: 8),
            for (final a in items)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _amenityKeys.contains(a.key),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _amenityKeys.add(a.key);
                    } else {
                      _amenityKeys.remove(a.key);
                    }
                  });
                },
                title: Text(
                  a.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMenuStep() {
    final statusAsync = ref.watch(
      ownerOnboardingMenuStatusProvider(_selectedBusinessId),
    );

    return statusAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(AppErrorMapper.message(e)),
      data: (status) {
        final complete = status.isComplete;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('En az 1 bÃ¶lÃ¼m ve 1 Ã¼rÃ¼n gerekli.'),
            const SizedBox(height: 8),
            Text('MenÃ¼ sayÄ±sÄ±: ${status.menuCount}'),
            Text('BÃ¶lÃ¼m sayÄ±sÄ±: ${status.sectionCount}'),
            Text('ÃœrÃ¼n sayÄ±sÄ±: ${status.itemCount}'),
            const SizedBox(height: 8),
            if (!complete)
              const Text(
                'MenÃ¼sÃ¼z paylaÅŸÄ±m olmaz.',
                style: TextStyle(color: AppColors.danger),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _openMenuManagement(),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('MenÃ¼ yÃ¶netimine Git'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewStep() {
    final previewAsync = ref.watch(
      ownerOnboardingMenuPreviewProvider(_selectedBusinessId),
    );
    return previewAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(AppErrorMapper.message(e)),
      data: (preview) {
        if (preview == null || preview.sections.isEmpty) {
          return const Text('Ã–nizleme icin once menu olusturun.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.menuTitle,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final section in preview.sections) ...[
              Text(
                section.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (section.items.isEmpty)
                const Text('ÃœrÃ¼n bulunamadÄ±.')
              else
                for (final item in section.items) ...[
                  _PreviewItemRow(item: item),
                  const SizedBox(height: 6),
                ],
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShareStep() {
    final statusAsync = ref.watch(
      ownerOnboardingMenuStatusProvider(_selectedBusinessId),
    );
    final previewAsync = ref.watch(
      ownerOnboardingMenuPreviewProvider(_selectedBusinessId),
    );

    return statusAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(AppErrorMapper.message(e)),
      data: (status) {
        if (status.primaryMenuId == null || status.primaryMenuId!.isEmpty) {
          return const Text('PaylaÅŸim icin once menu olusturun.');
        }
        final link = _buildShareLink(status.primaryMenuId!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PaylaÅŸim linki'),
            const SizedBox(height: 6),
            SelectableText(link),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copyText(link),
                  icon: const Icon(Icons.copy),
                  label: const Text('Linki kopyala'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _shareLink(link),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('PaylaÅŸ'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data: link,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _downloadQr(link),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('QR indir'),
              ),
            ),
            const SizedBox(height: 16),
            const _ShareSectionLabel(
              icon: FontAwesomeIcons.whatsapp,
              text: 'WhatsApp metni',
            ),
            const SizedBox(height: 6),
            _CopyRow(text: _whatsAppText(link), label: 'WhatsApp kopyala'),
            const SizedBox(height: 12),
            const _ShareSectionLabel(
              icon: FontAwesomeIcons.xTwitter,
              text: 'Twitter (X) metni',
            ),
            const SizedBox(height: 6),
            _CopyRow(text: _twitterText(link), label: 'X kopyala'),
            const SizedBox(height: 12),
            const _ShareSectionLabel(
              icon: FontAwesomeIcons.instagram,
              text: 'Instagram metni',
            ),
            const SizedBox(height: 6),
            _CopyRow(text: _instagramText(link), label: 'Instagram kopyala'),
            const SizedBox(height: 12),
            previewAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, _) => const SizedBox.shrink(),
              data: (preview) => preview == null
                  ? const SizedBox.shrink()
                  : Text(
                      'Menu: ${preview.menuTitle}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedBusinessId.isEmpty) return;
    if (_stepBusy) return;

    switch (_currentStep) {
      case 0:
        await _completeStep1();
        break;
      case 1:
        await _completeStep2();
        break;
      case 2:
        await _completeStep3();
        break;
      case 3:
        await _completeStep4();
        break;
      case 4:
        await _completeStep5();
        break;
    }
  }

  Future<void> _completeStep1() async {
    final logo = _logoCtrl.text.trim();
    final cover = _coverCtrl.text.trim();
    if (logo.isEmpty || cover.isEmpty) {
      _showSnack('Logo ve kapak zorunlu.');
      return;
    }
    if (_openTime == null || _closeTime == null) {
      _showSnack('Saatler zorunlu.');
      return;
    }
    final open = _formatTime(_openTime!);
    final close = _formatTime(_closeTime!);

    setState(() => _stepBusy = true);
    try {
      final repo = ref.read(ownerOnboardingRepositoryProvider);
      await repo.updateBusinessProfile(
        businessId: _selectedBusinessId,
        logoUrl: logo,
        coverUrl: cover,
      );
      await repo.upsertBusinessHours(
        businessId: _selectedBusinessId,
        openTime: open,
        closeTime: close,
      );
      await repo.setProgress(_selectedBusinessId, 1);
      ref.invalidate(ownerOnboardingProgressProvider(_selectedBusinessId));
      ref.invalidate(ownerBusinessProfileProvider(_selectedBusinessId));
      ref.invalidate(ownerBusinessHoursProvider(_selectedBusinessId));
      if (!mounted) return;
      setState(() => _currentStep = 1);
    } catch (e) {
      _showSnack(AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _stepBusy = false);
    }
  }

  Future<void> _completeStep2() async {
    if (_amenityKeys.length < 2) {
      _showSnack('En az 2 Ã¶zellik seÃ§melisiniz.');
      return;
    }
    setState(() => _stepBusy = true);
    try {
      await ref
          .read(businessAmenitiesRepositoryProvider)
          .updateBusinessAmenities(
            businessId: _selectedBusinessId,
            amenityKeys: _amenityKeys.toList(),
          );
      ref.invalidate(businessAmenitiesProvider(_selectedBusinessId));
      await ref
          .read(ownerOnboardingRepositoryProvider)
          .setProgress(_selectedBusinessId, 2);
      ref.invalidate(ownerOnboardingProgressProvider(_selectedBusinessId));
      if (!mounted) return;
      setState(() => _currentStep = 2);
    } catch (e) {
      _showSnack(AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _stepBusy = false);
    }
  }

  Future<void> _completeStep3() async {
    setState(() => _stepBusy = true);
    try {
      final status = await ref
          .read(ownerOnboardingRepositoryProvider)
          .getMenuStatus(_selectedBusinessId);
      if (!status.isComplete) {
        _showSnack('MenÃ¼sÃ¼z paylaÅŸÄ±m olmaz.');
        return;
      }
      await ref
          .read(ownerOnboardingRepositoryProvider)
          .setProgress(_selectedBusinessId, 3);
      ref.invalidate(ownerOnboardingProgressProvider(_selectedBusinessId));
      if (!mounted) return;
      setState(() => _currentStep = 3);
    } catch (e) {
      _showSnack(AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _stepBusy = false);
    }
  }

  Future<void> _completeStep4() async {
    setState(() => _stepBusy = true);
    try {
      await ref
          .read(ownerOnboardingRepositoryProvider)
          .setProgress(_selectedBusinessId, 4);
      ref.invalidate(ownerOnboardingProgressProvider(_selectedBusinessId));
      if (!mounted) return;
      setState(() => _currentStep = 4);
    } catch (e) {
      _showSnack(AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _stepBusy = false);
    }
  }

  Future<void> _completeStep5() async {
    setState(() => _stepBusy = true);
    try {
      await ref
          .read(ownerOnboardingRepositoryProvider)
          .setProgress(_selectedBusinessId, 5);
      ref.invalidate(ownerOnboardingProgressProvider(_selectedBusinessId));
      if (!mounted) return;
      context.go(widget.redirect ?? '/owner/menus');
    } catch (e) {
      _showSnack(AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _stepBusy = false);
    }
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final current = isOpen ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _openTime = picked;
      } else {
        _closeTime = picked;
      }
    });
  }

  void _openMenuManagement() {
    final encoded = Uri.encodeComponent(widget.redirect ?? '/owner/menus');
    context.go(
      '/owner/menus?onboarding=1&businessId=$_selectedBusinessId&redirect=$encoded',
    );
  }

  Future<void> _downloadQr(String link) async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      _showSnack('QR hazÄ±r deÄŸil.');
      return;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      _showSnack('QR indirilemedi.');
      return;
    }
    final bytes = byteData.buffer.asUint8List();

    if (kIsWeb) {
      await downloadBytes(
        bytes: bytes,
        fileName: AppConfig.menuQrFileName,
        mimeType: 'image/png',
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: AppConfig.menuQrFileName,
              mimeType: 'image/png',
            ),
          ],
        ),
      );
    }
  }

  void _shareLink(String link) {
    if (kIsWeb) {
      _copyText(link);
      return;
    }
    SharePlus.instance.share(ShareParams(text: link));
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('KopyalandÄ±');
  }

  String _buildShareLink(String menuId) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      final base = origin.isEmpty ? AppConfig.webBaseUrl : origin;
      return '$base/menu/$menuId';
    }
    return AppConfig.menuWebUrl(menuId);
  }

  String _whatsAppText(String link) {
    return 'MenÃ¼mÃ¼z gÃ¼ncel. Buradan inceleyebilirsiniz: $link';
  }

  String _twitterText(String link) {
    return 'GÃ¼ncel menÃ¼ - DoÄŸrulanmÄ±ÅŸ fiyatlar - $link';
  }

  String _instagramText(String link) {
    return 'GÃ¼ncel menÃ¼ - DoÄŸrulanmÄ±ÅŸ fiyatlar - $link';
  }
  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PreviewItemRow extends StatelessWidget {
  const _PreviewItemRow({required this.item});
  final OwnerOnboardingMenuItem item;

  @override
  Widget build(BuildContext context) {
    final price = _fmtPrice(item.priceCents, item.currency);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (item.description.trim().isNotEmpty)
                Text(
                  item.description,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(price, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.text, required this.label});

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text)),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          child: Text(label),
        ),
      ],
    );
  }
}

class _ShareSectionLabel extends StatelessWidget {
  const _ShareSectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

String _fmtPrice(int? cents, String? currency) {
  if (cents == null) return '-';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  final cur = (currency ?? 'TRY') == 'TRY' ? 'TL ' : '${currency ?? ''} ';
  return '$cur$text';
}

class _BusinessSelector extends StatelessWidget {
  const _BusinessSelector({
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  final List<dynamic> items;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Ä°ÅŸletme:', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedId.isEmpty ? null : selectedId,
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item.claim.businessId,
                  child: Text(item.businessName),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}


