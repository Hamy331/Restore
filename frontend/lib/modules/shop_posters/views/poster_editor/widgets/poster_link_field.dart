import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';

import '../../../bloc/poster_editor_cubit.dart';
import '../../../models/shop_poster.dart';

/// Nơi mở khi bấm poster: trang shop hoặc một tin đang bán của shop
class PosterLinkField extends StatelessWidget {
  const PosterLinkField({super.key});

  Future<void> _chooseListing(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PosterEditorCubit>();
    await cubit.loadListings();
    if (!context.mounted) return;
    final listings = cubit.state.listings ?? const <PosterListingRef>[];
    final chosen = await showAppOptionSheet<String>(
      context,
      title: l.spChooseListing,
      subtitle: listings.isEmpty ? l.spNoListings : null,
      selected: cubit.state.listing?.id,
      options: [
        for (final listing in listings)
          AppSheetOption(listing.id, listing.title),
      ],
    );
    if (chosen == null) return;
    cubit.setListing(listings.firstWhere((listing) => listing.id == chosen));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<PosterEditorCubit>().state;
    final cubit = context.read<PosterEditorCubit>();
    final listing = state.listing;
    final missing = state.showErrors && !state.listingValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppChoiceChips<bool>(
          alignment: WrapAlignment.start,
          items: [
            AppChoiceItem(false, l.spOpenShop),
            AppChoiceItem(true, l.spOpenListing),
          ],
          selected: state.linkListing,
          onSelected: cubit.setLinkListing,
        ),
        if (state.linkListing) ...[
          const SizedBox(height: 12),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const ValueKey('poster-listing'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => _chooseListing(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: missing ? AppColors.error : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.listings,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        listing?.title ?? l.spChooseListing,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: listing == null
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: listing == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      AppIcons.chevronRight,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (missing)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.spListingRequired,
                style: const TextStyle(fontSize: 12.5, color: AppColors.error),
              ),
            ),
        ],
      ],
    );
  }
}
