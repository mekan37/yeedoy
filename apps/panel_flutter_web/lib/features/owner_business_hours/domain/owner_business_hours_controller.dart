import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_business_hours_repository.dart';
import 'owner_business_hours_models.dart';

final ownerBusinessHoursControllerProvider = NotifierProvider.family<
    OwnerBusinessHoursController, BusinessHoursState, String>(
  OwnerBusinessHoursController.new,
);

class OwnerBusinessHoursController extends Notifier<BusinessHoursState> {
  OwnerBusinessHoursController(this._businessId);
  final String _businessId;

  @override
  BusinessHoursState build() {
    Future.microtask(() => _load(_businessId));
    return const BusinessHoursState(isLoading: true);
  }

  Future<void> _load(String businessId) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final data = await _repo.fetchHours(businessId);
      final weeklyRaw = data['weekly'] as List? ?? [];
      final specialRaw = data['special'] as List? ?? [];
      final isOpenNow = data['is_open_now'] as bool?;

      // Build 7-row schedule (0=Sunday … 6=Saturday). Fill gaps with defaults.
      final serverMap = {
        for (final r in weeklyRaw)
          (r as Map).cast<String, dynamic>()['day_of_week'] as int:
              BusinessHourRow.fromMap((r).cast<String, dynamic>())
      };
      final weekly = List.generate(
        7,
        (i) => serverMap[i] ?? BusinessHourRow.defaultForDay(i),
      );
      final special = specialRaw
          .map((r) =>
              BusinessSpecialHour.fromMap((r as Map).cast<String, dynamic>()))
          .toList();

      state = state.copyWith(
        weekly: weekly,
        special: special,
        isOpenNow: () => isOpenNow,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e);
    }
  }

  Future<void> refresh() => _load(_businessId);

  // ── Weekly mutations ──────────────────────────────────────────────────────

  void updateDayClosed(int dayOfWeek, bool isClosed) {
    state = state.copyWith(
      weekly: state.weekly
          .map((r) =>
              r.dayOfWeek == dayOfWeek ? r.copyWith(isClosed: isClosed) : r)
          .toList(),
    );
  }

  void updateDayOpenTime(int dayOfWeek, String openTime) {
    state = state.copyWith(
      weekly: state.weekly
          .map((r) =>
              r.dayOfWeek == dayOfWeek ? r.copyWith(openTime: openTime) : r)
          .toList(),
    );
  }

  void updateDayCloseTime(int dayOfWeek, String closeTime) {
    state = state.copyWith(
      weekly: state.weekly
          .map((r) =>
              r.dayOfWeek == dayOfWeek ? r.copyWith(closeTime: closeTime) : r)
          .toList(),
    );
  }

  Future<String?> saveWeeklyHours() async {
    state = state.copyWith(
        isSaving: true, error: () => null, savedMessage: () => null);
    try {
      await _repo.upsertWeeklyHours(
        businessId: _businessId,
        hours: state.weekly,
      );
      state = state.copyWith(
        isSaving: false,
        savedMessage: () => 'Çalışma saatleri kaydedildi.',
      );
      await _load(_businessId);
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: () => e);
      return e.toString();
    }
  }

  // ── Special hour mutations ─────────────────────────────────────────────────

  Future<String?> addSpecialHour({
    required String date,
    String? openTime,
    String? closeTime,
    required bool isClosed,
    String? note,
  }) async {
    state = state.copyWith(isSaving: true, error: () => null);
    try {
      await _repo.upsertSpecialHour(
        businessId: _businessId,
        date: date,
        openTime: openTime,
        closeTime: closeTime,
        isClosed: isClosed,
        note: note,
      );
      state = state.copyWith(isSaving: false);
      await _load(_businessId);
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: () => e);
      return e.toString();
    }
  }

  Future<String?> deleteSpecialHour(String date) async {
    state = state.copyWith(isSaving: true, error: () => null);
    try {
      await _repo.deleteSpecialHour(businessId: _businessId, date: date);
      state = state.copyWith(isSaving: false);
      await _load(_businessId);
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: () => e);
      return e.toString();
    }
  }

  OwnerBusinessHoursRepository get _repo =>
      ref.read(ownerBusinessHoursRepositoryProvider);
}
