import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../domain/inbox_models.dart';
import '../domain/inbox_provider.dart';
import '../domain/push_notification_service.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../core/utils/greeting_utils.dart';

enum _InboxFilter { all, unread, business }

const _kBusinessTypes = {
  'nearby_trending',
  'favorite_price_changed',
  'owner_new_review',
  'owner_new_price_suggestion',
  'owner_business_reported',
  'review_reply',
};

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  _InboxFilter _filter = _InboxFilter.all;

  List<InboxItem> _filtered(InboxState st) => switch (_filter) {
        _InboxFilter.all => st.items,
        _InboxFilter.unread => st.items.where((e) => !st.isRead(e)).toList(),
        _InboxFilter.business =>
          st.items.where((e) => _kBusinessTypes.contains(e.type)).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final st = ref.watch(inboxProvider);
    final controller = ref.read(inboxProvider.notifier);
    final notificationsDenied = ref.watch(notificationsDeniedProvider);
    final items = _filtered(st);

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(t),
            _buildFilterBar(),
            if (notificationsDenied)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _NotificationDeniedBanner(),
              ),
            if (st.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  AppErrorMapper.message(st.error),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            if (st.isLoading && st.items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: t.inboxEmptyTitle,
                  description: t.inboxEmptyDescription,
                ),
              )
            else
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: RepaintBoundary(
                    child: _buildInboxTile(
                      context: context,
                      ref: ref,
                      controller: controller,
                      item: item,
                      unread: !st.isRead(item),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
          ],
        ),
    );
  }

  Widget _buildHeader(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeBasedGreeting(),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            t.inboxTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _FilterPill(
              label: 'Tümü',
              selected: _filter == _InboxFilter.all,
              onTap: () => setState(() => _filter = _InboxFilter.all),
            ),
            _FilterPill(
              label: 'Okunmamış',
              selected: _filter == _InboxFilter.unread,
              onTap: () => setState(() => _filter = _InboxFilter.unread),
            ),
            _FilterPill(
              label: 'İşletme',
              selected: _filter == _InboxFilter.business,
              onTap: () => setState(() => _filter = _InboxFilter.business),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: selected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildInboxTile({
  required BuildContext context,
  required WidgetRef ref,
  required InboxController controller,
  required InboxItem item,
  required bool unread,
}) {
  final visual = _visualFor(item);
  return _InboxTile(
    icon: visual.icon,
    accentColor: visual.color,
    title: item.title,
    message: _messageForInboxItem(context, item),
    timeText: _relative(context, item.createdAt),
    unread: unread,
    onTap: () async {
      await controller.markRead(item.id);
      if (!context.mounted) return;
      final clientId = await getAnalyticsClientId();
      await ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.notificationOpen,
            source: 'inbox_page',
            clientId: clientId,
            meta: {'type': item.type, 'target_path': item.targetPath},
          );
      if (!context.mounted) return;
      context.go(item.targetPath);
    },
  );
}

String _messageForInboxItem(BuildContext context, InboxItem item) {
  if (item.type == 'favorite_price_changed') {
    final prevCents = (item.meta['previous_price_cents'] as num?)?.toInt();
    final newCents = (item.meta['matched_price_cents'] as num?)?.toInt();
    if (prevCents != null && newCents != null && newCents < prevCents) {
      final savingsCents = prevCents - newCents;
      final savings = _formatCents(savingsCents);
      return '${item.message} • $savings tasarruf';
    }
    return item.message;
  }

  return item.message;
}


class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.message,
    required this.timeText,
    required this.unread,
    required this.onTap,
  });

  final Object icon;
  final Color accentColor;
  final String title;
  final String message;
  final String timeText;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                child: icon is FaIconData
                    ? FaIcon(icon as FaIconData, size: 20, color: accentColor)
                    : Icon(icon as IconData, size: 20, color: accentColor),
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
                            title,
                            style: TextStyle(
                              fontWeight:
                                  unread ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textStrong,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeText,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCents(int cents) {
  final tl = cents ~/ 100;
  final kr = cents % 100;
  if (kr == 0) return '₺$tl';
  return '₺$tl,${kr.toString().padLeft(2, '0')}';
}

String _relative(BuildContext context, DateTime time) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return t.inboxNow;
  if (diff.inHours < 1) return t.timeMinutes(diff.inMinutes);
  if (diff.inDays < 1) return t.timeHours(diff.inHours);
  if (diff.inDays < 30) return t.timeDays(diff.inDays);
  final d = time.day.toString().padLeft(2, '0');
  final m = time.month.toString().padLeft(2, '0');
  return '$d.$m.${time.year}';
}

class _InboxVisual {
  const _InboxVisual({required this.icon, required this.color});

  /// Either [IconData] (Material) or [FaIconData] (Font Awesome).
  final Object icon;
  final Color color;
}

_InboxVisual _visualFor(InboxItem item) {
  final status = (item.meta['status'] ?? '').toString();
  switch (item.type) {
    case 'price_suggestion_result':
    case 'price_verification_result':
      return _InboxVisual(
        icon: Icons.price_check_outlined,
        color: status == 'approved' ? AppColors.success : AppColors.danger,
      );
    case 'favorite_price_changed':
      return const _InboxVisual(
        icon: Icons.sell_outlined,
        color: AppColors.warning,
      );
    case 'claim_result':
      return _InboxVisual(
        icon: Icons.verified_outlined,
        color: status == 'approved' ? AppColors.success : AppColors.danger,
      );
    case 'owner_new_price_suggestion':
      return const _InboxVisual(
        icon: Icons.attach_money_outlined,
        color: AppColors.info,
      );
    case 'owner_new_review':
      return const _InboxVisual(
        icon: Icons.rate_review_outlined,
        color: AppColors.info,
      );
    case 'owner_business_reported':
      return const _InboxVisual(
        icon: Icons.flag_outlined,
        color: AppColors.warning,
      );
    case 'nearby_trending':
      return const _InboxVisual(
        icon: Icons.local_fire_department_outlined,
        color: AppColors.warning,
      );
    case 'report_result':
      return _InboxVisual(
        icon: Icons.report_outlined,
        color: status == 'kapandı' ? AppColors.success : AppColors.warning,
      );
    case 'review_reply':
      return const _InboxVisual(
        icon: Icons.reply_outlined,
        color: AppColors.info,
      );
    default:
      return const _InboxVisual(
        icon: Icons.notifications_outlined,
        color: AppColors.info,
      );
  }
}


class _NotificationDeniedBanner extends StatelessWidget {
  const _NotificationDeniedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bildirimler kapalı. Fiyat değişikliklerini kaçırmamak için bildirimlere izin ver.',
              style: TextStyle(fontSize: 12, color: AppColors.warningText),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('app-settings:')),
            child: const Text(
              'İzin ver',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.warningText,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

