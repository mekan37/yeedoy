import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/offline_submission_queue.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/suggestions_repository.dart';

// ── Category & reason constants ───────────────────────────────────────────────

const _kCategories = [
  ('restaurant', 'Restoran'),
  ('cafe', 'Kafe'),
  ('fish', 'Balık & Et'),
  ('bakery', 'Pastane & Fırın'),
  ('fastfood', 'Fast Food'),
  ('other', 'Diğer'),
];

const _kReasons = [
  'Lezzetli yemekleri var',
  'Harika atmosferi var',
  'Uygun fiyatlı',
  'Arkadaşlarıma tavsiye etmek istiyorum',
  'Henüz Yeedoy\'da yok',
  'Diğer',
];

// ── Page ─────────────────────────────────────────────────────────────────────

class SuggestBusinessPage extends ConsumerStatefulWidget {
  const SuggestBusinessPage({super.key});

  @override
  ConsumerState<SuggestBusinessPage> createState() =>
      _SuggestBusinessPageState();
}

class _SuggestBusinessPageState extends ConsumerState<SuggestBusinessPage> {
  final _nameCtrl = TextEditingController();
  String? _category;
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _reason;
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  double? _pickedLat;
  double? _pickedLng;

  bool _loading = false;
  bool _checkingDuplicates = false;
  List<ExistingBusinessCandidate> _duplicates = const [];
  Timer? _dupTimer;

  @override
  void initState() {
    super.initState();
    _notesCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _dupTimer?.cancel();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Help ──────────────────────────────────────────────────────────────────

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _HelpSheet(),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);

    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Öneri göndermek için giriş yapmanız gerekiyor.'),
        ),
      );
      context.go('/login?redirect=/suggest-business');
      return;
    }

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşletme adı zorunludur.')),
      );
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin.')),
      );
      return;
    }
    if (_duplicates.isNotEmpty) {
      final proceed = await _confirmWithDuplicates(t);
      if (!proceed) return;
    }

    setState(() => _loading = true);
    try {
      final notesParts = <String>[];
      if (_notesCtrl.text.trim().isNotEmpty) notesParts.add(_notesCtrl.text.trim());
      if (_reason != null) notesParts.add('Öneri Nedeni: $_reason');
      if (_pickedLat != null && _pickedLng != null) {
        notesParts.add(
          'Konum: ${_pickedLat!.toStringAsFixed(6)},${_pickedLng!.toStringAsFixed(6)}',
        );
      }
      if (_emailCtrl.text.trim().isNotEmpty) {
        notesParts.add('İletişim E-posta: ${_emailCtrl.text.trim()}');
      }

      final id = await ref.read(suggestionsRepositoryProvider).submit(
        name: _nameCtrl.text.trim(),
        category: _category!,
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        notes: notesParts.isEmpty ? null : notesParts.join('\n\n'),
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.suggestBusinessSubmitDialogTitle),
          content: Text(t.suggestBusinessSubmitDialogContent(id.substring(0, 8))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.ok),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.pop();
    } on OfflineSubmissionQueuedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.weakConnectionQueueNotice)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Duplicate check ───────────────────────────────────────────────────────

  void _scheduleDuplicateCheck() {
    _dupTimer?.cancel();
    _dupTimer = Timer(const Duration(milliseconds: 350), _runDuplicateCheck);
  }

  Future<void> _runDuplicateCheck() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 3) {
      if (!mounted) return;
      setState(() {
        _checkingDuplicates = false;
        _duplicates = const [];
      });
      return;
    }
    if (mounted) setState(() => _checkingDuplicates = true);
    try {
      final list = await ref.read(suggestionsRepositoryProvider).findPossibleExisting(
        name: name,
        address: _addressCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _duplicates = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _duplicates = const []);
    } finally {
      if (mounted) setState(() => _checkingDuplicates = false);
    }
  }

  Future<bool> _confirmWithDuplicates(AppLocalizations t) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.suggestBusinessDuplicateTitle),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.suggestBusinessDuplicateFound),
              const SizedBox(height: 8),
              for (final d in _duplicates.take(3)) ...[
                Text('• ${d.name} (${d.district} / ${d.city})'),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 8),
              Text(t.suggestBusinessDuplicateConfirm),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.suggestBusinessSendAnyway),
          ),
        ],
      ),
    );
    return res == true;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/discover'),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textStrong,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'İşletme Öner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showHelp,
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _HeroCard(),
                  const SizedBox(height: 24),

                  // ── İşletme Bilgileri ────────────────────────────────────
                  _SectionTitle('İşletme Bilgileri'),
                  const SizedBox(height: 10),
                  _InputBox(
                    icon: Icons.storefront_outlined,
                    hint: 'İşletme Adı',
                    ctrl: _nameCtrl,
                    onChanged: (_) => _scheduleDuplicateCheck(),
                  ),
                  const SizedBox(height: 8),
                  _CategoryBox(
                    value: _category,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  if (_checkingDuplicates) ...[
                    const SizedBox(height: 6),
                    const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
                  ],
                  if (_duplicates.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DuplicateWarning(
                      items: _duplicates,
                      onOpenBusiness: (id) => context.go('/b/$id'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _AddressBox(
                    ctrl: _addressCtrl,
                    onChanged: (_) => _scheduleDuplicateCheck(),
                  ),
                  const SizedBox(height: 8),
                  _LocationPickerCard(
                    lat: _pickedLat,
                    lng: _pickedLng,
                    onTap: () async {
                      final result = await showModalBottomSheet<(double, double)?>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _LocationPickerSheet(),
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _pickedLat = result.$1;
                          _pickedLng = result.$2;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _NotesBox(ctrl: _notesCtrl),

                  const SizedBox(height: 24),

                  // ── Öneri Nedeni ─────────────────────────────────────────
                  _SectionTitle('Öneri Nedeni'),
                  const SizedBox(height: 10),
                  _ReasonBox(
                    value: _reason,
                    onChanged: (v) => setState(() => _reason = v),
                  ),

                  const SizedBox(height: 24),

                  // ── Fotoğraf ─────────────────────────────────────────────
                  const _OptionalSectionTitle(
                    title: 'Fotoğraf',
                    subtitle: '(İsteğe Bağlı)',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'İşletmeye ait fotoğraflar ekleyerek önerinizi güçlendirin.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  _PhotoBox(),

                  const SizedBox(height: 24),

                  // ── İletişim Bilgileri ───────────────────────────────────
                  const _OptionalSectionTitle(
                    title: 'İletişim Bilgileri',
                    subtitle: '(İsteğe Bağlı)',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sizinle iletişime geçebilmemiz için bilgilerinizi bırakabilirsiniz.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  _InputBox(
                    icon: Icons.mail_outline_rounded,
                    hint: 'E-posta adresiniz',
                    ctrl: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  _InputBox(
                    icon: Icons.phone_outlined,
                    hint: 'Telefon numaranız',
                    ctrl: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _FeedbackInfoCard(),

                  const SizedBox(height: 24),

                  // ── Submit button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                      label: const Text(
                        'Öneriyi Gönder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: 36,
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şehrine değer kat!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Beğendiğin bir işletmeyi mi bulamıyorsun? Bize öner, değerlendirelim. Topluluğumuzun önerileriyle daha iyi bir deneyim sunalım.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input box ─────────────────────────────────────────────────────────────────

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.icon,
    required this.hint,
    required this.ctrl,
    this.onChanged,
    this.keyboardType,
  });

  final IconData icon;
  final String hint;
  final TextEditingController ctrl;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.muted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textStrong,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Category dropdown box ─────────────────────────────────────────────────────

class _CategoryBox extends StatelessWidget {
  const _CategoryBox({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.label_outline_rounded, color: AppColors.muted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                isExpanded: true,
                hint: const Text(
                  'İşletme Kategorisi',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
                items: _kCategories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.$1,
                        child: Text(c.$2),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Address box ───────────────────────────────────────────────────────────────

class _AddressBox extends StatelessWidget {
  const _AddressBox({required this.ctrl, required this.onChanged});

  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: AppColors.textStrong),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'İşletme Adresi',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Icon(Icons.my_location_outlined, color: AppColors.muted, size: 18),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ── Notes (textarea) box ──────────────────────────────────────────────────────

class _NotesBox extends StatelessWidget {
  const _NotesBox({required this.ctrl});

  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.format_list_bulleted_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLines: 4,
                  maxLength: 500,
                  buildCounter:
                      (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                  style: const TextStyle(fontSize: 13, color: AppColors.textStrong),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: 'İşletme Hakkında',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 12, 8),
            child: Text(
              '${ctrl.text.length}/500',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reason dropdown box ───────────────────────────────────────────────────────

class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.star_border_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                isExpanded: true,
                hint: const Text(
                  'Neden bu işletmeyi öneriyorsunuz?',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
                items: _kReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Photo upload box ──────────────────────────────────────────────────────────

class _PhotoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Fotoğraf Ekle',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'PNG, JPG (Maks. 5MB)',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback info card ────────────────────────────────────────────────────────

class _FeedbackInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Öneriniz değerlendirildikten sonra size geri dönüş sağlayacağız.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Duplicate warning ─────────────────────────────────────────────────────────

class _DuplicateWarning extends StatelessWidget {
  const _DuplicateWarning({required this.items, required this.onOpenBusiness});

  final List<ExistingBusinessCandidate> items;
  final ValueChanged<String> onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
              SizedBox(width: 6),
              Text(
                'Benzer işletmeler mevcut',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final d in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${d.name} • ${d.district} ${d.city}'.trim(),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenBusiness(d.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'İncele',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section title helpers ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textStrong,
      ),
    );
  }
}

class _OptionalSectionTitle extends StatelessWidget {
  const _OptionalSectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$title ',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ],
    );
  }
}

// ── Help sheet ────────────────────────────────────────────────────────────────

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Öneri Süreci Nasıl İşler?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _HelpStep(
              number: '1',
              title: 'Öneriyi gönderiyorsunuz',
              body: 'İşletme adı ve kategori zorunlu. Adres, not ve öneri nedeninizi eklerseniz değerlendirme daha hızlı olur.',
            ),
            _HelpStep(
              number: '2',
              title: 'Ekibimiz inceliyor',
              body: 'Gönderdiğiniz öneri yönetim paneline düşer. Ekibimiz tekrar eden ya da uygunsuz önerileri ayıklar.',
            ),
            _HelpStep(
              number: '3',
              title: 'İşletme platforma eklenir',
              body: 'Onaylanan işletme Yeedoy\'a eklenir. Öneri durumunu "Önerilerim" ekranından takip edebilirsiniz.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Giriş yapmış olmanız gerekiyor. Önerilerinizi takip etmek için hesabınıza giriş yapın.',
                      style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Konum seçici kart ─────────────────────────────────────────────────────────

class _LocationPickerCard extends StatelessWidget {
  const _LocationPickerCard({
    required this.lat,
    required this.lng,
    required this.onTap,
  });

  final double? lat;
  final double? lng;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocation = lat != null && lng != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation
                  ? Icons.location_on_rounded
                  : Icons.add_location_alt_outlined,
              color: hasLocation ? AppColors.primary : AppColors.muted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasLocation
                    ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                    : 'Haritadan Konum Seç (İsteğe Bağlı)',
                style: TextStyle(
                  fontSize: 13,
                  color: hasLocation ? AppColors.textStrong : AppColors.muted,
                ),
              ),
            ),
            if (hasLocation)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 16,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Konum seçici bottom sheet ─────────────────────────────────────────────────

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _mapController = MapController();
  LatLng? _selected;
  bool _gettingGps = false;

  static const _kDefaultCenter = LatLng(37.0, 35.3213);

  Future<void> _useGps() async {
    setState(() => _gettingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _selected = point);
      try {
        _mapController.move(point, 15);
      } catch (_) {}
    } catch (_) {
      // Konum alınamazsa sessizce yok say
    } finally {
      if (mounted) setState(() => _gettingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.88;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Tutamaç
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Başlık satırı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Konum Seç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _gettingGps ? null : _useGps,
                  tooltip: 'Mevcut konumum',
                  icon: Icon(
                    _gettingGps
                        ? Icons.hourglass_top_rounded
                        : Icons.my_location_rounded,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),

          // İpucu
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Haritaya dokunarak işletmenin konumunu işaretleyin.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),

          // Harita
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selected ?? _kDefaultCenter,
                initialZoom: 13.0,
                onTap: (_, point) => setState(() => _selected = point),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yeedoy.app',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 48,
                        height: 56,
                        alignment: Alignment.bottomCenter,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 48,
                          shadows: [
                            Shadow(blurRadius: 12, color: Color(0x33000000)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Alt panel
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selected != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin_drop_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selected!.latitude.toStringAsFixed(6)}, '
                          '${_selected!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).pop(
                              (_selected!.latitude, _selected!.longitude),
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _selected == null
                          ? 'Haritadan Konum Seçin'
                          : 'Bu Konumu Kullan',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
}
