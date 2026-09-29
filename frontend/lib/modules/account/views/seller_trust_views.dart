import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/listing_grid.dart';
import '../../listings/presentation/fixtures/figma_preview_listings.dart';
import '../bloc/account_ui_cubit.dart';

class SellerProfileView extends StatelessWidget {
  const SellerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.sellerTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => context.push('/report/user/minh-anh'),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'report', child: Text(l10n.reportSeller)),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ResponsiveContent(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SellerIdentity(l10n: l10n),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    l10n.sellingListings,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(l10n.listingCountShort(3)),
                  ),
                ],
              ),
              ListingGrid(listings: figmaPreviewListings.take(4).toList()),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingsView extends StatelessWidget {
  const RatingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reviews = [
      const _ReviewData('TN', 'Thảo Nguyễn', '20/09/2026', 5),
      const _ReviewData('QH', 'Quốc Hưng', '15/09/2026', 5),
      const _ReviewData('BT', 'Bảo Trâm', '02/09/2026', 4),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.sellerRatingsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ResponsiveContent(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RatingSummary(l10n: l10n),
              const SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    l10n.communityReviews,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.reviewCount(48),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...reviews.map((review) => _ReviewCard(review: review)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomAction(
        label: l10n.writeReview,
        onPressed: () => context.push('/seller/minh-anh/review'),
      ),
    );
  }
}

class LeaveReviewView extends StatelessWidget {
  const LeaveReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<ReviewCubit, ReviewState>(
      listenWhen: (previous, current) =>
          !previous.submitted && current.submitted,
      listener: (context, state) => context.pop(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.leaveReviewTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ResponsiveContent(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SellerSummary(l10n: l10n),
                const SizedBox(height: 12),
                BlocBuilder<ReviewCubit, ReviewState>(
                  builder: (context, state) => _WhiteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reviewQuestion,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          children: List.generate(
                            5,
                            (index) => IconButton(
                              tooltip: l10n.starSelection(
                                index + 1,
                                l10n.selected,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 31,
                                height: 36,
                              ),
                              onPressed: () => context
                                  .read<ReviewCubit>()
                                  .ratingChanged(index + 1),
                              icon: Icon(
                                index < state.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.starSelection(
                            state.rating,
                            state.rating == 5 ? l10n.veryGood : l10n.selected,
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.optionalReview,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: context.read<ReviewCubit>().commentChanged,
                        minLines: 4,
                        maxLines: 4,
                        decoration: InputDecoration(hintText: l10n.reviewHint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.reviewGuidance,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomAction(
          label: l10n.submitReview,
          onPressed: context.read<ReviewCubit>().submitted,
        ),
      ),
    );
  }
}

enum ReportTarget { listing, user }

class ReportView extends StatelessWidget {
  const ReportView({required this.target, super.key});

  final ReportTarget target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = {
      'inappropriate': l10n.inappropriateContent,
      'fraud': l10n.suspectedFraud,
      'prohibited': l10n.prohibitedProduct,
      'misleading': l10n.misleadingInformation,
      'spam': l10n.spam,
      'other': l10n.otherReason,
    };
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) => state.submitted
          ? _ReportSuccess(l10n: l10n)
          : Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  target == ReportTarget.listing
                      ? l10n.reportListing
                      : l10n.reportUser,
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ResponsiveContent(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      target == ReportTarget.listing
                          ? _ReportedListing(l10n: l10n)
                          : _SellerSummary(l10n: l10n),
                      const SizedBox(height: 12),
                      Text(
                        l10n.reportReason,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reasons.entries.map(
                        (reason) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () => context
                                .read<ReportCubit>()
                                .reasonChanged(reason.key),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  _SelectionCircle(
                                    selected: state.reason == reason.key,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      reason.value,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        l10n.optionalDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: context
                            .read<ReportCubit>()
                            .descriptionChanged,
                        minLines: 3,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.reportDescriptionHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _BottomAction(
                label: l10n.submitReport,
                onPressed: context.read<ReportCubit>().submitted,
              ),
            ),
    );
  }
}

class _SellerIdentity extends StatelessWidget {
  const _SellerIdentity({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.infoBg,
              child: Text(
                'MA',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sellerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.sellerArea,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    l10n.sellerMemberSince,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SellerMetric(l10n.ratingValue, l10n.ratingCount(48)),
            ),
            Expanded(child: _SellerMetric(3.toString(), l10n.sellingListings)),
            Expanded(child: _SellerMetric(12.toString(), l10n.soldListings)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => context.push('/messages/minh-anh'),
                  child: Text(l10n.chat),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text(l10n.viewListings),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 19,
    height: 19,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? AppColors.primary : AppColors.surface,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    ),
    child: selected
        ? const Icon(Icons.circle, size: 7, color: AppColors.surface)
        : null,
  );
}

class _SellerMetric extends StatelessWidget {
  const _SellerMetric(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Column(
            children: [
              const Text(
                '4,9',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700),
              ),
              const Text(
                '★★★★★',
                style: TextStyle(color: AppColors.primary, fontSize: 18),
              ),
              Text(
                l10n.ratingCount(48),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            children: [
              _RatingBar(label: '5★', value: .88, count: 42),
              _RatingBar(label: '4★', value: .12, count: 5),
              _RatingBar(label: '3★', value: .04, count: 1),
              _RatingBar(label: '2★', value: 0, count: 0),
              _RatingBar(label: '1★', value: 0, count: 0),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.label,
    required this.value,
    required this.count,
  });
  final String label;
  final double value;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
        SizedBox(
          width: 20,
          child: Text(
            count.toString(),
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 9),
          ),
        ),
      ],
    ),
  );
}

class _ReviewData {
  const _ReviewData(this.initials, this.name, this.date, this.stars);
  final String initials;
  final String name;
  final String date;
  final int stars;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _ReviewData review;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    margin: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppColors.infoBg,
          child: Text(
            review.initials,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                review.date,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          List.filled(review.stars, '★').join(),
          style: const TextStyle(color: AppColors.primary, fontSize: 12),
        ),
      ],
    ),
  );
}

class _SellerSummary extends StatelessWidget {
  const _SellerSummary({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Row(
      children: [
        const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.infoBg,
          child: Text(
            'MA',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sellerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l10n.sellerRoleArea,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReportedListing extends StatelessWidget {
  const _ReportedListing({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset(
            'assets/images/marketplace/listing-camera.png',
            width: 54,
            height: 54,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reportedListingTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reportedListingMeta,
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
  );
}

class _ReportSuccess extends StatelessWidget {
  const _ReportSuccess({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(l10n.report)),
    body: ResponsiveContent(
      maxWidth: 560,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.successBg,
              child: Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.reportSuccessTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reportSuccessDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: Text(l10n.goBack),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.margin});
  final Widget child;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: margin,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(9),
    ),
    child: child,
  );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(onPressed: onPressed, child: Text(label)),
        ),
      ),
    ),
  );
}
