import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../marketing/ui/widgets/site_footer.dart';
import '../data/legal_registry.dart';
import '../domain/legal_document.dart';
import '../legal_routes.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PublicSiteScaffold(
      title: 'Legal Merkezi',
      subtitle:
          'Yeedoy platformunun kullanım, gizlilik, güvenlik ve trust & safety belgelerine tek merkezden erişin.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF8FAFC), Color(0xFFFEE2E2)],
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: const [
                    SizedBox(
                      width: 640,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yasal, gizlilik ve güven belgeleri',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textStrong,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Bu merkez; kullanıcı, işletme ve kamuya açık QR deneyimi için gerekli hukuki çerçeveyi tek noktada toplar. Her belge sürüm numarası ve güncelleme tarihi ile yayımlanır.',
                            style: TextStyle(
                              height: 1.7,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _InlineMetaCard(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: wide
                      ? 3
                      : constraints.maxWidth >= 700
                      ? 2
                      : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: wide ? 1.18 : 1.36,
                ),
                itemCount: LegalRegistry.documents.length,
                itemBuilder: (context, index) {
                  final document = LegalRegistry.documents[index];
                  return _LegalCard(document: document);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class LegalDetailPage extends StatefulWidget {
  const LegalDetailPage({super.key, required this.slug});

  final String slug;

  @override
  State<LegalDetailPage> createState() => _LegalDetailPageState();
}

class _LegalDetailPageState extends State<LegalDetailPage> {
  late final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _rebuildSectionKeys();
  }

  @override
  void didUpdateWidget(covariant LegalDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _rebuildSectionKeys();
    }
  }

  void _rebuildSectionKeys() {
    _sectionKeys.clear();
    final document = LegalRegistry.bySlug(widget.slug);
    if (document == null) return;
    for (final section in document.sections) {
      _sectionKeys[section.id] = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = LegalRegistry.bySlug(widget.slug);
    if (document == null) {
      return _PublicSiteScaffold(
        title: 'Belge Bulunamadı',
        subtitle: 'İstenen legal doküman bulunamadı.',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.find_in_page_outlined,
                    size: 42,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Legal dokümanı bulunamadı.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Linki kontrol edin veya legal merkezine geri dönün.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate, height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => context.go(LegalRoutes.hub),
                    child: const Text('Legal Merkezine Dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _PublicSiteScaffold(
      title: document.title,
      subtitle: document.description,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1040;
          final content = _LegalArticle(
            document: document,
            sectionKeys: _sectionKeys,
          );
          final toc = _TocCard(
            document: document,
            onSelect: (sectionId) async {
              final key = _sectionKeys[sectionId];
              final target = key?.currentContext;
              if (target == null) return;
              await Scrollable.ensureVisible(
                target,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: 0.06,
              );
            },
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 18), toc],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              SizedBox(width: 280, child: toc),
            ],
          );
        },
      ),
    );
  }
}

class _PublicSiteScaffold extends StatelessWidget {
  const _PublicSiteScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SiteTopBar(),
                          const SizedBox(height: 26),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.slate,
                              height: 1.7,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _SiteTopBar extends StatelessWidget {
  const _SiteTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        spacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.menu_book_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'yeedoy.com',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Ana Sayfa'),
              ),
              OutlinedButton(
                onPressed: () => context.go(LegalRoutes.hub),
                child: const Text('Legal Merkezi'),
              ),
              FilledButton(
                onPressed: () => context.go('/isletme-giris'),
                child: const Text('İşletme Girişi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineMetaCard extends StatelessWidget {
  const _InlineMetaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yayın standardı',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Her belge için sürüm, son güncelleme tarihi ve okunabilir özet yayımlanır.',
            style: TextStyle(color: AppColors.slate, height: 1.6),
          ),
          const SizedBox(height: 12),
          _InlineMetaPill(label: '${LegalRegistry.count} belge'),
          const SizedBox(height: 8),
          _InlineMetaPill(label: LegalRegistry.currentVersion),
          const SizedBox(height: 8),
          _InlineMetaPill(
            label: 'Güncel: ${_formatDate(LegalRegistry.currentLastUpdated)}',
          ),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.go(LegalRoutes.detail(document.slug)),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(document.icon, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                document.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                document.description,
                style: const TextStyle(color: AppColors.slate, height: 1.6),
              ),
              const Spacer(),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(label: document.version),
                  _MetaChip(label: _formatDate(document.lastUpdated)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMetaPill extends StatelessWidget {
  const _InlineMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _MetaChip(label: label),
    );
  }
}

class _LegalArticle extends StatelessWidget {
  const _LegalArticle({required this.document, required this.sectionKeys});

  final LegalDocument document;
  final Map<String, GlobalKey> sectionKeys;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: document.version),
              _MetaChip(label: _formatDate(document.lastUpdated)),
              const _MetaChip(label: 'Türkçe'),
            ],
          ),
          const SizedBox(height: 20),
          for (final section in document.sections) ...[
            Container(
              key: sectionKeys[section.id],
              padding: const EdgeInsets.only(top: 10),
              child: _SectionBlock(section: section),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _TocCard extends StatelessWidget {
  const _TocCard({required this.document, required this.onSelect});

  final LegalDocument document;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İçindekiler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          for (final section in document.sections)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(section.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  section.title,
                  style: const TextStyle(color: AppColors.slate, height: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 10),
        for (final paragraph in section.paragraphs) ...[
          Text(
            paragraph,
            style: const TextStyle(
              color: AppColors.slate,
              height: 1.8,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (final bullet in section.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.circle, size: 7, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: const TextStyle(
                      color: AppColors.slate,
                      height: 1.75,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = <int, String>{
    1: 'Ocak',
    2: 'Şubat',
    3: 'Mart',
    4: 'Nisan',
    5: 'Mayıs',
    6: 'Haziran',
    7: 'Temmuz',
    8: 'Ağustos',
    9: 'Eylül',
    10: 'Ekim',
    11: 'Kasım',
    12: 'Aralık',
  };
  return '${date.day} ${months[date.month]} ${date.year}';
}
