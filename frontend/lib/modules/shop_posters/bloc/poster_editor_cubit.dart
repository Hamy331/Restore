import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';

import '../models/poster_draft.dart';
import '../models/shop_poster.dart';
import '../models/shop_poster_overview.dart';
import '../repositories/shop_poster_repository.dart';

class PosterEditorState extends Equatable {
  const PosterEditorState({
    required this.limits,
    this.poster,
    this.title = '',
    this.imageBytes,
    this.sourceBytes,
    this.imageUrl,
    this.linkListing = false,
    this.listing,
    this.startsAt,
    this.days = 7,
    this.listings,
    this.submitting = false,
    this.showErrors = false,
  });

  final PosterLimits limits;

  /// Poster đang sửa; null = tạo mới
  final ShopPoster? poster;
  final String title;

  /// Ảnh đã cắt 1200×600 (PNG), chưa tải lên
  final Uint8List? imageBytes;

  /// Ảnh gốc vừa chọn, giữ lại để căn chỉnh lại
  final Uint8List? sourceBytes;

  /// Ảnh đã có trên server (khi sửa)
  final String? imageUrl;

  /// Bấm poster mở một tin thay vì trang shop
  final bool linkListing;
  final PosterListingRef? listing;

  /// null = chạy ngay khi được duyệt
  final DateTime? startsAt;
  final int days;

  /// Tin đang bán để chọn (null = chưa tải)
  final List<PosterListingRef>? listings;
  final bool submitting;

  /// Đã bấm gửi một lần: hiện lỗi các trường còn thiếu
  final bool showErrors;

  bool get editing => poster != null;
  bool get hasImage => imageBytes != null || (imageUrl?.isNotEmpty ?? false);
  String get trimmedTitle => title.trim();
  bool get titleValid => trimmedTitle.isNotEmpty && trimmedTitle.length <= 80;
  bool get listingValid => !linkListing || listing != null;
  bool get valid => hasImage && titleValid && listingValid;

  /// Ngày kết thúc dự kiến (tính từ hôm nay nếu chạy ngay)
  DateTime endsAt(DateTime now) => (startsAt ?? now).add(Duration(days: days));

  PosterEditorState copyWith({
    String? title,
    Uint8List? imageBytes,
    Uint8List? sourceBytes,
    String? imageUrl,
    bool? linkListing,
    PosterListingRef? listing,
    DateTime? startsAt,
    bool clearStartsAt = false,
    int? days,
    List<PosterListingRef>? listings,
    bool? submitting,
    bool? showErrors,
  }) => PosterEditorState(
    limits: limits,
    poster: poster,
    title: title ?? this.title,
    imageBytes: imageBytes ?? this.imageBytes,
    sourceBytes: sourceBytes ?? this.sourceBytes,
    imageUrl: imageUrl ?? this.imageUrl,
    linkListing: linkListing ?? this.linkListing,
    listing: listing ?? this.listing,
    startsAt: clearStartsAt ? null : startsAt ?? this.startsAt,
    days: days ?? this.days,
    listings: listings ?? this.listings,
    submitting: submitting ?? this.submitting,
    showErrors: showErrors ?? this.showErrors,
  );

  @override
  List<Object?> get props => [
    limits,
    poster,
    title,
    imageBytes,
    sourceBytes,
    imageUrl,
    linkListing,
    listing,
    startsAt,
    days,
    listings,
    submitting,
    showErrors,
  ];
}

/// Kết quả gửi duyệt
sealed class PosterSubmitResult {
  const PosterSubmitResult();
}

class PosterSubmitted extends PosterSubmitResult {
  const PosterSubmitted(this.poster);
  final ShopPoster poster;
}

class PosterSubmitFailed extends PosterSubmitResult {
  const PosterSubmitFailed(this.code, {this.until});
  final String code;
  final DateTime? until;
}

/// Trang tạo / sửa poster
class PosterEditorCubit extends Cubit<PosterEditorState>
    with SafeEmit<PosterEditorState> {
  PosterEditorCubit({
    required ShopPosterRepository repository,
    required PosterLimits limits,
    ShopPoster? poster,
  }) : _repository = repository,
       super(_initial(limits, poster));

  final ShopPosterRepository _repository;

  static PosterEditorState _initial(PosterLimits limits, ShopPoster? poster) {
    if (poster == null) {
      return PosterEditorState(
        limits: limits,
        days: 7.clamp(limits.minDays, limits.maxDays),
      );
    }
    final now = DateTime.now();
    final start = poster.startsAt;
    final listing = poster.listing;
    return PosterEditorState(
      limits: limits,
      poster: poster,
      title: poster.title,
      imageUrl: poster.imageUrl,
      linkListing: listing != null && listing.available,
      listing: listing != null && listing.available ? listing : null,
      // poster đã chạy hoặc ngày cũ đã qua thì coi như chạy ngay khi duyệt lại
      startsAt: start != null && start.isAfter(now) ? start : null,
      days: (poster.days ?? 7).clamp(limits.minDays, limits.maxDays),
    );
  }

  /// Tải danh sách tin đang bán (một lần)
  Future<void> loadListings() async {
    if (state.listings != null) return;
    try {
      emit(state.copyWith(listings: await _repository.myListings()));
    } catch (_) {
      emit(state.copyWith(listings: const []));
    }
  }

  void setTitle(String value) => emit(state.copyWith(title: value));

  /// Ảnh đã cắt ở màn căn chỉnh ([source] là ảnh gốc để căn lại)
  void setImage(Uint8List cropped, {Uint8List? source}) =>
      emit(state.copyWith(imageBytes: cropped, sourceBytes: source));

  void setLinkListing(bool value) {
    emit(state.copyWith(linkListing: value));
    if (value) loadListings();
  }

  void setListing(PosterListingRef listing) =>
      emit(state.copyWith(listing: listing, linkListing: true));

  void setStartsAt(DateTime? value) => emit(
    value == null
        ? state.copyWith(clearStartsAt: true)
        : state.copyWith(startsAt: value),
  );

  void setDays(int value) => emit(
    state.copyWith(
      days: value.clamp(state.limits.minDays, state.limits.maxDays),
    ),
  );

  /// Tải ảnh (nếu chọn ảnh mới) rồi gửi duyệt
  Future<PosterSubmitResult?> submit() async {
    if (state.submitting) return null;
    if (!state.valid) {
      emit(state.copyWith(showErrors: true));
      return null;
    }
    emit(state.copyWith(submitting: true, showErrors: true));
    try {
      final cropped = state.imageBytes;
      final imageUrl = cropped != null
          ? await _repository.uploadImage(cropped)
          : state.imageUrl!;
      final draft = PosterDraft(
        title: state.trimmedTitle,
        imageUrl: imageUrl,
        days: state.days,
        listingId: state.linkListing ? state.listing?.id : null,
        startsAt: state.startsAt,
      );
      final poster = state.poster;
      final saved = poster == null
          ? await _repository.create(draft)
          : await _repository.update(poster.id, draft);
      return PosterSubmitted(saved);
    } on ShopPosterException catch (error) {
      return PosterSubmitFailed(error.code, until: error.until);
    } catch (_) {
      return const PosterSubmitFailed('NETWORK');
    } finally {
      emit(state.copyWith(submitting: false));
    }
  }
}
