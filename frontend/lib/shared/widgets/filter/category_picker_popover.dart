import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/shared/widgets/filter/filter_popover.dart';

/// Danh mục được chọn: [category] null là "Tất cả danh mục",
/// [subcategoryId] null là "Tất cả `danh mục cha`"
class CategoryPick {
  final CategoryModel? category;
  final String? subcategoryId;

  const CategoryPick(this.category, [this.subcategoryId]);
}

/// Bảng danh mục khi bấm chip danh mục trên thanh lọc: nút quay
/// lại + tên danh mục cha, dòng "Tất cả `danh mục`" và các danh mục con (dòng
/// đang chọn tô màu). Quay lại thì ra danh sách mọi danh mục cha.
///
/// [category] null (chưa lọc danh mục, VD trang tìm kiếm) thì mở thẳng danh
/// sách danh mục cha. [allowAll] thêm dòng "Tất cả danh mục" để bỏ lọc.
/// [parentsOnly] chỉ chọn danh mục cha (luôn mở danh sách danh mục cha).
Future<CategoryPick?> showCategoryPicker(
  BuildContext anchor, {
  required CategoryModel? category,
  required String? subcategoryId,
  bool allowAll = false,
  bool parentsOnly = false,
  CategoryRepository? repository,
}) => showFilterPopover<CategoryPick>(
  anchor,
  builder: (_) => _CategoryPicker(
    category: category,
    subcategoryId: subcategoryId,
    allowAll: allowAll,
    parentsOnly: parentsOnly,
    repository: repository ?? ApiCategoryRepository(),
  ),
);

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    required this.category,
    required this.subcategoryId,
    required this.allowAll,
    required this.parentsOnly,
    required this.repository,
  });

  final CategoryModel? category;
  final String? subcategoryId;
  final bool allowAll;
  final bool parentsOnly;
  final CategoryRepository repository;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  /// Khác null khi đang xem danh sách mọi danh mục cha
  late Future<List<CategoryModel>>? _all =
      widget.category == null || widget.parentsOnly
      ? widget.repository.getCategories()
      : null;

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
          color: selected ? AppColors.actionPrimary : AppColors.textPrimary,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = widget.category;
    final all = _all;
    if (all != null || category == null) {
      return FilterPanel(
        title: l10n.categoryPickerTitle,
        onClear: widget.allowAll ? () => _pick(const CategoryPick(null)) : null,
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
                if (widget.allowAll)
                  _row(
                    l10n.categoryPickerTitle,
                    category == null,
                    () => _pick(const CategoryPick(null)),
                  ),
                for (final item in items)
                  _row(
                    item.name.of(context),
                    item.id == category?.id,
                    () => _pick(CategoryPick(item)),
                  ),
              ],
            );
          },
        ),
      );
    }
    final name = category.name.of(context);
    void clear() => _pick(CategoryPick(category));
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
              () => _pick(CategoryPick(category, item.id)),
            ),
        ],
      ),
    );
  }
}
