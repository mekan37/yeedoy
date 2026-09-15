part of '../account_security_page.dart';

// ── Güvenilen Cihazlar sheet ──────────────────────────────────────────────────

class _TrustedDevicesSheet extends StatefulWidget {
  const _TrustedDevicesSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_TrustedDevicesSheet> createState() => _TrustedDevicesSheetState();
}

class _TrustedDevicesSheetState extends State<_TrustedDevicesSheet> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = widget.ref.read(supabaseProvider);
      final res = await client
          .from('user_devices')
          .select('id, platform, app_version, last_seen_at, created_at')
          .order('last_seen_at', ascending: false);
      if (mounted) {
        setState(() {
          _devices = List<Map<String, dynamic>>.from(res as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String id) async {
    try {
      final client = widget.ref.read(supabaseProvider);
      // `.select()` zorunlu: onsuz RLS'in sessizce 0 satır silmesi (örn.
      // eksik DELETE policy'si) `error` fırlatmaz, yalnızca boş sonuç döner.
      final deleted = await client
          .from('user_devices')
          .delete()
          .eq('id', id)
          .select('id');
      if ((deleted as List).isEmpty) {
        throw Exception('device_delete_denied');
      }
      if (mounted) {
        setState(() => _devices.removeWhere((d) => d['id'] == id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.accountSecurityDeviceRemoveFailed),
          ),
        );
      }
    }
  }

  String _relativeTime(String? raw) {
    final t = context.l10n;
    if (raw == null) return t.accountSecurityUnknown;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return t.accountSecurityUnknown;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return t.accountSecurityTimeJustNow;
    if (diff.inHours < 1)
      return t.accountSecurityTimeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return t.accountSecurityTimeHoursAgo(diff.inHours);
    if (diff.inDays < 30) return t.accountSecurityTimeDaysAgo(diff.inDays);
    return t.accountSecurityTimeMonthsAgo((diff.inDays / 30).round());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.accountSecurityTrustedDevicesTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.textStrong,
                    ),
                  ),
                  Text(
                    context.l10n.accountSecurityTrustedDevicesSheetSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  context.l10n.accountSecurityNoDevicesFound,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...List.generate(_devices.length, (i) {
              final d = _devices[i];
              final platform = (d['platform'] as String?) ?? 'Bilinmiyor';
              final version = (d['app_version'] as String?) ?? '';
              final lastSeen = _relativeTime(d['last_seen_at'] as String?);
              final isAndroid = platform.toLowerCase().contains('android');
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isAndroid
                            ? Icons.android_rounded
                            : Icons.phone_iphone_rounded,
                        color: AppColors.textStrong,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      isAndroid
                          ? context.l10n.accountSecurityAndroidDevice
                          : context.l10n.accountSecurityIosDevice,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textStrong,
                      ),
                    ),
                    subtitle: Text(
                      version.isNotEmpty ? 'v$version · $lastSeen' : lastSeen,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(
                              dialogContext
                                  .l10n
                                  .accountSecurityRemoveDeviceDialogTitle,
                            ),
                            content: Text(
                              dialogContext
                                  .l10n
                                  .accountSecurityRemoveDeviceDialogBody,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: Text(
                                  dialogContext
                                      .l10n
                                      .accountSecurityCancelButton,
                                ),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                ),
                                child: Text(
                                  dialogContext
                                      .l10n
                                      .accountSecurityRemoveButton,
                                ),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) _remove(d['id'] as String);
                      },
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

