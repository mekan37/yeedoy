import 'package:flutter/foundation.dart';

/// One row in the weekly schedule (0=Sunday … 6=Saturday).
@immutable
class BusinessHourRow {
  const BusinessHourRow({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
  });

  final int dayOfWeek;
  final String openTime;   // HH:MM
  final String closeTime;  // HH:MM
  final bool isClosed;

  BusinessHourRow copyWith({
    String? openTime,
    String? closeTime,
    bool? isClosed,
  }) =>
      BusinessHourRow(
        dayOfWeek: dayOfWeek,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
        isClosed: isClosed ?? this.isClosed,
      );

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'open_time': openTime,
        'close_time': closeTime,
        'is_closed': isClosed,
      };

  factory BusinessHourRow.fromMap(Map<String, dynamic> m) => BusinessHourRow(
        dayOfWeek: (m['day_of_week'] as num).toInt(),
        openTime: m['open_time'] as String? ?? '09:00',
        closeTime: m['close_time'] as String? ?? '22:00',
        isClosed: m['is_closed'] as bool? ?? false,
      );

  static BusinessHourRow defaultForDay(int dayOfWeek) => BusinessHourRow(
        dayOfWeek: dayOfWeek,
        openTime: '09:00',
        closeTime: '22:00',
        isClosed: false,
      );
}

/// A special/holiday override for a specific date.
@immutable
class BusinessSpecialHour {
  const BusinessSpecialHour({
    required this.date,
    this.openTime,
    this.closeTime,
    required this.isClosed,
    this.note,
  });

  final String date;       // YYYY-MM-DD
  final String? openTime;  // HH:MM — null means closed all day
  final String? closeTime; // HH:MM
  final bool isClosed;
  final String? note;

  factory BusinessSpecialHour.fromMap(Map<String, dynamic> m) =>
      BusinessSpecialHour(
        date: m['date'].toString(),
        openTime: m['open_time'] as String?,
        closeTime: m['close_time'] as String?,
        isClosed: m['is_closed'] as bool? ?? true,
        note: m['note'] as String?,
      );
}

@immutable
class BusinessHoursState {
  const BusinessHoursState({
    this.weekly = const [],
    this.special = const [],
    this.isOpenNow,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.savedMessage,
  });

  final List<BusinessHourRow> weekly;
  final List<BusinessSpecialHour> special;
  final bool? isOpenNow;
  final bool isLoading;
  final bool isSaving;
  final Object? error;
  final String? savedMessage;

  BusinessHoursState copyWith({
    List<BusinessHourRow>? weekly,
    List<BusinessSpecialHour>? special,
    bool? Function()? isOpenNow,
    bool? isLoading,
    bool? isSaving,
    Object? Function()? error,
    String? Function()? savedMessage,
  }) =>
      BusinessHoursState(
        weekly: weekly ?? this.weekly,
        special: special ?? this.special,
        isOpenNow: isOpenNow != null ? isOpenNow() : this.isOpenNow,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error != null ? error() : this.error,
        savedMessage: savedMessage != null ? savedMessage() : this.savedMessage,
      );
}
