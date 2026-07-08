import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _Topic {
  const _Topic({required this.icon, required this.question, required this.answer});
  final IconData icon;
  final String question;
  final String answer;
}

const List<_Topic> _kTopics = [
  _Topic(
    icon: Icons.help_outline_rounded,
    question: 'Fiyat değişikliği nasıl bildirilir?',
    answer:
        'Bir işletmeyi ziyaret ettikten sonra "Fiyat Bildir" butonuna tıklayarak güncel fiyatı girebilirsiniz. Katkınız için puan kazanırsınız.',
  ),
  _Topic(
    icon: Icons.qr_code_2_rounded,
    question: 'QR Menü nasıl taranır?',
    answer:
        'Ana ekranda sağ üstteki QR simgesine dokunun ve kamerayı masadaki QR koda tutun. Menü otomatik açılır.',
  ),
  _Topic(
    icon: Icons.shield_outlined,
    question: 'Hesabımı nasıl güvene alırım?',
    answer:
        'Güçlü bir şifre kullanın ve iki adımlı doğrulamayı etkinleştirin. Hesap Güvenliği sayfasından tüm ayarları yönetebilirsiniz.',
  ),
  _Topic(
    icon: Icons.star_outline_rounded,
    question: 'Katkı yap ve puan kazanma nasıl çalışır?',
    answer:
        'Fiyat bildirimi, yorum ve fotoğraf ekleme gibi katkılarla puan kazanırsınız. Puanlarınızı profilinizden takip edebilirsiniz.',
  ),
  _Topic(
    icon: Icons.location_on_outlined,
    question: 'Konum ve bölge ayarlarını nasıl değiştiririm?',
    answer:
        'Ayarlar → Uygulama Tercihleri → Konum Ayarları yolunu izleyerek konumunuzu ve bölgenizi güncelleyebilirsiniz.',
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Topic> get _filteredTopics {
    if (_query.isEmpty) return _kTopics;
    final q = _query.toLowerCase();
    return _kTopics
        .where((t) => t.question.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildPopularTopics(context),
                  const SizedBox(height: 24),
                  _buildHelpCenter(),
                  const SizedBox(height: 16),
                  _buildContactCard(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: IconButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/discover'),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Yardım & Destek',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/live-support'),
                child: Material(
                  color: AppColors.primarySoft,
                  shape: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.headset_mic_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Size nasıl yardımcı olabiliriz?',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Sorununuzu yazın, çözüme birlikte ulaşalım...',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick action cards ──────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Canlı Destek',
                subtitle: 'Ekibimizle anında görüşün',
                badgeLabel: 'Çevrimiçi',
                badgeColor: AppColors.success,
                badgeBg: const Color(0xFFDCFCE7),
                onTap: () => context.push('/live-support'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickCard(
                icon: Icons.mail_outline_rounded,
                title: 'E-posta Gönder',
                subtitle: 'Bize e-posta ile ulaşın',
                badgeLabel: '24 Saat İçinde Yanıt',
                badgeColor: const Color(0xFF3B82F6),
                badgeBg: const Color(0xFFDBEAFE),
                onTap: () => launchUrl(Uri(
                  scheme: 'mailto',
                  path: 'destek@yeedoy.com',
                  queryParameters: {'subject': 'Yeedoy Destek Talebi'},
                )),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickCard(
                icon: Icons.quiz_outlined,
                title: 'S.S.S.',
                subtitle: 'Sık sorulan sorulara göz atın',
                badgeLabel: 'Hızlı Çözümler',
                badgeColor: const Color(0xFF8B5CF6),
                badgeBg: const Color(0xFFEDE9FE),
                onTap: () => context.push('/faq'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickCard(
                icon: Icons.menu_book_outlined,
                title: 'Kullanım Rehberi',
                subtitle: 'Uygulamayı daha iyi öğrenin',
                badgeLabel: 'Rehbere Git',
                badgeColor: const Color(0xFFF59E0B),
                badgeBg: const Color(0xFFFEF3C7),
                onTap: () => context.push('/faq'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Popular topics ──────────────────────────────────────────────────────────

  Widget _buildPopularTopics(BuildContext context) {
    final topics = _filteredTopics;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Popüler Konular',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/faq'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tümünü Gör'),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: topics.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Sonuç bulunamadı.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < topics.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16),
                        _TopicItem(topic: topics[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Help center ─────────────────────────────────────────────────────────────

  Widget _buildHelpCenter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yardım Merkezi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _HelpCenterTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Hesap İşlemleri',
                      subtitle: 'Hesap, giriş, şifre ve profil işlemleri',
                      onTap: () => context.push('/faq'),
                    ),
                  ),
                  Expanded(
                    child: _HelpCenterTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Katkı ve Puanlar',
                      subtitle: 'Katkı yapma, puan kazanma ve ödüller',
                      onTap: () => context.push('/faq'),
                    ),
                  ),
                  Expanded(
                    child: _HelpCenterTile(
                      icon: Icons.smartphone_outlined,
                      title: 'Uygulama Kullanımı',
                      subtitle: 'Uygulama özellikleri ve kullanımı',
                      onTap: () => context.push('/faq'),
                    ),
                  ),
                  Expanded(
                    child: _HelpCenterTile(
                      icon: Icons.shield_outlined,
                      title: 'Yasal & Gizlilik',
                      subtitle: 'Gizlilik, güvenlik ve yasal konular',
                      onTap: () => context.push('/faq'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact card ─────────────────────────────────────────────────────────────

  Widget _buildContactCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bizimle İletişime Geçin',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.textStrong,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Her türlü soru, öneri veya şikayetinizi bizimle paylaşabilirsiniz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ContactRow(
                    icon: Icons.mail_outline_rounded,
                    text: 'destek@yeedoy.com',
                  ),
                  SizedBox(height: 6),
                  _ContactRow(
                    icon: Icons.access_time_outlined,
                    text: 'Hafta içi 09:00 - 18:00',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sorununuz çözüldü mü?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Teşekkürler! 👍')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    foregroundColor: Color(0xFF16A34A),
                    backgroundColor: Color(0xFFF0FDF4),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('Evet, çözüldü'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/live-support'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.danger),
                    foregroundColor: AppColors.danger,
                    backgroundColor: const Color(0xFFFFF1F2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.thumb_down_outlined, size: 16),
                  label: const Text('Hayır, devam ediyor'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeBg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                height: 1.3,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Topic accordion item ──────────────────────────────────────────────────────

class _TopicItem extends StatefulWidget {
  const _TopicItem({required this.topic});
  final _Topic topic;

  @override
  State<_TopicItem> createState() => _TopicItemState();
}

class _TopicItemState extends State<_TopicItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.topic.icon,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.topic.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8, left: 40),
                child: Text(
                  widget.topic.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Help center tile ──────────────────────────────────────────────────────────

class _HelpCenterTile extends StatelessWidget {
  const _HelpCenterTile({
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact row ───────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textStrong,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
