import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';

// ── Message model ─────────────────────────────────────────────────────────────

class _Msg {
  const _Msg({
    required this.text,
    required this.isUser,
    required this.time,
    this.isRead = false,
  });
  final String text;
  final bool isUser;
  final String time;
  final bool isRead;
}

const List<_Msg> _kInitialMessages = [
  _Msg(
    text: 'Merhaba! 👋 Size nasıl yardımcı olabilirim?',
    isUser: false,
    time: '09:41',
  ),
  _Msg(
    text: 'Merhaba, fiyat bildirimi hakkında bilgi almak istiyorum.',
    isUser: true,
    time: '09:42',
    isRead: true,
  ),
  _Msg(
    text:
        'Tabii ki, hemen yardımcı olalım. Fiyat bildirimi oluşturmak için '
        '"Fiyat Bildir" sayfasına giderek gerekli bilgileri doldurabilirsiniz.',
    isUser: false,
    time: '09:43',
  ),
];

const List<String> _kFaqs = [
  'Fiyat değişikliği nasıl bildirilir?',
  'Hesabımı nasıl güvende tutabilirim?',
  'Katkı yap ve puan kazanma nasıl çalışır?',
  'Konum ve bölge ayarlarını nasıl değiştirebilirim?',
];

// ── Page ─────────────────────────────────────────────────────────────────────

class LiveSupportPage extends ConsumerStatefulWidget {
  const LiveSupportPage({super.key});

  @override
  ConsumerState<LiveSupportPage> createState() => _LiveSupportPageState();
}

class _LiveSupportPageState extends ConsumerState<LiveSupportPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Msg> _messages = List.of(_kInitialMessages);

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _nowTime() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isUser: true, time: _nowTime()));
    });
    _msgCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _HeroCard(),
                  ),
                  const SizedBox(height: 20),
                  _buildFaqSection(),
                  const SizedBox(height: 20),
                  _buildChatSection(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _MessageInput(controller: _msgCtrl, onSend: _sendMessage),
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
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Canlı Destek',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Material(
                color: AppColors.primarySoft,
                shape: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ekibimizle anında iletişime geçin, sorularınıza\nhızlı çözümler bulun.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── FAQ section ─────────────────────────────────────────────────────────────

  Widget _buildFaqSection() {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sık Sorulan Sorular',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
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
            ),
            const Divider(height: 1),
            for (int i = 0; i < _kFaqs.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16),
              _FaqItem(question: _kFaqs[i]),
            ],
          ],
        ),
      ),
    );
  }

  // ── Chat section ─────────────────────────────────────────────────────────────

  Widget _buildChatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Canlı Sohbet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 10),
          // Agent online status row
          Row(
            children: [
              SizedBox(
                width: 62,
                height: 28,
                child: Stack(
                  children: const [
                    Positioned(left: 0, child: _MiniAvatar()),
                    Positioned(left: 18, child: _MiniAvatar()),
                    Positioned(left: 36, child: _MiniAvatar()),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Destek ekibimiz şu anda aktif',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Messages
          for (final msg in _messages) ...[
            _ChatBubble(msg: msg),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 185,
        color: AppColors.primarySoft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: status + stats
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Şu anda uygunuz!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ortalama yanıt süremiz 30 saniye.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const Spacer(),
                    const Row(
                      children: [
                        _StatItem(
                          icon: Icons.access_time_outlined,
                          label: '7/24\nDestek',
                        ),
                        SizedBox(width: 8),
                        _StatItem(
                          icon: Icons.shield_outlined,
                          label: 'Güvenli\nİletişim',
                        ),
                        SizedBox(width: 8),
                        _StatItem(
                          icon: Icons.people_outline_rounded,
                          label: 'Uzman\nEkip',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Right: support agent illustration
            SizedBox(
              width: 155,
              child: Image.asset(
                'assets/images/canli.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ── FAQ item ──────────────────────────────────────────────────────────────────

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question});
  final String question;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  static const Map<String, String> _answers = {
    'Fiyat değişikliği nasıl bildirilir?':
        'Bir işletmeyi ziyaret ettikten sonra "Fiyat Bildir" butonuna tıklayarak güncel fiyatı girebilirsiniz. Katkınız için puan kazanırsınız.',
    'Hesabımı nasıl güvende tutabilirim?':
        'Güçlü bir şifre belirleyin, iki adımlı doğrulamayı aktifleştirin ve hesap güvenlik ayarlarınızı düzenli kontrol edin.',
    'Katkı yap ve puan kazanma nasıl çalışır?':
        'Fiyat bildirimi, yorum yazma ve fotoğraf ekleme gibi katkılarla puan kazanırsınız. Puanlarınızı profilinizden takip edebilirsiniz.',
    'Konum ve bölge ayarlarını nasıl değiştirebilirim?':
        'Ayarlar → Uygulama Tercihleri → Konum Ayarları yolunu izleyerek konumunuzu ve bölge tercihlerinizi güncelleyebilirsiniz.',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
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
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _answers[widget.question] ?? '',
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

// ── Chat widgets ──────────────────────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.support_agent_rounded,
        color: AppColors.primary,
        size: 14,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    if (msg.isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg.time,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              if (msg.isRead) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ],
      );
    }

    // Agent message
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Agent avatar
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/canli.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.66,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Message input bar ─────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  const _MessageInput({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Attachment icon
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(
              Icons.attach_file_rounded,
              color: AppColors.muted,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  hintStyle: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textStrong),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
