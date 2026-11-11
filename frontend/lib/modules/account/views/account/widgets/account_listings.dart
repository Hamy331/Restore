import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/utils/formatters/currency_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_local_image.dart';
import '../../../../feeds/widgets/feed_shared.dart';
import '../../../../listings/models/create_listing_step.dart';
import '../../../bloc/account_listings/account_listings_cubit.dart';
import '../../../bloc/account_listings/account_listings_state.dart';
import '../../../models/account_listing.dart';
import 'account_menu.dart';
import 'listing_lifecycle_actions.dart';
import '../../../widgets/profile_header.dart';

/// Các sliver của mục "Tin đăng": tab trạng thái, danh sách và tải thêm.
List<Widget> accountListingSlivers(AccountListingsState state) => [
  const SliverToBoxAdapter(child: _ListingTabs()),
  const SliverToBoxAdapter(child: SizedBox(height: 10)),
  if (state.loading)
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
    )
  else if (state.displayed.isEmpty)
    SliverToBoxAdapter(child: _EmptyListings(status: state.selected))
  else
    SliverList.builder(
      itemCount: state.displayed.length,
      itemBuilder: (_, index) => _ListingRow(item: state.displayed[index]),
    ),
  if (state.loadingMore)
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
];

class _ListingTabs extends StatelessWidget {
  const _ListingTabs();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountListingsCubit, AccountListingsState>(
      builder: (context, state) => Row(
        children: [
          for (final status in AccountListingStatus.values)
            _Tab(
              status: status,
              active: state.selected == status,
              label: switch (status) {
                AccountListingStatus.visible => l.accTabVisible,
                AccountListingStatus.pending => l.accTabPending,
                AccountListingStatus.hidden => l.accTabHidden,
              }(state.count(status)),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.status, required this.active, required this.label});
  final AccountListingStatus status;
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: active,
      child: InkWell(
        onTap: () => context.read<AccountListingsCubit>().select(status),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: profileFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Container(
              height: 3,
              color: active ? AppColors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({required this.status});
  final AccountListingStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Text(
            switch (status) {
              AccountListingStatus.visible => l.accEmptyVisible,
              AccountListingStatus.pending => l.accEmptyPending,
              AccountListingStatus.hidden => l.accEmptyHidden,
            },
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: profileFontFamily,
              color: AppColors.textSecondary,
            ),
          ),
          if (status == AccountListingStatus.visible) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(CreateListingStep.category.path),
              child: Text(l.accPostListing),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.item});
  final AccountListing item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isHidden = item.status == AccountListingStatus.hidden;
    final now = DateTime.now();
    final expired = item.isExpiredAt(now);
    final daysLeft = item.daysLeftAt(now);
    final meta = [
      if (item.category.isNotEmpty) item.category,
      if (item.createdAt != null) l.accPosted(feedTime(l, item.createdAt!)),
      l.accViews(item.views),
    ].join(' · ');
    // Hạn hiển thị: tin đang hiện thì ngày hết hạn và số ngày còn lại,
    // tin ẩn vì quá hạn thì báo đã hết hạn từ ngày nào
    final end = item.expiresAt;
    final endText = end == null
        ? null
        : DateFormat('dd/MM/yyyy').format(end.toLocal());
    final scheduled = item.isScheduledAt(now);
    final expiry = scheduled
        ? l.displayDaysScheduled(
            DateFormat('dd/MM/yyyy').format(item.startsAt!.toLocal()),
          )
        : expired && endText != null
        ? l.accExpiredOn(endText)
        : item.status == AccountListingStatus.visible &&
              daysLeft != null &&
              endText != null
        ? l.accExpiresOn(endText, daysLeft)
        : null;
    final expiryUrgent = !scheduled && (expired || (daysLeft ?? 99) <= 3);
    final visible = item.status == AccountListingStatus.visible;
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => context.push('/listings/${item.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AppLocalImage(
                  path: item.image,
                  width: 78,
                  height: 79,
                  cacheWidth: 160,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: profileFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      CurrencyFormatter.formatVnd(
                        item.price,
                        locale: l.localeName,
                      ),
                      style: const TextStyle(
                        fontFamily: profileFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: profileFontFamily,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (expiry != null) ...[
                      const SizedBox(height: 6),
                      _ExpiryChip(label: expiry, urgent: expiryUrgent),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Hàng nút trải hết chiều ngang để nhãn không bị co chữ
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Expanded(
                child: _RowAction(
                  l.accEdit,
                  icon: AppIcons.edit,
                  onTap: () => showComingSoon(context),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _RowAction(
                  isHidden
                      ? (expired ? l.accReactivate : l.accShow)
                      : l.accHide,
                  icon: isHidden
                      ? (expired ? AppIcons.refresh : AppIcons.visible)
                      : AppIcons.hidden,
                  // Tin ẩn: hiện lại / kích hoạt lại là việc chính
                  filled: isHidden,
                  onTap: () => isHidden
                      ? showAccountListing(context, item)
                      : context.read<AccountListingsCubit>().setStatus(
                          item.id,
                          AccountListingStatus.hidden,
                        ),
                ),
              ),
              if (visible) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: _RowAction(
                    l.accBoost,
                    icon: AppIcons.boost,
                    filled: true,
                    onTap: () => boostAccountListing(context, item),
                  ),
                ),
                const SizedBox(width: 6),
                _MoreButton(
                  tooltip: l.accMoreOptions,
                  actions: [
                    (
                      AppIcons.hot,
                      l.featureAction,
                      () => featureAccountListing(context, item),
                    ),
                    (
                      AppIcons.calendar,
                      l.accExtend,
                      () => extendAccountListing(context, item),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction(
    this.label, {
    required this.icon,
    required this.onTap,
    this.filled = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.textPrimary;
    return Material(
      color: filled ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: FittedBox(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: profileFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút ⋯ vuông cùng cỡ với hàng nút, mở menu thao tác thêm của tin
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.tooltip, required this.actions});
  final String tooltip;
  final List<(IconData, String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 34,
    child: PopupMenuButton<VoidCallback>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        for (final (icon, label, action) in actions)
          PopupMenuItem(
            value: action,
            height: 44,
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: profileFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          AppIcons.moreHorizontal,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    ),
  );
}

/// Dòng hạn hiển thị của tin: đỏ khi đã hết hạn hoặc còn tối đa 3 ngày
class _ExpiryChip extends StatelessWidget {
  const _ExpiryChip({required this.label, required this.urgent});
  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppColors.error : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: urgent ? AppColors.errorBg : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.clock, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: profileFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
