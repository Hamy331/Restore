import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/boost_listing_cubit.dart';

class BoostListingView extends StatelessWidget {
  const BoostListingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BoostListingCubit, BoostListingState>(
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            state.step == BoostStep.success ||
                    state.step == BoostStep.failed ||
                    state.step == BoostStep.cancelled ||
                    state.step == BoostStep.pending
                ? l10n.paymentResult
                : l10n.boostListing,
          ),
          actions: [
            PopupMenuButton<BoostStep>(
              onSelected: context.read<BoostListingCubit>().stepSelected,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: BoostStep.active,
                  child: Text(l10n.activeBoost),
                ),
                PopupMenuItem(
                  value: BoostStep.expired,
                  child: Text(l10n.expiredBoost),
                ),
                PopupMenuItem(
                  value: BoostStep.unavailable,
                  child: Text(l10n.boostUnavailable),
                ),
                PopupMenuItem(
                  value: BoostStep.failed,
                  child: Text(l10n.boostPaymentFailed),
                ),
                PopupMenuItem(
                  value: BoostStep.cancelled,
                  child: Text(l10n.boostPaymentCancelled),
                ),
                PopupMenuItem(
                  value: BoostStep.pending,
                  child: Text(l10n.boostPaymentPending),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ResponsiveContent(
            maxWidth: 720,
            child: _BoostContent(state: state, l10n: l10n),
          ),
        ),
        bottomNavigationBar: _BoostFooter(state: state, l10n: l10n),
      ),
    );
  }
}

class _BoostContent extends StatelessWidget {
  const _BoostContent({required this.state, required this.l10n});
  final BoostListingState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => switch (state.step) {
    BoostStep.packages => _PackageSelection(state: state, l10n: l10n),
    BoostStep.summary => _ServiceSummary(l10n: l10n),
    BoostStep.payment => _PaymentConfirmation(l10n: l10n),
    BoostStep.success => _PaymentSuccess(l10n: l10n),
    BoostStep.active => _StatusContent(
      icon: Icons.trending_up,
      color: AppColors.success,
      background: AppColors.successBg,
      title: l10n.activeBoost,
      description: l10n.activeBoostDescription,
      l10n: l10n,
    ),
    BoostStep.expired => _StatusContent(
      icon: Icons.schedule,
      color: AppColors.warning,
      background: AppColors.warningBg,
      title: l10n.expiredBoost,
      description: l10n.expiredBoostDescription,
      l10n: l10n,
    ),
    BoostStep.unavailable => _StatusContent(
      icon: Icons.block,
      color: AppColors.textSecondary,
      background: AppColors.surface,
      title: l10n.boostUnavailable,
      description: l10n.boostUnavailableDescription,
      l10n: l10n,
    ),
    BoostStep.failed ||
    BoostStep.cancelled ||
    BoostStep.pending => _PaymentState(state: state.step, l10n: l10n),
  };
}

class _PackageSelection extends StatelessWidget {
  const _PackageSelection({required this.state, required this.l10n});
  final BoostListingState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final packages = [
      _BoostPackage(
        'day',
        l10n.boost24Hours,
        l10n.visible24Hours,
        l10n.boostPrice24,
      ),
      _BoostPackage(
        'threeDays',
        l10n.boost3Days,
        l10n.visible3Days,
        l10n.boostPrice3Days,
      ),
      _BoostPackage(
        'sevenDays',
        l10n.boost7Days,
        l10n.visible7Days,
        l10n.boostPrice7Days,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListingSummary(l10n: l10n),
        const SizedBox(height: 12),
        _InfoCard(
          title: l10n.boostVisibilityTitle,
          description: l10n.boostVisibilityDescription,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.selectBoostDuration,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...packages.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () =>
                  context.read<BoostListingCubit>().packageChanged(item.id),
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: state.package == item.id
                      ? AppColors.cream
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.package == item.id
                        ? AppColors.primary
                        : AppColors.border,
                    width: state.package == item.id ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    _PackageSelectionCircle(selected: state.package == item.id),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(
          l10n.boostDemoPriceNote,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.confirmPromotionService,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      _ListingSummary(l10n: l10n),
      const SizedBox(height: 12),
      _SummaryCard(l10n: l10n),
      const SizedBox(height: 12),
      _InfoCard(
        title: l10n.restoreServiceFee,
        description: l10n.boostServiceBoundary,
      ),
      const SizedBox(height: 10),
      Text(
        l10n.boostDemoPriceNote,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _PackageSelectionCircle extends StatelessWidget {
  const _PackageSelectionCircle({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 19,
    height: 19,
    margin: const EdgeInsets.only(right: 10),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? AppColors.primary : AppColors.surface,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    ),
  );
}

class _PaymentConfirmation extends StatelessWidget {
  const _PaymentConfirmation({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _InfoCard(
        title: l10n.restoreServiceFee,
        description: l10n.boostServiceBoundary,
      ),
      const SizedBox(height: 12),
      _ListingSummary(l10n: l10n),
      const SizedBox(height: 12),
      _SummaryCard(l10n: l10n),
      const SizedBox(height: 12),
      _WhiteCard(
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.vnpay,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.vnpayDescription,
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
      ),
    ],
  );
}

class _PaymentSuccess extends StatelessWidget {
  const _PaymentSuccess({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.paymentSuccess,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              l10n.boostActivatedDescription,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.transactionDetails,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _SummaryRow(l10n.transactionCode, l10n.transactionCodeValue),
            _SummaryRow(l10n.amount, l10n.boostPrice3Days, emphasized: true),
            _SummaryRow(l10n.boostPeriod, l10n.threeDays),
            _SummaryRow(l10n.paymentMethod, l10n.vnpay),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _ListingSummary(l10n: l10n),
    ],
  );
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.description,
    required this.l10n,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String description;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _ListingSummary(l10n: l10n),
      const SizedBox(height: 12),
      _InfoCard(
        title: l10n.restoreServiceFee,
        description: l10n.boostServiceBoundary,
      ),
    ],
  );
}

class _PaymentState extends StatelessWidget {
  const _PaymentState({required this.state, required this.l10n});
  final BoostStep state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      BoostStep.failed => l10n.boostPaymentFailed,
      BoostStep.cancelled => l10n.boostPaymentCancelled,
      _ => l10n.boostPaymentPending,
    };
    final icon = state == BoostStep.pending
        ? Icons.schedule
        : Icons.error_outline;
    return _StatusContent(
      icon: icon,
      color: state == BoostStep.pending ? AppColors.warning : AppColors.error,
      background: state == BoostStep.pending
          ? AppColors.warningBg
          : AppColors.errorBg,
      title: title,
      description: l10n.boostServiceBoundary,
      l10n: l10n,
    );
  }
}

class _BoostFooter extends StatelessWidget {
  const _BoostFooter({required this.state, required this.l10n});
  final BoostListingState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (state.step == BoostStep.active ||
        state.step == BoostStep.unavailable ||
        state.step == BoostStep.pending) {
      return const SizedBox.shrink();
    }
    if (state.step == BoostStep.success) {
      return _TwoActions(
        primary: l10n.viewListing,
        secondary: l10n.backToManageListings,
        onPrimary: () => context.go('/listings/camera'),
        onSecondary: () => context.go('/manage-listings'),
      );
    }
    final label = switch (state.step) {
      BoostStep.summary => l10n.continuePayment,
      BoostStep.payment => l10n.confirmPayment,
      BoostStep.expired => l10n.boostAgain,
      BoostStep.failed || BoostStep.cancelled => l10n.tryPaymentAgain,
      _ => l10n.continueAction,
    };
    return _SingleAction(
      label: label,
      onPressed: context.read<BoostListingCubit>().continued,
    );
  }
}

class _ListingSummary extends StatelessWidget {
  const _ListingSummary({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset(
            'assets/images/marketplace/listing-camera.png',
            width: 78,
            height: 78,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.canonListingTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.canonPrice,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.listingVisibilityStatus,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Column(
      children: [
        _SummaryRow(l10n.boostPackage, l10n.threeDays),
        _SummaryRow(l10n.duration, l10n.seventyTwoHours),
        _SummaryRow(l10n.serviceFee, l10n.boostPrice3Days),
        const Divider(),
        _SummaryRow(
          l10n.totalServiceFee,
          l10n.boostPrice3Days,
          emphasized: true,
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w700 : null,
              color: emphasized
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: emphasized ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _SingleAction extends StatelessWidget {
  const _SingleAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(onPressed: onPressed, child: Text(label)),
        ),
      ),
    ),
  );
}

class _TwoActions extends StatelessWidget {
  const _TwoActions({
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onSecondary,
  });
  final String primary;
  final String secondary;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(onPressed: onPrimary, child: Text(primary)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondary),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BoostPackage {
  const _BoostPackage(this.id, this.title, this.description, this.price);
  final String id;
  final String title;
  final String description;
  final String price;
}
