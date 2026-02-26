import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/report_repository.dart';

enum ReportStatus { idle, loading, success, error }

class ReportState {
  const ReportState({required this.status, this.errorCode, this.message});

  final ReportStatus status;
  final String? errorCode;
  final String? message;

  factory ReportState.idle() => const ReportState(status: ReportStatus.idle);

  ReportState copyWith({
    ReportStatus? status,
    String? errorCode,
    String? message,
  }) {
    return ReportState(
      status: status ?? this.status,
      errorCode: errorCode,
      message: message,
    );
  }
}

final reportControllerProvider =
    NotifierProvider.family<ReportController, ReportState, String>(
      ReportController.new,
    );

class ReportController extends Notifier<ReportState> {
  ReportController(this.businessId);
  final String businessId;

  @override
  ReportState build() => ReportState.idle();

  Future<ReportResult> submit({required String reason, String? details}) async {
    state = state.copyWith(
      status: ReportStatus.loading,
      errorCode: null,
      message: null,
    );

    try {
      final repo = ref.read(reportRepositoryProvider);
      final res = await repo.submitBusinessReport(
        businessId: businessId,
        reason: reason,
        details: details,
      );
      if (res.ok) {
        state = state.copyWith(status: ReportStatus.success);
        return res;
      }
      state = state.copyWith(
        status: ReportStatus.error,
        errorCode: res.error,
        message: res.error,
      );
      return res;
    } catch (e) {
      state = state.copyWith(status: ReportStatus.error, message: e.toString());
      return const ReportResult(ok: false, error: 'unknown');
    }
  }
}

final reviewReportControllerProvider =
    NotifierProvider.family<ReviewReportController, ReportState, String>(
      ReviewReportController.new,
    );

class ReviewReportController extends Notifier<ReportState> {
  ReviewReportController(this.reviewId);
  final String reviewId;

  @override
  ReportState build() => ReportState.idle();

  Future<ReportResult> submit({required String reason, String? details}) async {
    state = state.copyWith(
      status: ReportStatus.loading,
      errorCode: null,
      message: null,
    );

    try {
      final repo = ref.read(reportRepositoryProvider);
      final res = await repo.submitReviewReport(
        reviewId: reviewId,
        reason: reason,
        details: details,
      );
      if (res.ok) {
        state = state.copyWith(status: ReportStatus.success);
        return res;
      }
      state = state.copyWith(
        status: ReportStatus.error,
        errorCode: res.error,
        message: res.error,
      );
      return res;
    } catch (e) {
      state = state.copyWith(status: ReportStatus.error, message: e.toString());
      return const ReportResult(ok: false, error: 'unknown');
    }
  }
}

final menuPhotoReportControllerProvider =
    NotifierProvider.family<MenuPhotoReportController, ReportState, String>(
      MenuPhotoReportController.new,
    );

class MenuPhotoReportController extends Notifier<ReportState> {
  MenuPhotoReportController(this.menuItemPhotoId);
  final String menuItemPhotoId;

  @override
  ReportState build() => ReportState.idle();

  Future<ReportResult> submit({required String reason, String? details}) async {
    state = state.copyWith(
      status: ReportStatus.loading,
      errorCode: null,
      message: null,
    );

    try {
      final repo = ref.read(reportRepositoryProvider);
      final res = await repo.submitMenuItemPhotoReport(
        menuItemPhotoId: menuItemPhotoId,
        reason: reason,
        details: details,
      );
      if (res.ok) {
        state = state.copyWith(status: ReportStatus.success);
        return res;
      }
      state = state.copyWith(
        status: ReportStatus.error,
        errorCode: res.error,
        message: res.error,
      );
      return res;
    } catch (e) {
      state = state.copyWith(status: ReportStatus.error, message: e.toString());
      return const ReportResult(ok: false, error: 'unknown');
    }
  }
}
