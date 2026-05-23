part of '../isletme_sayfasi.dart';

class BusinessHeaderSection extends ConsumerWidget {
  const BusinessHeaderSection({super.key, required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (!business.isActive ||
            business.lifecycleStatus == 'closed' ||
            business.lifecycleStatus == 'temporarily_closed') ...[
          _BusinessClosedBanner(business: business),
          const SizedBox(height: 8),
        ],
        _BusinessIdentityCard(business: business),
        const SizedBox(height: 8),
        _BusinessHeaderCompactContainer(business: business),
      ],
    );
  }
}

/// Kapandı / geçici olarak kapalı banner'ı
class _BusinessClosedBanner extends StatelessWidget {
  const _BusinessClosedBanner({required this.business});
  final Business business;

  @override
  Widget build(BuildContext context) {
    final isTemp = business.lifecycleStatus == 'temporarily_closed';
    final label = isTemp
        ? 'Bu işletme geçici olarak hizmet vermiyor'
        : 'Bu işletme artık hizmet vermemektedir';
    final icon = isTemp ? Icons.pause_circle_outline : Icons.cancel_outlined;
    final color = isTemp ? AppColors.warning : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if ((business.lifecycleNote ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    business.lifecycleNote!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessIdentityCard extends StatelessWidget {
  const _BusinessIdentityCard({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business.name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${business.category} - ${_locText(context, business.district, business.city)}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BusinessHeaderCompactContainer extends ConsumerWidget {
  const _BusinessHeaderCompactContainer({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final (openNow, closeText) = ref.watch(
      _businessHoursProvider(business.id).select((async) {
        return async.maybeWhen(
          data: (today) {
            if (today == null) return (null, t.noTime);
            return (
              _isOpenNow(today.open, today.close, DateTime.now()),
              today.close ?? t.noTime,
            );
          },
          orElse: () => (null, t.noTime),
        );
      }),
    );
    final topItems = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value ?? const [];
        if (items.isEmpty) return const <String>[];
        return items
            .map((e) => e.itemName.trim())
            .where((e) => e.isNotEmpty)
            .take(2)
            .toList(growable: false);
      }),
    );
    final topItemPriceCents = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value;
        if (items == null || items.isEmpty) return null;
        return items.first.priceCents;
      }),
    );
    final topItemCurrency = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value;
        if (items == null || items.isEmpty) return 'TRY';
        return items.first.currency;
      }),
    );
    final firstMenuId = ref.watch(
      businessMenusProvider(business.id).select((async) {
        final menus = async.asData?.value;
        if (menus == null || menus.isEmpty) return null;
        return menus.first.id;
      }),
    );
    final lastVerifiedText = _daysAgoText(context, business.lifecycleUpdatedAt);
    final topItemsText = topItems.isEmpty ? t.unknown : topItems.join(', ');

    return BusinessHeaderCompact(
      isOpenNow: openNow,
      closingTimeText: closeText,
      averagePriceText: _formatPriceWithCurrency(
        context,
        topItemPriceCents,
        topItemCurrency,
      ),
      topItemsText: topItemsText,
      lastVerifiedText: lastVerifiedText,
      onDirectionsTap: () {
        unawaited(
          _openDirections(
            businessName: business.name,
            address: business.address,
            lat: business.lat,
            lng: business.lng,
          ),
        );
      },
      onMenuTap: () {
        if (firstMenuId == null) return;
        context.go('/isletme/${business.id}/menu/$firstMenuId');
      },
    );
  }
}

class BusinessActionsSection extends ConsumerWidget {
  const BusinessActionsSection({super.key, required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));
    final isFavorited = ref.watch(isFavoritedProvider(business.id));
    final checkinState = ref.watch(checkinControllerProvider(business.id));
    final isCheckedIn = checkinState.value ?? false;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    if (!isLoggedIn) {
                      await showQuickLoginSheet(
                        context,
                        redirectPath: '/isletme/${business.id}',
                      );
                      return;
                    }
                    try {
                      HapticFeedback.lightImpact();
                      final nowFav = await ref
                          .read(favoritesControllerProvider.notifier)
                          .toggleFavorite(business.id);
                      if (nowFav && context.mounted) {
                        await _showEmailOptInSheet(context, ref, business.id);
                      }
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppErrorMapper.message(error))),
                      );
                    }
                  },
                  icon: Icon(isFavorited ? Icons.star : Icons.star_border),
                  label: Text(isFavorited ? t.favoriteAdded : t.addToFavorites),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/isletme/${business.id}/review'),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(t.writeReview),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Check-in butonu — tam genişlik, ayrı satır
          SizedBox(
            width: double.infinity,
            child: isCheckedIn
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    label: const Text(
                      'Bugün buradaydınız ✓',
                      style: TextStyle(color: AppColors.success),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () async {
                      if (!isLoggedIn) {
                        await showQuickLoginSheet(
                          context,
                          redirectPath: '/isletme/${business.id}',
                        );
                        return;
                      }
                      HapticFeedback.mediumImpact();
                      final result = await ref
                          .read(checkinControllerProvider(business.id).notifier)
                          .submitCheckin();
                      if (!context.mounted) return;
                      if (result.ok) {
                        await _showCheckinBasariDialog(
                          context,
                          result: result,
                          businessName: business.name,
                        );
                      } else if (result.error == 'already_checked_in_today') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bugün zaten check-in yaptınız.'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.error ?? 'Hata oluştu'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Buradayım — Check-in'),
                  ),
          ),
        ],
      ),
    );
  }
}

// Check-in başarı dialog — streak + puan + sosyal paylaşım
Future<void> _showCheckinBasariDialog(
  BuildContext context, {
  required CheckinResult result,
  required String businessName,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) =>
        _CheckinBasariDialog(result: result, businessName: businessName),
  );
}

class _CheckinBasariDialog extends StatelessWidget {
  const _CheckinBasariDialog({
    required this.result,
    required this.businessName,
  });

  final CheckinResult result;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    final streak = result.streakDays;
    final points = result.pointsEarned;
    final total = result.totalCheckins;
    final next = result.nextMilestone;
    final toNext = next - (total % next == 0 ? next : total % next);
    final progressPct = next > 0
        ? ((total % next) / next).clamp(0.0, 1.0)
        : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başarı ikonu
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.place_rounded,
              size: 36,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Check-in Yapıldı! 🎉',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          // Yeni rozet bildirimi
          if (result.newBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🏆 Yeni rozet: ${result.newBadge}',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Puan + streak stat satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                emoji: '⭐',
                label: '+$points puan',
                color: const Color(0xFFFEF3C7),
                textColor: const Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              _StatChip(
                emoji: '🔥',
                label: '$streak günlük seri',
                color: AppColors.primarySoft,
                textColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Sonraki milestone progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sonraki ödül',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    toNext <= 0 ? 'Ödül kazanıldı!' : '$toNext check-in kaldı',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPct,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Toplam check-in bilgisi
          Text(
            'Bu işletmede toplam $total ziyaret',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
      actions: [
        // Paylaş butonu
        TextButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await _shareCheckin(
              businessName: businessName,
              streak: streak,
              points: points,
            );
          },
          icon: const Icon(Icons.share_outlined, size: 16),
          label: const Text('Paylaş'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Harika!'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String emoji;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _shareCheckin({
  required String businessName,
  required int streak,
  required int points,
}) async {
  final msg = streak >= 3
      ? '$businessName\'e $streak gün üst üste check-in yaptım! 🔥 +$points puan kazandım. #Yeedoy'
      : '$businessName\'e check-in yaptım! ⭐ +$points puan kazandım. #Yeedoy';
  try {
    await SharePlus.instance.share(ShareParams(text: msg));
  } catch (_) {
    // Paylaşım desteklenmiyorsa sessizce geç
  }
}

class BusinessTrustSection extends ConsumerWidget {
  const BusinessTrustSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final trustAsync = ref.watch(_businessTrustProvider(businessId));
    return trustAsync.when(
      loading: () => const AppSkeletonCard(),
      error: (error, _) => AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.trustDataUnavailable,
        description:
            '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
        ctaLabel: AppLocalizations.of(context).retry,
        onCta: () => ref.invalidate(_businessTrustProvider(businessId)),
      ),
      data: (trust) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.freshnessAndTrust,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _TrustLine(
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.success,
                label: t.menuUpdatedLabel,
                value:
                    '${t.updatedDaysAgo(_daysAgo(trust.menuUpdatedAt))} ${t.versionAndSource(trust.menuVersion, _menuSourceLabel(context, trust.menuSource))}',
              ),
              const SizedBox(height: 6),
              _TrustLine(
                icon: Icons.price_check_outlined,
                iconColor: AppColors.success,
                label: t.lastPriceVerification,
                value:
                    '${t.verifiedDaysAgo(_daysAgo(trust.lastPriceVerifiedAt))} (${trust.lastPriceVerifiedPeople} ${t.usersLabel})',
              ),
              const SizedBox(height: 6),
              _TrustLine(
                icon: Icons.shield_outlined,
                iconColor: trust.trustScore >= 75
                    ? AppColors.warning
                    : AppColors.danger,
                label: t.communityScoreDataTrustLabel,
                value: '${trust.trustScore}/100',
              ),
              const SizedBox(height: 12),
              Text(
                t.last3MonthsPriceChange,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              _PriceChangeMiniChart(points: trust.priceChanges3m),
            ],
          ),
        );
      },
    );
  }
}

class BusinessHoursSection extends ConsumerWidget {
  const BusinessHoursSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hoursAsync = ref.watch(_businessHoursProvider(businessId));
    return hoursAsync.when(
      loading: () => const AppSkeletonCard(),
      error: (_, _) => AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.hoursInfoUnavailable,
        description: t.connectionProblemTryAgain,
        ctaLabel: AppLocalizations.of(context).retry,
        onCta: () => ref.invalidate(_businessHoursProvider(businessId)),
      ),
      data: (today) {
        if (today == null) {
          return AppEmptyState(
            icon: Icons.schedule_outlined,
            title: t.hoursInfoMissing,
            description: t.addHoursHelp,
            ctaLabel: t.reportHoursInfo,
            onCta: () => _openReportSheet(context, businessId),
          );
        }
        final openNow = _isOpenNow(today.open, today.close, DateTime.now());
        return AppCard(
          child: Row(
            children: [
              Icon(
                openNow ? Icons.schedule : Icons.schedule_outlined,
                color: openNow ? AppColors.success : AppColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  openNow
                      ? '${t.openNow} - ${_hoursText(context, today.open, today.close)}'
                      : '${t.closedNow} - ${_hoursText(context, today.open, today.close)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BusinessMenusSection extends ConsumerWidget {
  const BusinessMenusSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final menusAsync = ref.watch(businessMenusProvider(businessId));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.menus,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          menusAsync.when(
            loading: () => const AppSkeletonLine(width: 140),
            error: (error, _) => AppEmptyState(
              icon: Icons.wifi_off_outlined,
              title: t.menusLoadFailed,
              description:
                  '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
              ctaLabel: AppLocalizations.of(context).retry,
              onCta: () => ref.invalidate(businessMenusProvider(businessId)),
            ),
            data: (menus) {
              if (menus.isEmpty) {
                return AppEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: t.noMenu,
                  description: t.addFirstMenuHelp,
                  ctaLabel: AppLocalizations.of(context).addFirstMenuCta,
                  onCta: () => _openReportSheet(context, businessId),
                );
              }
              return Column(
                children: [
                  for (final menu in menus)
                    ListTile(
                      key: ValueKey(menu.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(menu.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.go('/isletme/$businessId/menu/${menu.id}'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class BusinessCrowdSection extends ConsumerStatefulWidget {
  const BusinessCrowdSection({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<BusinessCrowdSection> createState() =>
      _BusinessCrowdSectionState();
}

class _BusinessCrowdSectionState extends ConsumerState<BusinessCrowdSection> {
  bool _submitting = false;

  Future<void> _report(String crowd) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(businessCrowdProvider(widget.businessId).notifier)
          .submitPresence(crowd);
      ref.invalidate(businessCrowdProvider(widget.businessId));
    } catch (_) {
      // silent — best-effort crowd report
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final crowdAsync = ref.watch(businessCrowdProvider(widget.businessId));
    return AppCard(
      child: crowdAsync.when(
        loading: () => const AppSkeletonLine(width: 150),
        error: (error, s) => AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: t.crowdInfoUnavailable,
          description:
              '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: () => ref.invalidate(businessCrowdProvider(widget.businessId)),
        ),
        data: (status) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined, color: AppColors.textStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.liveCrowdLabel(status.state),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (status.userCanReport) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _CrowdChip(
                    label: 'Sakin',
                    icon: Icons.sentiment_satisfied_outlined,
                    onTap: _submitting ? null : () => _report('quiet'),
                  ),
                  _CrowdChip(
                    label: 'Orta',
                    icon: Icons.sentiment_neutral_outlined,
                    onTap: _submitting ? null : () => _report('moderate'),
                  ),
                  _CrowdChip(
                    label: 'Kalabalık',
                    icon: Icons.sentiment_very_dissatisfied_outlined,
                    onTap: _submitting ? null : () => _report('busy'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Şu anki kalabalığı bildirerek diğer kullanıcılara yardım et.',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CrowdChip extends StatelessWidget {
  const _CrowdChip({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class BusinessReviewsSection extends ConsumerWidget {
  const BusinessReviewsSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final detailAsync = ref.watch(businessDetailProvider(businessId));
    return AppCard(
      child: detailAsync.when(
        loading: () => const AppSkeletonCard(),
        error: (error, _) => AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: t.reviewsLoadFailed,
          description:
              '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: () => ref.invalidate(businessDetailProvider(businessId)),
        ),
        data: (detail) {
          if (detail.latestReviews.isEmpty) {
            return AppEmptyState(
              icon: Icons.reviews_outlined,
              title: t.noReviews,
              description: t.leaveFirstReviewHelp,
              ctaLabel: t.writeFirstReview,
              onCta: () => context.go('/isletme/$businessId/review'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.recentReviews,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${detail.latestReviews.length} ${t.reviewsCountSuffix}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final review in detail.latestReviews.take(3))
                ListTile(
                  key: ValueKey(review.id),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    review.title?.trim().isEmpty == false
                        ? review.title!
                        : t.reviewFallbackTitle,
                  ),
                  subtitle: Text(
                    review.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Kalabalık / Yoğunluk Göstergesi
/// Son 2 saatte check-in sayısına göre mekan yoğunluğunu gösterir.
class KalabalikGostergesi extends ConsumerWidget {
  const KalabalikGostergesi({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(businessRecentCheckinsProvider(businessId));
    return asyncCount.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (count) {
        if (count <= 0) {
          return _KalabalikBant(
            icon: Icons.nights_stay_outlined,
            label: 'Şu an sessiz görünüyor',
            color: AppColors.muted,
            backgroundColor: AppColors.card,
          );
        }
        if (count < 5) {
          return _KalabalikBant(
            icon: Icons.people_outline,
            label: 'Son 2 saatte $count kişi burada',
            color: AppColors.info,
            backgroundColor: AppColors.info.withValues(alpha: 0.08),
          );
        }
        return _KalabalikBant(
          icon: Icons.local_fire_department_outlined,
          label: 'Hareketli! Son 2 saatte $count kişi burada',
          color: AppColors.warning,
          backgroundColor: AppColors.warning.withValues(alpha: 0.10),
        );
      },
    );
  }
}

class _KalabalikBant extends StatelessWidget {
  const _KalabalikBant({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessMealCardsSection extends ConsumerWidget {
  const BusinessMealCardsSection({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(
      businessMealCardProvidersProvider(businessId),
    );
    return providersAsync.maybeWhen(
      data: (providers) {
        if (providers.isEmpty) return const SizedBox.shrink();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Geçerli Yemek Kartları',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bu işletmede kabul edilen kartlar aşağıda listelenir.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              MealCardBadgeRow(providers: providers),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class BusinessPerksSection extends ConsumerWidget {
  const BusinessPerksSection({
    super.key,
    required this.businessId,
    required this.businessName,
  });
  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final perksAsync = ref.watch(businessPerksProvider(businessId));
    final hasPerks = perksAsync.asData?.value.isNotEmpty ?? false;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.activeCampaigns,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (hasPerks)
                TextButton(
                  onPressed: () => context.push(
                    Uri(
                      path: '/ayricaliklar/$businessId',
                      queryParameters: {'name': businessName},
                    ).toString(),
                  ),
                  child: const Text('Tümünü gör'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _PerksSummaryLine(businessId: businessId),
          _AmenitiesSummaryLine(businessId: businessId),
          _CheckinsSummaryLine(businessId: businessId),
          _NewItemsSummaryLine(businessId: businessId),
        ],
      ),
    );
  }
}

class _PerksSummaryLine extends ConsumerWidget {
  const _PerksSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perksAsync = ref.watch(businessPerksProvider(businessId));
    return perksAsync.when(
      loading: () => const AppSkeletonLine(width: 160),
      error: (_, _) => const SizedBox.shrink(),
      data: (perks) => Text(
        perks.isEmpty
            ? AppLocalizations.of(context).noActiveCampaign
            : '${perks.length} ${AppLocalizations.of(context).activeCampaignCountLabel}',
        style: const TextStyle(color: AppColors.muted),
      ),
    );
  }
}

class _AmenitiesSummaryLine extends ConsumerWidget {
  const _AmenitiesSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenitiesAsync = ref.watch(businessAmenitiesProvider(businessId));
    return amenitiesAsync.maybeWhen(
      data: (items) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          items.isEmpty
              ? AppLocalizations.of(context).noAmenityInfo
              : '${items.length} ${AppLocalizations.of(context).amenityCountLabel}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _CheckinsSummaryLine extends ConsumerWidget {
  const _CheckinsSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(businessRecentCheckinsProvider(businessId));
    return checkinsAsync.maybeWhen(
      data: (count) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          count <= 0
              ? AppLocalizations.of(context).noLocationVerificationData
              : '${AppLocalizations.of(context).lastLocationVerification}: $count',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _NewItemsSummaryLine extends ConsumerWidget {
  const _NewItemsSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newItemsAsync = ref.watch(businessNewItemsProvider(businessId));
    return newItemsAsync.maybeWhen(
      data: (items) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          items.isEmpty
              ? AppLocalizations.of(context).noNewProductRecord
              : '${AppLocalizations.of(context).newProduct}: ${items.length}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class BusinessFooterSection extends StatelessWidget {
  const BusinessFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppLocalizations.of(context).reportInfoErrorPrefix} ${_fmtDate(DateTime.now())}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PriceChangeMiniChart extends StatelessWidget {
  const _PriceChangeMiniChart({required this.points});
  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final values = points.length == 3 ? points : [0, 0, 0];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 54,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: maxValue <= 0
                          ? 6
                          : (8 + (values[i] / maxValue) * 42).clamp(8, 52),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${values[i]}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (i != values.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class BusinessReviewPhotosSection extends ConsumerWidget {
  const BusinessReviewPhotosSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(businessReviewPhotosProvider(businessId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (urls) {
        if (urls.isEmpty) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        final isLocTr = t.localeName.startsWith('tr');
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isLocTr ? 'Topluluk Fotoğrafları' : 'Community Photos',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (urls.length >= 6)
                    TextButton(
                      onPressed: () => _openAllPhotos(context, urls),
                      child: Text(
                        isLocTr ? 'Tümünü gör' : 'See all',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _openAllPhotos(context, urls, initial: i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urls[i],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        semanticLabel: 'İşletme fotoğrafı ${i + 1}',
                        errorBuilder: (context, e, stack) => Container(
                          width: 90,
                          height: 90,
                          color: AppColors.card,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAllPhotos(
    BuildContext context,
    List<String> urls, {
    int initial = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            _BusinessPhotosViewer(urls: urls, initialIndex: initial),
      ),
    );
  }
}

class _BusinessPhotosViewer extends StatefulWidget {
  const _BusinessPhotosViewer({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_BusinessPhotosViewer> createState() => _BusinessPhotosViewerState();
}

class _BusinessPhotosViewerState extends State<_BusinessPhotosViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocTr = AppLocalizations.of(context).localeName.startsWith('tr');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          isLocTr
              ? 'Fotoğraf ${_current + 1} / ${widget.urls.length}'
              : 'Photo ${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.urls[i],
              fit: BoxFit.contain,
              semanticLabel: 'Tam ekran fotoğraf ${i + 1}',
              errorBuilder: (context, e, stack) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BusinessFrequentTagsSection extends ConsumerWidget {
  const BusinessFrequentTagsSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(_businessFrequentTagsProvider(businessId));
    return tagsAsync.maybeWhen(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        final isLocTr = t.localeName.startsWith('tr');
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLocTr ? 'Sıkça Bahsedilen' : 'Frequently Mentioned',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text(
                        tag.count >= 5 ? '${tag.tag} (${tag.count})' : tag.tag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.primarySoft,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class BusinessContactSection extends ConsumerWidget {
  const BusinessContactSection({super.key, required this.business});
  final Business business;

  bool get _hasAny =>
      business.phone != null ||
      business.socialWebsite != null ||
      business.socialInstagram != null ||
      business.socialWhatsapp != null ||
      business.socialFacebook != null ||
      business.socialTiktok != null ||
      (business.lat != null && business.lng != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_hasAny) return const SizedBox.shrink();

    final t = AppLocalizations.of(context);
    final links = <_ContactLink>[
      if (business.phone != null)
        _ContactLink(
          icon: Icons.phone_outlined,
          label: business.phone!,
          uri: Uri(scheme: 'tel', path: business.phone),
        ),
      if (business.socialWhatsapp != null)
        _ContactLink(
          icon: Icons.chat_outlined,
          label: 'WhatsApp',
          uri: Uri.parse(
            'https://wa.me/${business.socialWhatsapp!.replaceAll(RegExp(r'\D'), '')}',
          ),
        ),
      if (business.lat != null && business.lng != null)
        _ContactLink(
          icon: Icons.map_outlined,
          label: t.mapsLabel,
          // geo: URI opens native Maps app (Google Maps on Android, Apple Maps on iOS).
          // Encodes business name in the label for a better pin label.
          uri: Uri.parse(
            'geo:${business.lat},${business.lng}?q=${business.lat},${business.lng}(${Uri.encodeComponent(business.name)})',
          ),
        ),
      if (business.socialInstagram != null)
        _ContactLink(
          icon: Icons.photo_camera_outlined,
          label: 'Instagram',
          uri: Uri.parse(business.socialInstagram!),
        ),
      if (business.socialFacebook != null)
        _ContactLink(
          icon: Icons.thumb_up_outlined,
          label: 'Facebook',
          uri: Uri.parse(business.socialFacebook!),
        ),
      if (business.socialTiktok != null)
        _ContactLink(
          icon: Icons.music_note_outlined,
          label: 'TikTok',
          uri: Uri.parse(business.socialTiktok!),
        ),
      if (business.socialWebsite != null)
        _ContactLink(
          icon: Icons.language_outlined,
          label: t.websiteLabel,
          uri: Uri.parse(business.socialWebsite!),
        ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.contactTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final link in links)
                OutlinedButton.icon(
                  onPressed: () async {
                    // Track WhatsApp taps for analytics
                    if (link.uri.scheme == 'https' &&
                        link.uri.host == 'wa.me') {
                      ref
                          .read(analyticsRepositoryProvider)
                          .logEvent(
                            eventName: 'whatsapp_click',
                            businessId: business.id,
                            source: 'business_contact_section',
                          );
                    }
                    launchUrl(link.uri, mode: LaunchMode.externalApplication);
                  },
                  icon: Icon(link.icon, size: 16),
                  label: Text(link.label),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLink {
  const _ContactLink({
    required this.icon,
    required this.label,
    required this.uri,
  });
  final IconData icon;
  final String label;
  final Uri uri;
}

// ── Email opt-in helper (P3) ──────────────────────────────────────────────────

Future<void> _showEmailOptInSheet(
  BuildContext context,
  WidgetRef ref,
  String businessId,
) async {
  var optIn = false;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sheetCtx, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Favori eklendi',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu işletmenin kampanyalarından ve güncellemelerinden e-posta ile haberdar olmak ister misiniz?',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: optIn,
                  onChanged: (v) => setState(() => optIn = v ?? false),
                  title: const Text('E-posta bildirimlerine abone ol'),
                  subtitle: const Text(
                    'Kampanya, menü değişikliği gibi güncellemeleri alırsınız.',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      child: const Text('Hayır, teşekkürler'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (optIn) {
                          try {
                            await ref
                                .read(supabaseProvider)
                                .rpc(
                                  'set_favorite_email_optin_v1',
                                  params: {
                                    'p_business_id': businessId,
                                    'p_email_optin': true,
                                  },
                                );
                          } catch (_) {
                            // best-effort; ignore errors
                          }
                        }
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                      },
                      child: const Text('Tamam'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ── Loyalty Badge (P1) ─────────────────────────────────────────────────────────

class _BusinessLoyaltyBadge extends ConsumerWidget {
  const _BusinessLoyaltyBadge({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(loyaltyStatusProvider(businessId));
    return statusAsync.maybeWhen(
      data: (status) {
        if (status == null) return const SizedBox.shrink();
        final pct = status.progressPct.clamp(0, 100);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.card_giftcard_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Puan Kazan',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          '${status.points} / ${status.rewardThresholdPts} puan',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '%$pct',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100.0,
                  minHeight: 6,
                  backgroundColor: AppColors.primarySoft,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check-in yaparak +${status.checkinPoints} puan, yorum bırakarak +${status.reviewPoints} puan kazanabilirsiniz.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
