import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/listing_form_cubit.dart';

class CreateListingView extends StatelessWidget {
  const CreateListingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<ListingFormCubit, ListingFormState>(
      listenWhen: (previous, current) =>
          previous.submitted != current.submitted ||
          previous.photoRequestVersion != current.photoRequestVersion,
      listener: (context, state) {
        if (state.submitted) {
          context.go('/manage-listings');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.featureApiPending(l10n.addPhotos))),
          );
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              ResponsiveContent(
                maxWidth: 680,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: state.step == 1 ? l10n.close : l10n.back,
                        onPressed: state.step == 2
                            ? context.read<ListingFormCubit>().previousStep
                            : () => context.go(
                                state.editing ? '/manage-listings' : '/home',
                              ),
                        icon: const Icon(Icons.arrow_back, size: 23),
                      ),
                      Text(
                        state.editing ? l10n.editListing : l10n.createListing,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.stepCount(state.step, 2),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(height: 4, color: AppColors.primary),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: state.step == 2
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ResponsiveContent(
                    maxWidth: 680,
                    child: state.step == 1
                        ? _StepOne(state: state, l10n: l10n)
                        : _StepTwo(state: state, l10n: l10n),
                  ),
                ),
              ),
              _ListingFooter(state: state, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepOne extends StatelessWidget {
  const _StepOne({required this.state, required this.l10n});
  final ListingFormState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final conditions = {'new': l10n.newCondition, 'used': l10n.usedCondition};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.productPhotosCount(2),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 78,
          child: Row(
            children: [
              const _PhotoTile(order: 1),
              const SizedBox(width: 8),
              const _PhotoTile(order: 2),
              const SizedBox(width: 8),
              InkWell(
                onTap: context.read<ListingFormCubit>().photosRequested,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.addPhotos,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          l10n.firstPhotoHint,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 15),
        _ListingField(
          label: l10n.productName,
          initialValue: state.title,
          onChanged: context.read<ListingFormCubit>().titleChanged,
        ),
        const SizedBox(height: 15),
        _ListingField(
          label: l10n.category,
          initialValue: l10n.electronicsCamera,
          readOnly: true,
          onChanged: context.read<ListingFormCubit>().categoryChanged,
        ),
        const SizedBox(height: 15),
        Text(
          l10n.condition,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          children: conditions.entries
              .map(
                (item) => ChoiceChip(
                  label: Text(item.value),
                  selected: state.condition == item.key,
                  showCheckmark: false,
                  selectedColor: AppColors.primarySoft,
                  side: BorderSide(
                    color: state.condition == item.key
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  onSelected: (_) => context
                      .read<ListingFormCubit>()
                      .conditionChanged(item.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _WarmNote(text: l10n.photoTip),
      ],
    );
  }
}

class _StepTwo extends StatelessWidget {
  const _StepTwo({required this.state, required this.l10n});
  final ListingFormState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final contacts = {'chat': l10n.chat, 'phone': l10n.phone};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListingField(
          label: l10n.salePrice,
          initialValue: state.price,
          helper: l10n.priceVndHint,
          keyboardType: TextInputType.number,
          onChanged: context.read<ListingFormCubit>().priceChanged,
        ),
        const SizedBox(height: 15),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                l10n.negotiable,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Switch(
                value: state.negotiable,
                activeTrackColor: AppColors.primary,
                onChanged: context.read<ListingFormCubit>().negotiableChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _ListingField(
          label: l10n.description,
          initialValue: state.description,
          lines: 4,
          onChanged: context.read<ListingFormCubit>().descriptionChanged,
        ),
        const SizedBox(height: 15),
        _ListingField(
          label: l10n.location,
          initialValue: state.location,
          onChanged: context.read<ListingFormCubit>().locationChanged,
        ),
        const SizedBox(height: 15),
        Text(
          l10n.contactPreference,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          children: contacts.entries
              .map(
                (item) => ChoiceChip(
                  label: Text(item.value),
                  selected: state.contact == item.key,
                  showCheckmark: false,
                  selectedColor: AppColors.primarySoft,
                  side: BorderSide(
                    color: state.contact == item.key
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  onSelected: (_) =>
                      context.read<ListingFormCubit>().contactChanged(item.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 26),
        Text(
          l10n.directArrangementNote,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ListingFooter extends StatelessWidget {
  const _ListingFooter({required this.state, required this.l10n});
  final ListingFormState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 648),
          child: Row(
            children: [
              if (state.step == 2) ...[
                SizedBox(
                  width: 116,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '/create-listing/preview?source=${state.editing ? 'edit' : 'create'}',
                    ),
                    child: Text(l10n.preview),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.step == 1
                        ? context.read<ListingFormCubit>().nextStep
                        : context.read<ListingFormCubit>().submitted,
                    child: Text(
                      state.step == 1
                          ? l10n.continueAction
                          : state.editing
                          ? l10n.saveChanges
                          : l10n.publishListing,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.order});
  final int order;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/marketplace/listing-camera.png',
          width: 78,
          height: 78,
          fit: BoxFit.cover,
        ),
      ),
      const Positioned(
        right: 4,
        top: 4,
        child: CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.surface,
          child: Icon(Icons.close, size: 15),
        ),
      ),
      Positioned(
        left: 4,
        bottom: 4,
        child: Container(
          width: 22,
          height: 19,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            order.toString(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  );
}

class _ListingField extends StatelessWidget {
  const _ListingField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.helper,
    this.lines = 1,
    this.readOnly = false,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? helper;
  final int lines;
  final bool readOnly;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: initialValue,
        readOnly: readOnly,
        minLines: lines,
        maxLines: lines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          suffixIcon: readOnly
              ? const Icon(Icons.chevron_right, size: 20)
              : null,
        ),
      ),
      if (helper != null) ...[
        const SizedBox(height: 6),
        Text(
          helper!,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ],
  );
}

class _WarmNote extends StatelessWidget {
  const _WarmNote({required this.text});
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
