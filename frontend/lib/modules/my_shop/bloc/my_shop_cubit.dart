import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';

import '../models/my_shop_overview.dart';
import '../repositories/my_shop_repository.dart';

enum MyShopStatus { loading, ready, failure }

class MyShopState extends Equatable {
  const MyShopState({
    this.status = MyShopStatus.loading,
    this.overview,
    this.saving = false,
  });

  final MyShopStatus status;
  final MyShopOverview? overview;

  /// Đang mở shop hoặc lưu thay đổi
  final bool saving;

  MyShopState copyWith({
    MyShopStatus? status,
    MyShopOverview? overview,
    bool? saving,
  }) => MyShopState(
    status: status ?? this.status,
    overview: overview ?? this.overview,
    saving: saving ?? this.saving,
  );

  @override
  List<Object?> get props => [status, overview, saving];
}

class MyShopCubit extends Cubit<MyShopState> with SafeEmit<MyShopState> {
  MyShopCubit(this._repository) : super(const MyShopState());

  final MyShopRepository _repository;

  Future<void> load() async {
    if (state.overview == null) {
      emit(state.copyWith(status: MyShopStatus.loading));
    }
    try {
      final overview = await _repository.load();
      emit(MyShopState(status: MyShopStatus.ready, overview: overview));
    } catch (_) {
      emit(
        state.copyWith(
          status: state.overview == null
              ? MyShopStatus.failure
              : MyShopStatus.ready,
        ),
      );
    }
  }

  /// Chạy [work], trả về `null` khi thành công, mã lỗi (hoặc 'NETWORK') khi
  /// thất bại
  Future<String?> _run(Future<MyShopOverview> Function() work) async {
    if (state.saving) return 'BUSY';
    emit(state.copyWith(saving: true));
    try {
      final overview = await work();
      emit(MyShopState(status: MyShopStatus.ready, overview: overview));
      return null;
    } on MyShopException catch (error) {
      emit(state.copyWith(saving: false));
      return error.code;
    } catch (_) {
      emit(state.copyWith(saving: false));
      return 'NETWORK';
    }
  }

  Future<String?> create({
    required String name,
    String? tagline,
    String? address,
  }) => _run(
    () => _repository.create(name: name, tagline: tagline, address: address),
  );

  /// Tải logo / ảnh bìa mới (nếu có) rồi lưu các trường đã đổi
  Future<String?> save(
    Map<String, dynamic> changes, {
    Uint8List? logo,
    Uint8List? cover,
  }) => _run(() async {
    final body = {...changes};
    if (logo != null) body['logoUrl'] = await _repository.uploadImage(logo);
    if (cover != null) body['coverUrl'] = await _repository.uploadImage(cover);
    return _repository.update(body);
  });
}
