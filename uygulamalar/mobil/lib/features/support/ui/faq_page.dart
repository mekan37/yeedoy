import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _Category {
  const _Category({
    required this.icon,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final String label;
  final int count;
}

class _FaqEntry {
  const _FaqEntry({
    required this.catIndex,
    required this.question,
    required this.answer,
  });
  final int catIndex;
  final String question;
  final String answer;
}

// ── Data ──────────────────────────────────────────────────────────────────────

List<_Category> _kCategories(BuildContext context) => <_Category>[
  _Category(
    icon: Icons.person_outline_rounded,
    label: context.l10n.faqCategoryAccountLabel,
    count: 10,
  ),
  _Category(
    icon: Icons.shield_outlined,
    label: context.l10n.faqCategorySecurityLabel,
    count: 10,
  ),
  _Category(
    icon: Icons.credit_card_outlined,
    label: context.l10n.faqCategoryPaymentsLabel,
    count: 10,
  ),
  _Category(
    icon: Icons.local_offer_outlined,
    label: context.l10n.faqCategoryCampaignsLabel,
    count: 5,
  ),
  _Category(
    icon: Icons.smartphone_outlined,
    label: context.l10n.faqCategoryAppUsageLabel,
    count: 15,
  ),
];

List<_FaqEntry> _kFaqs(BuildContext context) => <_FaqEntry>[
  // Hesap İşlemleri (0)
  _FaqEntry(
    catIndex: 0,
    question: context.l10n.faqQ1Question,
    answer: context.l10n.faqQ1Answer,
  ),
  _FaqEntry(
    catIndex: 0,
    question: context.l10n.faqQ2Question,
    answer: context.l10n.faqQ2Answer,
  ),
  _FaqEntry(
    catIndex: 0,
    question: context.l10n.faqQ3Question,
    answer: context.l10n.faqQ3Answer,
  ),
  _FaqEntry(
    catIndex: 0,
    question: context.l10n.faqQ4Question,
    answer: context.l10n.faqQ4Answer,
  ),
  _FaqEntry(
    catIndex: 0,
    question: context.l10n.faqQ5Question,
    answer: context.l10n.faqQ5Answer,
  ),
  // Güvenlik (1)
  _FaqEntry(
    catIndex: 1,
    question: context.l10n.faqQ6Question,
    answer: context.l10n.faqQ6Answer,
  ),
  _FaqEntry(
    catIndex: 1,
    question: context.l10n.faqQ7Question,
    answer: context.l10n.faqQ7Answer,
  ),
  _FaqEntry(
    catIndex: 1,
    question: context.l10n.faqQ8Question,
    answer: context.l10n.faqQ8Answer,
  ),
  _FaqEntry(
    catIndex: 1,
    question: context.l10n.faqQ9Question,
    answer: context.l10n.faqQ9Answer,
  ),
  // Ödemeler (2)
  _FaqEntry(
    catIndex: 2,
    question: context.l10n.faqQ10Question,
    answer: context.l10n.faqQ10Answer,
  ),
  _FaqEntry(
    catIndex: 2,
    question: context.l10n.faqQ11Question,
    answer: context.l10n.faqQ11Answer,
  ),
  _FaqEntry(
    catIndex: 2,
    question: context.l10n.faqQ12Question,
    answer: context.l10n.faqQ12Answer,
  ),
  // Kampanya ve Fırsatlar (3)
  _FaqEntry(
    catIndex: 3,
    question: context.l10n.faqQ13Question,
    answer: context.l10n.faqQ13Answer,
  ),
  _FaqEntry(
    catIndex: 3,
    question: context.l10n.faqQ14Question,
    answer: context.l10n.faqQ14Answer,
  ),
  // Uygulama Kullanımı (4)
  _FaqEntry(
    catIndex: 4,
    question: context.l10n.faqQ15Question,
    answer: context.l10n.faqQ15Answer,
  ),
  _FaqEntry(
    catIndex: 4,
    question: context.l10n.faqQ16Question,
    answer: context.l10n.faqQ16Answer,
  ),
  _FaqEntry(
    catIndex: 4,
    question: context.l10n.faqQ17Question,
    answer: context.l10n.faqQ17Answer,
  ),
  _FaqEntry(
    catIndex: 4,
    question: context.l10n.faqQ18Question,
    answer: context.l10n.faqQ18Answer,
  ),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final _searchCtrl = TextEditingController();
  int _selectedCat = 0;
  int? _expandedIndex;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_FaqEntry> get _filtered {
    final catItems =
        _kFaqs(context).where((f) => f.catIndex == _selectedCat).toList();
    if (_query.isEmpty) return catItems;
    final q = _query.toLowerCase();
    return catItems.where((f) => f.question.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar(context)),
                  SliverToBoxAdapter(child: _buildSearch()),
                  SliverToBoxAdapter(child: _buildCategories()),
                  SliverToBoxAdapter(child: _buildFaqHeader()),
                  _buildFaqList(),
                  SliverToBoxAdapter(child: _buildSupportBanner(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
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
          Expanded(
            child: Text(
              context.l10n.faqPageTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 1,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ───────────────────────────────────────────────────────────────────

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.muted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() {
                    _query = v;
                    _expandedIndex = null;
                  });
                },
                decoration: InputDecoration(
                  hintText: context.l10n.faqSearchHint,
                  hintStyle:
                      const TextStyle(color: AppColors.muted, fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
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

  // ── Categories ───────────────────────────────────────────────────────────────

  Widget _buildCategories() {
    final categories = _kCategories(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            context.l10n.faqCategoriesSectionTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = i == _selectedCat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCat = i;
                    _expandedIndex = null;
                  });
                },
                child: Container(
                  width: 82,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primarySoft : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icon,
                          size: 18,
                          color: selected
                              ? Colors.white
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cat.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textStrong,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.faqQuestionCount(cat.count),
                        style: TextStyle(
                          fontSize: 8,
                          color: selected
                              ? AppColors.primary
                              : AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── FAQ header ────────────────────────────────────────────────────────────────

  Widget _buildFaqHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        context.l10n.faqListSectionTitle,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: AppColors.textStrong,
        ),
      ),
    );
  }

  // ── FAQ list ──────────────────────────────────────────────────────────────────

  Widget _buildFaqList() {
    final items = _filtered;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                context.l10n.faqNoResultsInCategory,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16),
                _FaqAccordion(
                  entry: items[i],
                  isExpanded: _expandedIndex == i,
                  onToggle: () {
                    setState(() {
                      _expandedIndex = _expandedIndex == i ? null : i;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Support banner ────────────────────────────────────────────────────────────

  Widget _buildSupportBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFBCFCF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headset_mic_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.faqSupportBannerTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.faqSupportBannerBody,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => context.push('/live-support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(context.l10n.faqSupportBannerButton),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.faqBottomHelpfulQuestion,
            style: const TextStyle(
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
                      SnackBar(content: Text(context.l10n.faqThanksSnackbar)),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    foregroundColor: Color(0xFF16A34A),
                    backgroundColor: Color(0xFFF0FDF4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.thumb_up_outlined, size: 15),
                  label: Text(context.l10n.faqYesHelpfulButton),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.thumb_down_outlined, size: 15),
                  label: Text(context.l10n.faqNoHelpfulButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── FAQ accordion item ────────────────────────────────────────────────────────

class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
  });

  final _FaqEntry entry;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      entry.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10, left: 42),
                child: Text(
                  entry.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.55,
                  ),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}
