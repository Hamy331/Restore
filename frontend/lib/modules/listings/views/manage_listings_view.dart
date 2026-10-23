import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import '../repositories/listings_repository.dart';

String listingStatusText(ListingStatus status) => switch (status) {
  ListingStatus.draft => 'Nháp',
  ListingStatus.pending => 'Chờ duyệt',
  ListingStatus.rejected => 'Bị từ chối',
  ListingStatus.available => 'Đang hiển thị',
  ListingStatus.hidden => 'Đã ẩn',
  ListingStatus.sold => 'Đã bán',
  ListingStatus.exchanged => 'Đã trao đổi',
  ListingStatus.reserved => 'Đã đặt trước',
  ListingStatus.expired => 'Hết hạn',
};

class ManageListingsView extends StatefulWidget {
  const ManageListingsView({this.repository, super.key});
  final ListingsRepository? repository;
  @override
  State<ManageListingsView> createState() => _ManageListingsViewState();
}

class _ManageListingsViewState extends State<ManageListingsView> {
  late final _repository =
      widget.repository ??
      (AppEnvironment.useMockData
          ? MockListingsRepository()
          : ApiListingsRepository());
  List<ListingModel> _items = [];
  bool _loading = false, _more = false;
  String? _filter, _busy;
  String _error = '';
  int _page = 0, _version = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loading || !_more)) return;
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await _repository.mine(
        page: more ? _page + 1 : 1,
        status: _filter,
      );
      if (!mounted || version != _version) return;
      setState(() {
        _items = [if (more) ..._items, ...result.items];
        _page = result.page;
        _more = result.hasMore;
      });
    } catch (_) {
      if (mounted && version == _version) {
        setState(() => _error = 'Không tải được Tin của tôi. Thử lại.');
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  Future<void> _edit(ListingModel item) async {
    await context.push(
      '/create-listing/category?draft=${Uri.encodeQueryComponent(item.id)}',
    );
    if (mounted) await _load();
  }

  Future<void> _action(ListingModel item, String action) async {
    if (_busy != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action?'),
        content: Text(item.title.isEmpty ? 'Tin chưa đặt tên' : item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = item.id);
    try {
      if (action == 'Xóa nháp') {
        await _repository.deleteDraft(item.id);
      } else {
        await _repository.changeStatus(item.id, switch (action) {
          'Ẩn tin' => ListingStatus.hidden,
          'Hiện lại' => ListingStatus.available,
          'Đã bán' => ListingStatus.sold,
          _ => ListingStatus.exchanged,
        });
      }
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không cập nhật được tin. Tải lại và thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: const Text('Tin của tôi'),
      actions: [
        IconButton(
          onPressed: _loading ? null : () => _load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            initialValue: _filter ?? '',
            items: [
              const DropdownMenuItem(value: '', child: Text('Tất cả')),
              for (final status in ListingStatus.values.where(
                (value) => value != ListingStatus.expired,
              ))
                DropdownMenuItem(
                  value: status.apiValue,
                  child: Text(listingStatusText(status)),
                ),
            ],
            onChanged: (value) {
              _filter = value?.isEmpty == true ? null : value;
              _load();
            },
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error.isNotEmpty)
          TextButton(onPressed: () => _load(), child: Text(_error)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (!_loading && _items.isEmpty && _error.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Chưa có tin trong mục này.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final item in _items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: item.coverImage == null
                                    ? const Icon(Icons.image_outlined)
                                    : AppLocalImage(path: item.coverImage!),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title.isEmpty
                                          ? 'Tin chưa đặt tên'
                                          : item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      item.status == ListingStatus.draft &&
                                              (item.price ?? 0) == 0
                                          ? 'Chưa có giá'
                                          : !item.allowSale
                                          ? 'Trao đổi'
                                          : CurrencyFormatter.formatVnd(
                                              item.price ?? 0,
                                              locale: 'vi',
                                            ),
                                    ),
                                    Text(listingStatusText(item.status)),
                                    Text('${item.viewCount} lượt mở tin'),
                                    if (item.address != null)
                                      Text(item.address!.areaLabel),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (item.reviewReason != null)
                            Text(
                              item.reviewReason!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          if (item.status != ListingStatus.draft &&
                              [
                                ListingStatus.available,
                                ListingStatus.hidden,
                                ListingStatus.pending,
                              ].contains(item.status))
                            const Text(
                              'Lưu chỉnh sửa sẽ chuyển tin về nháp. Gửi lại để được duyệt.',
                            ),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (item.status == ListingStatus.available)
                                TextButton(
                                  onPressed: () =>
                                      context.push('/listings/${item.id}'),
                                  child: const Text('Xem tin'),
                                ),
                              if ([
                                ListingStatus.draft,
                                ListingStatus.pending,
                                ListingStatus.rejected,
                                ListingStatus.available,
                                ListingStatus.hidden,
                              ].contains(item.status))
                                TextButton(
                                  onPressed: _busy == null
                                      ? () => _edit(item)
                                      : null,
                                  child: Text(
                                    item.status == ListingStatus.draft
                                        ? 'Tiếp tục nháp'
                                        : 'Sửa tin',
                                  ),
                                ),
                              if (item.status == ListingStatus.draft)
                                TextButton(
                                  onPressed: _busy == null
                                      ? () => _action(item, 'Xóa nháp')
                                      : null,
                                  child: const Text('Xóa nháp'),
                                ),
                              if (item.status == ListingStatus.available)
                                TextButton(
                                  onPressed: _busy == null
                                      ? () => _action(item, 'Ẩn tin')
                                      : null,
                                  child: const Text('Ẩn tin'),
                                ),
                              if (item.status == ListingStatus.hidden)
                                TextButton(
                                  onPressed: _busy == null
                                      ? () => _action(item, 'Hiện lại')
                                      : null,
                                  child: const Text('Hiện lại'),
                                ),
                              if ([
                                ListingStatus.available,
                                ListingStatus.hidden,
                              ].contains(item.status)) ...[
                                if (item.allowSale)
                                  TextButton(
                                    onPressed: _busy == null
                                        ? () => _action(item, 'Đã bán')
                                        : null,
                                    child: const Text('Đã bán'),
                                  ),
                                if (item.allowExchange)
                                  TextButton(
                                    onPressed: _busy == null
                                        ? () => _action(item, 'Đã trao đổi')
                                        : null,
                                    child: const Text('Đã trao đổi'),
                                  ),
                              ],
                              if (_busy == item.id)
                                const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_more)
                  TextButton(
                    onPressed: _loading ? null : () => _load(more: true),
                    child: const Text('Xem thêm'),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
