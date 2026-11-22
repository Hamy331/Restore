import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/shared/widgets/filter/filter_popover.dart';

/// Danh mục được chọn: [subcategoryId] null là "Tất cả `danh mục cha`"
class CategoryPick {
  final String categoryId;
  final String? subcategoryId;

  const CategoryPick(this.categoryId, [this.subcategoryId]);
}

/// Bảng danh mục khi bấm chip danh mục trên thanh lọc: nút quay
/// lại + tên danh mục cha, dòng "Tất cả `danh mục`" và các danh mục con (dòng
/// đang chọn tô màu). Quay lại thì ra danh sách mọi danh mục cha.
Future<CategoryPick?> showCategoryPicker(
  BuildContext anchor, {
  required CategoryModel category,
  required String? subcategoryId,
  CategoryRepository? repository,
}) => showFilterPopover<CategoryPick>(
  anchor,
  builder: (_) => _CategoryPicker(
    category: category,
    subcategoryId: subcategoryId,
    repository: repository ?? ApiCategoryRepository(),
  ),
);

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    required this.category,
    required this.subcategoryId,
    required this.repository,
  });

  final CategoryModel category;
  final String? subcategoryId;
  final CategoryRepository repository;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  /// Khác null khi đang xem danh sách mọi danh mục cha
  Future<List<CategoryModel>>? _all;

  void _pick(CategoryPick pick) => Navigator.of(context).pop(pick);

  Widget _row(String label, bool selected, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = widget.category;
    final all = _all;
    void clear() => _pick(CategoryPick(category.id));
    if (all != null) {
      return FilterPanel(
        title: l10n.categoryPickerTitle,
        onClear: clear,
        child: FutureBuilder<List<CategoryModel>>(
          future: all,
          builder: (context, snapshot) {
            final items = snapshot.data;
            if (items == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: snapshot.hasError
                      ? Text(l10n.listingFilterCategoryError)
                      : const CircularProgressIndicator(),
                ),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final item in items)
                  _row(
                    item.name.of(context),
                    item.id == category.id,
                    () => _pick(CategoryPick(item.id)),
                  ),
              ],
            );
          },
        ),
      );
    }
    final name = category.name.of(context);
    return FilterPanel(
      title: name,
      onBack: () => setState(() => _all = widget.repository.getCategories()),
      onClear: clear,
      child: ListView(
        shrinkWrap: true,
        children: [
          _row(
            l10n.listingFilterAllOf(name),
            widget.subcategoryId == null,
            clear,
          ),
          for (final item in category.subcategories)
            _row(
              item.name.of(context),
              item.id == widget.subcategoryId,
              () => _pick(CategoryPick(category.id, item.id)),
            ),
        ],
      ),
    );
  }
}
