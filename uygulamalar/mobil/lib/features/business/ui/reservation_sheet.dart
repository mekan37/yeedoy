import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/colors.dart';
import '../data/reservation_repository.dart';
import '../domain/business.dart';

// ─── Sentinel for nullable copyWith fields ─────────────────────────────────────
const _sentinel = Object();

// ─── State ─────────────────────────────────────────────────────────────────────

class _ReservationFormState {
  const _ReservationFormState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.partySize = 2,
    this.date,
    this.time = '19:30',
    this.specialRequest = '',
    this.pending = false,
    this.error,
    this.successNo,
  });

  final String name;
  final String phone;
  final String email;
  final int partySize;
  final DateTime? date;
  final String time;
  final String specialRequest;
  final bool pending;
  final String? error;
  final String? successNo;

  _ReservationFormState copyWith({
    String? name,
    String? phone,
    String? email,
    int? partySize,
    DateTime? date,
    String? time,
    String? specialRequest,
    bool? pending,
    Object? error = _sentinel,
    Object? successNo = _sentinel,
  }) {
    return _ReservationFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      partySize: partySize ?? this.partySize,
      date: date ?? this.date,
      time: time ?? this.time,
      specialRequest: specialRequest ?? this.specialRequest,
      pending: pending ?? this.pending,
      error: identical(error, _sentinel) ? this.error : error as String?,
      successNo:
          identical(successNo, _sentinel) ? this.successNo : successNo as String?,
    );
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class _ReservationController extends Notifier<_ReservationFormState> {
  @override
  _ReservationFormState build() => const _ReservationFormState();

  void update(_ReservationFormState Function(_ReservationFormState) fn) {
    state = fn(state);
  }

  Future<void> submit(Business business) async {
    final s = state;

    // ── Validation ────────────────────────────────────────────────────────────
    if (s.name.trim().length < 2) {
      state = state.copyWith(error: 'Ad Soyad en az 2 karakter olmalıdır.');
      return;
    }
    if (s.phone.trim().length < 10) {
      state = state.copyWith(
          error: 'Telefon numarası en az 10 karakter olmalıdır.');
      return;
    }
    if (s.date == null) {
      state = state.copyWith(error: 'Lütfen bir tarih seçin.');
      return;
    }
    final minParty = business.reservationMinParty;
    final maxParty = business.reservationMaxParty;
    if (s.partySize < minParty || s.partySize > maxParty) {
      state = state.copyWith(
        error: 'Kişi sayısı $minParty ile $maxParty arasında olmalıdır.',
      );
      return;
    }

    state = state.copyWith(pending: true, error: null);

    try {
      final result =
          await ref.read(reservationRepositoryProvider).submitReservation(
                businessId: business.id,
                guestName: s.name.trim(),
                guestPhone: s.phone.trim(),
                guestEmail:
                    s.email.trim().isEmpty ? null : s.email.trim(),
                partySize: s.partySize,
                date: s.date!,
                time: s.time,
                specialRequest: s.specialRequest.trim().isEmpty
                    ? null
                    : s.specialRequest.trim(),
              );
      state = state.copyWith(
        pending: false,
        successNo: result.reservationNo,
      );
    } catch (e) {
      final msg = e.toString();
      final cleanMsg = msg.startsWith('Exception: ')
          ? msg.substring('Exception: '.length)
          : msg;
      state = state.copyWith(pending: false, error: cleanMsg);
    }
  }
}

final _reservationControllerProvider = NotifierProvider.autoDispose<
    _ReservationController, _ReservationFormState>(
  _ReservationController.new,
);

// ─── Public API ────────────────────────────────────────────────────────────────

void showReservationSheet(BuildContext context, Business business) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => _ReservationSheet(business: business),
  );
}

// ─── Sheet Widget ──────────────────────────────────────────────────────────────

class _ReservationSheet extends ConsumerWidget {
  const _ReservationSheet({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_reservationControllerProvider);
    final ctrl = ref.read(_reservationControllerProvider.notifier);
    final tok = AppTokens.of(context);

    // Success screen replaces the form
    if (state.successNo != null) {
      return _buildSuccessScreen(context, state.successNo!, tok);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetContext, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: AppColors.card,
            child: Column(
              children: [
                _DragHandle(),
                _buildHeader(context),
                const Divider(height: 1, thickness: 0.5),
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          tok.space16,
                          tok.space16,
                          tok.space16,
                          tok.space8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildFormFields(context, state, ctrl, tok),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSubmitArea(context, state, ctrl, tok),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rezervasyon Yap',
                  style: context.sectionTitleStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  business.name,
                  style: context.subtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Kapat',
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form Fields ─────────────────────────────────────────────────────────────

  Widget _buildFormFields(
    BuildContext context,
    _ReservationFormState state,
    _ReservationController ctrl,
    AppTokens tok,
  ) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final maxDate = DateTime.now().add(const Duration(days: 30));
    final timeParts = state.time.split(':');
    final initialHour = int.tryParse(timeParts[0]) ?? 19;
    final initialMinute =
        timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ad Soyad
        _FormField(
          label: 'Ad Soyad *',
          child: TextField(
            onChanged: (v) => ctrl.update((s) => s.copyWith(name: v)),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Adınız ve soyadınız'),
          ),
        ),
        SizedBox(height: tok.space12),

        // Telefon
        _FormField(
          label: 'Telefon *',
          child: TextField(
            onChanged: (v) => ctrl.update((s) => s.copyWith(phone: v)),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '0555 000 00 00'),
          ),
        ),
        SizedBox(height: tok.space12),

        // E-posta
        _FormField(
          label: 'E-posta',
          child: TextField(
            onChanged: (v) => ctrl.update((s) => s.copyWith(email: v)),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'ornek@email.com'),
          ),
        ),
        SizedBox(height: tok.space12),

        // Tarih
        _FormField(
          label: 'Tarih *',
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.date ?? tomorrow,
                firstDate: tomorrow,
                lastDate: maxDate,
                locale: const Locale('tr', 'TR'),
              );
              if (picked != null) {
                ctrl.update((s) => s.copyWith(date: picked));
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: _DateTimeDisplay(
              value: state.date != null
                  ? '${state.date!.day.toString().padLeft(2, '0')}.'
                      '${state.date!.month.toString().padLeft(2, '0')}.'
                      '${state.date!.year}'
                  : null,
              hint: 'Tarih seçin',
              icon: Icons.calendar_today_outlined,
            ),
          ),
        ),
        SizedBox(height: tok.space12),

        // Saat
        _FormField(
          label: 'Saat *',
          child: InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: initialHour,
                  minute: initialMinute,
                ),
              );
              if (picked != null) {
                final formatted =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                ctrl.update((s) => s.copyWith(time: formatted));
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: _DateTimeDisplay(
              value: state.time,
              hint: 'Saat seçin',
              icon: Icons.access_time_outlined,
            ),
          ),
        ),
        SizedBox(height: tok.space12),

        // Kişi Sayısı
        _FormField(
          label: 'Kişi Sayısı *',
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                onPressed: state.partySize > business.reservationMinParty
                    ? () => ctrl
                        .update((s) => s.copyWith(partySize: s.partySize - 1))
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                '${state.partySize}',
                style: context.appText.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(width: 16),
              _StepButton(
                icon: Icons.add,
                onPressed: state.partySize < business.reservationMaxParty
                    ? () => ctrl
                        .update((s) => s.copyWith(partySize: s.partySize + 1))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '(${business.reservationMinParty}–${business.reservationMaxParty} kişi)',
                  style: context.captionStyle,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tok.space12),

        // Özel İstek
        _FormField(
          label: 'Özel İstek',
          child: TextField(
            onChanged: (v) => ctrl.update((s) => s.copyWith(specialRequest: v)),
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Doğum günü, pencere kenarı, vb.',
              alignLabelWithHint: true,
            ),
          ),
        ),

        // İşletme notu
        if (business.reservationNote != null) ...[
          SizedBox(height: tok.space12),
          _InfoBox(
            text: business.reservationNote!,
            backgroundColor: AppColors.warningBg,
            borderColor: AppColors.warning,
            iconColor: AppColors.warningIcon,
            icon: Icons.info_outline,
          ),
        ],

        // Hata mesajı
        if (state.error != null) ...[
          SizedBox(height: tok.space12),
          _InfoBox(
            text: state.error!,
            backgroundColor: AppColors.dangerBg,
            borderColor: AppColors.danger,
            iconColor: AppColors.danger,
            icon: Icons.error_outline,
          ),
        ],

        SizedBox(height: tok.space24),
      ],
    );
  }

  // ── Submit Area ─────────────────────────────────────────────────────────────

  Widget _buildSubmitArea(
    BuildContext context,
    _ReservationFormState state,
    _ReservationController ctrl,
    AppTokens tok,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        tok.space16,
        tok.space12,
        tok.space16,
        tok.space16 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: state.pending ? null : () => ctrl.submit(business),
          child: state.pending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                  ),
                )
              : Text(
                  'Rezervasyon Yap',
                  style: context.appText.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Success Screen ──────────────────────────────────────────────────────────

  Widget _buildSuccessScreen(
    BuildContext context,
    String reservationNo,
    AppTokens tok,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Material(
        color: AppColors.card,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tok.space24,
              vertical: tok.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DragHandle(),
                SizedBox(height: tok.space16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 36,
                  ),
                ),
                SizedBox(height: tok.space16),
                Text(
                  'Rezervasyon Talebiniz Alındı!',
                  style: context.sectionTitleStyle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tok.space8),
                Text(
                  'İşletme en kısa sürede sizinle iletişime geçecektir.',
                  style: context.subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tok.space20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: tok.space16,
                    vertical: tok.space12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rezervasyon No',
                        style: context.captionStyle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reservationNo,
                        style: context.appText.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tok.space24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private Helper Widgets ────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// A labeled form field row (label on top, child widget below).
class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.captionStyle,
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Bordered display box for date / time tappable rows.
class _DateTimeDisplay extends StatelessWidget {
  const _DateTimeDisplay({
    required this.value,
    required this.hint,
    required this.icon,
  });

  final String? value;
  final String hint;
  final IconData icon;

  // 52px = standard input row height (icon 18 + vertical padding 17×2)
  static const double _inputHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final tok = AppTokens.of(context);
    final hasValue = value != null;
    return Container(
      height: _inputHeight,
      padding: EdgeInsets.symmetric(horizontal: tok.space12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 15,
                color: hasValue ? AppColors.textStrong : AppColors.muted,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}

/// Small circular +/- stepper button (44×44 tap target).
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: enabled ? AppColors.primarySoft : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline info / error box with icon + text.
class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
  });

  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.captionStyle.copyWith(color: iconColor),
            ),
          ),
        ],
      ),
    );
  }
}
