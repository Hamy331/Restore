import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/feedback_view.dart';
import '../../../../shared/widgets/listing_grid.dart';
import '../../data/listing_repository.dart';
import '../../../stores/data/store_repository.dart';

class SearchView extends StatefulWidget {
  const SearchView({
    this.repository,
    this.storeRepository,
    this.initialCategoryId = '',
    super.key,
  });
  final ListingRepository? repository;
  final StoreRepository? storeRepository;
  final String initialCategoryId;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  late final ListingRepository _repository =
      widget.repository ?? ListingRepository();
  late final StoreRepository _storeRepository =
      widget.storeRepository ?? StoreRepository();
  late Future<List<StoreCategory>> _categories = _storeRepository.categories();
  late String _categoryId = widget.initialCategoryId;
  String _condition = '';
  String _priceError = '';
  late Future<ListingPage> _result = _repository.search(
    categoryId: _categoryId,
  );
  Timer? _debounce;
  int _page = 1;

  void _load({int page = 1}) {
    final min = int.tryParse(_minPrice.text);
    final max = int.tryParse(_maxPrice.text);
    if (min != null && max != null && min > max) {
      setState(() => _priceError = 'Giá từ phải nhỏ hơn hoặc bằng giá đến.');
      return;
    }
    setState(() {
      _priceError = '';
      _page = page;
      _result = _repository.search(
        page: page,
        query: _controller.text,
        categoryId: _categoryId,
        condition: _condition,
        minPrice: _minPrice.text,
        maxPrice: _maxPrice.text,
      );
    });
  }

  void _debouncedLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ResponsiveContent(
      maxWidth: 840,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                AppSearchField(
                  controller: _controller,
                  hintText: 'Tìm theo tên sản phẩm',
                  onChanged: (_) => _debouncedLoad(),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<StoreCategory>>(
                  future: _categories,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return TextButton(
                        onPressed: () => setState(
                          () => _categories = _storeRepository.categories(),
                        ),
                        child: const Text('Không tải được danh mục. Thử lại'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    return DropdownButtonFormField<String>(
                      key: const ValueKey('search-category'),
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Tất cả danh mục'),
                        ),
                        if (_categoryId.isNotEmpty &&
                            !snapshot.data!.any(
                              (category) => category.id == _categoryId,
                            ))
                          DropdownMenuItem(
                            value: _categoryId,
                            child: const Text('Danh mục không còn tồn tại'),
                          ),
                        for (final category in snapshot.data!)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) {
                        _categoryId = value ?? '';
                        _load();
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const ValueKey('search-condition'),
                  initialValue: _condition,
                  decoration: const InputDecoration(labelText: 'Tình trạng'),
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả tình trạng'),
                    ),
                    DropdownMenuItem(value: 'NEW', child: Text('Mới')),
                    DropdownMenuItem(value: 'LIKE_NEW', child: Text('Như mới')),
                    DropdownMenuItem(
                      value: 'USED_GOOD',
                      child: Text('Đã sử dụng, còn tốt'),
                    ),
                    DropdownMenuItem(
                      value: 'USED_FAIR',
                      child: Text('Đã sử dụng'),
                    ),
                    DropdownMenuItem(
                      value: 'FOR_PARTS',
                      child: Text('Dùng lấy linh kiện'),
                    ),
                  ],
                  onChanged: (value) {
                    _condition = value ?? '';
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('search-min-price'),
                        controller: _minPrice,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Giá từ (đ)',
                        ),
                        onChanged: (_) => _debouncedLoad(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('search-max-price'),
                        controller: _maxPrice,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Giá đến (đ)',
                        ),
                        onChanged: (_) => _debouncedLoad(),
                      ),
                    ),
                  ],
                ),
                if (_priceError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _priceError,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                FutureBuilder<ListingPage>(
                  future: _result,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return FeedbackView(
                        icon: Icons.wifi_off_outlined,
                        title: 'Không tải được tin đăng',
                        message: 'Kiểm tra kết nối rồi thử lại.',
                        action: TextButton(
                          onPressed: () => _load(page: _page),
                          child: const Text('Thử lại'),
                        ),
                      );
                    }
                    final result = snapshot.data!;
                    if (result.items.isEmpty) {
                      return const FeedbackView(
                        icon: Icons.search_off_outlined,
                        title: 'Không tìm thấy tin đăng',
                        message: 'Thử tên sản phẩm khác.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.totalItems} tin phù hợp',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListingGrid(listings: result.items),
                        if (result.totalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _page > 1
                                    ? () => _load(page: _page - 1)
                                    : null,
                                child: const Text('Trước'),
                              ),
                              Text('$_page/${result.totalPages}'),
                              TextButton(
                                onPressed: _page < result.totalPages
                                    ? () => _load(page: _page + 1)
                                    : null,
                                child: const Text('Sau'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
