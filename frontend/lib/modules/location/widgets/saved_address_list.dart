import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/data/models/saved_address_model.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Mục "Địa chỉ đã lưu" đầu sheet chọn địa chỉ: bấm một dòng để dùng lại,
/// nút ba chấm để đặt tên hoặc xoá. Không có địa chỉ nào thì không hiện gì.
class SavedAddressList extends StatelessWidget {
  final List<SavedAddressModel> addresses;

  /// Địa chỉ đang chọn trong sheet trùng với địa chỉ đã lưu này
  final bool Function(SavedAddressModel address) isSelected;
  final ValueChanged<SavedAddressModel> onSelected;
  final ValueChanged<SavedAddressModel> onMore;

  const SavedAddressList({
    super.key,
    required this.addresses,
    required this.isSelected,
    required this.onSelected,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(
                AppIcons.history,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.savedAddressesTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        for (final (index, address) in addresses.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          _SavedAddressTile(
            address: address,
            selected: isSelected(address),
            onTap: () => onSelected(address),
            onMore: () => onMore(address),
          ),
        ],
      ],
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  final SavedAddressModel address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _SavedAddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AppGlass.fieldRadius);
    final label = address.label;
    final street = address.streetAddress.trim();
    // Có tên thì tên là dòng chính; không thì số nhà/đường, rồi tới phường
    final title = label ?? (street.isNotEmpty ? street : address.ward.name);
    final subtitle = label != null
        ? address.fullLabel
        : street.isNotEmpty
        ? '${address.ward.name}, ${address.province.name}'
        : address.province.name;

    return Material(
      color: AppGlass.fillStrong,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? AppColors.primary : AppGlass.stroke,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? AppIcons.checkCircleActive : AppIcons.location,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMore,
                tooltip: l10n.savedAddressMore,
                icon: const Icon(
                  AppIcons.more,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
