import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing_preview.dart';
import '../bloc/manage_listings_cubit.dart';

class ManageListingsView extends StatelessWidget {
  const ManageListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ManageListingsCubit>();
    return BlocConsumer<ManageListingsCubit, ManageListingsState>(
      listenWhen: (before, after) =>
          after.error.isNotEmpty && before.error != after.error,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error))),
      builder: (context, state) => SafeArea(
        child: Column(
          children: [
            ResponsiveContent(
              maxWidth: 760,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.manageListings,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tải lại',
                      onPressed: () => cubit.load(),
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton.filled(
                      tooltip: l10n.newListing,
                      onPressed: () => context.go('/create-listing'),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      icon: const Icon(Icons.add),
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
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final status in ManagedListingStatus.values)
                      TextButton(
                        onPressed: () => cubit.statusChanged(status),
                        child: Text(
                          _tabLabel(status, l10n),
                          style: TextStyle(
                            fontWeight: state.status == status
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: state.status == status
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: RefreshIndicator(
                  onRefresh: () => cubit.load(),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      ResponsiveContent(
                        maxWidth: 760,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.isLoading && state.items.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            if (!state.isLoading && state.items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 40,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.error.isEmpty
                                            ? 'Chưa có tin trong mục này.'
                                            : 'Không tải được tin.',
                                      ),
                                      if (state.error.isNotEmpty)
                                        TextButton(
                                          onPressed: () => cubit.load(),
                                          child: const Text('Thử lại'),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            for (final item in state.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ListingCard(
                                  item: item,
                                  busy: state.busyId != null,
                                  onEdit: () =>
                                      context.push('/edit-listing/${item.id}'),
                                  onBoost: () =>
                                      context.push('/boost/${item.id}'),
                                  onHide: () =>
                                      cubit.changeStatus(item, 'HIDDEN'),
                                  onShow: () =>
                                      cubit.changeStatus(item, 'AVAILABLE'),
                                  onSold: () =>
                                      _confirmSold(context, item, cubit),
                                ),
                              ),
                            if (state.hasMore)
                              Center(
                                child: TextButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : () => cubit.load(more: true),
                                  child: Text(
                                    state.isLoading
                                        ? 'Đang tải...'
                                        : 'Xem thêm tin',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tabLabel(ManagedListingStatus status, AppLocalizations l10n) =>
      switch (status) {
        ManagedListingStatus.all => 'Tất cả',
        ManagedListingStatus.visible => l10n.visibleStatus,
        ManagedListingStatus.hidden => l10n.hiddenStatus,
        ManagedListingStatus.sold => l10n.soldStatus,
      };

  Future<void> _confirmSold(
    BuildContext context,
    ListingPreview item,
    ManageListingsCubit cubit,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đánh dấu đã bán?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(item.title),
              const SizedBox(height: 8),
              const Text('Tin sẽ ngừng hiển thị và không thể mở bán lại.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Hủy'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Đã bán'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && !cubit.isClosed) {
      await cubit.changeStatus(item, 'SOLD');
    }
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onBoost,
    required this.onHide,
    required this.onShow,
    required this.onSold,
  });
  final ListingPreview item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onBoost;
  final VoidCallback onHide;
  final VoidCallback onShow;
  final VoidCallback onSold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = switch (item.status) {
      'AVAILABLE' => <(String, VoidCallback)>[
        (l10n.editAction, onEdit),
        (l10n.boostListing, onBoost),
        (l10n.hideListing, onHide),
        (l10n.markAsSold, onSold),
      ],
      'HIDDEN' => <(String, VoidCallback)>[
        (l10n.editAction, onEdit),
        (l10n.showAgain, onShow),
        (l10n.markAsSold, onSold),
      ],
      _ => <(String, VoidCallback)>[],
    };
    final statusText = switch (item.status) {
      'AVAILABLE' => l10n.visibleStatus,
      'HIDDEN' => l10n.hiddenStatus,
      'SOLD' => l10n.soldStatus,
      'RESERVED' => 'Đã đặt trước',
      'EXCHANGED' => 'Đã trao đổi',
      _ => item.status,
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
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: item.imageUrl == null
                      ? const Icon(Icons.image_outlined, size: 32)
                      : Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
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
                      statusText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      item.location,
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
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final action in actions)
                  OutlinedButton(
                    onPressed: busy ? null : action.$2,
                    child: Text(
                      action.$1,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
