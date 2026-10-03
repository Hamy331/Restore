import 'package:flutter_bloc/flutter_bloc.dart';

enum ManagedListingStatus { visible, pending, hidden, sold }

class ManagedListingItem {
  const ManagedListingItem({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.meta,
  });

  final String id;
  final String title;
  final String price;
  final String image;
  final String meta;
}

class ManageListingsState {
  const ManageListingsState({
    this.status = ManagedListingStatus.visible,
    this.markSoldRequestVersion = 0,
    this.selectedItem,
  });

  final ManagedListingStatus status;
  final int markSoldRequestVersion;
  final ManagedListingItem? selectedItem;

  ManageListingsState copyWith({
    ManagedListingStatus? status,
    int? markSoldRequestVersion,
    ManagedListingItem? selectedItem,
  }) => ManageListingsState(
    status: status ?? this.status,
    markSoldRequestVersion:
        markSoldRequestVersion ?? this.markSoldRequestVersion,
    selectedItem: selectedItem ?? this.selectedItem,
  );
}

class ManageListingsCubit extends Cubit<ManageListingsState> {
  ManageListingsCubit() : super(const ManageListingsState());

  static const activeItems = <ManagedListingItem>[
    ManagedListingItem(
      id: 'camera',
      title: 'Máy ảnh Canon AE-1 + lens 50mm',
      price: '2.450.000 đ',
      image: 'assets/images/marketplace/listing-camera.png',
      meta: 'Đăng 2 giờ trước · 128 lượt xem',
    ),
    ManagedListingItem(
      id: 'lamp',
      title: 'Đèn bàn đồng vintage',
      price: '590.000 đ',
      image: 'assets/images/marketplace/listing-lamp.png',
      meta: 'Đăng hôm qua · 76 lượt xem',
    ),
    ManagedListingItem(
      id: 'chair',
      title: 'Ghế gỗ sồi Bắc Âu',
      price: '1.200.000 đ',
      image: 'assets/images/marketplace/listing-chair.png',
      meta: 'Đăng 3 ngày trước · 204 lượt xem',
    ),
  ];

  List<ManagedListingItem> get visibleItems =>
      state.status == ManagedListingStatus.visible
      ? activeItems
      : state.status == ManagedListingStatus.pending
      ? [activeItems[1]]
      : state.status == ManagedListingStatus.hidden
      ? [activeItems[2]]
      : [activeItems[0]];

  void statusChanged(ManagedListingStatus value) =>
      emit(state.copyWith(status: value));

  void markSoldRequested(ManagedListingItem item) => emit(
    state.copyWith(
      selectedItem: item,
      markSoldRequestVersion: state.markSoldRequestVersion + 1,
    ),
  );

  void markSoldConfirmed() =>
      emit(state.copyWith(status: ManagedListingStatus.sold));

  void listingHidden() =>
      emit(state.copyWith(status: ManagedListingStatus.hidden));

  void listingShown() =>
      emit(state.copyWith(status: ManagedListingStatus.visible));
}
