import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/manage_listings_cubit.dart';

class ManageListingsView extends StatelessWidget {
  const ManageListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<ManageListingsCubit, ManageListingsState>(
      listenWhen: (previous, current) =>
          previous.markSoldRequestVersion != current.markSoldRequestVersion,
      listener: (context, state) {
        final item = state.selectedItem;
        if (item == null) return;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => _MarkSoldSheet(
            item: item,
            l10n: l10n,
            onConfirm: () {
              context.read<ManageListingsCubit>().markSoldConfirmed();
              sheetContext.pop();
            },
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<ManageListingsCubit>();
        final items = cubit.visibleItems;
        final statusLabels = <ManagedListingStatus, String>{
          ManagedListingStatus.visible: l10n.visibleStatus,
          ManagedListingStatus.pending: l10n.pendingStatus,
          ManagedListingStatus.hidden: l10n.hiddenStatus,
          ManagedListingStatus.sold: l10n.soldStatus,
        };
        final statusNotes = <ManagedListingStatus, String>{
          ManagedListingStatus.visible: '',
          ManagedListingStatus.pending: l10n.pendingStatusNote,
          ManagedListingStatus.hidden: l10n.hiddenStatusNote,
          ManagedListingStatus.sold: l10n.soldStatusNote,
        };
        return SafeArea(
          child: Column(
            children: [
              ResponsiveContent(
                maxWidth: 760,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Text(
                        l10n.manageListings,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton.filled(
                        tooltip: l10n.newListing,
                        onPressed: () => context.go('/create-listing'),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
              ResponsiveContent(
                maxWidth: 760,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    scrollDirection: Axis.horizontal,
                    children: ManagedListingStatus.values
                        .map(
                          (status) => TextButton(
                            onPressed: () => cubit.statusChanged(status),
                            child: Text(
                              statusLabels[status]!,
                              style: TextStyle(
                                fontSize: state.status == status ? 12 : 11,
                                fontWeight: state.status == status
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: state.status == status
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: AppColors.background,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ResponsiveContent(
                      maxWidth: 760,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.listingStatusCount(
                              items.length,
                              statusLabels[state.status]!.toLowerCase(),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ManagedListingCard(
                                item: item,
                                status: state.status,
                                statusLabel: statusLabels[state.status]!,
                                l10n: l10n,
                              ),
                            ),
                          ),
                          if (state.status != ManagedListingStatus.visible)
                            _StatusNote(text: statusNotes[state.status]!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ManagedListingCard extends StatelessWidget {
  const _ManagedListingCard({
    required this.item,
    required this.status,
    required this.statusLabel,
    required this.l10n,
  });

  final ManagedListingItem item;
  final ManagedListingStatus status;
  final String statusLabel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ManageListingsCubit>();
    final actions = switch (status) {
      ManagedListingStatus.visible => <_ListingAction>[
        _ListingAction(
          l10n.editAction,
          () => context.push('/edit-listing/${item.id}'),
        ),
        _ListingAction(
          l10n.boostListing,
          () => context.push('/boost/${item.id}'),
          emphasized: true,
        ),
        _ListingAction(l10n.hideListing, cubit.listingHidden),
        _ListingAction(
          l10n.markAsSold,
          () => cubit.markSoldRequested(item),
          emphasized: true,
        ),
      ],
      ManagedListingStatus.pending => <_ListingAction>[
        _ListingAction(
          l10n.editAction,
          () => context.push('/edit-listing/${item.id}'),
        ),
        _ListingAction(l10n.deleteListing, () {}),
      ],
      ManagedListingStatus.hidden => <_ListingAction>[
        _ListingAction(l10n.showAgain, cubit.listingShown),
        _ListingAction(l10n.deleteListing, () {}),
      ],
      ManagedListingStatus.sold => <_ListingAction>[
        _ListingAction(l10n.deleteListing, () {}),
      ],
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  item.image,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.meta,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: actions
                .map(
                  (action) => SizedBox(
                    height: 35,
                    child: OutlinedButton(
                      onPressed: action.onPressed,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: action.emphasized
                            ? AppColors.primarySoft
                            : AppColors.surface,
                        side: BorderSide(
                          color: action.emphasized
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: action.emphasized
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MarkSoldSheet extends StatelessWidget {
  const _MarkSoldSheet({
    required this.item,
    required this.l10n,
    required this.onConfirm,
  });

  final ManagedListingItem item;
  final AppLocalizations l10n;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.markSoldTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  item.image,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.price,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.markSoldDescription),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.platformNoOrderPayment,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    child: Text(l10n.markAsSold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}

class _ListingAction {
  const _ListingAction(this.label, this.onPressed, {this.emphasized = false});
  final String label;
  final VoidCallback onPressed;
  final bool emphasized;
}
