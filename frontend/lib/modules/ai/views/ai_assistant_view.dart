import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/ai_assistant_cubit.dart';

class AiAssistantView extends StatelessWidget {
  const AiAssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AiAssistantCubit, AiAssistantState>(
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(l10n.restoreAi),
          actions: [
            PopupMenuButton<AiAssistantStatus>(
              onSelected: context.read<AiAssistantCubit>().statusSelected,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: AiAssistantStatus.welcome,
                  child: Text(l10n.aiStartOver),
                ),
                PopupMenuItem(
                  value: AiAssistantStatus.empty,
                  child: Text(l10n.aiEmptyStateMenu),
                ),
                PopupMenuItem(
                  value: AiAssistantStatus.error,
                  child: Text(l10n.aiErrorStateMenu),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ResponsiveContent(
                    maxWidth: 720,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _AiContent(state: state, l10n: l10n),
                    ),
                  ),
                ),
              ),
              _Composer(state: state, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.state, required this.l10n});
  final AiAssistantState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 688),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: ValueKey(state.query),
                textInputAction: TextInputAction.send,
                onChanged: context.read<AiAssistantCubit>().draftChanged,
                onSubmitted: context.read<AiAssistantCubit>().submitted,
                decoration: InputDecoration(hintText: l10n.aiInputHint),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              height: 42,
              child: ElevatedButton(
                onPressed: context.read<AiAssistantCubit>().draftSubmitted,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.arrow_upward, size: 20),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AiContent extends StatelessWidget {
  const _AiContent({required this.state, required this.l10n});
  final AiAssistantState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => switch (state.status) {
    AiAssistantStatus.welcome => _WelcomeState(l10n: l10n),
    AiAssistantStatus.results || AiAssistantStatus.filtered => _ResultsState(
      query: state.query,
      filtered: state.status == AiAssistantStatus.filtered,
      l10n: l10n,
    ),
    AiAssistantStatus.comparison => _ComparisonState(l10n: l10n),
    AiAssistantStatus.empty => _MessageState(
      icon: Icons.search_off,
      title: l10n.aiEmptyTitle,
      message: l10n.aiEmptyDescription,
      actionLabel: l10n.adjustRequest,
      status: AiAssistantStatus.welcome,
    ),
    AiAssistantStatus.error => _MessageState(
      icon: Icons.refresh,
      title: l10n.aiErrorTitle,
      message: l10n.aiErrorDescription,
      actionLabel: l10n.retry,
      status: AiAssistantStatus.results,
    ),
  };
}

class _WelcomeState extends StatelessWidget {
  const _WelcomeState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      l10n.aiSampleCameraQuery,
      l10n.aiSampleGamingQuery,
      l10n.aiSampleIphoneQuery,
      l10n.aiSampleStudentLaptopQuery,
    ];
    return Column(
      key: const ValueKey('welcome'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.askRestoreAi,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.aiIntro,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.quickPrompts,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...prompts.map(
          (prompt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.read<AiAssistantCubit>().submitted(prompt),
              icon: const Icon(Icons.search, size: 18),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(prompt),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ),
        _AiCard(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sellerOwnsListings,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l10n.sellerOwnsListingsDescription,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _AiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.continueConversation,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.continueConversationTips,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultsState extends StatelessWidget {
  const _ResultsState({
    required this.query,
    required this.filtered,
    required this.l10n,
  });
  final String query;
  final bool filtered;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('results'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: _QueryBubble(text: query.isEmpty ? l10n.aiDefaultQuery : query),
      ),
      const SizedBox(height: 12),
      _AiCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.primaryDark,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                filtered ? l10n.aiFilteredMessage : l10n.aiResultsMessage,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        l10n.matchingListingsDemo,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Divider(height: 22),
      _AiListing(
        title: l10n.canonListingTitle,
        price: l10n.canonPrice,
        location: l10n.canonLocationTime,
      ),
      const Divider(height: 12),
      _AiListing(
        title: l10n.nikonListingTitle,
        price: l10n.nikonPrice,
        location: l10n.nikonLocationTime,
      ),
      const SizedBox(height: 12),
      _AiCard(
        color: AppColors.background,
        child: Text(
          l10n.sellerDataCaveat,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        l10n.youCanAskNext,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () =>
            context.read<AiAssistantCubit>().submitted(l10n.canonOnly),
        icon: const Icon(Icons.search, size: 18),
        label: Text(l10n.canonOnly),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () =>
            context.read<AiAssistantCubit>().submitted(l10n.compareTheseTwo),
        icon: const Icon(Icons.search, size: 18),
        label: Text(l10n.compareTheseTwo),
      ),
    ],
  );
}

class _ComparisonState extends StatelessWidget {
  const _ComparisonState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('comparison'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: _QueryBubble(text: l10n.compareTheseTwo),
      ),
      const SizedBox(height: 12),
      _AiCard(
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.primaryDark,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.comparisonMessage,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        l10n.canonVsNikon,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(9),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _CompareRow(
              l10n.listing,
              l10n.canonListingTitle,
              l10n.nikonListingTitle,
              heading: true,
            ),
            _CompareRow(l10n.price, l10n.canonPrice, l10n.nikonPrice),
            _CompareRow(l10n.condition, l10n.goodCondition, l10n.notSpecified),
            _CompareRow(l10n.area, l10n.district1Hcm, l10n.district3Hcm),
            _CompareRow(l10n.posted, l10n.twoHoursAgo, l10n.yesterday),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _AiCard(
        color: AppColors.background,
        child: Text(
          l10n.sellerInfoOnly,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('/listings/camera'),
              child: Text(l10n.viewCanon),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('/listings/camera'),
              child: Text(l10n.viewNikon),
            ),
          ),
        ],
      ),
    ],
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.status,
  });
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final AiAssistantStatus status;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey(status),
    padding: const EdgeInsets.only(top: 70),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () =>
                context.read<AiAssistantCubit>().statusSelected(status),
            child: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.child, this.color = AppColors.cream});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _QueryBubble extends StatelessWidget {
  const _QueryBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 300),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}

class _AiListing extends StatelessWidget {
  const _AiListing({
    required this.title,
    required this.price,
    required this.location,
  });
  final String title;
  final String price;
  final String location;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/listings/camera'),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset(
            'assets/images/marketplace/listing-camera.png',
            width: 62,
            height: 62,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    ),
  );
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(
    this.label,
    this.first,
    this.second, {
    this.heading = false,
  });
  final String label;
  final String first;
  final String second;
  final bool heading;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 55),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    color: heading ? AppColors.cream : AppColors.surface,
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: heading ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: heading ? FontWeight.w700 : null,
            ),
          ),
        ),
        Expanded(
          child: Text(
            first,
            style: TextStyle(
              fontSize: 10,
              fontWeight: heading ? FontWeight.w700 : null,
            ),
          ),
        ),
        Expanded(
          child: Text(
            second,
            style: TextStyle(
              fontSize: 10,
              fontWeight: heading ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    ),
  );
}
