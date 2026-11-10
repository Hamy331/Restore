import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    // Hạn hiển thị: tin đang hiện thì còn bao nhiêu ngày, tin ẩn vì quá hạn thì báo hết hạn
    final expiry = expired
        ? l.accExpired
        : item.status == AccountListingStatus.visible && daysLeft != null
        ? l.accExpiresIn(daysLeft)
        : null;
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
                      const SizedBox(height: 3),
                      Text(
                        expiry,
                        style: TextStyle(
                          fontFamily: profileFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: expired || (daysLeft ?? 99) <= 3
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const SizedBox(width: 90),
            Expanded(
              child: _RowAction(
                l.accEdit,
                onTap: () => showComingSoon(context),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _RowAction(
                isHidden ? (expired ? l.accReactivate : l.accShow) : l.accHide,
                onTap: () => isHidden
                    ? showAccountListing(context, item)
                    : context.read<AccountListingsCubit>().setStatus(
                        item.id,
                        AccountListingStatus.hidden,
                      ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _RowAction(
                l.accBoost,
                filled: true,
                onTap: () => context.push('/boost/${item.id}'),
              ),
            ),
            SizedBox(
              width: 30,
              child: item.status == AccountListingStatus.visible
                  ? PopupMenuButton<VoidCallback>(
                      padding: EdgeInsets.zero,
                      tooltip: l.accMoreOptions,
                      onSelected: (action) => action(),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: () => extendAccountListing(context, item),
                          child: Text(l.accExtend),
                        ),
                      ],
                      icon: const Icon(
                        AppIcons.more,
                        size: 19,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      tooltip: l.accMoreOptions,
                      onPressed: () => showComingSoon(context),
                      icon: const Icon(
                        AppIcons.more,
                        size: 19,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction(this.label, {required this.onTap, this.filled = false});
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Material(
    color: filled ? AppColors.primary : AppColors.background,
    borderRadius: BorderRadius.circular(5),
    child: InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        child: Center(
          child: FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: profileFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
