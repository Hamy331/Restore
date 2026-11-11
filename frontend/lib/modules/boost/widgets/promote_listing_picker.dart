import 'package:flutter/material.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

import '../../account/models/account_listing.dart';
import '../../account/repositories/account_listings_repository.dart';
import '../../credits/utils/credit_format.dart';
import '../../listings/repositories/listings_repository.dart';

/// Kết quả chọn tin: [listingId] để mở trang quảng bá, hoặc [post] = người
/// dùng chưa có tin đang hiển thị và bấm Đăng tin
typedef PromotePick = ({String? listingId, bool post});

/// Sheet chọn một tin đang hiển thị để quảng bá (mở từ nút Đẩy tin của menu
/// xoè). Trả về null khi đóng sheet.
Future<PromotePick?> showPromoteListingPicker(
  BuildContext context, {
  AccountListingsRepository? repository,
}) {
  final l = AppLocalizations.of(context)!;
  final source =
      repository ??
      ApiAccountListingsRepository(
        AppEnvironment.useMockData ? MockListingsRepository() : null,
      );
  return showAppGlassSheet<PromotePick>(
    context,
    title: l.promoPickTitle,
    subtitle: l.promoPickSubtitle,
    icon: AppIcons.boost,
    heightFactor: 0.7,
    builder: (_) => _Picker(repository: source),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({required this.repository});
  final AccountListingsRepository repository;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late Future<List<AccountListing>> _items = _load();

  Future<List<AccountListing>> _load() async =>
      (await widget.repository.mine(AccountListingStatus.visible)).items;

  void _pick(PromotePick value) {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<List<AccountListing>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _Message(
            text: l.promoLoadError,
            action: l.retry,
            onAction: () => setState(() => _items = _load()),
          );
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return _Message(
            text: l.promoPickEmpty,
            action: l.quickActionPost,
            onAction: () => _pick((listingId: null, post: true)),
          );
        }
        return ListView.separated(
          key: const ValueKey('promote-picker-list'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _Row(
              item: item,
              onTap: () => _pick((listingId: item.id, post: false)),
            );
          },
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.onTap});
  final AccountListing item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      key: ValueKey('promote-pick-${item.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: AppColors.cream,
                child: item.image.isEmpty
                    ? const Icon(AppIcons.boost, color: AppColors.primary)
                    : Image(
                        image: appImageProvider(item.image),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          AppIcons.boost,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.price > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      CreditFormat.vnd(context, item.price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(AppIcons.boost, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.action,
    required this.onAction,
  });
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}
