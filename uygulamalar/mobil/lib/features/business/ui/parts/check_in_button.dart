part of '../business_page.dart';

class CheckInButton extends ConsumerStatefulWidget {
  const CheckInButton({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends ConsumerState<CheckInButton> {
  bool _isSubmitting = false;

  Future<void> _onCheckIn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(
        checkInNotifierProvider(widget.businessId).notifier,
      );
      final result = await notifier.checkIn();
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      switch (result) {
        case CheckInResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.checkInSuccess),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        case CheckInResult.alreadyCheckedIn:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.checkInAlreadyDone),
              behavior: SnackBarBehavior.floating,
            ),
          );
        case CheckInResult.notAuthenticated:
          await showQuickLoginSheet(
            context,
            redirectPath: '/b/${widget.businessId}',
          );
        case CheckInResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.errorOccurred),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final checkInAsync = ref.watch(checkInNotifierProvider(widget.businessId));

    return checkInAsync.when(
      loading: () => const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) => const SizedBox.shrink(),
      data: (checkedIn) {
        if (checkedIn) {
          return Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: tokens.space16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(tokens.radius12),
              border: Border.all(color: const Color(0xFF16A34A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 18,
                ),
                SizedBox(width: tokens.space8),
                Text(
                  t.checkedInToday,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: const Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return FilledButton.icon(
          onPressed: _isSubmitting ? null : _onCheckIn,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : const Icon(Icons.location_on_rounded, size: 18),
          label: Text(t.checkInButton),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius12),
            ),
          ),
        );
      },
    );
  }
}
