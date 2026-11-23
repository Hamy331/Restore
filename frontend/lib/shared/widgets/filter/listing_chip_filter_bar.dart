import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/area_filter_panel.dart';
import 'package:restore/shared/widgets/filter/category_picker_popover.dart';
import 'package:restore/shared/widgets/filter/filter_popover.dart';
import 'package:restore/shared/widgets/filter/listing_filter_labels.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';

/// Thanh lọc dùng chung cho trang danh mục, kết quả tìm kiếm,
/// Gần bạn, shop và Báo khi có hàng: Lọc · danh mục (bấm để chọn danh mục /
/// danh mục con) · Giá · bộ lọc riêng của danh mục con · Tình trạng · Đăng
/// bởi. Khu vực theo từng cỡ màn hình:
/// - Điện thoại: hàng "Khu vực: Toàn quốc ▾" (bấm để chọn) và "Xoá lọc" nằm
///   trên hàng chip.
/// - Desktop: "Xoá lọc" cuối hàng chip, bên dưới là hàng tỉnh / thành chọn
///   nhanh + Xem thêm.
/// Mỗi chip "▾" mở popover ngay dưới chip (bottom sheet trên điện thoại).
/// Mọi thay đổi trả qua [onChanged].
class ListingChipFilterBar extends StatelessWidget {
  const ListingChipFilterBar({
    super.key,
    required this.filter,
    required this.defaults,
    required this.category,
    required this.onChanged,
    required this.onFilters,
    this.onSwitchCategory,
    this.onCloseCategory,
    this.onClearAll,
    this.extraChips = const [],
    this.showArea = true,
    this.subcategories = true,
    this.showSeller = true,
  });

  final ListingFilter filter;
  final ListingFilter defaults;

  /// Danh mục cha đang lọc (đã tải), null là chưa lọc danh mục
  final CategoryModel? category;
  final ValueChanged<ListingFilter> onChanged;

  /// Nút "Lọc": mở sheet bộ lọc đầy đủ
  final VoidCallback onFilters;

  /// Chọn danh mục cha khác. Trang danh mục mở trang của danh mục đó; null
  /// thì đổi ngay trong bộ lọc (trang tìm kiếm), có thêm "Tất cả danh mục"
  final ValueChanged<String>? onSwitchCategory;

  /// Bấm × trên chip danh mục khi không chọn danh mục con; null là bỏ lọc
  /// danh mục
  final VoidCallback? onCloseCategory;

  /// "Xoá lọc"; null là về [defaults] (giữ sắp xếp và khu vực)
  final VoidCallback? onClearAll;

  /// Chip thêm của từng trang, đặt ngay sau "Lọc" (VD bán kính ở Gần bạn)
  final List<Widget> extraChips;

  /// Hàng "Khu vực:" (Gần bạn lọc theo bán kính nên không cần)
  final bool showArea;

  /// false: chỉ chọn danh mục cha, không có danh mục con, bộ lọc riêng và
  /// "Còn bảo hành" (Báo khi có hàng chưa lưu được các tiêu chí đó)
  final bool subcategories;

  /// Chip "Đăng bởi"
  final bool showSeller;

  /// Danh mục đã gộp danh mục con đang chọn (bộ lọc riêng, giá tối đa...)
  CategoryModel? get _merged =>
      subcategories ? category?.withSubcategory(filter.subcategoryId) : null;

  /// Bảng chọn trong danh sách (radio / checkbox), trả tập giá trị đã chọn
  Future<Set<T>?> _choose<T>(
    BuildContext anchor,
    String title,
    List<FilterChoice<T>> choices,
    Set<T> selected, {
    bool multiple = false,
  }) => showFilterPopover<Set<T>>(
    anchor,
    builder: (_) => FilterChoicePanel<T>(
      title: title,
      choices: choices,
      selected: selected,
      multiple: multiple,
    ),
  );

  /// Chip danh mục: chọn danh mục con, đổi danh mục cha hoặc bỏ lọc
  Future<void> _pickCategory(BuildContext anchor) async {
    final pick = await showCategoryPicker(
      anchor,
      category: category,
      subcategoryId: filter.subcategoryId,
      allowAll: onSwitchCategory == null,
      parentsOnly: !subcategories,
    );
    if (pick == null) return;
    final id = pick.categoryId;
    if (id != null && id == category?.id) {
      onChanged(filter.withSubcategory(pick.subcategoryId));
    } else if (id != null && onSwitchCategory != null) {
      onSwitchCategory!(id);
    } else {
      onChanged(filter.withCategory(id));
    }
  }

  /// Chip "Giá ▾": thanh trượt tới giá tối đa của danh mục con + hai ô nhập
  Future<void> _pickPrice(BuildContext anchor) async {
    final l10n = AppLocalizations.of(anchor)!;
    final range = await showFilterPopover<FilterRange>(
      anchor,
      builder: (_) => FilterRangePanel(
        min: filter.minPrice,
        max: filter.maxPrice,
        top: _merged?.priceMax,
        money: true,
        minLabel: l10n.listingFilterPriceMin,
        maxLabel: l10n.listingFilterPriceMax,
      ),
    );
    if (range == null) return;
    onChanged(
      filter.copyWith(
        minPrice: () => range.min?.toInt(),
        maxPrice: () => range.max?.toInt(),
      ),
    );
  }

  /// Chip bộ lọc riêng ("Hãng ▾", "Dung lượng ▾"...) theo ux_type
  Future<void> _pickAttribute(
    BuildContext anchor,
    CategoryAttributeModel attribute,
  ) async {
    final label = attribute.label.of(anchor);
    final current = filter.attributeFilters[attribute.key];
    if (attribute.filter == AttributeFilterKind.range) {
      final unit = attribute.unit?.of(anchor);
      final range = await showFilterPopover<FilterRange>(
        anchor,
        builder: (_) => FilterRangePanel(
          title: label,
          min: current?.min,
          max: current?.max,
          unit: unit,
        ),
      );
      if (range == null) return;
      onChanged(
        filter.withAttribute(
          attribute.key,
          AttributeFilterValue(min: range.min, max: range.max),
        ),
      );
      return;
    }
    final values = await _choose(
      anchor,
      label,
      [
        for (final option in attribute.options)
          (value: option.value, label: option.label.of(anchor)),
      ],
      current?.values ?? const <String>{},
      multiple: attribute.filter == AttributeFilterKind.multi,
    );
    if (values == null) return;
    onChanged(
      filter.withAttribute(attribute.key, AttributeFilterValue(values: values)),
    );
  }

  /// Chip bật/tắt của thuộc tính có/không ("Đã tiêm phòng"): chỉ lọc tin có
  /// giá trị true, bấm lại để bỏ
  void _toggleFlag(String key) => onChanged(
    filter.withAttribute(
      key,
      AttributeFilterValue(
        values: filter.attributeFilters[key]?.values.contains('true') ?? false
            ? const {}
            : const {'true'},
      ),
    ),
  );

  /// Chip "Tình trạng ▾": theo nhóm (Điện tử có thêm Còn bảo hành)
  Future<void> _pickCondition(BuildContext anchor) async {
    final l10n = AppLocalizations.of(anchor)!;
    final groups = ListingConditionGroup.available(
      warranty: _merged?.hasWarranty ?? false,
    );
    final picked = await _choose(
      anchor,
      l10n.listingFilterCondition,
      [for (final group in groups) (value: group, label: group.label(l10n))],
      {?filter.conditionGroup},
    );
    if (picked == null) return;
    onChanged(filter.withConditionGroup(picked.firstOrNull));
  }

  /// Chip "Đăng bởi ▾": chọn nhiều Cá nhân / Bán chuyên / Đối tác
  Future<void> _pickSeller(BuildContext anchor) async {
    final l10n = AppLocalizations.of(anchor)!;
    final picked = await _choose(
      anchor,
      l10n.listingFilterSeller,
      [
        for (final kind in ListingSellerKind.values)
          (value: kind, label: kind.label(l10n)),
      ],
      filter.sellers,
      multiple: true,
    );
    if (picked == null) return;
    onChanged(filter.copyWith(sellers: picked));
  }

  /// Bảng "Khu vực", mở dưới [anchor] (sheet trên điện thoại)
  Future<void> _pickArea(BuildContext anchor) async {
    final picked = await showAreaFilterPanel(anchor, filter);
    if (picked != null) onChanged(picked);
  }

  /// Chip tỉnh nhanh: bấm lại để bỏ. So theo mã vì nhãn từ trang chọn khu
  /// vực có thể khác ("Hồ Chí Minh")
  void _toggleProvince(String name) {
    final code = quickProvinceCodes[name];
    onChanged(
      filter.provinceCode == code
          ? filter.withArea(null)
          : filter.withArea(code, label: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final active = filter.activeCount(defaults);
    final merged = _merged;
    final filterAttributes = merged?.filterAttributes ?? const [];

    // Hãng đã chọn thành chip riêng "Apple ×" cạnh danh mục
    final brand = filterAttributes
        .where((item) => item.key == 'brand')
        .firstOrNull;
    final brandValues = filter.attributeFilters['brand']?.values ?? const {};
    final brandChip = brand != null && brandValues.length == 1
        ? brand.optionOf(brandValues.first)
        : null;

    final area = filter.areaLabel;
    // Điện thoại: khu vực thu gọn thành một dòng chọn
    final compactArea = showArea && !isDesktopLayout(context);
    final clear = TextButton(
      onPressed: onClearAll ?? () => onChanged(filter.resetTo(defaults)),
      child: Text(
        l10n.filterClear,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compactArea)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                Text(
                  t('Khu vực: ', 'Area: '),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Flexible(
                  child: Builder(
                    builder: (anchor) => InkWell(
                      onTap: () => _pickArea(anchor),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                area ?? l10n.areaNationwide,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.actionPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (active > 0) clear,
              ],
            ),
          ),
        _scrollRow([
          ListingBarChip(
            label: active > 0
                ? '${l10n.listingFilterButton} ($active)'
                : l10n.listingFilterButton,
            leading: AppIcons.filter,
            selected: active > 0,
            onTap: (_) => onFilters(),
          ),
          ...extraChips,
          if (category case final category?)
            ListingBarChip(
              label:
                  merged?.subcategory?.name.of(context) ??
                  category.name.of(context),
              selected: true,
              dropdown: true,
              onTap: _pickCategory,
              // Bỏ danh mục con thì về cả danh mục; đang ở cả danh mục thì
              // bỏ lọc danh mục (trang danh mục: thoát)
              onClear: filter.subcategoryId != null
                  ? () => onChanged(filter.withSubcategory(null))
                  : onCloseCategory ??
                        () => onChanged(filter.withCategory(null)),
            )
          else
            ListingBarChip(
              label: l10n.listingFilterCategory,
              dropdown: true,
              onTap: _pickCategory,
            ),
          if (brandChip != null)
            ListingBarChip(
              label: brandChip.label.of(context),
              selected: true,
              onTap: (anchor) => _pickAttribute(anchor, brand!),
              onClear: () => onChanged(
                filter.withAttribute('brand', const AttributeFilterValue()),
              ),
            ),
          ListingBarChip(
            label: t('Giá', 'Price'),
            dropdown: true,
            selected: filter.hasPriceRange,
            onTap: _pickPrice,
          ),
          for (final attribute in filterAttributes)
            if (attribute.type == AttributeType.boolean)
              ListingBarChip(
                label: attribute.label.of(context),
                selected:
                    filter.attributeFilters[attribute.key]?.values.contains(
                      'true',
                    ) ??
                    false,
                onTap: (_) => _toggleFlag(attribute.key),
              )
            else if (brandChip == null || attribute.key != 'brand')
              ListingBarChip(
                label: attribute.label.of(context),
                dropdown: true,
                selected: filter.attributeFilters.containsKey(attribute.key),
                onTap: (anchor) => _pickAttribute(anchor, attribute),
              ),
          if (merged?.hasCondition ?? true)
            ListingBarChip(
              label: l10n.listingFilterCondition,
              dropdown: true,
              selected: filter.conditionGroup != null,
              onTap: _pickCondition,
            ),
          if (showSeller)
            ListingBarChip(
              label: l10n.listingFilterSeller,
              dropdown: true,
              selected: filter.sellers.isNotEmpty,
              onTap: _pickSeller,
            ),
          if (active > 0 && !compactArea) clear,
        ]),
        if (showArea && !compactArea) ...[
          const SizedBox(height: 10),
          // Hàng "Khu vực:": vài tỉnh / thành chọn nhanh + Xem thêm
          _scrollRow([
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  t('Khu vực:', 'Area:'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Khu vực chọn từ "Xem thêm" (không nằm trong chip nhanh) hiện
            // đầu hàng, bấm để chọn lại
            if (filter.hasArea &&
                !quickProvinceCodes.containsValue(filter.provinceCode) &&
                area != null)
              _AreaChip(area, selected: true, onPressed: _pickArea),
            for (final MapEntry(key: name, value: code)
                in quickProvinceCodes.entries)
              _AreaChip(
                name,
                selected: filter.provinceCode == code,
                onPressed: (_) => _toggleProvince(name),
              ),
            _AreaChip(
              t('Xem thêm', 'More'),
              selected: false,
              onPressed: _pickArea,
            ),
          ]),
        ],
      ],
    );
  }

  static Widget _scrollRow(List<Widget> children) => SizedBox(
    height: 40,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: children,
    ),
  );
}

/// Chip viên thuốc của thanh lọc: nền xám, đang chọn thì nền đậm chữ trắng;
/// [dropdown] thêm "▾", [onClear] thêm "×". [onTap] nhận context của chip để
/// mở popover ngay dưới nó.
class ListingBarChip extends StatelessWidget {
  const ListingBarChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.leading,
    this.dropdown = false,
    this.onClear,
  });

  final String label;
  final ValueChanged<BuildContext> onTap;
  final bool selected;
  final IconData? leading;
  final bool dropdown;
  final VoidCallback? onClear;

  static const fill = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.textPrimary : fill,
        shape: const StadiumBorder(),
        child: Builder(
          builder: (chipContext) => InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => onTap(chipContext),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    Icon(leading, size: 17, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (dropdown) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 20, color: foreground),
                  ],
                  if (onClear != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(AppIcons.close, size: 16, color: foreground),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip tròn viền của hàng "Khu vực:"
class _AreaChip extends StatelessWidget {
  const _AreaChip(this.name, {required this.selected, required this.onPressed});

  final String name;
  final bool selected;

  /// Nhận context của chip để bảng Khu vực mở ngay dưới chip
  final ValueChanged<BuildContext> onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: OutlinedButton(
      onPressed: () => onPressed(context),
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: selected ? AppColors.textPrimary : Colors.transparent,
        foregroundColor: selected ? Colors.white : AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(name),
    ),
  );
}

/// Hàng sắp xếp ("Mới nhất ▾") + nút đổi dạng danh sách / lưới
class ListingSortRow extends StatelessWidget {
  const ListingSortRow({
    super.key,
    required this.sort,
    required this.onSort,
    required this.grid,
    required this.onGridToggle,
  });

  final ListingSort sort;
  final VoidCallback onSort;
  final bool grid;
  final VoidCallback onGridToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          InkWell(
            onTap: onSort,
            child: Row(
              children: [
                Text(
                  sort.label(l10n),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(AppIcons.chevronDown, size: 18),
              ],
            ),
          ),
          const Spacer(),
          IconButton.outlined(
            tooltip: grid
                ? t('Xem dạng danh sách', 'List view')
                : t('Xem dạng lưới', 'Grid view'),
            onPressed: onGridToggle,
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
            ),
            icon: Icon(
              grid ? Icons.view_agenda_outlined : Icons.grid_view,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
