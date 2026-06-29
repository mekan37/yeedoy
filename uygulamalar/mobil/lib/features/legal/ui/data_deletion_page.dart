import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../legal_providers.dart';
import '../legal_repository.dart';

class DataDeletionPage extends ConsumerStatefulWidget {
  const DataDeletionPage({super.key});

  @override
  ConsumerState<DataDeletionPage> createState() => _DataDeletionPageState();
}

class _DataDeletionPageState extends ConsumerState<DataDeletionPage> {
  String? _reason;
  final _descCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  static const _reasons = [
    'Hesabımı silme talebi',
    'Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi',
    'Yorum, favori veya check-in verilerimle ilgili talep',
    'Destek talebi geçmişimle ilgili talep',
    'İşletme sahipliği başvurumla ilgili talep',
    'Pazarlama e-postası iznini kapatmak istiyorum',
    'Diğer',
  ];

  static const _marketingReason = 'Pazarlama e-postası iznini kapatmak istiyorum';

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _isMarketingSelected => _reason == _marketingReason;

  /// UI seçeneğini RPC request_type değerine dönüştürür.
  static String _reasonToRequestType(String reason) {
    return switch (reason) {
      'Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi' =>
        'delete_data',
      'Yorum, favori veya check-in verilerimle ilgili talep' =>
        'delete_interactions',
      'Destek talebi geçmişimle ilgili talep' => 'delete_support',
      'İşletme sahipliği başvurumla ilgili talep' => 'delete_owner_claims',
      _ => 'other',
    };
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (_reason == null) {
      setState(() => _errorMessage = 'Lütfen talep nedenini seçin.');
      return;
    }

    // Pazarlama e-postası kapatma, veri silme talebinden farklı bir işlemdir.
    // Kullanıcıyı bildirim ayarları sayfasına yönlendiriyoruz; form göndermiyoruz.
    if (_isMarketingSelected) {
      if (!mounted) return;
      context.push('/notification-preferences');
      return;
    }

    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Lütfen e-posta adresinizi girin.');
      return;
    }

    setState(() => _loading = true);
    try {
      final details = 'Neden: $_reason'
          '${_descCtrl.text.trim().isNotEmpty ? '\n\n${_descCtrl.text.trim()}' : ''}';

      // Hesap silme talebi ayrı RPC ve ayrı tabloya gider.
      if (_reason == 'Hesabımı silme talebi') {
        await ref.read(legalRepositoryProvider).submitAccountDeletionRequest(
          reason: details,
        );
      } else {
        // Diğer gizlilik/veri talepleri → submit_privacy_request_v1
        final requestType = _reasonToRequestType(_reason!);
        await ref.read(legalRepositoryProvider).submitPrivacyRequest(
          requestType: requestType,
          details: details,
        );
      }

      ref.invalidate(legalRequestOverviewProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Talebiniz alınmıştır. Değerlendirme sonucu size bildirilecektir.',
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textStrong,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Veri Silme Talebi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
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
            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _InfoHeroCard(),
                  const SizedBox(height: 24),
                  _SectionTitle('Talep Öncesi Bilgilendirme'),
                  const SizedBox(height: 8),
                  _PreRequestCard(),
                  const SizedBox(height: 24),
                  _SectionTitle('Talep Bilgileri'),
                  const SizedBox(height: 8),
                  _FormCard(
                    reason: _reason,
                    reasons: _reasons,
                    descCtrl: _descCtrl,
                    emailCtrl: _emailCtrl,
                    showEmailField: !_isMarketingSelected,
                    onReasonChanged: (v) => setState(() {
                      _reason = v;
                      _errorMessage = null;
                    }),
                  ),
                  if (_isMarketingSelected) ...[
                    const SizedBox(height: 16),
                    _MarketingRedirectNote(),
                  ],
                  if (!_isMarketingSelected) ...[
                    const SizedBox(height: 24),
                    _SectionTitle('Talebiniz Alındıktan Sonra'),
                    const SizedBox(height: 8),
                    _AfterSubmitCard(),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: _errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isMarketingSelected
                                  ? 'Bildirim Ayarlarına Git'
                                  : 'Talebimi Gönder',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.muted),
                      SizedBox(width: 6),
                      Text(
                        'Tüm talepleriniz gizli ve güvenli bir şekilde işlenir.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
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

// ── Info hero card ────────────────────────────────────────────────────────────

class _InfoHeroCard extends StatelessWidget {
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
            width: 68,
            height: 68,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.primary.withValues(alpha: 0.45),
                    size: 30,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 15,
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
                  'Verilerinizi silme hakkınız',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında, kişisel verilerinizin silinmesini talep etme hakkına sahipsiniz.',
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

// ── Pre-request info card ─────────────────────────────────────────────────────

class _PreRequestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _InfoRow(
            iconBg: Color(0xFFE8F5E9),
            iconColor: Color(0xFF2E7D32),
            icon: Icons.check_circle_outline_rounded,
            text:
                'Hesabınıza ilişkin kişisel verilerinizin silinmesini, yok edilmesini veya anonim hale getirilmesini talep edebilirsiniz.',
            isBold: false,
            isFirst: true,
          ),
          Divider(height: 1, color: AppColors.border, indent: 60),
          _InfoRow(
            iconBg: Color(0xFFF3E5F5),
            iconColor: Color(0xFF6A1B9A),
            icon: Icons.shield_outlined,
            text:
                'Bazı veriler yasal yükümlülükler veya güvenlik nedeniyle sınırlı süre saklanabilir.',
          ),
          Divider(height: 1, color: AppColors.border, indent: 60),
          _InfoRow(
            iconBg: Color(0xFFE3F2FD),
            iconColor: Color(0xFF1565C0),
            icon: Icons.mail_outline_rounded,
            text: 'Talebinizin sonucu size bildirilecektir.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.text,
    this.isBold = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String text;
  final bool isBold;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textStrong,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.reason,
    required this.reasons,
    required this.descCtrl,
    required this.emailCtrl,
    required this.onReasonChanged,
    this.showEmailField = true,
  });

  final String? reason;
  final List<String> reasons;
  final TextEditingController descCtrl;
  final TextEditingController emailCtrl;
  final ValueChanged<String?> onReasonChanged;
  final bool showEmailField;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Talep Nedeni',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: reason,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Seçiniz',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                ),
                isExpanded: true,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                  ),
                ),
                items: reasons
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(r, style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onReasonChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                'Açıklama ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              Text(
                '(İsteğe Bağlı)',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: descCtrl,
                  maxLines: 5,
                  maxLength: 500,
                  buildCounter:
                      (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.all(12),
                    hintText:
                        'Talebinizle ilgili eklemek istediğiniz bir açıklama varsa yazabilirsiniz...',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 12, 8),
                  child: Text(
                    '${descCtrl.text.length}/500',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          if (showEmailField) ...[
            const SizedBox(height: 16),
            const Text(
              'E-posta Adresiniz',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Talebinizin sonucu bu e-posta adresine iletilecektir.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintText: 'ornek@email.com',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Marketing redirect note ───────────────────────────────────────────────────

class _MarketingRedirectNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pazarlama e-postasını kapatmak, veri silme talebinden farklı bir işlemdir. '
              'Bu seçenek yalnızca gelecekteki kampanya e-postalarını durdurur; '
              'mevcut verilerinizin silinmesini sağlamaz. '
              'Bildirim Ayarları sayfasından kolayca kapatabilirsiniz.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6D4C00),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── After submit card ─────────────────────────────────────────────────────────

class _AfterSubmitCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF1565C0),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Talebiniz alınır ve değerlendirilir. Talebinizin sonucu size bildirilecektir. Bazı veriler yasal yükümlülükler nedeniyle sınırlı süre saklanabilir.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1565C0),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

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

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
