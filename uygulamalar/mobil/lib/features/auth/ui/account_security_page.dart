import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../legal/legal_repository.dart';
import '../data/auth_service_provider.dart';
import '../domain/auth_providers.dart';

// ── Security score constants (would come from a real provider later) ──────────

const int _kScore = 4;
const int _kTotal = 5;
const Color _kGreen = AppColors.success;

// ── Page ─────────────────────────────────────────────────────────────────────

class AccountSecurityPage extends ConsumerStatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  ConsumerState<AccountSecurityPage> createState() =>
      _AccountSecurityPageState();
}

class _AccountSecurityPageState extends ConsumerState<AccountSecurityPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Hesap Güvenliği',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          'Hesabınızı koruyun, güvende kalın.',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.primarySoft,
                    shape: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Security score card ───────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SecurityScoreCard(score: _kScore, total: _kTotal),
            ),

            const SizedBox(height: 24),

            // ── Güvenlik Ayarları ─────────────────────────────────────
            const _SectionLabel('Güvenlik Ayarları'),
            const SizedBox(height: 10),
            _SecurityGroup(
              items: [
                _SecurityRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Şifre',
                  subtitle: 'Şifrenizi düzenleyin',
                  trailing: const _MetaText('Son değişiklik: 15.05.2024'),
                  onTap: () => _showChangePassword(context),
                ),
                _SecurityRow(
                  icon: Icons.smartphone_rounded,
                  title: 'İki Adımlı Doğrulama',
                  subtitle: 'Hesabınıza ekstra güvenlik katın',
                  trailing: const _ActiveBadge(),
                  onTap: () {},
                ),
                _SecurityRow(
                  icon: Icons.mail_outline_rounded,
                  title: 'E-posta Adresi',
                  subtitle: 'E-posta adresinizi yönetin',
                  trailing: _MetaText(user?.email ?? ''),
                  onTap: () => _showChangeEmail(context),
                ),
                _SecurityRow(
                  icon: Icons.phone_android_rounded,
                  title: 'Güvenilen Cihazlar',
                  subtitle: 'Hesabınıza giriş yapan cihazları yönetin',
                  trailing: const _MetaText('3 cihaz'),
                  onTap: () {},
                ),
                _SecurityRow(
                  icon: Icons.key_rounded,
                  title: 'Oturum Yönetimi',
                  subtitle: 'Açık oturumlarınızı görüntüleyin',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Tips card ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TipsCard(),
            ),

            const SizedBox(height: 24),

            // ── Hesap İşlemleri ───────────────────────────────────────
            const _SectionLabel('Hesap İşlemleri'),
            const SizedBox(height: 10),
            _SecurityGroup(
              items: [
                _SecurityRow(
                  icon: Icons.download_outlined,
                  iconBgColor: const Color(0xFFF1F5F9),
                  iconColor: AppColors.textStrong,
                  title: 'Verilerinizi İndirin',
                  subtitle: 'Hesabınıza ait verilerin bir kopyasını indirin.',
                  onTap: () {},
                ),
                _SecurityRow(
                  icon: Icons.delete_outline_rounded,
                  iconBgColor: const Color(0xFFF1F5F9),
                  iconColor: AppColors.textStrong,
                  title: 'Hesabımı Sil',
                  subtitle: 'Hesabınızı kalıcı olarak silin.',
                  onTap: () => _showDeleteAccount(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Support banner ────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SupportBanner(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePassword(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChangePasswordSheet(ref: ref),
    );
  }

  Future<void> _showChangeEmail(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChangeEmailSheet(ref: ref),
    );
  }

  void _showDeleteAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final confirmationController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            final canSubmit =
                confirmationController.text.trim().toUpperCase() == 'SIL';
            return AlertDialog(
              title: const Text('Hesabımı Sil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bu işlem hesabınıza erişimi kapatır ve silinebilir veriler için silme sürecini başlatır.',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Silme nedeni',
                      hintText: 'İsterseniz nedeninizi paylaşın',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmationController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Onay',
                      hintText: 'Devam etmek için SIL yazın',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Silme Talebi Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(legalRepositoryProvider)
          .submitAccountDeletionRequest(reason: reasonController.text.trim());
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Silme talebiniz iletildi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Talep gönderilemedi.')),
        );
      }
    } finally {
      reasonController.dispose();
      confirmationController.dispose();
    }
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

// ── Security score card ───────────────────────────────────────────────────────

class _SecurityScoreCard extends StatelessWidget {
  const _SecurityScoreCard({required this.score, required this.total});
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = score / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress ring
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 7,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 7,
                        backgroundColor: Colors.transparent,
                        color: _kGreen,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: _kGreen,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Sora',
                        ),
                        children: [
                          TextSpan(text: 'Güvenlik Skorunuz: '),
                          TextSpan(
                            text: 'Yüksek',
                            style: TextStyle(
                              color: _kGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hesabınız iyi korunuyor. Güvenliğinizi artırmak için önerileri inceleyin.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Score number
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$score',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _kGreen,
                        fontFamily: 'Sora',
                      ),
                    ),
                    TextSpan(
                      text: ' /$total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress segments
          Row(
            children: [
              for (int i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          i < score ? _kGreen : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Security rows & group ─────────────────────────────────────────────────────

class _SecurityGroup extends StatelessWidget {
  const _SecurityGroup({required this.items});
  final List<_SecurityRow> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 56),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconBgColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconBgColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor ?? const Color(0xFFFEE2E2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 20,
          ),
    );
  }
}

// ── Trailing widgets ──────────────────────────────────────────────────────────

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
      ],
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Aktif',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kGreen,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
      ],
    );
  }
}

// ── Tips card ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEDEAA)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Güvenliğinizi Artırın',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textStrong,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Aşağıdaki önerileri uygulayarak hesabınızı daha da güvenli hale getirin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          _TipRow(
            icon: Icons.shield_outlined,
            title: 'Güçlü bir şifre kullanın',
            subtitle: 'Tahmin edilmesi zor, güçlü bir şifre seçin.',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _TipRow(
            icon: Icons.smartphone_outlined,
            title: 'İki adımlı doğrulamayı etkinleştirin',
            subtitle: 'Hesabınıza ekstra koruma ekleyin.',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFED7AA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFF97316), size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.muted,
        size: 20,
      ),
    );
  }
}

// ── Support banner ────────────────────────────────────────────────────────────

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yardıma mı ihtiyacınız var?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Güvenlik ile ilgili sorularınız için destek ekibimizle iletişim geçin.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            child: const Text('Destek Al'),
          ),
        ],
      ),
    );
  }
}

// ── Şifre değiştirme sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pass = _newPassCtrl.text;
    if (pass.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.ref.read(authServiceProvider).updatePassword(pass);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre başarıyla güncellendi.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Şifre Değiştir',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Yeni şifre',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Yeni şifre (tekrar)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Kaydediliyor…' : 'Şifreyi Güncelle'),
          ),
        ],
      ),
    );
  }
}

// ── E-posta değiştirme sheet ──────────────────────────────────────────────────

class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Geçerli bir e-posta girin.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.ref.read(authServiceProvider).updateEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _sent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                Text(
                  '${_emailCtrl.text.trim()} adresine doğrulama e-postası gönderildi. Bağlantıya tıkladıktan sonra e-postanız güncellenecektir.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'E-posta Değiştir',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yeni e-posta adresinize doğrulama bağlantısı gönderilecektir.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Yeni e-posta adresi',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: Text(
                    _loading ? 'Gönderiliyor…' : 'Doğrulama Bağlantısı Gönder',
                  ),
                ),
              ],
            ),
    );
  }
}
