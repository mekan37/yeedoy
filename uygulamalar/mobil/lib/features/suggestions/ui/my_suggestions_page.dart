import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/greeting_utils.dart';
import '../domain/my_suggestions_controller.dart';
import '../domain/suggestion.dart';

// ── Tab enum ──────────────────────────────────────────────────────────────────

enum _Tab { sent, answered, rejected }

extension _TabX on _Tab {
  String label(AppLocalizations t) => switch (this) {
    _Tab.sent => t.mySuggestionsTabSent,
    _Tab.answered => t.mySuggestionsTabAnswered,
    _Tab.rejected => t.mySuggestionsTabRejected,
  };

  bool matches(String status) => switch (this) {
    _Tab.sent => status == 'pending',
    _Tab.answered => status == 'approved',
    _Tab.rejected => status == 'rejected',
  };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class MySuggestionsPage extends ConsumerStatefulWidget {
  const MySuggestionsPage({super.key});

  @override
  ConsumerState<MySuggestionsPage> createState() => _MySuggestionsPageState();
}

class _MySuggestionsPageState extends ConsumerState<MySuggestionsPage> {
  final _scrollCtrl = ScrollController();
  _Tab _tab = _Tab.sent;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(mySuggestionsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(mySuggestionsControllerProvider);
    final filtered = st.items.where((s) => _tab.matches(s.status)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(mySuggestionsControllerProvider.notifier).refresh(),
          child: ListView(
            controller: _scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(context),
              _buildTabBar(),
              _buildInfoBanner(context),
              const SizedBox(height: 4),

              if (st.error != null)
                _ErrorBanner(
                  message: AppErrorMapper.message(st.error),
                  onRetry: () => ref
                      .read(mySuggestionsControllerProvider.notifier)
                      .refresh(),
                ),

              if (st.isLoading && st.items.isEmpty)
                const _Skeleton()
              else if (filtered.isEmpty)
                _EmptyState(tab: _tab, l10n: context.l10n)
              else ...[
                for (final s in filtered) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: RepaintBoundary(
                      child: _SuggestionCard(suggestion: s),
                    ),
                  ),
                ],
              ],

              if (st.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),

              _buildTipCard(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeBasedGreeting(),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.mySuggestionsPageTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.mySuggestionsPageSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: const Color(0xFFF4F5F7),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => context.push('/inbox'),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: _Tab.values.map((tab) {
            final selected = _tab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tab.label(AppLocalizations.of(context)),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.muted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Info banner ──────────────────────────────────────────────────────────────

  Widget _buildInfoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        // Metin ("İşletmelerin sana özel teklif vermesini bekle") grup
        // talebi özelliğinin kendi metniyle birebir örtüşüyor:
        // groupRequestWizardInfoTitle = "Teklifler işletmelerden gelir"
        // (B21).
        onTap: () => context.push('/group-requests/new'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFBCFCF)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.mySuggestionsInfoBannerTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.mySuggestionsInfoBannerSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tip card ─────────────────────────────────────────────────────────────────

  Widget _buildTipCard(BuildContext context) {
    // Bu kart salt bilgilendirme metni — gidilecek bir hedef yok, bu yüzden
    // sessiz no-op yerine (B21) dokunma efekti tamamen kaldırıldı.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.mySuggestionsTipCardTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.mySuggestionsTipCardBody,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
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

// ── Suggestion card ───────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final BusinessSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final approvedId = (suggestion.approvedBusinessId ?? '').trim();
    final hasNote = (suggestion.adminNote ?? '').trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top section ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon placeholder (no image in current model)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            status: suggestion.status,
                            l10n: context.l10n,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.category,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _locText(
                              context.l10n,
                              suggestion.district,
                              suggestion.city,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Admin note ────────────────────────────────────────────
          if (hasNote) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  suggestion.adminNote!.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],

          // ── Footer row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 5),
                Text(
                  _fmtDate(context.l10n, suggestion.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const Spacer(),
                if (suggestion.status == 'approved' && approvedId.isNotEmpty)
                  OutlinedButton(
                    onPressed: () => context.go('/b/$approvedId'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      foregroundColor: AppColors.textStrong,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(context.l10n.mySuggestionsViewDetailsButton),
                  )
                else
                  OutlinedButton(
                    // Onaylanmamış/eşleşmemiş bir öneri için gidilecek bir
                    // işletme sayfası yok — önceden bu buton "Detayları
                    // Gör" yazıp tıklanınca hiçbir şey yapmıyordu. Görsel
                    // olarak devre dışı bırakılıyor (Flutter'ın standart
                    // disabled stiliyle) ki sahte bir tıklanabilirlik izlenimi
                    // vermesin.
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      foregroundColor: AppColors.textStrong,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(context.l10n.mySuggestionsViewDetailsButton),
                  ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: AppColors.muted,
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

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});
  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      'approved' => _Badge(
        icon: Icons.check_circle_outline_rounded,
        label: l10n.mySuggestionsStatusApproved,
        iconColor: AppColors.success,
        bg: const Color(0xFFDCFCE7),
        textColor: AppColors.success,
      ),
      'rejected' => _Badge(
        icon: Icons.cancel_outlined,
        label: l10n.mySuggestionsStatusRejected,
        iconColor: AppColors.danger,
        bg: const Color(0xFFFEE2E2),
        textColor: AppColors.danger,
      ),
      _ => _Badge(
        icon: Icons.schedule_rounded,
        label: l10n.mySuggestionsStatusPending,
        iconColor: const Color(0xFFD97706),
        bg: const Color(0xFFFEF3C7),
        textColor: const Color(0xFFD97706),
      ),
    };
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bg,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab, required this.l10n});
  final _Tab tab;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (icon, title, sub) = switch (tab) {
      _Tab.sent => (
        Icons.send_outlined,
        l10n.mySuggestionsEmptySentTitle,
        l10n.mySuggestionsEmptySentBody,
      ),
      _Tab.answered => (
        Icons.check_circle_outline_rounded,
        l10n.mySuggestionsEmptyAnsweredTitle,
        l10n.mySuggestionsEmptyAnsweredBody,
      ),
      _Tab.rejected => (
        Icons.cancel_outlined,
        l10n.mySuggestionsEmptyRejectedTitle,
        l10n.mySuggestionsEmptyRejectedBody,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: AppColors.danger),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(context.l10n.mySuggestionsRefreshButton),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _locText(AppLocalizations l10n, String? district, String? city) {
  final d = (district ?? '').trim();
  final c = (city ?? '').trim();
  if (d.isEmpty && c.isEmpty) return l10n.mySuggestionsNoLocation;
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d • $c';
}

String _fmtDate(AppLocalizations l10n, DateTime d) {
  final months = [
    '',
    l10n.mySuggestionsMonthJanuary,
    l10n.mySuggestionsMonthFebruary,
    l10n.mySuggestionsMonthMarch,
    l10n.mySuggestionsMonthApril,
    l10n.mySuggestionsMonthMay,
    l10n.mySuggestionsMonthJune,
    l10n.mySuggestionsMonthJuly,
    l10n.mySuggestionsMonthAugust,
    l10n.mySuggestionsMonthSeptember,
    l10n.mySuggestionsMonthOctober,
    l10n.mySuggestionsMonthNovember,
    l10n.mySuggestionsMonthDecember,
  ];
  return '${d.day} ${months[d.month]} ${d.year}';
}
