import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../stores/data/store_repository.dart';
import '../bloc/listing_form_cubit.dart';

class CreateListingView extends StatefulWidget {
  const CreateListingView({this.storeRepository, super.key});
  final StoreRepository? storeRepository;

  @override
  State<CreateListingView> createState() => _CreateListingViewState();
}

class _CreateListingViewState extends State<CreateListingView> {
  late final Future<List<StoreCategory>> _categories =
      (widget.storeRepository ?? StoreRepository()).categories();

  Future<void> _pickImages() async {
    try {
      final files = await ImagePicker().pickMultiImage();
      if (!mounted) return;
      final form = context.read<ListingFormCubit>();
      for (final file in files) {
        if (await file.length() > 5 * 1024 * 1024) {
          form.imageError('Mỗi ảnh phải nhỏ hơn 5 MB.');
          continue;
        }
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        form.addImage(bytes);
      }
    } catch (_) {
      if (mounted) {
        context.read<ListingFormCubit>().imageError(
          'Không đọc được ảnh. Vui lòng thử lại.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<ListingFormCubit, ListingFormState>(
      listenWhen: (previous, current) =>
          previous.createdId != current.createdId ||
          previous.finishedAsDraft != current.finishedAsDraft,
      listener: (context, state) {
        if (state.finishedAsDraft) {
          context.go(
            '/manage-listings?refresh=${DateTime.now().microsecondsSinceEpoch}',
          );
          return;
        }
        if (state.createdId.isNotEmpty) {
          if (state.editing) {
            context.go(
              '/manage-listings?refresh=${DateTime.now().microsecondsSinceEpoch}',
            );
          } else {
            context.go('/listings/${state.createdId}');
          }
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
                        state.listingStatus == 'DRAFT'
                            ? 'Tiếp tục bản nháp'
                            : state.editing
                            ? l10n.editListing
                            : l10n.createListing,
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
                child: state.editing && !state.isLoaded
                    ? Center(
                        child: state.isLoading
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: context
                                    .read<ListingFormCubit>()
                                    .load,
                                child: const Text(
                                  'Không tải được tin. Thử lại',
                                ),
                              ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ResponsiveContent(
                          maxWidth: 680,
                          child: state.step == 1
                              ? _StepOne(
                                  state: state,
                                  l10n: l10n,
                                  categories: _categories,
                                  onPickImages: _pickImages,
                                )
                              : _StepTwo(state: state, l10n: l10n),
                        ),
                      ),
              ),
              if (state.error.isNotEmpty)
                ResponsiveContent(
                  maxWidth: 680,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        state.error,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
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
  const _StepOne({
    required this.state,
    required this.l10n,
    required this.categories,
    required this.onPickImages,
  });
  final ListingFormState state;
  final AppLocalizations l10n;
  final Future<List<StoreCategory>> categories;
  final VoidCallback onPickImages;

  @override
  Widget build(BuildContext context) {
    final conditions = {
      'NEW': l10n.newCondition,
      'LIKE_NEW': 'Như mới',
      'USED_GOOD': l10n.usedCondition,
      'USED_FAIR': 'Đã sử dụng',
      'FOR_PARTS': 'Dùng lấy linh kiện',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<StoreCategory>>(
          future: categories,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Không tải được danh mục. Vui lòng mở lại màn hình.',
              );
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            return DropdownButtonFormField<String>(
              key: const ValueKey('listing-category'),
              initialValue: state.categoryId.isEmpty ? null : state.categoryId,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: [
                for (final category in snapshot.data!)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<ListingFormCubit>().categoryChanged(value);
                }
              },
            );
          },
        ),
        const SizedBox(height: 15),
        _ListingField(
          label: l10n.productName,
          initialValue: state.title,
          onChanged: context.read<ListingFormCubit>().titleChanged,
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
        Text(
          'Ảnh sản phẩm (${state.images.length}/6)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < state.images.length; i++)
              _ImageTile(
                image: state.images[i],
                index: i,
                count: state.images.length,
              ),
            if (state.images.length < 6)
              OutlinedButton.icon(
                onPressed: onPickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Thêm ảnh'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Ảnh đầu tiên là ảnh bìa. JPEG, PNG hoặc WebP, tối đa 5 MB mỗi ảnh.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.image,
    required this.index,
    required this.count,
  });
  final ListingFormImage image;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 132,
            height: 100,
            child: image.bytes != null
                ? Image.memory(image.bytes!, fit: BoxFit.cover)
                : Image.network(
                    image.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Chuyển ảnh sang trái',
              onPressed: index == 0
                  ? null
                  : () => context.read<ListingFormCubit>().moveImage(index, -1),
              icon: const Icon(Icons.arrow_back, size: 18),
            ),
            IconButton(
              tooltip: 'Xóa ảnh',
              onPressed: () =>
                  context.read<ListingFormCubit>().removeImage(index),
              icon: const Icon(Icons.close, size: 18),
            ),
            IconButton(
              tooltip: 'Chuyển ảnh sang phải',
              onPressed: index == count - 1
                  ? null
                  : () => context.read<ListingFormCubit>().moveImage(index, 1),
              icon: const Icon(Icons.arrow_forward, size: 18),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StepTwo extends StatelessWidget {
  const _StepTwo({required this.state, required this.l10n});
  final ListingFormState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
              if (!state.editing || state.listingStatus == 'DRAFT') ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: state.isSubmitting || !state.isLoaded
                        ? null
                        : context.read<ListingFormCubit>().saveDraft,
                    child: const Text('Lưu nháp'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting || !state.isLoaded
                        ? null
                        : state.step == 1
                        ? context.read<ListingFormCubit>().nextStep
                        : context.read<ListingFormCubit>().submit,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            state.step == 1
                                ? l10n.continueAction
                                : state.editing &&
                                      state.listingStatus != 'DRAFT'
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

class _ListingField extends StatelessWidget {
  const _ListingField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.helper,
    this.lines = 1,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? helper;
  final int lines;
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
        minLines: lines,
        maxLines: lines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: const InputDecoration(),
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
